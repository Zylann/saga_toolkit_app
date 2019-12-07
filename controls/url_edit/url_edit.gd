extends HBoxContainer

signal changed(new_url)

onready var _edit = get_node("LineEdit")


func set_url(url: String):
	_edit.text = url


func _on_LineEdit_text_changed(new_text):
	emit_signal("changed", new_text)


func _on_Button_pressed():
	var url = _edit.text
	OS.shell_open(url)
