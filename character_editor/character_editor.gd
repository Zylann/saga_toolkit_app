extends HSplitContainer

#signal characters_list_changed(names)

onready var _character_list = get_node("CharacterList")


func clear():
	_character_list.clear()


func _update_characters_list(project):
	
	_character_list.clear()
	
	for cname in project.characters:
		var character = project.characters[cname]

		var i = _character_list.get_item_count()
		_character_list.add_item(cname)
		_character_list.set_item_metadata(i, cname)

	#emit_signal("characters_list_changed", project)


func _on_ScriptEditor_script_parsed(project, script_path, errors):
	_update_characters_list(project)

# TODO Frequency map

#func generate_character_frequency_image(script_data, character_name):
#	var statements = _get_all_statements(script_data)
#	var im = Image.new()
#	im.create(len(statements), 1, Image.FORMAT_RGB8)
#	im.fill(Color(0,0,0))
#	im.lock()
#	for i in len(statements):
#		var s = statements[i]
#		if s.character_name == character_name:
#			im.set_pixel(i, 0, Color(1,1,0.2))
#	im.unlock()
#	return im


#static func _get_all_statements(script_data):
#	var statements = []
#	for scene in script_data.scenes:
#		for e in scene.elements:
#			if e is ScriptParser.Statement:
#				statements.append(e)
#	return statements


func _on_CharacterList_item_selected(index):
	pass # Replace with function body.
