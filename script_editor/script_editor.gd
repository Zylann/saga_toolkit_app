extends HSplitContainer

const Errors = preload("res://util/errors.gd")
const ScriptParser = preload("res://script_parser.gd")
const HtmlExporter = preload("res://html_exporter/html_exporter.gd")
const ScriptData = preload("./../script_data.gd")
const AccentorController = preload("./../spell_checker/accentor_controller.gd")
const WordsDictionary = preload("../words_dictionary.gd")
const UserPrefs = preload("./../util/userprefs.gd")

const CHARACTER_NAME_COLOR = Color(0.5, 0.5, 1.0)
const HEADING_COLOR = Color(0.3, 0.6, 0.3)
const COMMENT_COLOR = Color(0.5, 0.5, 0.5)
const SELECTION_COLOR = Color(1, 1, 1, 0.1)
const BACKGROUND_COLOR = Color(0.1, 0.1, 0.1)
const CURRENT_LINE_COLOR = Color(0.0, 0.0, 0.0, 0.2)

const MENU_FILE_OPEN_SCRIPT = 0
const MENU_FILE_SAVE_CURRENT_SCRIPT = 1
const MENU_FILE_EXPORT_AS_HTML = 2

const MENU_VIEW_ACCENT_BUTTONS = 0
const MENU_VIEW_STATISTICS = 1

signal script_parsed(project, path)

onready var _file_list = get_node("VSplitContainer/ScriptList")
onready var _text_editor = get_node("VBoxContainer/TextEditor")
onready var _search_bar = get_node("VBoxContainer/SearchBox")
onready var _scene_list = get_node("VSplitContainer/VBoxContainer/SceneList")
onready var _accent_buttons = get_node("VBoxContainer/HBoxContainer/AccentsHelper")
onready var _spell_check_panel = get_node("VBoxContainer/SpellCheckPanel")
onready var _file_menu = get_node("VBoxContainer/HBoxContainer/FileMenu")
onready var _view_menu = get_node("VBoxContainer/HBoxContainer/ViewMenu")

var _project = ScriptData.Project.new()
var _modified_files = {}
var _open_script_dialog: FileDialog
var _statistics_window: AcceptDialog


func _ready():
	_text_editor.syntax_highlighting = true
	_setup_colors([])
	
	_accent_buttons.set_text_edit(_text_editor)
	
	_search_bar.set_text_edit(_text_editor)
	
	var words_dictionary = WordsDictionary.new()
	words_dictionary.load_from_file(WordsDictionary.FRENCH_PATH)

	var accentor_controller = AccentorController.new()
	accentor_controller.set_words_dictionary(words_dictionary)
	
	# TODO Have an actual spell-checker controller too
	_spell_check_panel.set_text_edit(_text_editor)
	_spell_check_panel.set_controller(accentor_controller)
	
	_file_menu.get_popup().add_item("Open Script...", MENU_FILE_OPEN_SCRIPT)
	_file_menu.get_popup().add_item("Save Current Script...", MENU_FILE_SAVE_CURRENT_SCRIPT)
	_file_menu.get_popup().add_separator()
	_file_menu.get_popup().add_item("Export As HTML...", MENU_FILE_EXPORT_AS_HTML)
	_file_menu.get_popup().connect("id_pressed", self, "_on_FileMenu_id_pressed")
	
	_view_menu.get_popup().add_item("Accent Buttons", MENU_VIEW_ACCENT_BUTTONS)
	_view_menu.get_popup().add_item("Statistics", MENU_VIEW_STATISTICS)
	_view_menu.get_popup().connect("id_pressed", self, "_on_ViewMenu_id_pressed")
	
	_open_script_dialog = FileDialog.new()
	_open_script_dialog.window_title = "Open Script"
	_open_script_dialog.add_filter("*.txt ; TXT files")
	_open_script_dialog.add_filter("*.md ; MD files")
	_open_script_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_open_script_dialog.resizable = true
	_open_script_dialog.connect("file_selected", self, "_on_OpenScriptDialog_file_selected")
	add_child(_open_script_dialog)
	
	_statistics_window = AcceptDialog.new()
	_statistics_window.window_title = "Script Statistics"
	add_child(_statistics_window)


