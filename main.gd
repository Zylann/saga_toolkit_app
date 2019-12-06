extends Panel

const UserPrefs = preload("./util/userprefs.gd")
const ScriptData = preload("./script_data.gd")
const Errors = preload("./util/errors.gd")
const ThemeGenerator = preload("./theme/theme_generator.gd")
const ScriptParser = preload("./script_parser.gd")

onready var _project_menu = get_node("VBoxContainer/MenuBar/ProjectMenu")
onready var _edit_menu = get_node("VBoxContainer/MenuBar/EditMenu")
onready var _help_menu = get_node("VBoxContainer/MenuBar/HelpMenu")
onready var _script_editor = get_node("VBoxContainer/TabContainer/ScriptEditor")
onready var _character_editor = get_node("VBoxContainer/TabContainer/CharacterEditor")
onready var _actor_editor = get_node("VBoxContainer/TabContainer/ActorEditor")
onready var _episode_editor = get_node("VBoxContainer/TabContainer/EpisodeEditor")
onready var _project_editor = get_node("VBoxContainer/TabContainer/ProjectEditor")
onready var _tab_container = get_node("VBoxContainer/TabContainer")
onready var _about_window = get_node("AboutWindow")
onready var _preferences_window = get_node("PreferencesDialog")
onready var _status_label = get_node("VBoxContainer/StatusBar/Label")

const MENU_PROJECT_NEW = 0
const MENU_PROJECT_OPEN = 1
const MENU_PROJECT_SAVE = 2
const MENU_PROJECT_SAVE_AS = 3

const MENU_EDIT_PREFERENCES = 0

const MENU_HELP_ABOUT = 0

var _project = ScriptData.Project.new()
var _open_project_dialog = null
var _save_project_dialog = null


func _init():
	var locale = UserPrefs.get_value("locale")
	if locale != null:
		TranslationServer.set_locale(locale)


func _ready():
	theme = ThemeGenerator.get_theme()
	
	_project_menu.get_popup().add_item(tr("New"), MENU_PROJECT_NEW)
	_project_menu.get_popup().add_item(tr("Open..."), MENU_PROJECT_OPEN)
	_project_menu.get_popup().add_item(tr("Save"), MENU_PROJECT_SAVE)
	_project_menu.get_popup().add_item(tr("Save As..."), MENU_PROJECT_SAVE_AS)
	_project_menu.get_popup().connect("id_pressed", self, "_on_ProjectMenu_id_pressed")
	
	_edit_menu.get_popup().add_item(tr("Preferences"), MENU_EDIT_PREFERENCES)
	_edit_menu.get_popup().connect("id_pressed", self, "_on_EditMenu_id_pressed")
	
	_help_menu.get_popup().add_item(tr("About..."), MENU_HELP_ABOUT)
	_help_menu.get_popup().connect("id_pressed", self, "_on_HelpMenu_id_pressed")
		
	_script_editor.connect("script_parsed", _character_editor, "_on_ScriptEditor_script_parsed")
	_script_editor.connect("script_parsed", self, "_on_ScriptEditor_script_parsed")
	_script_editor.connect("script_removed", self, "_on_ScriptEditor_script_removed")
	
	var dialogs_parent = self

	var fd = FileDialog.new()
	fd.mode = FileDialog.MODE_OPEN_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.window_title = tr("Open Project")
	fd.resizable = true
	fd.add_filter("*.stk ; STK Project Files")
	fd.connect("file_selected", self, "_on_OpenProjectDialog_file_selected")
	dialogs_parent.add_child(fd)
	_open_project_dialog = fd

	fd = FileDialog.new()
	fd.mode = FileDialog.MODE_SAVE_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.window_title = tr("Save Project As")
	fd.resizable = true
	fd.add_filter("*.stk ; STK Project Files")
	fd.connect("file_selected", self, "_on_SaveProjectDialog_file_selected")
	dialogs_parent.add_child(fd)
	_save_project_dialog = fd
	
	_tab_container.set_tab_title(_script_editor.get_index(), tr("Script"))
	_tab_container.set_tab_title(_character_editor.get_index(), tr("Characters"))
	_tab_container.set_tab_title(_actor_editor.get_index(), tr("Actors"))
	_tab_container.set_tab_title(_episode_editor.get_index(), tr("Episodes"))
	_tab_container.set_tab_title(_project_editor.get_index(), tr("Project"))
	
	_actor_editor.setup_dialogs(dialogs_parent)

	_set_project(_project)


