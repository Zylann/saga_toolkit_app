extends WindowDialog

signal discard_selected

onready var _label = get_node("VBoxContainer/Label") as Label
onready var _discard_button = get_node("VBoxContainer/Buttons/Discard") as Button


func _on_Discard_pressed():
	emit_signal("discard_selected")
	hide()


func _on_Cancel_pressed():
	hide()


func configure(p_text: String, p_discard_text: String):
	_label.text = p_text
	_discard_button.text = p_discard_text


func set_discard_action(target: Object, method: String, binds := []):
	var connections = get_signal_connection_list("discard_selected")
	for con in connections:
		disconnect("discard_selected", con.target, con.method)
	connect("discard_selected", target, method, binds, CONNECT_ONESHOT)

