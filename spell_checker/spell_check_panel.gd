extends Control


onready var _suggestions_list = get_node("HBoxContainer/VBoxContainer/SuggestionList")
onready var _label = get_node("HBoxContainer/VBoxContainer/Label")

var _controller = null
var _text_edit: TextEdit = null
var _last_result = null
var _ignored_words = {}


func set_text_edit(text_edit: TextEdit):
	assert(text_edit is TextEdit)
	_text_edit = text_edit


func set_controller(controller):
	_controller = controller
	assert(_controller.has_method("find_next"))
	#assert(_controller.has_method("correct"))


func _unhandled_input(event):
	
	if not _text_edit.visible:
		return
	
	if event is InputEventKey:
		if not event.is_echo():
			match event.scancode:
				KEY_A:
					if event.control and event.shift:
						_start()
				KEY_ESCAPE:
					hide()


func _start():
	_ignored_words.clear()
	show()
	_find_next()


func _on_SkipButton_pressed():
	_find_next()


func _on_CorrectButton_pressed():
	var selection = _suggestions_list.get_selected_items()
	if len(selection) == 0:
		print("No word selected")
		return
	var selected_word = _suggestions_list.get_item_metadata(selection[0])
	
	var line = _last_result.line
	var begin = _last_result.column
	var end = _last_result.column + len(_last_result.word)
	_text_edit.select(line, begin, line, end)
	_text_edit.insert_text_at_cursor(selected_word)
	
	_find_next()


func _find_next():
	
	var line = _text_edit.cursor_get_line()
	var col = _text_edit.cursor_get_column()
	
	var res
	while true:
		res = _controller.find_next(_text_edit, line, col)
		if not res.finished:
			line = res.line
			col = res.column + len(res.word)
			if _ignored_words.has(res.word):
				continue
		break
	
	# TODO If only one word is available, select it
	# TODO Remember choice of words
	# TODO Allow double-clicking to correct
	# TODO Increase font size
	# TODO When Ctrl+F is used, close panel
	
	_suggestions_list.clear()
	
	if not res.finished:
		_text_edit.cursor_set_line(res.line)
		_text_edit.cursor_set_column(res.column + len(res.word))
		_text_edit.select(res.line, res.column, res.line, res.column + len(res.word))
		_text_edit.center_viewport_to_cursor()
	
		if len(res.suggestions) > 0:
			_label.text = tr("Suggestions:")
			for word in res.suggestions:
				var i = _suggestions_list.get_item_count()
				_suggestions_list.add_item(word)
				_suggestions_list.set_item_metadata(i, word)
		else:
			_label.text = tr("No suggestions")

		_last_result = res
	
	else:
		_label.text = tr("Search complete")
	

func _on_AddToDictionaryButton_pressed():
	# TODO Add to dict
	#_last_result.word
	pass


func _on_CloseButton_pressed():
	hide()


func _on_IgnoreAllButton_pressed():
	if _last_result != null:
		_ignored_words[_last_result.word] = true
	_find_next()
