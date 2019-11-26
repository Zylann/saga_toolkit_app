extends HSplitContainer

const ScriptData = preload("./../script_data.gd")
const WordCountComparer = preload("./../word_count_comparer.gd")

#signal characters_list_changed(names)

const OCCURRENCES_IMAGE_BG_COLOR = Color(0, 0, 0, 0.8)
const OCCURRENCES_IMAGE_FG_COLOR = Color(1, 1, 1)

const SORT_BY_NAME = 0
const SORT_BY_WORD_COUNT = 1

onready var _character_list = get_node("CharacterListContainer/CharacterList")
onready var _character_sort_option_button = \
	get_node("CharacterListContainer/HBoxContainer/SortOption")
onready var _occurrence_grid = get_node("VBoxContainer/OccurenceMap")
onready var _name_edit = get_node("VBoxContainer/HBoxContainer/GridContainer/LineEdit")
onready var _actor_edit = get_node("VBoxContainer/HBoxContainer/GridContainer/LineEdit3")

var _project = null
var _empty_texture = null


func _ready():
	_character_sort_option_button.get_popup().add_item(tr("Name"), SORT_BY_NAME)
	_character_sort_option_button.get_popup().add_item(tr("Word Count"), SORT_BY_WORD_COUNT)
	_character_sort_option_button.select(0)
	_character_sort_option_button.get_popup().connect("id_pressed", self, "_on_SortOption_id_pressed")


func set_project(project):
	_project = project
	_update_characters_list(_project)
	
	for ep in project.episodes:
		_generate_character_occurrence_maps_highp(project, ep.file_path)
	
	# TODO Show/hide controls depending on active selection


func _update_characters_list(project, sort_mode = -1):
	
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

	for cname in sorted_names:
		var i = _character_list.get_item_count()
		_character_list.add_item(cname)
		_character_list.set_item_metadata(i, cname)

	#emit_signal("characters_list_changed", project)


func _on_ScriptEditor_script_parsed(project, script_path, errors):
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


func _on_CharacterList_item_selected(index):
	var character_name = _character_list.get_item_metadata(index)
	
	_name_edit.text = character_name
	
	var character = _project.characters[character_name]
	var actor = _project.get_actor_by_id(character.actor_id)
	if actor == null:
		_actor_edit.text = ""
	else:
		_actor_edit.text = actor.name
	
	# Display occurrence grid
	
	for i in _occurrence_grid.get_child_count():
		var child = _occurrence_grid.get_child(i)
		child.queue_free()
	
	for i in len(_project.episodes):
		var episode = _project.episodes[i]
		
		var word_count = 0
		var tex = null
		
		if episode.character_occurrences.has(character_name):
			var occurrence = episode.character_occurrences[character_name]
			tex = occurrence.texture
			word_count = occurrence.word_count
			if tex == null:
				tex = ImageTexture.new()
				tex.create_from_image(occurrence.image, Texture.FLAG_FILTER)
				occurrence.texture = tex
		
		if tex == null:
			if _empty_texture == null:
				var im = Image.new()
				im.create(1, 1, false, Image.FORMAT_RGBA8)
				im.fill(OCCURRENCES_IMAGE_BG_COLOR)
				_empty_texture = ImageTexture.new()
				_empty_texture.create_from_image(im, Texture.FLAG_FILTER)
			tex = _empty_texture
		
		var ep_name_label = Label.new()
		ep_name_label.text = str(episode.title, "    ")
		_occurrence_grid.add_child(ep_name_label)
		
		var word_count_label = Label.new()
		word_count_label.text = str(word_count, " ", tr("words"), "    ")
		_occurrence_grid.add_child(word_count_label)

		var tex_control = TextureRect.new()
		tex_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tex_control.stretch_mode = TextureRect.STRETCH_SCALE
		tex_control.expand = true
		tex_control.texture = tex
		var mod = get_color("accent_color", "App").lightened(0.2)
		tex_control.modulate = mod
		_occurrence_grid.add_child(tex_control)

		if word_count == 0:
			ep_name_label.modulate = Color(1,1,1, 0.5)
			word_count_label.modulate = Color(1,1,1, 0.5)
			tex_control.modulate = Color(mod.r, mod.g, mod.b, mod.a * 0.5)


func _on_SortOption_id_pressed(id):
	_update_characters_list(_project, id)
