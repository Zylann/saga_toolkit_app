extends Panel

const UserPrefs = preload("util/userprefs.gd")

onready var _file_menu = get_node("VBoxContainer/MenuBar/FileMenu")
onready var _help_menu = get_node("VBoxContainer/MenuBar/HelpMenu")
onready var _view_menu = get_node("VBoxContainer/MenuBar/ViewMenu")
onready var _open_script_dialog = get_node("OpenScriptDialog")
onready var _script_editor = get_node("VBoxContainer/TabContainer/ScriptEditor")
onready var _character_editor = get_node("VBoxContainer/TabContainer/CharacterEditor")
onready var _tab_container = get_node("VBoxContainer/TabContainer")
onready var _about_window = get_node("AboutWindow")
onready var _status_label = get_node("VBoxContainer/StatusBar/Label")

const MENU_FILE_OPEN_SCRIPT = 0
const MENU_FILE_EXPORT_AS_HTML = 1
const MENU_FILE_QUIT = 2
const MENU_FILE_SAVE_CURRENT_SCRIPT = 3

const MENU_HELP_ABOUT = 0

const MENU_VIEW_ACCENT_BUTTONS = 0

func _ready():
	
	_file_menu.get_popup().add_item("Open Script...", MENU_FILE_OPEN_SCRIPT)
	_file_menu.get_popup().add_item("Save Current Script...", MENU_FILE_SAVE_CURRENT_SCRIPT)
	_file_menu.get_popup().add_separator()
	_file_menu.get_popup().add_item("Export As HTML...", MENU_FILE_EXPORT_AS_HTML)
	_file_menu.get_popup().add_separator()
	_file_menu.get_popup().add_item("Quit", MENU_FILE_QUIT)
	_file_menu.get_popup().connect("id_pressed", self, "_on_FileMenu_id_pressed")
	
	_help_menu.get_popup().add_item("About...", MENU_HELP_ABOUT)
	_help_menu.get_popup().connect("id_pressed", self, "_on_HelpMenu_id_pressed")
	
	_view_menu.get_popup().add_item("Accent Buttons", MENU_VIEW_ACCENT_BUTTONS)
	_view_menu.get_popup().connect("id_pressed", self, "_on_ViewMenu_id_pressed")
	
	_script_editor.connect("script_parsed", _character_editor, "_on_ScriptEditor_script_parsed")
	_script_editor.connect("script_parsed", self, "_on_ScriptEditor_script_parsed")

	# TEST
	for i in 8:
		_script_editor.open_script(\
			str("D:/PROJETS/AUDIO/Enfer Liquide/Script/Episodes/ep", (i+1), ".txt"))


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


func _on_FileMenu_id_pressed(id):
	match id:
		
		MENU_FILE_OPEN_SCRIPT:
			_trigger_open_script_dialog()

		MENU_FILE_SAVE_CURRENT_SCRIPT:
			_trigger_save()
		
		MENU_FILE_EXPORT_AS_HTML:
			_script_editor.export_as_html()
		
		MENU_FILE_QUIT:
			get_tree().quit()


func _on_HelpMenu_id_pressed(id):
	match id:
		MENU_HELP_ABOUT:
			_about_window.popup_centered_minsize()


func _on_ViewMenu_id_pressed(id):
	match id:
		MENU_VIEW_ACCENT_BUTTONS:
			_script_editor.toggle_accent_buttons()


func _on_OpenScriptDialog_file_selected(path):
	UserPrefs.set_value("last_open_script_path", path.get_base_dir())
	_script_editor.open_script(path)


func _on_OpenButton_pressed():
	_trigger_open_script_dialog()


func _on_SaveButton_pressed():
	_trigger_save()


func _trigger_open_script_dialog():
	var dir = UserPrefs.get_value("last_open_script_path")
	if dir != null:
		_open_script_dialog.current_dir = dir
	_open_script_dialog.popup_centered_ratio(0.75)


func _trigger_save():
	_script_editor.save_current_script()

