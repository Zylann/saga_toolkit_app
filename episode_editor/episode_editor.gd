extends HSplitContainer

const WordCountComparer = preload("./../word_count_comparer.gd")
const ScriptData = preload("./../script_data.gd")
const PostDialogScene = preload("./episode_post_dialog.tscn")

const NOT_STARTED_COLOR = Color(1, 0.5, 0.5)
const IN_PROGRESS_COLOR = Color(1, 1, 0.5)
const COMPLETED_COLOR = Color(0.5, 1, 0.5)

onready var _episode_list = get_node("EpisodeList")
onready var _title_edit = get_node("VBoxContainer/Properties/TitleEdit")
onready var _synopsis_edit = get_node("VBoxContainer/Properties/Synopsis")
onready var _controls_container = get_node("VBoxContainer")
onready var _progress_label = get_node("VBoxContainer/HBoxContainer/ProgressLabel")
onready var _character_grid = get_node("VBoxContainer/ScrollContainer/CharacterGrid")

var _project : ScriptData.Project = null
var _post_dialog = null


func setup_dialogs(parent):
	assert(_post_dialog == null)
	_post_dialog = PostDialogScene.instance()
	parent.add_child(_post_dialog)


func set_project(project):
	_project = project
	_update_episode_list()
	_update_controls()


func _update_episode_list():
	
	# Remember selection
	var selected = _episode_list.get_selected_items()
	var selected_ep = ""
	if len(selected) != 0:
		selected_ep = _episode_list.get_item_metadata(selected[0])
	
	_episode_list.clear()
	for ep in _project.episodes:
		var i = _episode_list.get_item_count()
		_episode_list.add_item(ep.title)
		_episode_list.set_item_metadata(i, ep.file_path)
	_episode_list.sort_items_by_text()
	
	if selected_ep != "":
		for i in _episode_list.get_item_count():
			if _episode_list.get_item_metadata(i) == selected_ep:
				_episode_list.select(i)
				break


func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			_update_episode_list()
			_update_controls()


func _update_controls():
	
	# Clear all

	for i in _character_grid.get_child_count():
		var child = _character_grid.get_child(i)
		child.queue_free()

	var selection = _episode_list.get_selected_items()
	var episode = null
	if len(selection) > 0:
		var ep_path = _episode_list.get_item_metadata(selection[0])
		episode = _project.get_episode_from_path(ep_path)
	
	for i in _controls_container.get_child_count():
		var child = _controls_container.get_child(i)
		child.visible = (episode != null)
	
	if episode == null:
		return
	
	# Properties
	
	_title_edit.text = episode.title
	_synopsis_edit.text = episode.synopsis
	
	# Character grid
	
	_update_progress(episode.file_path)
	
	var character_names = episode.character_occurrences.keys()
	
	var word_counts = {}
	for cname in character_names:
		var occurrence = episode.character_occurrences[cname]
		word_counts[cname] = occurrence.word_count
	
	var comparer = WordCountComparer.new()
	comparer.word_count_totals = word_counts
	character_names.sort_custom(comparer, "compare")
	
	var label = Label.new()
	label.text = tr("Character")
	_character_grid.add_child(label)

	label = Label.new()
	label.text = tr("Actor")
	_character_grid.add_child(label)

	label = Label.new()
	label.text = tr("Recorded")
	_character_grid.add_child(label)
	
	_character_grid.add_child(HSeparator.new())
	_character_grid.add_child(HSeparator.new())
	_character_grid.add_child(HSeparator.new())
	
	for cname in character_names:
		var occurrence = episode.character_occurrences[cname]
		var character = _project.characters[cname]
		var actor = _project.get_actor_by_id(character.actor_id)
		
		var character_label = Label.new()
		character_label.text = cname
		character_label.rect_min_size = Vector2(200, 0)
		_character_grid.add_child(character_label)
		
		var actor_label = Label.new()
		if actor != null:
			actor_label.text = actor.name
		else:
			actor_label.text = "---"
		actor_label.rect_min_size = Vector2(200, 0)
		_character_grid.add_child(actor_label)
		
		var recorded_checkbox = CheckBox.new()
		recorded_checkbox.pressed = occurrence.recorded
		recorded_checkbox.connect("toggled", self, "_on_RecordedCheckbox_toggled",\
			[cname, episode.file_path])
		_character_grid.add_child(recorded_checkbox)


func _on_RecordedCheckbox_toggled(checked, character_name, episode_path):
	var ep = _project.get_episode_from_path(episode_path)
	var occurrence = ep.character_occurrences[character_name]
	occurrence.recorded = checked
	_update_progress(episode_path)
	_project.make_modified()


func _update_progress(episode_path):
	var episode = _project.get_episode_from_path(episode_path)
	if episode == null:
		push_error("Episode not found: {0}".format([episode_path]))
		return
	var recorded_count = 0
	for cname in episode.character_occurrences:
		var occurrence = episode.character_occurrences[cname]
		if occurrence.recorded:
			recorded_count += 1
	var label = _progress_label
	var pc = 100
	if len(episode.character_occurrences) > 0:
		pc = int(round(100.0 * float(recorded_count) / float(len(episode.character_occurrences))))
	label.text = str(pc, "%")
	
	if pc == 0:
		label.modulate = NOT_STARTED_COLOR
	elif pc < 100:
		label.modulate = IN_PROGRESS_COLOR
	else:
		label.modulate = COMPLETED_COLOR


func _on_EpisodeList_item_selected(index):
	_update_controls()


func _get_selected_episode_path():
	var selected = _episode_list.get_selected_items()
	if len(selected) == 0:
		return ""
	return _episode_list.get_item_metadata(selected[0])


func _on_Synopsis_text_changed():
	var ep = _project.get_episode_from_path(_get_selected_episode_path())
	ep.synopsis = _synopsis_edit.text
	_project.make_modified()


func _on_GeneratePost_pressed():
	_post_dialog.configure(_project, _get_selected_episode_path())
	_post_dialog.popup_centered_ratio()