func set_project(project):
	_project = project


func close_all_scripts():
	_modified_files.clear()
	_file_list.clear()
	_text_editor.text = ""
	_text_editor.clear_undo_history()


func open_script(path):
	
	if _project.get_episode_from_path(path) != null:
		print("Script ", path, " is already open")
		return
	
	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		printerr("Could not load file ", path, ", ", Errors.get_message(err))
		return
	var text = f.get_as_text()
	f.close()

	var errors = _update_episode_data(_project, text, path)
	
	var filename = path.get_file()
	var i = _file_list.get_item_count()
	_file_list.add_item(filename)
	_file_list.set_item_metadata(i, path)
	
	_update_character_colors()

	_file_list.select(i)
	_set_current_script(path)
	
	emit_signal("script_parsed", _project, path, errors)


# TODO I think this should be part of the parser
static func _update_episode_data( \
		project: ScriptData.Project, text: String, path: String) -> Array:
	
	var res = ScriptParser.parse_episode(text)
	var ep = res.data
	ep.file_path = path
	
	var epi = project.get_episode_index_from_path(path)
	if epi == -1:
		project.episodes.append(ep)
	else:
		project.episodes[epi] = ep
	
	var character_occurences : Dictionary = ep.character_occurrences
	if len(character_occurences) != 0:
		for cname in character_occurences:
			
			# Get or create character
			var character : ScriptData.Character
			if project.characters.has(cname):
				character = project.characters[cname]
			else:
				character = ScriptData.Character.new()
				character.name = cname
				project.characters[cname] = character
	
	return res.errors


func _set_current_script(path):
	var data = _project.get_episode_from_path(path)
	
	_text_editor.text = data.text
	_text_editor.cursor_set_line(0, true, false)
	
	_scene_list.clear()
	for scene in data.scenes:
		var i = _scene_list.get_item_count()
		_scene_list.add_item(scene.title)
		_scene_list.set_item_metadata(i, scene)
	
	# TODO To workaround this limitation, we may instance multiple TextEdits
	_text_editor.clear_undo_history()


func _on_SceneList_item_selected(index):
	var scene = _scene_list.get_item_metadata(index)
	
	# TODO Need a function to center that line
	# Hack: scroll to bottom first
	_text_editor.cursor_set_line(_text_editor.get_line_count() - 1)
	
	_text_editor.cursor_set_line(scene.line_index)


func _get_current_script_path():
	var selection = _file_list.get_selected_items()
	if len(selection) == 0:
		return null
	return _file_list.get_item_metadata(selection[0])


func export_as_html():
	var script_path = _get_current_script_path()
	if script_path == null:
		printerr("No selected script")
		return
	var data = _project.get_episode_from_path(script_path)
	var exporter = HtmlExporter.new()
	var output_path = script_path.get_basename() + ".html"
	exporter.export_script(data, output_path)
	OS.shell_open(output_path)


func _on_ScriptList_item_selected(index):
	var path = _file_list.get_item_metadata(index)
	_set_current_script(path)


func _update_character_colors():
	_setup_colors(_project.characters.keys())


func _setup_colors(character_names):
	
	_text_editor.clear_colors()

	_text_editor.add_color_override("number_color", _text_editor.get_color("font_color"))
	_text_editor.add_color_override("function_color", _text_editor.get_color("font_color"))
	_text_editor.add_color_region("<", ">", COMMENT_COLOR)
	_text_editor.add_color_region("(", ")", COMMENT_COLOR)
	_text_editor.add_color_region("/*", "*/", COMMENT_COLOR)
	_text_editor.add_color_region("*", "*", COMMENT_COLOR)
	_text_editor.add_color_region("//", "", COMMENT_COLOR, false)
	_text_editor.add_color_region("---", "", HEADING_COLOR, false)
	_text_editor.add_color_region("===", "", HEADING_COLOR, false)
	_text_editor.add_color_override("selection_color", SELECTION_COLOR)
	_text_editor.add_color_override("background_color", BACKGROUND_COLOR)
	_text_editor.add_color_override("current_line_color", CURRENT_LINE_COLOR)
	_text_editor.highlight_current_line = true

	for cname in character_names:
		# TODO What if the keyword contains a space? Godot doesnt check that.
		_text_editor.add_keyword_color(cname, CHARACTER_NAME_COLOR)


