extends HSplitContainer

const ScriptData = preload("./../script_data.gd")
const WordCountComparer = preload("./../word_count_comparer.gd")
const ThemeGenerator = preload("./../theme/theme_generator.gd")

const OCCURRENCES_IMAGE_BG_COLOR = Color(0, 0, 0, 0.8)
const OCCURRENCES_IMAGE_FG_COLOR = Color(1, 1, 1)

const SORT_BY_NAME = 0
const SORT_BY_WORD_COUNT = 1
const SORT_BY_FIRST_OCCURRENCE = 2

onready var _character_list := get_node("CharacterListContainer/CharacterList") as ItemList
onready var _character_sort_option_button := \
	get_node("CharacterListContainer/HBoxContainer/SortOption") as OptionButton
onready var _editors_container := get_node("VBoxContainer") as Control
onready var _occurrence_grid := get_node("VBoxContainer/OccurenceMap") as GridContainer
onready var _name_edit := get_node("VBoxContainer/HBoxContainer/GridContainer/LineEdit") as LineEdit
onready var _actor_edit := get_node("VBoxContainer/HBoxContainer/GridContainer/LineEdit3") as LineEdit
onready var _full_name_edit := \
	get_node("VBoxContainer/HBoxContainer/GridContainer/FullNameEdit") as LineEdit
onready var _description_edit := get_node("VBoxContainer/DescriptionEdit") as TextEdit
onready var _gender_selector := \
	get_node("VBoxContainer/HBoxContainer/GridContainer/GenderSelector") as OptionButton

var _project : ScriptData.Project = null
var _empty_texture : ImageTexture = null


func _ready():
	_character_sort_option_button.get_popup().add_item(tr("Name"), SORT_BY_NAME)
	_character_sort_option_button.get_popup().add_item(tr("Word Count"), SORT_BY_WORD_COUNT)
	_character_sort_option_button.get_popup().add_item(tr("First Occurrence"), SORT_BY_FIRST_OCCURRENCE)
	_character_sort_option_button.select(0)
	_character_sort_option_button.get_popup().connect("id_pressed", self, "_on_SortOption_id_pressed")

	_gender_selector.add_item(tr("Male"), ScriptData.GENDER_MALE)
	_gender_selector.add_item(tr("Female"), ScriptData.GENDER_FEMALE)
	_gender_selector.add_item(tr("Other"), ScriptData.GENDER_OTHER)


func set_project(project):
	_project = project
	
	if len(project.episodes) == 0:
		_update_characters_list(_project)
	else:
		for ep in project.episodes:
			refresh_episode(ep.file_path)
	

func refresh_episode(ep_path: String):
	_update_characters_list(_project)
	_generate_character_occurrence_maps_highp(_project, ep_path)


#func _notification(what):
#	if what == NOTIFICATION_VISIBILITY_CHANGED:
#		if visible:
#			_update_characters_list(_project)


func _set_editors_visible(visible):
	for i in _editors_container.get_child_count():
		var child = _editors_container.get_child(i)
		child.visible = visible


class FirstOccurrenceComparer:
	# character name => [first episode, first scene, first statement]
	var first_occurences : Dictionary
	func compare(a, b):
		var fa = null
		var fb = null
		if first_occurences.has(a):
			fa = first_occurences[a]
		if first_occurences.has(b):
			fb = first_occurences[b]
		if fa == null:
			if fb == null:
				return a < b
			else:
				return false
		else:
			if fb == null:
				return true
		if fa[0] < fb[0]:
			return true
		if fa[0] > fb[0]:
			return false
		if fa[1] < fb[1]:
			return true
		if fa[1] > fb[1]:
			return false
		if fa[2] < fb[2]:
			return true
		if fa[2] > fb[2]:
			return false
		return a < b


static func _get_first_occurrences(project):
	var characters = {}
	for i in len(project.episodes):
		var episode = project.episodes[i]
		for j in len(episode.scenes):
			var scene = episode.scenes[j]
			for k in len(scene.elements):
				var element = scene.elements[k]
				if element is ScriptData.Statement:
					if characters.has(element.character_name):
						continue
					characters[element.character_name] = [i, j, k]
	return characters