func _on_ScriptEditor_script_parsed(project, path, errors):
	
	if len(errors) > 0:
		if len(errors) == 1:
			_status_label.text = "Found 1 error in script"
		else:
			_status_label.text = "Found {0} errors in script".format([len(errors)])
		_status_label.modulate = Color(1, 0.2, 0.1)
	else:
		_status_label.text = "Script successfully parsed"
		_status_label.modulate = Color(1, 1, 1)
	
	_character_editor.refresh_episode(path)


func _on_ScriptEditor_script_removed(path):
	pass


func _on_ProjectMenu_id_pressed(id):
	match id:
		MENU_PROJECT_NEW:
			_close_project()
		
		MENU_PROJECT_OPEN:
			_trigger_open_project_dialog()
		
		MENU_PROJECT_SAVE:
			_save_project()
		
		MENU_PROJECT_SAVE_AS:
			_save_project_dialog.popup_centered_ratio()


func _on_EditMenu_id_pressed(id):
	match id:
		MENU_EDIT_PREFERENCES:
			_preferences_window.popup_centered_minsize()


func _on_HelpMenu_id_pressed(id):
	match id:
		MENU_HELP_ABOUT:
			_about_window.popup_centered_minsize()


func _trigger_open_project_dialog():
	var dir = UserPrefs.get_value("last_open_project_path")
	if dir != null:
		_open_project_dialog.current_dir = dir
	_open_project_dialog.popup_centered_ratio()


func _on_OpenProjectDialog_file_selected(fpath):
	_open_project(fpath)
	UserPrefs.set_value("last_open_project_path", fpath.get_base_dir())


func _on_SaveProjectDialog_file_selected(fpath):
	_save_project_as(fpath)
	UserPrefs.set_value("last_open_project_path", fpath.get_base_dir())


func _save_project():
	if _project.file_path == "":
		_save_project_dialog.popup_centered_ratio()
	else:
		_save_project_as(_project.file_path)


func _save_project_as(fpath):
	
	var dir = fpath.get_base_dir()
	
	var episodes = []
	for episode in _project.episodes:
		if episode.file_path != "":
			var path = episode.file_path
			# Relative path
			path = path.right(1 + len(dir))
			var ep_data = {
				"file_path": path,
				"character_occurrences": []
			}
			episodes.append(ep_data)
			for cname in episode.character_occurrences:
				var occurrence = episode.character_occurrences[cname]
				var occurrence_data = {
					"character_name": cname,
					"recorded": occurrence.recorded
				}
				ep_data.character_occurrences.append(occurrence_data)
	
	var characters = []
	for cname in _project.characters:
		var character = _project.characters[cname]
		var char_data = {
			"name": character.name,
			"full_name": character.full_name,
			"gender": character.gender,
			"description": character.description,
			"actor_id": character.actor_id
		}
		characters.append(char_data)
	
	var actors = []
	for actor in _project.actors:
		var actor_data = {
			"id": actor.id,
			"name": actor.name,
			"gender": actor.gender,
			"notes": actor.notes
		}
		actors.append(actor_data)
	
	var data = {
		"title": _project.title,
		"episodes": episodes,
		"actors": actors,
		"characters": characters
	}
	
	if _save_project_file(data, fpath):
		_project.file_path = fpath


func _close_project():
	_set_project(ScriptData.Project.new())


func _set_project(project):
	_project = project
	_script_editor.set_project(_project)
	_character_editor.set_project(_project)
	_actor_editor.set_project(_project)
	_episode_editor.set_project(_project)


