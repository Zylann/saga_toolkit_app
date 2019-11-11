
const Errors = preload("./util/errors.gd")
const Accents = preload("./util/accents.gd")

const FRENCH_PATH = "res://spell_checker/all_french_words.json"

class Data:
	var words = {}
	var non_accentued_to_accentued = {}

# TODO Add lazy-load/threading
var _base_db = Data.new()
# TODO Have ways to populate custom words
var _custom_db = Data.new()


func load_from_file(fpath):
	
	print("Loading ", fpath, "...")
	var text = _load_text_file(fpath)
	var res = JSON.parse(text)
	if res.error != OK:
		print("Failed to parse ", fpath, ", ", res.error_string, ", line ", res.error_line)
		return

	var words_array = res.result

	print("Registering words...")
	for word in words_array:
		_add_word(_base_db, word)
	
	print("Done")


func exists(word):
	for db in [_base_db, _custom_db]:
		if db.words.has(word):
			return true
	return false


func get_accentued_variants(non_accentued_word):
	var all_variants = []
	for db in [_custom_db, _base_db]:
		if db.non_accentued_to_accentued.has(non_accentued_word):
			var variants = db.non_accentued_to_accentued[non_accentued_word]
			for v in variants:
				all_variants.append(v)
	return all_variants


static func _add_word(db, word):
	db.words[word] = true
	
	if Accents.has_accents(word):
		var word_stripped = Accents.remove_accents(word)

		if db.non_accentued_to_accentued.has(word_stripped):
			var variants = db.non_accentued_to_accentued[word_stripped]
			variants.append(word)
		else:
			db.non_accentued_to_accentued[word_stripped] = [word]


static func _load_text_file(fpath):
	var f = File.new()
	var err = f.open(fpath, File.READ)
	if err != OK:
		printerr("Could not read ", fpath, ", ", Errors.get_message(err))
		return null
	var text = f.get_as_text()
	f.close()
	return text

