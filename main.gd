extends Panel

const UserPrefs = preload("./util/userprefs.gd")
const ScriptData = preload("./script_data.gd")
const Errors = preload("./util/errors.gd")
const ThemeGenerator = preload("./theme/theme_generator.gd")
const ScriptParser = preload("./script_parser.gd")

const MENU_PROJECT_NEW = 0
const MENU_PROJECT_OPEN = 1
const MENU_PROJECT_SAVE = 2
const MENU_PROJECT_SAVE_AS = 3
const MENU_PROJECT_QUIT = 4

const MENU_EDIT_PREFERENCES = 0

const MENU_HELP_ABOUT = 0
const MENU_HELP_REPORT_ISSUE = 1

const ISSUE_TRACKER_URL = "https://github.com/Zylann/saga_toolkit_app/issues"

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
onready var _unsaved_changes_dialog = get_node("UnsavedChangesDialog")
onready var _status_label = get_node("VBoxContainer/StatusBar/Label")
onready var _save_project_button = get_node("VBoxContainer/MenuBar/SaveProjectButton")

var _project : ScriptData.Project = null
var _open_project_dialog = null
var _save_project_dialog = null
var _action_on_discard_unsaved_changes : FuncRef = null


func _init():
	var locale = UserPrefs.get_value("locale")
	if locale != null:
		TranslationServer.set_locale(locale)


func _ready():
	theme = ThemeGenerator.get_theme()
	
	_project_menu.get_popup().add_item(tr("New"), MENU_PROJECT_NEW)
	_project_menu.get_popup().add_item(tr("Open..."), MENU_PROJECT_OPEN)
	_project_menu.get_popup().add_separator()
	_project_menu.get_popup().add_item(tr("Save"), MENU_PROJECT_SAVE)
	_project_menu.get_popup().add_item(tr("Save As..."), MENU_PROJECT_SAVE_AS)
	_project_menu.get_popup().add_separator()
	_project_menu.get_popup().add_item(tr("Quit"), MENU_PROJECT_QUIT)
	_project_menu.get_popup().connect("id_pressed", self, "_on_ProjectMenu_id_pressed")
	
	_edit_menu.get_popup().add_item(tr("Preferences"), MENU_EDIT_PREFERENCES)
	_edit_menu.get_popup().connect("id_pressed", self, "_on_EditMenu_id_pressed")
	
	_help_menu.get_popup().add_item(tr("About..."), MENU_HELP_ABOUT)
	_help_menu.get_popup().add_item(tr("Report an Issue"), MENU_HELP_REPORT_ISSUE)
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
	_episode_editor.setup_dialogs(dialogs_parent)
	
	_set_project(ScriptData.Project.new())


func _notification(what):
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		_request_quit()


func _on_ScriptEditor_script_parsed(project, path):
	_character_editor.refresh_episode(path)


func _on_ScriptEditor_script_removed(path):
	pass


func _on_ProjectMenu_id_pressed(id):
	match id:
		MENU_PROJECT_NEW:
			_request_new_project()
		
		MENU_PROJECT_OPEN:
			_request_open_project()
		
		MENU_PROJECT_SAVE:
			_save_project()
		
		MENU_PROJECT_SAVE_AS:
			_save_project_dialog.popup_centered_ratio()
		
		MENU_PROJECT_QUIT:
			_request_quit()


func _on_EditMenu_id_pressed(id):
	match id:
		MENU_EDIT_PREFERENCES:
			_preferences_window.popup_centered_minsize()


func _on_HelpMenu_id_pressed(id):
	match id:
		MENU_HELP_ABOUT:
			_about_window.popup_centered_minsize()
		
		MENU_HELP_REPORT_ISSUE:
			OS.shell_open(ISSUE_TRACKER_URL)


func _request_new_project():
	if _project.modified:
		_unsaved_changes_dialog.configure(
			tr("The project has unsaved changes.\nAre you sure you want to close it?"),
			tr("Discard"))
		_action_on_discard_unsaved_changes = funcref(self, "_close_project")
		_unsaved_changes_dialog.popup_centered_minsize()
	else:
		_close_project()


func _request_open_project():
	if _project.modified:
		_unsaved_changes_dialog.configure(
			tr("The project has unsaved changes.\nAre you sure you want to close it?"),
			tr("Discard"))
		_action_on_discard_unsaved_changes = funcref(self, "_show_open_project_dialog")
		_unsaved_changes_dialog.popup_centered_minsize()
	else:
		_show_open_project_dialog()


func _request_quit():
	if _project.modified:
		_unsaved_changes_dialog.configure(
			tr("The project has unsaved changes.\nAre you sure you want to quit?"),
			tr("Quit"))
		_action_on_discard_unsaved_changes = funcref(get_tree(), "quit")
		_unsaved_changes_dialog.popup_centered_minsize()
		OS.request_attention()
	else:
		get_tree().quit()


func _on_UnsavedChangesDialog_discard_selected():
	var a = _action_on_discard_unsaved_changes
	_action_on_discard_unsaved_changes = null
	a.call_func()


