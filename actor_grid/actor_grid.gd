extends Control

const WordCountComparer = preload("./../word_count_comparer.gd")

const SHORT_EPISODE_NAME_MAX_LENGTH = 12
const NOT_STARTED_COLOR = Color(1, 0.5, 0.5)
const IN_PROGRESS_COLOR = Color(1, 1, 0.5)
const COMPLETED_COLOR = Color(0.5, 1, 0.5)

onready var _grid_container = get_node("ScrollContainer/GridContainer")

var _project = null
var _progress_labels = {}


func set_project(project):
	_project = project
	_refresh_all()


func _refresh_all():
	_progress_labels.clear()

	var character_names = _project.characters.keys()
	var word_count_comparer = WordCountComparer.new()
	word_count_comparer.word_count_totals = _project.get_word_count_totals()
	character_names.sort_custom(word_count_comparer, "compare")

	for i in _grid_container.get_child_count():
		var child = _grid_container.get_child(i)
		child.queue_free()
	
	_grid_container.columns = 2 + len(_project.episodes)
	
	var spacer = Control.new()
	_grid_container.add_child(spacer)

	spacer = Control.new()
	_grid_container.add_child(spacer)
	
	for ep in _project.episodes:
		var short_name = ep.file_path.get_file().get_basename()
		short_name = get_right_ellipsis(short_name, SHORT_EPISODE_NAME_MAX_LENGTH)
		var ep_label = Label.new()
		ep_label.rect_min_size = Vector2(50, 0)
		ep_label.text = short_name
		_grid_container.add_child(ep_label)

	spacer = Control.new()
	_grid_container.add_child(spacer)

	spacer = Control.new()
	_grid_container.add_child(spacer)
	
	for ep in _project.episodes:
		var progress_label = Label.new()
		progress_label.text = "---%"
		_progress_labels[ep.file_path] = progress_label
		_grid_container.add_child(progress_label)	
	
	for character_name in character_names:
		var character = _project.characters[character_name]
		var actor = _project.get_actor_by_id(character.actor_id)
		
		var character_label = Label.new()
		character_label.text = character.name
		_grid_container.add_child(character_label)
		
		var actor_button = Button.new()
		if actor != null:
			actor_button.text = actor.name
		else:
			actor_button.text = "---"
		actor_button.connect("pressed", self, "_on_ActorButton_pressed", [character_name])
		_grid_container.add_child(actor_button)
		
		for ep in _project.episodes:
			if ep.character_occurrences.has(character_name):
				
				var occurence = ep.character_occurrences[character_name]
				var recorded_checkbox = CheckBox.new()
				recorded_checkbox.pressed = occurence.recorded
				#recorded_checkbox.flat = true
				var ep_name = ep.file_path.get_file().get_basename()
				recorded_checkbox.hint_tooltip = str("Recorded ", ep_name)
				
				recorded_checkbox.connect("toggled", self, "_on_RecordedCheckBox_toggled", \
					[character_name, ep.file_path])
				
				_grid_container.add_child(recorded_checkbox)
				
			else:
				spacer = Control.new()
				_grid_container.add_child(spacer)

	for ep in _project.episodes:
		_update_progress(ep.file_path)


static func get_right_ellipsis(text, max_len):
	if len(text) > max_len:
		return "…" + text.right(len(text) - max_len)
	return text


func _on_RecordedCheckBox_toggled(checked, character_name, episode_path):
	var ep = _project.get_episode_from_path(episode_path)
	var occurrence = ep.character_occurrences[character_name]
	occurrence.recorded = checked
	_update_progress(episode_path)


func _on_ActorButton_pressed(character_name):
	# TODO Allow to change actor by clicking on the button
	pass


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
	var label = _progress_labels[episode.file_path]
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