func save_current_script():
	var script_path = _get_current_script_path()
	if script_path == null:
		printerr("No selected script")
		return
	
	var f = File.new()
	var err = f.open(script_path, File.WRITE)
	if err != OK:
		printerr("Could not save file ", script_path, ", ", Errors.get_message(err))
		return
	f.store_string(_text_editor.text)
	f.close()
	
	var errors = _update_episode_data(_project, _text_editor.text, script_path)
	var i = _get_file_list_index(script_path)
	assert(i != -1)
	_file_list.set_item_text(i, script_path.get_file())
	_modified_files.erase(script_path)
	
	emit_signal("script_parsed", _project, script_path, errors)


func _toggle_accent_buttons():
	_accent_buttons.visible = not _accent_buttons.visible


func _get_current_script_statistics():
	var path = _get_current_script_path()
	if path == "":
		return null
	var ep = _project.get_episode_from_path(path)
	if ep == null:
		return null
	var statement_count = 0
	for scene in ep.scenes:
		for elem in scene.elements:
			if elem is ScriptData.Statement:
				statement_count += 1
	print("Char count ", len(ep.text))
	# This is pure guesswork. For an accurate measure, read your text out loud
	var estimated_duration = 60 * len(ep.text) / 1200
	return {
		"statement_count": statement_count,
		"estimated_duration": estimated_duration
	}


func _show_statistics():
	var stats = _get_current_script_statistics()
	print("Stats: ", stats)
	if stats == null:
		_statistics_window.dialog_text = "No statistics available."
	else:
		_statistics_window.dialog_text = PoolStringArray([
			str("Statements: ", stats.statement_count),
			str("Estimated duration: ", _format_time(stats.estimated_duration))
		]).join("\n")
	_statistics_window.popup_centered_minsize()


static func _format_time(total_seconds):
	var mins = total_seconds / 60
	var seconds = total_seconds % 60
	return str(mins, " min ", seconds, " seconds")


func _on_TextEditor_text_changed():
	if _file_list.get_item_count() == 0:
		return
	var path = _get_current_script_path()
	if path != "":
		if not _modified_files.has(path):
			_modified_files[path] = true
			var i = _get_file_list_index(path)
			assert(i != -1)
			_file_list.set_item_text(i, str(path.get_file(), " (*)"))


func _get_file_list_index(path):
	for i in _file_list.get_item_count():
		var meta = _file_list.get_item_metadata(i)
		if meta == path:
			return i
	return -1


func _on_FileMenu_id_pressed(id):
	match id:
		MENU_FILE_OPEN_SCRIPT:
			_trigger_open_script_dialog()
		MENU_FILE_SAVE_CURRENT_SCRIPT:
			save_current_script()
		MENU_FILE_EXPORT_AS_HTML:
			export_as_html()


func _trigger_open_script_dialog():
	var dir = UserPrefs.get_value("last_open_script_path")
	if dir != null:
		_open_script_dialog.current_dir = dir
	_open_script_dialog.popup_centered_ratio(0.75)


func _on_OpenScriptDialog_file_selected(path):
	UserPrefs.set_value("last_open_script_path", path.get_base_dir())
	open_script(path)


func _on_OpenButton_pressed():
	_trigger_open_script_dialog()


func _on_SaveButton_pressed():
	save_current_script()


func _on_ViewMenu_id_pressed(id):
	match id:
		MENU_VIEW_ACCENT_BUTTONS:
			_toggle_accent_buttons()
		MENU_VIEW_STATISTICS:
			_show_statistics()