func _show_open_project_dialog():
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
	
	_script_editor.save_all_scripts()
	
	var dir = fpath.get_base_dir()
	
	var episodes = []
	for episode in _project.episodes:
		if episode.file_path != "":
			var path = episode.file_path
			# Relative path
			path = path.right(1 + len(dir))
			var ep_data = {
				"file_path": path,
				"synopsis": episode.synopsis,
				"mp3_url": episode.mp3_url,
				"character_occurrences": []
			}
			for cname in episode.character_occurrences:
				var occurrence = episode.character_occurrences[cname]
				var occurrence_data = {
					"character_name": cname,
					"recorded": occurrence.recorded
				}
				ep_data.character_occurrences.append(occurrence_data)
			episodes.append(ep_data)
	
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
		"synopsis": _project.synopsis,
		"website_url": _project.website,
		"post_banner_url": _project.post_banner_url,
		"netophonix_saga_id": _project.netophonix_saga_id,
		"episodes": episodes,
		"actors": actors,
		"characters": characters
	}
	
	if _save_project_file(data, fpath):
		_project.file_path = fpath
		_project.modified = false
		_update_project_modified_state()


func _close_project():
	_set_project(ScriptData.Project.new())


func _set_project(project):
	if _project != null:
		_project.disconnect("modified", self, "_on_project_modified")
	
	_project = project
	
	if _project != null:
		_project.connect("modified", self, "_on_project_modified")
	
	_update_project_modified_state()
	
	_script_editor.set_project(_project)
	_character_editor.set_project(_project)
	_actor_editor.set_project(_project)
	_episode_editor.set_project(_project)
	_project_editor.set_project(_project)


func _on_project_modified():
	_update_project_modified_state()


func _update_project_modified_state():
	_update_window_title()
	_save_project_button.disabled = not (_project.modified or _project.file_path == "")


func _update_window_title():
	
	var suffix := ""
	
	if _project.file_path == "":
		suffix = str(tr("Unsaved Project"))
	else:
		suffix = _project.file_path.get_file()
	
	if _project.modified:
		suffix = str(suffix, " (", tr("Modified"), ")")

	OS.set_window_title(str(ProjectSettings.get("application/config/name"), " - ", suffix))


func _open_project(fpath: String):
	_close_project()

	var data = _load_project_file(fpath)
	if data == null:
		return
	
	var project = ScriptData.Project.new()

	project.title = data.title
	project.synopsis = data.synopsis as String
	project.post_banner_url = data.post_banner_url
	project.website = data.website_url
	project.netophonix_saga_id = int(data.netophonix_saga_id)
	
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
		if project.characters.has(character.name):
			push_error("Project file contains two characters with the same name")
			continue
		project.characters[character.name] = character
	
	if len(data.episode_files) > 0:
		# Legacy
		var dir := fpath.get_base_dir()
		for ep_file_rpath in data.episode_files:
			var path := dir.plus_file(ep_file_rpath) as String
			ScriptParser.update_episode_data_from_file(project, path)
			# TODO Display errors
	
	for ep_data in data.episodes:
		
		var dir = fpath.get_base_dir()
		# Path in project file is relative to project dir
		var ep_fullpath = dir.plus_file(ep_data.file_path) as String
		ScriptParser.update_episode_data_from_file(project, ep_fullpath)
		# TODO Display errors
		
		var episode = project.get_episode_from_path(ep_fullpath)
		if episode == null:
			# Some error happened
			continue
		
		if ep_data.has("synopsis"):
			episode.synopsis = ep_data.synopsis as String
		if ep_data.has("mp3_url"):
			episode.mp3_url = ep_data.mp3_url
		
		for occurrence_data in ep_data.character_occurrences:
			var cname = occurrence_data.character_name
			if not episode.character_occurrences.has(cname):
				push_error("Character {0} has no occurrence in {1}".format(\
					[cname, ep_data.file_path]))
				continue
			var occurrence = episode.character_occurrences[cname]
			occurrence.recorded = occurrence_data.recorded
	
	for actor_data in data.actors:
		var actor = ScriptData.Actor.new()
		actor.id = int(actor_data.id)
		if project.next_actor_id <= actor.id:
			project.next_actor_id = actor.id + 1
		actor.name = actor_data.name
		actor.gender = int(actor_data.gender)
		actor.notes = actor_data.notes
		if project.get_actor_by_id(actor.id) != null:
			push_error("Project file contains two actors with the same ID")
			continue
		project.actors.append(actor)
	
	project.file_path = fpath
	_set_project(project)


static func tryget(d, k, def):
	if d.has(k):
		return d[k]
	return def


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
		"title": tryget(json_data, "title", TranslationServer.translate("Untitled")),
		"episodes": tryget(json_data, "episodes", []),
		"episode_files": tryget(json_data, "episode_files", []),
		"actors": tryget(json_data, "actors", []),
		"characters": tryget(json_data, "characters", []),
		"website_url": tryget(json_data, "website_url", ""),
		"netophonix_saga_id": tryget(json_data, "netophonix_saga_id", -1),
		"post_banner_url": tryget(json_data, "post_banner_url", ""),
		"synopsis": tryget(json_data, "synopsis", "")
	}
	
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


func _on_SaveProjectButton_pressed():
	_save_project()
