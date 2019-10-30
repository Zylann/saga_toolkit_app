extends HBoxContainer


var _text_edit = null

const letters = "àâéèêôùûç"


func _ready():
	for letter in letters:
		var b = Button.new()
		b.text = letter
		b.connect("pressed", self, "_on_button_pressed", [letter])
		add_child(b)


func set_text_edit(te):
	assert(te != null)
	assert(te is TextEdit)
	_text_edit = te


func _on_button_pressed(letter):
	_text_edit.insert_text_at_cursor(letter)
	_text_edit.grab_focus()
