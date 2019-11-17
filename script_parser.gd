
const Accents = preload("util/accents.gd")
const ScriptData = preload("./script_data.gd")

# These may be ignored because they are not proper characters,
# but rather "all of them" or "all those present in scene"
const _ignored_character_names = {
	"TOUS": true,
	"TOUT LE MONDE": true,
	"FOULE": true
}


static func parse_episode(text):
	
	var time_before = OS.get_ticks_msec()
	
	var res = _parse_episode(text)
	
	res.data.text = text

	if len(res.errors) > 0:
		printerr("--- Unrecognized content ---")
		for e in res.errors:
			printerr("Line ", e.line_index, ":")
			print("\"", e.text, "\"\n")
		printerr("----------------------------")
	
	var time_spent = OS.get_ticks_msec() - time_before
	print("Took ", time_spent, "ms to parse text")
	
	return res


static func _parse_episode(text):

	var lines = text.split("\n")
	
	var data = ScriptData.Episode.new()
	var scene = null
	
	var unrecognized_content = {}
	
	# Using a while because for loop forbids incrementing the index --"
	var line_index = 0
	while line_index < len(lines):
		
		var raw_line = lines[line_index]
		var line = raw_line.strip_edges()
		
		if line.begins_with("//"):
			var note = ScriptData.Note.new()
			note.text = line
			scene.elements.append(note)

		elif line.begins_with("/*"):
			var begin_index = line_index
			var note = ScriptData.Note.new()
			while line_index < len(lines):
				if note.text == "":
					note.text = line
				else:
					line = lines[line_index]
					note.text = str(note.text, "\n", line)
				if line.ends_with("*/"):
					break
				line_index += 1
				line = lines[line_index].strip_edges()
			scene.elements.append(note)
		
		elif line.begins_with("(") or line.begins_with("<") \
		or line.begins_with("*") or line.begins_with("#"):
			var desc = ScriptData.Description.new()
			desc.text = line
			scene.elements.append(desc)

		elif line.begins_with("==="):
			data.title = lines[line_index - 1].strip_edges()
			unrecognized_content.erase(line_index - 1)
		
		elif line.begins_with("---"):
			scene = ScriptData.Scene.new()
			scene.title = lines[line_index - 1].strip_edges()
			scene.line_index = line_index - 1
			data.scenes.append(scene)
			unrecognized_content.erase(line_index - 1)
		
		elif line.find("--") != -1:
			var res = parse_statement(lines, line_index)
			if res == null:
				unrecognized_content[line_index] = {
					"text": line
				}
			else:
				var statement = res.statement
				_add_statement(scene, data, statement)
				line_index = res.line_index
		
		elif line != "" and (raw_line.begins_with("    ") or raw_line.begins_with("\t")):
			# TODO This is for poems or songs, find something better than defaulting to some crowd
			var statement = ScriptData.Statement.new()
			statement.text = line
			statement.character_name = "FOULE"
			statement.word_count = len(line.split(" ", false))
			_add_statement(scene, data, statement)
		
		elif line.begins_with("FIN"):
			# The End
			var note = ScriptData.Note.new()
			note.text = line
			scene.elements.append(note)

		elif line != "":
			unrecognized_content[line_index] = {
				"text": line
			}
		
		line_index += 1
	
	var errors = []

	if unrecognized_content.empty():
		print("No problem found in script.")
	else:
		for line_index in unrecognized_content:
			var c = unrecognized_content[line_index]
			errors.append({
				"line_index": line_index,
				"text": c.text
			})
	
	return {
		"data": data,
		"errors": errors
	}


static func _add_statement(scene, data, statement):
	if not _ignored_character_names.has(statement.character_name):
		
		var occurrence : ScriptData.CharacterOccurrence
		if data.character_occurrences.has(statement.character_name):
			occurrence = data.character_occurrences[statement.character_name]
		else:
			occurrence = ScriptData.CharacterOccurrence.new()
			data.character_occurrences[statement.character_name] = occurrence
		
		occurrence.word_count += statement.word_count
	
	scene.elements.append(statement)


static func parse_statement(lines, line_index):
	var line = lines[line_index]
	
	var dash_index = line.find("--")
	if dash_index == -1:
		return null
	
	var strip_index = dash_index
	var comma_index = line.find(",")
	
	if comma_index != -1 and comma_index < strip_index:
		strip_index = comma_index
	
	var char_name = line.substr(0, strip_index).strip_edges()
	var parts = char_name.split(" ")
	
	if len(parts) == 0:
		return null
	
	char_name = ""
	for i in len(parts):
		var part = parts[i]
		if part.to_upper() == part:
			if i == 0:
				char_name = part
			else:
				char_name = str(char_name, " ", part)
		else:
			break
	
	char_name = Accents.remove_accents(char_name)
	
	if char_name == "":
		return null
	
	var statement = ScriptData.Statement.new()
	statement.character_name = char_name
	
	var head_note = line.substr(len(char_name), dash_index - len(char_name)).strip_edges()
	if head_note.begins_with(","):
		head_note = head_note.right(1)
	statement.note = head_note
	
	var word_count = 0
	
	while line_index < len(lines):
		line = lines[line_index].strip_edges()
		if line == "":
			break
		if statement.text == "":
			var after_dash = dash_index + 2
			statement.text = line.substr(after_dash, len(line) - after_dash)
			word_count += len(statement.text.split(" ", false))
		else:
			# In case of two statements not separated by an empty line...
			if line.find("--") != -1:
				break
			word_count += len(line.split(" ", false))
			statement.text = str(statement.text, "\n", line)
		line_index += 1
	
	statement.word_count = word_count
	
	return {
		"statement": statement,
		"line_index": line_index,
		"word_count": word_count
	}


#static func _count_words(text):
#	var count = 0
#	var i = 0
#	while i < len(text):
#		while i < len(text):
#			var c = text[i]
#			if c == ' ' or c == '\n':
#				break
#			i += 1
#		while i < len(text):
#			var c = text[i]
#			if c != ' ' and c != '\n':
#				break
#			i += 1
#		count += 1
#		i += 1
#	return count
	