func _update_characters_list(project, sort_mode = -1):
	
	# Remember selection if any
	var selected = _character_list.get_selected_items()
	var selected_name = ""
	if len(selected) > 0:
		selected_name = _character_list.get_item_metadata(selected[0])
		
	_character_list.clear()
	
	var sorted_names = []
	if sort_mode == -1:
		sort_mode = _character_sort_option_button.selected
	
	for cname in project.characters:
		sorted_names.append(cname)

	match sort_mode:
		SORT_BY_NAME:
			sorted_names.sort()
			
		SORT_BY_WORD_COUNT:
			var comparer = WordCountComparer.new()
			comparer.word_count_totals = _project.get_word_count_totals()
			sorted_names.sort_custom(comparer, "compare")
		
		SORT_BY_FIRST_OCCURRENCE:
			var comparer = FirstOccurrenceComparer.new()
			comparer.first_occurences = _get_first_occurrences(_project)
			sorted_names.sort_custom(comparer, "compare")

	for cname in sorted_names:
		var i = _character_list.get_item_count()
		_character_list.add_item(cname)
		_character_list.set_item_metadata(i, cname)
		
		if cname == selected_name:
			_character_list.select(i)
	
	_set_editors_visible(len(_character_list.get_selected_items()) != 0)


func _on_ScriptEditor_script_parsed(project, script_path):
	_update_characters_list(project)
	_generate_character_occurrence_maps_highp(project, script_path)


static func _generate_character_occurrence_maps_highp(project, episode_path):
	var episode = project.get_episode_from_path(episode_path)

	var total_word_count = 0
	var statements = []
	for scene in episode.scenes:
		for elem in scene.elements:
			if elem is ScriptData.Statement:
				statements.append(elem)
				total_word_count += elem.word_count
	
	var images = {}
	
	for character_name in episode.character_occurrences:
		var im = Image.new()
		var width = total_word_count
		if width == 0:
			width = 1
		im.create(width, 1, false, Image.FORMAT_RGBA8)
		im.fill(OCCURRENCES_IMAGE_BG_COLOR)
		images[character_name] = im
		im.lock()
	
	var pos = 0
	for statement in statements:
		# Some characters can be ignored (i.e crowd/everyone)
		if images.has(statement.character_name):
			var im = images[statement.character_name]
			for i in statement.word_count:
				im.set_pixel(pos + i, 0, OCCURRENCES_IMAGE_FG_COLOR)
		pos += statement.word_count

	for character_name in images:
		var im = images[character_name]
		im.unlock()
		var occurrence = episode.character_occurrences[character_name]
		occurrence.image = images[character_name]
		occurrence.texture = null


#static func _generate_character_occurrence_maps_lowp(project, episode_path):
#	var episode = project.get_episode_from_path(episode_path)
#
#	var statements = []
#	for scene in episode.scenes:
#		for elem in scene.elements:
#			if elem is ScriptData.Statement:
#				statements.append(elem)
#
#	var images = {}
#
#	for character_name in episode.character_occurrences:
#		var im = Image.new()
#		var width = len(statements)
#		if width == 0:
#			width = 1
#		im.create(width, 1, false, Image.FORMAT_RGB8)
#		im.fill(OCCURRENCES_IMAGE_BG_COLOR)
#		images[character_name] = im
#		im.lock()
#
#	for i in len(statements):
#		var statement = statements[i]
#		# Some characters can be ignored (i.e crowd/everyone)
#		if images.has(statement.character_name):
#			var im = images[statement.character_name]
#			im.set_pixel(i, 0, OCCURRENCES_IMAGE_FG_COLOR)
#
#	for character_name in images:
#		var im = images[character_name]
#		im.unlock()
#		var occurrence = episode.character_occurrences[character_name]
#		occurrence.image = images[character_name]
#		occurrence.texture = null


