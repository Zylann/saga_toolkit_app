
const Accents = preload("util/accents.gd")

# These may be ignored because they are not proper characters,
# but rather "all of them" or "all those present in scene"
const _ignored_character_names = {
	"TOUS": true,
	"TOUT LE MONDE": true,
	"FOULE": true
}


class ScriptData:
	var title = "Untitled"
	var scenes = []
	var character_names = {}
	var text = ""


class Scene:
	var title = ""
	var line_index = 0
	var elements = []


class Note:
	var text = ""


class Description:
	var text = ""


class Statement:
	var character_name = ""
	var note = ""
	var text = ""


static func parse_text(text):
	
	var time_before = OS.get_ticks_msec()
	
	var lines = text.split("\n")
	var res = parse_scenes(lines)
	
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


static func parse_scenes(lines):
	
	var data = ScriptData.new()
	var scene = null
	
	var unrecognized_content = {}
	
	# Using a while because for loop forbids incrementing the index --"
	var line_index = 0
	while line_index < len(lines):
		
		var raw_line = lines[line_index]
		var line = raw_line.strip_edges()
		
		if line.begins_with("//"):
			var note = Note.new()
			note.text = line
			scene.elements.append(note)

		elif line.begins_with("/*"):
			var begin_index = line_index
			var note = Note.new()
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
			var desc = Description.new()
			desc.text = line
			scene.elements.append(desc)

		elif line.begins_with("==="):
			data.title = lines[line_index - 1].strip_edges()
			unrecognized_content.erase(line_index - 1)
		
		elif line.begins_with("---"):
			scene = Scene.new()
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
			var statement = Statement.new()
			statement.text = line
			statement.character_name = "FOULE"
			_add_statement(scene, data, statement)
		
		elif line.begins_with("FIN"):
			# The End
			var note = Note.new()
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
		data.character_names[statement.character_name] = true
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
	
	var statement = Statement.new()
	statement.character_name = char_name
	
	var head_note = line.substr(len(char_name), dash_index - len(char_name)).strip_edges()
	if head_note.begins_with(","):
		head_note = head_note.right(1)
	statement.note = head_note
	
	while line_index < len(lines):
		line = lines[line_index].strip_edges()
		if line == "":
			break
		if statement.text == "":
			var after_dash = dash_index + 2
			statement.text = line.substr(after_dash, len(line) - after_dash)
		else:
			# In case of two statements not separated by an empty line...
			if line.find("--") != -1:
				break
			statement.text = str(statement.text, "\n", line)
		line_index += 1
	
	return {
		"statement": statement,
		"line_index": line_index
	}

