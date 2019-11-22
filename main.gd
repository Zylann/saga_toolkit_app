extends Panel

const UserPrefs = preload("./util/userprefs.gd")
const ScriptData = preload("./script_data.gd")
const Errors = preload("./util/errors.gd")

onready var _project_menu = get_node("VBoxContainer/MenuBar/ProjectMenu")
onready var _help_menu = get_node("VBoxContainer/MenuBar/HelpMenu")
onready var _script_editor = get_node("VBoxContainer/TabContainer/ScriptEditor")
onready var _character_editor = get_node("VBoxContainer/TabContainer/CharacterEditor")
onready var _tab_container = get_node("VBoxContainer/TabContainer")
onready var _about_window = get_node("AboutWindow")
onready var _status_label = get_node("VBoxContainer/StatusBar/Label")

const MENU_PROJECT_OPEN = 0
const MENU_PROJECT_SAVE = 1
const MENU_PROJECT_SAVE_AS = 2

const MENU_HELP_ABOUT = 0

var _project = ScriptData.Project.new()
var _project_path = ""
var _open_project_dialog = null
var _save_project_dialog = null


func _ready():
	
	_project_menu.get_popup().add_item("Open...", MENU_PROJECT_OPEN)
	_project_menu.get_popup().add_item("Save", MENU_PROJECT_SAVE)
	_project_menu.get_popup().add_item("Save As...", MENU_PROJECT_SAVE_AS)
	_project_menu.get_popup().connect("id_pressed", self, "_on_ProjectMenu_id_pressed")
	
	_help_menu.get_popup().add_item("About...", MENU_HELP_ABOUT)
	_help_menu.get_popup().connect("id_pressed", self, "_on_HelpMenu_id_pressed")
		
	_script_editor.set_project(_project)
	_script_editor.connect("script_parsed", _character_editor, "_on_ScriptEditor_script_parsed")
	_script_editor.connect("script_parsed", self, "_on_ScriptEditor_script_parsed")
	
	_character_editor.set_project(_project)
	
	var dialogs_parent = self

	var fd = FileDialog.new()
	fd.mode = FileDialog.MODE_OPEN_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.window_title = "Open Project"
	fd.resizable = true
	fd.add_filter("*.stk ; STK Project Files")
	fd.connect("file_selected", self, "_on_OpenProjectDialog_file_selected")
	dialogs_parent.add_child(fd)
	_open_project_dialog = fd

	fd = FileDialog.new()
	fd.mode = FileDialog.MODE_SAVE_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.window_title = "Save Project As"
	fd.resizable = true
	fd.add_filter("*.stk ; STK Project Files")
	fd.connect("file_selected", self, "_on_SaveProjectDialog_file_selected")
	dialogs_parent.add_child(fd)
	_save_project_dialog = fd


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


func _on_ProjectMenu_id_pressed(id):
	match id:
		
		MENU_PROJECT_OPEN:
			_trigger_open_project_dialog()
		
		MENU_PROJECT_SAVE:
			_save_project()
		
		MENU_PROJECT_SAVE_AS:
			_save_project_dialog.popup_centered_ratio()


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
	if _project_path == "":
		_save_project_dialog.popup_centered_ratio()
	else:
		_save_project_as(_project_path)


func _save_project_as(fpath):
	
	var dir = fpath.get_base_dir()
	var episode_files = []
	
	for episode in _project.episodes:
		if episode.file_path != "":
			var path = episode.file_path
			# Relative path
			path = path.right(1 + len(dir))
			episode_files.append(path)
	
	var data = {
		"title": _project.title,
		"episode_files": episode_files
	}
	
	if _save_project_file(data, fpath):
		_project_path = fpath


func _close_project():
	_project.clear()
	_script_editor.close_all_scripts()
	_character_editor.clear()


func _open_project(fpath):
	_close_project()

	var data = _load_project_file(fpath)
	if data == null:
		return
	
	_project.title = data.title
	var dir = fpath.get_base_dir()
	
	for ep_path in data.episode_files:
		# Relative to global
		ep_path = dir.plus_file(ep_path)
		_script_editor.open_script(ep_path)
	
	_project_path = fpath


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
		"episode_files": []
	}
	
	if json_data.has("title"):
		data.title = json_data.title
	
	if json_data.has("episode_files"):
		data.episode_files = json_data.episode_files
	
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

