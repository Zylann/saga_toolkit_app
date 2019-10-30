extends HBoxContainer


onready var _next_button = get_node("NextButton")
onready var _prev_button = get_node("PrevButton")
onready var _line_edit = get_node("LineEdit")
onready var _label = get_node("Label")

var _text_edit: TextEdit = null
var _result_col = -1
var _result_line = -1


func set_text_edit(te):
	_text_edit = te


func _unhandled_input(event):
	
	if not _text_edit.visible:
		return
	
	if event is InputEventKey:
		if not event.is_echo():
			match event.scancode:
				KEY_F:
					if event.control:
						_start_search()
				KEY_ESCAPE:
					_close()


func _start_search():
	_label.text = ""
	show()
	var text = _text_edit.get_selection_text()
	_line_edit.text = text
	_line_edit.select_all()
	_line_edit.grab_focus()
	_result_col = -1
	_result_line = -1


func _close():
	if visible:
		hide()
		_text_edit.grab_focus()


func _on_LineEdit_text_entered(text):
	_search(0)


func _on_NextButton_pressed():
	_search(0)


func _on_PrevButton_pressed():
	_search(TextEdit.SEARCH_BACKWARDS)


func _search(flags):
	
	var text = _line_edit.text
	
	var search_col = _text_edit.cursor_get_column()
	var search_line = _text_edit.cursor_get_line()
	if search_line == _result_line:
		if search_col >= _result_col and search_col <= _result_col + len(text):
			if flags & TextEdit.SEARCH_BACKWARDS:
				search_col = _result_col - 1
				if search_col < 0:
					search_line -= 1
					if search_line < 0:
						search_line = _text_edit.get_line_count() - 1
					search_col = len(_text_edit.get_line(search_line))
			else:
				search_col = _result_col + len(text)
	
	print("Searching from ", search_line, ", col ", search_col)
	var res = _text_edit.search(text, flags, search_line, search_col)
	
	if len(res) == 0:
		_label.text = "No results"
		
	else:
		# TODO Show how many occurrences there are
		_label.text = ""
		# TODO In C++ those are misnamed the other way around
		_result_col = res[0]
		_result_line = res[1]
		_text_edit.cursor_set_line(_result_line)
		_text_edit.cursor_set_column(_result_col)
		_text_edit.select(_result_line, _result_col, _result_line, _result_col + len(text))


func _on_CloseButton_pressed():
	_close()