func _on_CharacterList_item_selected(index: int):
	
	_set_editors_visible(true)
	
	var character_name := _character_list.get_item_metadata(index) as String
	
	var character : ScriptData.Character = _project.characters[character_name]
	var actor : ScriptData.Actor = _project.get_actor_by_id(character.actor_id)
	if actor == null:
		_actor_edit.text = ""
	else:
		_actor_edit.text = actor.name

	for i in _gender_selector.get_item_count():
		if _gender_selector.get_item_id(i) == character.gender:
			_gender_selector.selected = i
			break
	
	_name_edit.text = character_name
	_full_name_edit.text = character.full_name
	_description_edit.text = character.description
	_description_edit.clear_undo_history()
	
	# Display occurrence grid
	
	for i in _occurrence_grid.get_child_count():
		var child = _occurrence_grid.get_child(i)
		child.queue_free()
	
	var label := Label.new()
	label.text = tr("Episode")
	_occurrence_grid.add_child(label)
	
	_occurrence_grid.add_child(Control.new())
	
	label = Label.new()
	label.text = tr("Occurrences")
	_occurrence_grid.add_child(label)

	label = Label.new()
	label.text = tr("Recorded")
	_occurrence_grid.add_child(label)
	
	_occurrence_grid.add_child(HSeparator.new())
	_occurrence_grid.add_child(HSeparator.new())
	_occurrence_grid.add_child(HSeparator.new())
	_occurrence_grid.add_child(HSeparator.new())
	
	var checkbox_styles := ThemeGenerator.make_button_styleboxes()
	for k in checkbox_styles:
		var sb := checkbox_styles[k] as StyleBoxFlat
		sb.set_expand_margin_all(0)
		sb.content_margin_left = 0
		sb.content_margin_right = 0
		sb.content_margin_top = 0
		sb.content_margin_bottom = 0
	
	for i in len(_project.episodes):
		var episode := _project.episodes[i] as ScriptData.Episode
		
		var word_count := 0
		var tex : ImageTexture = null
		
		var occurrence = null
		if episode.character_occurrences.has(character_name):
			occurrence = episode.character_occurrences[character_name]
			tex = occurrence.texture
			word_count = occurrence.word_count
			if tex == null:
				tex = ImageTexture.new()
				tex.create_from_image(occurrence.image, Texture.FLAG_FILTER)
				occurrence.texture = tex
		
		if tex == null:
			if _empty_texture == null:
				var im := Image.new()
				im.create(1, 1, false, Image.FORMAT_RGBA8)
				im.fill(OCCURRENCES_IMAGE_BG_COLOR)
				_empty_texture = ImageTexture.new()
				_empty_texture.create_from_image(im, Texture.FLAG_FILTER)
			tex = _empty_texture
		
		var ep_name_label := Label.new()
		ep_name_label.text = str(episode.title, "    ")
		_occurrence_grid.add_child(ep_name_label)
		
		var word_count_label := Label.new()
		word_count_label.text = str(word_count, " ", tr("words"), "    ")
		_occurrence_grid.add_child(word_count_label)

		var tex_control := TextureRect.new()
		tex_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tex_control.stretch_mode = TextureRect.STRETCH_SCALE
		tex_control.expand = true
		tex_control.texture = tex
		var mod = get_color("accent_color", "App").lightened(0.2)
		tex_control.modulate = mod
		_occurrence_grid.add_child(tex_control)

		var recorded_checkbox := CheckBox.new()
		for k in checkbox_styles:
			var sb = checkbox_styles[k]
			recorded_checkbox.add_stylebox_override(k, sb)
		
		if word_count == 0:
			ep_name_label.modulate = Color(1,1,1, 0.5)
			word_count_label.modulate = Color(1,1,1, 0.5)
			tex_control.modulate = Color(mod.r, mod.g, mod.b, mod.a * 0.5)
			recorded_checkbox.disabled = true
			recorded_checkbox.modulate = Color(0,0,0,0)
		else:
			recorded_checkbox.pressed = occurrence.recorded
			recorded_checkbox.connect("toggled", self, "_on_RecordedCheckbox_toggled", \
				[episode.file_path, character_name])
		
		_occurrence_grid.add_child(recorded_checkbox)


func _on_RecordedCheckbox_toggled(checked, episode_path, character_name):
	var ep = _project.get_episode_from_path(episode_path)
	var occurrence = ep.character_occurrences[character_name]
	occurrence.recorded = checked
	_project.make_modified()


func _on_SortOption_id_pressed(id):
	_update_characters_list(_project, id)


func _get_current_character_name() -> String:
	var selected = _character_list.get_selected_items()
	if len(selected) == 0:
		return ""
	return _character_list.get_item_metadata(selected[0])


func _get_current_character():
	var cname = _get_current_character_name()
	if _project.characters.has(cname):
		return _project.characters[cname]
	return null


func _on_FullNameEdit_text_changed(new_text: String):
	var character : ScriptData.Character = _get_current_character()
	assert(character != null)
	character.full_name = new_text.strip_edges()
	_project.make_modified()


func _on_DescriptionEdit_text_changed():
	var character : ScriptData.Character = _get_current_character()
	assert(character != null)
	character.description = _description_edit.text
	_project.make_modified()


func _on_GenderSelector_item_selected(id):
	var character : ScriptData.Character = _get_current_character()
	assert(character != null)
	character.gender = id
	_project.make_modified()
	
