extends HSplitContainer


signal characters_list_changed(names)

onready var _character_list = get_node("CharacterList")

var _characters_data = {}


func _merge_character_names(character_names):
	if len(character_names) == 0:
		return
	
	var added = 0
	for cname in character_names:
		
		if _characters_data.has(cname):
			continue
			
		var c = {
			"identifier": cname
		}
		_characters_data[cname] = c
		
		var i = _character_list.get_item_count()
		_character_list.add_item(cname)
		_character_list.set_item_metadata(i, c)
		added += 1
	
	if added > 0:
		_character_list.sort_items_by_text()
	
	emit_signal("characters_list_changed", _characters_data.keys())


func _on_ScriptEditor_script_parsed(script_path, result):
	var cnames = result.data.character_names
	_merge_character_names(cnames)

