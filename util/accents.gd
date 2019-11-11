
# Note: this only applies to latin and some cyrilic characters.
# TODO https://github.com/godotengine/godot/issues/26232
const _accentued_to_non_accentued = {
	"Š": "S",
	"š": "s",
	"Đ": "Dj",
	"đ": "dj",
	"Ž": "Z",
	"ž": "z",
	"Č": "C",
	"č": "c",
	"Ć": "C",
	"ć": "c",
	"À": "A",
	"Á": "A",
	"Â": "A",
	"Ã": "A",
	"Ä": "A",
	"Å": "A",
	"Æ": "A",
	"Ç": "C",
	"È": "E",
	"É": "E",
	"Ê": "E",
	"Ë": "E",
	"Ì": "I",
	"Í": "I",
	"Î": "I",
	"Ï": "I",
	"Ñ": "N",
	"Ò": "O",
	"Ó": "O",
	"Ô": "O",
	"Õ": "O",
	"Ö": "O",
	"Ø": "O",
	"Ù": "U",
	"Ú": "U",
	"Û": "U",
	"Ü": "U",
	"Ý": "Y",
	"Þ": "B",
	"ß": "Ss",
	"à": "a",
	"á": "a",
	"â": "a",
	"ã": "a",
	"ä": "a",
	"å": "a",
	"æ": "a",
	"ç": "c",
	"è": "e",
	"é": "e",
	"ê": "e",
	"ë": "e",
	"ì": "i",
	"í": "i",
	"î": "i",
	"ï": "i",
	"ð": "o",
	"ñ": "n",
	"ò": "o",
	"ó": "o",
	"ô": "o",
	"õ": "o",
	"ö": "o",
	"ø": "o",
	"ù": "u",
	"ú": "u",
	"û": "u",
	"ý": "y",
	"þ": "b",
	"ÿ": "y",
	"Ŕ": "R",
	"ŕ": "r",
}

static func remove_accents(s: String):
	var res = ""
	for c in s:
		if _accentued_to_non_accentued.has(c):
			res += _accentued_to_non_accentued[c]
		else:
			res += c
	return res


static func is_accentued_char(c: String) -> bool:
	return _accentued_to_non_accentued.has(c)


static func has_accents(s: String) -> bool:
	for c in s:
		if _accentued_to_non_accentued.has(c):
			return true
	return false
