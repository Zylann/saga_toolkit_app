extends Control

const ScriptData = preload("./../script_data.gd")

onready var _title_edit = get_node("Properties/Title")
onready var _synopsis_edit = get_node("Properties/Synopsis")
onready var _website_edit = get_node("Properties/WebsiteURL")
onready var _post_banner_url_edit = get_node("Properties/PostBannerURL")
onready var _neto_saga_id_edit = get_node("Properties/NetoSagaID")

var _project : ScriptData.Project


func set_project(project: ScriptData.Project):
	_project = project
	
	_title_edit.text = _project.title
	_synopsis_edit.text = _project.synopsis
	_synopsis_edit.clear_undo_history()
	_website_edit.set_url(_project.website)
	_post_banner_url_edit.set_url(_project.post_banner_url)
	_neto_saga_id_edit.value = _project.netophonix_saga_id


func _on_Title_text_changed(new_text):
	_project.title = new_text.strip_edges()
	_project.make_modified()


func _on_Synopsis_text_changed():
	_project.synopsis = _synopsis_edit.text
	_project.make_modified()


func _on_NetoSagaID_value_changed(value):
	_project.netophonix_saga_id = int(value)
	_project.make_modified()


func _on_PostBannerURL_changed(new_url):
	_project.post_banner_url = new_url.strip_edges()
	_project.make_modified()


func _on_WebsiteURL_changed(new_url):
	_project.website = new_url.strip_edges()
	_project.make_modified()
