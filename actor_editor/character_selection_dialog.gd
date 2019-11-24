extends ConfirmationDialog

signal characters_selected(cnames)

onready var _character_list = get_node("VBoxContainer/ItemList")


func configure(project, actor_id):
	
	_character_list.clear()
	
	var char_names = project.characters.keys()
	char_names.sort()
	
	for cname in char_names:
		
		var i = _character_list.get_item_count()
		_character_list.add_item(cname)
		_character_list.set_item_metadata(i, cname)
		
		var character = project.characters[cname]
		if character.actor_id != -1:
			_character_list.set_item_disabled(i, true)
			_character_list.set_item_selectable(i, false)
			
			var actor = project.get_actor_by_id(character.actor_id)
			if actor == null:
				push_error("Actor id={0} not found for character {1}".format(\
					[character.actor_id, cname]))
				continue
			
			_character_list.set_item_text(i, str(cname, " (", actor.name, ")"))
		
	get_ok().disabled = (_character_list.get_item_count() == 0)


func _on_ItemList_item_activated(index):
	var cname = _character_list.get_item_metadata(index)
	emit_signal("characters_selected", [cname])
	hide()


func _on_CharacterSelectionDialog_confirmed():
	if _character_list.get_item_count() == 0:
		return
	var selected = _character_list.get_selected_items()
	var cnames = []
	if len(selected) == 0:
		cnames = [_character_list.get_item_metadata(0)]
	else:
		for i in selected:
			var cname = _character_list.get_item_metadata(i)
			cnames.append(cname)
	emit_signal("characters_selected", cnames)

