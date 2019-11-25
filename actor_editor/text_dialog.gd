extends AcceptDialog


onready var _text_edit = get_node("TextEdit")


func set_text(text):
	_text_edit.text = text

