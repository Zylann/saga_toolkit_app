
const SpellCheckResult = preload("./spell_check_result.gd")
const Accents = preload("../util/accents.gd")

var _words_dictionary = null


func set_words_dictionary(words_dictionary):
	_words_dictionary = words_dictionary


func find_next(text_edit: TextEdit, line: int, col: int) -> SpellCheckResult:
	
	var res = SpellCheckResult.new()
	var found = false
	
	while line < text_edit.get_line_count():
		var line_text = text_edit.get_line(line)
		
		var word = _get_next_word(line_text, col)
		if word != null:
			#print("-> ", word.text)
			
			if not Accents.has_accents(word.text):
				var variants = _words_dictionary.get_accentued_variants(word.text)
				
				if len(variants) != 0:
					found = true
					col = word.begin
					res.word = word.text
					res.suggestions = variants.duplicate()
					if _words_dictionary.exists(word.text):
						res.suggestions.push_front(word.text)
					break
			
			col = word.begin + len(word.text)
			if col >= len(line_text):
				col = 0
				line += 1
		else:
			line += 1
			col = 0
	
	res.line = line
	res.column = col
	
	if not found:
		res.finished = true
	return res


static func _is_alpha(c):
	# Damn you Godot, why you no have is_alpha
	var o = c.ord_at(0)
	return (o >= 65 and o <= 90) or (o >= 97 and o <= 122) or Accents.is_accentued_char(c)


static func _get_next_word(text, from):
	var pos = from
	while pos < len(text) and not _is_alpha(text[pos]):
		pos += 1
	if pos >= len(text):
		return null
	var begin = pos
	while pos < len(text) and _is_alpha(text[pos]):
		pos += 1
	return {
		"text": text.substr(begin, pos - begin),
		"begin": begin
	}

