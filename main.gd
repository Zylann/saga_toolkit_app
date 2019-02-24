extends Panel

onready var _file_menu = get_node("VBoxContainer/MenuBar/FileMenu")
onready var _help_menu = get_node("VBoxContainer/MenuBar/HelpMenu")
onready var _open_script_dialog = get_node("OpenScriptDialog")
onready var _script_editor = get_node("VBoxContainer/TabContainer/ScriptEditor")
onready var _character_editor = get_node("VBoxContainer/TabContainer/CharacterEditor")
onready var _tab_container = get_node("VBoxContainer/TabContainer")
onready var _about_window = get_node("AboutWindow")

const MENU_FILE_OPEN_SCRIPT = 0
const MENU_FILE_EXPORT_AS_HTML = 1
const MENU_FILE_QUIT = 2

const MENU_HELP_ABOUT = 0

func _ready():
	_file_menu.get_popup().add_item("Open Script...", MENU_FILE_OPEN_SCRIPT)
	_file_menu.get_popup().add_item("Export As HTML...", MENU_FILE_EXPORT_AS_HTML)
	_file_menu.get_popup().add_item("Quit", MENU_FILE_QUIT)
	_file_menu.get_popup().connect("id_pressed", self, "_on_FileMenu_id_pressed")
	
	_help_menu.get_popup().add_item("About...", MENU_HELP_ABOUT)
	_help_menu.get_popup().connect("id_pressed", self, "_on_HelpMenu_id_pressed")
	
	_script_editor.connect("script_parsed", _character_editor, "_on_ScriptEditor_script_parsed")

	# TEST
	_script_editor.open_script("D:/PROJETS/AUDIO/Enfer Liquide/Script/Enfer Liquide/Script.txt")


func _on_FileMenu_id_pressed(id):
	match id:
		
		MENU_FILE_OPEN_SCRIPT:
			_open_script_dialog.popup_centered_ratio(0.75)
		
		MENU_FILE_EXPORT_AS_HTML:
			_script_editor.export_as_html()
		
		MENU_FILE_QUIT:
			get_tree().quit()


func _on_HelpMenu_id_pressed(id):
	match id:
		MENU_HELP_ABOUT:
			_about_window.popup_centered_minsize()


func _on_OpenScriptDialog_file_selected(path):
	_script_editor.open_script(path)


