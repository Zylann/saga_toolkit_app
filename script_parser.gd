
const Accents = preload("util/accents.gd")
const ScriptData = preload("./script_data.gd")
const Errors = preload("res://util/errors.gd")

# These may be ignored because they are not proper characters,
# but rather "all of them" or "all those present in scene"
const _ignored_character_names = {
	"TOUS": true,
	"TOUT LE MONDE": true,
	"FOULE": true
}


static func _parse_episode(text: String, existing_episode = null) -> ScriptData.Episode:
	
	var time_before = OS.get_ticks_msec()
	
	var res = _parse_episode_internal(text, existing_episode)
	
	res.text = text

	if len(res.errors) > 0:
		printerr("--- Unrecognized content ---")
		for e in res.errors:
			printerr("Line ", e.line, ":")
			print("\"", e.text, "\"\n")
		printerr("----------------------------")
	
	var time_spent = OS.get_ticks_msec() - time_before
	print("Took ", time_spent, "ms to parse text")
	
	return res


static func _parse_episode_internal(text, existing_episode = null):

	var lines = text.split("\n")
	
	var data = existing_episode
	if data == null:
		data = ScriptData.Episode.new()
	
	# Reset occurrences in case they change
	for cname in data.character_occurrences:
		var occurrence = data.character_occurrences[cname]
		occurrence.image = null
		occurrence.texture = null
		occurrence.word_count = 0
	
	data.scenes.clear()
	data.errors.clear()
	
	var scene = ScriptData.Scene.new()
	scene.title = "<DefaultScene>"
	scene.line_index = 0
	data.scenes.append(scene)
	
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
	
	if len(data.scenes) > 1 and len(data.scenes[0].elements) == 0:
		# Remove default scene
		data.scenes.remove(0)
	
	if unrecognized_content.empty():
		print("No problem found in script.")
	else:
		for line_index in unrecognized_content:
			var c = unrecognized_content[line_index]
			var e = ScriptData.ScriptError.new()
			e.line = line_index
			e.column = 0
			e.message = "Unrecognized content"
			e.text = c.text
			data.errors.append(e)
	
	var character_names = data.character_occurrences.keys()
	for cname in character_names:
		var occurrence = data.character_occurrences[cname]
		if occurrence.word_count == 0:
			# The character is no longer present in that episode
			data.character_occurrences.erase(cname)
	
	return data


static func _add_statement(scene, data, statement):
	if not _ignored_character_names.has(statement.character_name):
	
		# Add occurrence if not found	
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


static func update_episode_data_from_file(
	project: ScriptData.Project, path: String) -> ScriptData.Episode:
	
	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		var err_msg = "Could not load file {0}, {1}".format([path, Errors.get_message(err)])
		push_error(err_msg)
		return null
	var text = f.get_as_text()
	f.close()

	var episode = update_episode_data_from_text(project, text, path)
	
	return episode


static func update_episode_data_from_text( \
		project: ScriptData.Project, text: String, path: String) -> ScriptData.Episode:
	
	var ep : ScriptData.Episode = null
	var epi := project.get_episode_index_from_path(path)
	if epi != -1:
		ep = project.episodes[epi] as ScriptData.Episode
	
	ep = _parse_episode(text, ep)
	ep.file_path = path
	
	if epi == -1:
		project.episodes.append(ep)
	
	var character_occurences : Dictionary = ep.character_occurrences
	if len(character_occurences) != 0:
		for cname in character_occurences:
			
			# Get or create character
			var character : ScriptData.Character
			if project.characters.has(cname):
				character = project.characters[cname]
			else:
				character = ScriptData.Character.new()
				character.name = cname
				project.characters[cname] = character
	
	return ep