func _open_project(fpath):
	_close_project()

	var data = _load_project_file(fpath)
	if data == null:
		return
	
	for char_data in data.characters:
		var character = ScriptData.Character.new()
		character.name = char_data.name
		character.actor_id = int(char_data.actor_id)
		if char_data.has("description"):
			character.description = char_data.description
		if char_data.has("full_name"):
			character.full_name = char_data.full_name
		if char_data.has("gender"):
			character.gender = int(char_data.gender)
		else:
			character.gender = ScriptData.GENDER_OTHER
		if _project.characters.has(character.name):
			push_error("Project file contains two characters with the same name")
			continue
		_project.characters[character.name] = character
	
	_project.title = data.title
	
	if len(data.episode_files) > 0:
		# Legacy
		var dir = fpath.get_base_dir()
		for ep_file_rpath in data.episode_files:
			var path = dir.plus_file(ep_file_rpath)
			ScriptParser.update_episode_data_from_file(_project, path)
			# TODO Display errors
	
	for ep_data in data.episodes:
		
		var dir = fpath.get_base_dir()
		# Path in project file is relative to project dir
		var ep_fullpath = dir.plus_file(ep_data.file_path)
		ScriptParser.update_episode_data_from_file(_project, ep_fullpath)
		# TODO Display errors
		
		var episode = _project.get_episode_from_path(ep_fullpath)
		if episode == null:
			# Some error happened
			continue
		
		for occurrence_data in ep_data.character_occurrences:
			var cname = occurrence_data.character_name
			if not episode.character_occurrences.has(cname):
				push_error("Character {0} has no occurrence in {1}".format(\
					[cname, ep_data.file_path]))
				continue
			var occurrence = episode.character_occurrences[cname]
			occurrence.recorded = occurrence_data.recorded
	
	for actor_data in data.actors:
		if _project.next_actor_id <= actor_data.id:
			_project.next_actor_id = actor_data.id + 1
		var actor = ScriptData.Actor.new()
		actor.id = int(actor_data.id)
		actor.name = actor_data.name
		actor.gender = int(actor_data.gender)
		actor.notes = actor_data.notes
		if _project.get_actor_by_id(actor.id) != null:
			push_error("Project file contains two actors with the same ID")
			continue
		_project.actors.append(actor)
	
	_project.file_path = fpath
	_set_project(_project)


static func _load_project_file(fpath):
	
	var f = File.new()
	var err = f.open(fpath, File.READ)
	if err != OK:
		push_error("Could not open {0}, {1}".format([fpath, Errors.get_message(err)]))
		return null
	var json = f.get_as_text()
	f.close()
	
	var json_res = JSON.parse(json)
	if json_res.error != OK:
		push_error("Failed to parse {0}: line {1}: {2}".format(\
			[fpath, json_res.error_line, json_res.error_string]))
		return null
	
	if not json_res.result.has("stk_project"):
		push_error("Failed to parse {0}: `stk_project` not found".format([fpath]))
		return null
	
	var json_data = json_res.result["stk_project"]
	
	var data = {
		"title": "Untitled",
		"episodes": [],
		"episode_files": [],
		"actors": [],
		"characters": []
	}
	
	if json_data.has("title"):
		data.title = json_data.title
	
	if json_data.has("episodes"):
		data.episodes = json_data.episodes

	elif json_data.has("episode_files"):
		# Legacy
		data.episode_files = json_data.episode_files

	if json_data.has("actors"):
		data.actors = json_data.actors

	if json_data.has("characters"):
		data.characters = json_data.characters
	
	return data


static func _save_project_file(data, fpath):
	var json_data = {
		"stk_project": data
	}
	
	var json = JSON.print(json_data, "\t", true)
	
	var f = File.new()
	var err = f.open(fpath, File.WRITE)
	if err != OK:
		push_error("Could not write to {0}, {1}".format([fpath, Errors.get_message(err)]))
		return false
	
	f.store_string(json)
	f.close()
	print("Saved ", fpath)
	return true
