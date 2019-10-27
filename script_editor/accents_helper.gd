extends HBoxContainer


export(NodePath) var text_edit_path

const letters = "àâéèêôùû"


func _ready():
	assert(_get_text_edit() != null)
	for letter in letters:
		var b = Button.new()
		b.text = letter
		b.connect("pressed", self, "_on_button_pressed", [letter])
		add_child(b)
	get_parent().notification(NOTIFICATION_SORT_CHILDREN)


func _on_button_pressed(letter):
	var text_edit = _get_text_edit()
	text_edit.insert_text_at_cursor(letter)
	text_edit.grab_focus()


func _get_text_edit():
	var te = get_node(text_edit_path)
	assert(te is TextEdit)
	return te
