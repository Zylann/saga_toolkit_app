extends Control

const ScriptData = preload("./../script_data.gd")

onready var _title_edit = get_node("Properties/Title")
onready var _synopsis_edit = get_node("Properties/Synopsis")

var _project : ScriptData.Project


func set_project(project: ScriptData.Project):
	_project = project
	
	_title_edit.text = _project.title
	_synopsis_edit.text = _project.synopsis
	_synopsis_edit.clear_undo_history()


func _on_Title_text_changed(new_text):
	_project.title = new_text.strip_edges()
	_project.make_modified()


func _on_Synopsis_text_changed():
	_project.synopsis = _synopsis_edit.text
	_project.make_modified()
	

