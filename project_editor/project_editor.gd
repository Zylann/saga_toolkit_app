extends Control

const ScriptData = preload("./../script_data.gd")

onready var _title_edit = get_node("Properties/Title")
onready var _synopsis_edit = get_node("Properties/Synopsis")
onready var _website_edit = get_node("Properties/WebsiteURL")
onready var _post_banner_url_edit = get_node("Properties/PostBannerURL")
onready var _neto_saga_id_edit = get_node("Properties/NetoSagaID")
onready var _banner = get_node("Banner")

var _project : ScriptData.Project
var _http_request : HTTPRequest = null


func set_project(project: ScriptData.Project):
	_project = project
	
	_title_edit.text = _project.title
	_synopsis_edit.text = _project.synopsis
	_synopsis_edit.clear_undo_history()
	_website_edit.set_url(_project.website)
	_post_banner_url_edit.set_url(_project.post_banner_url)
	_neto_saga_id_edit.value = _project.netophonix_saga_id

	_update_banner()


func _update_banner():
	if _project.post_banner_url == "":
		_banner.texture = null
		return
	# Create an HTTP request node and connect its completion signal.
	if _http_request == null:
		_http_request = HTTPRequest.new()
		add_child(_http_request)
		_http_request.connect("request_completed", self, "_http_request_completed")
	
	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	print("Requesting ", _project.post_banner_url)
	var error = _http_request.request(_project.post_banner_url)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func _http_request_completed(
		result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
		
	if response_code != 200:
		push_error("Request error " + str(response_code))
		return
	
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("Couldn't load the image.")
		return
		
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	_banner.texture = texture


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
	_update_banner()


func _on_WebsiteURL_changed(new_url):
	_project.website = new_url.strip_edges()
	_project.make_modified()
