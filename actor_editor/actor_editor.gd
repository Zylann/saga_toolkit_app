extends Control

const ScriptData = preload("./../script_data.gd")
const CharacterSelectionDialogScene = preload("./character_selection_dialog.tscn")

onready var _actor_list = get_node("ActorList")
onready var _gender_selector = get_node("VSplitContainer/Properties/GenderSelector")
onready var _name_edit = get_node("VSplitContainer/Properties/ActorNameEdit")
onready var _characters_list = get_node("VSplitContainer/Properties/HBoxContainer2/CharacterList")
onready var _notes_edit = get_node("VSplitContainer/Properties/Notes")
onready var _properties_container = get_node("VSplitContainer/Properties")
onready var _remove_actor_button = get_node("VSplitContainer/HBoxContainer/RemoveActorButton")
onready var _get_statements_button = get_node("VSplitContainer/HBoxContainer/StatementsReduxButton")

var _project = null
var _character_selection_dialog = null
var _remove_actor_confirmation_dialog = null


func _ready():
	_gender_selector.add_item("Male", ScriptData.GENDER_MALE)
	_gender_selector.add_item("Female", ScriptData.GENDER_FEMALE)
	_gender_selector.add_item("Other", ScriptData.GENDER_OTHER)
	
	_properties_container.hide()
	_update_buttons_availability()


func set_project(project):
	_project = project
	_properties_container.hide()
	_update_buttons_availability()
	_update_actors_list()


func setup_dialogs(parent):
	assert(_character_selection_dialog == null)
	_character_selection_dialog = CharacterSelectionDialogScene.instance()
	_character_selection_dialog.connect( \
		"characters_selected", self, "_on_CharacterSelectionDialog_characters_selected")
	parent.add_child(_character_selection_dialog)
	
	_remove_actor_confirmation_dialog = ConfirmationDialog.new()
	_remove_actor_confirmation_dialog.window_title = "Removing Actor"
	_remove_actor_confirmation_dialog.dialog_text = "Delete Actor?"
	_remove_actor_confirmation_dialog.connect(\
		"confirmed", self, "_on_RemoveActorConfirmationDialog_confirmed")
	parent.add_child(_remove_actor_confirmation_dialog)


func _update_buttons_availability():
	var available = false
	if _project != null:
		var actor_id = _get_selected_actor_id()
		var actor = _project.get_actor_by_id(actor_id)
		available = (actor != null)
	_remove_actor_button.disabled = not available
	_get_statements_button.disabled = not available


func _update_actors_list():
	_actor_list.clear()
	for actor in _project.actors:
		var i = _actor_list.get_item_count()
		_actor_list.add_item(actor.name)
		_actor_list.set_item_metadata(i, actor.id)
	_actor_list.sort_items_by_text()	


func _get_selected_actor_id():
	var selected = _actor_list.get_selected_items()
	if len(selected) == 0:
		return -1
	return _actor_list.get_item_metadata(selected[0])


func _on_AddCharacterButton_pressed():
	var actor_id = _get_selected_actor_id()
	if actor_id == -1:
		return
	_character_selection_dialog.configure(_project, actor_id)
	_character_selection_dialog.popup_centered_minsize()


func _on_RemoveCharacterButton_pressed():
	var selected = _characters_list.get_selected_items()
	var actor_id = _get_selected_actor_id()
	assert(actor_id != -1)
	for i in selected:
		var cname = _characters_list.get_item_metadata(i)
		if not _project.characters.has(cname):
			push_error("Character {0} not found".format([cname]))
			continue
		var character = _project.characters[cname]
		if character.actor_id == actor_id:
			character.actor_id = -1
	_update_characters_list()


func _update_characters_list():
	_characters_list.clear()
	var actor_id = _get_selected_actor_id()
	if actor_id == -1:
		return
	for cname in _project.characters:
		var character = _project.characters[cname]
		if character.actor_id == actor_id:
			var i = _characters_list.get_item_count()
			_characters_list.add_item(cname)
			_characters_list.set_item_metadata(i, cname)


func _on_CharacterSelectionDialog_characters_selected(character_names):
	var actor_id = _get_selected_actor_id()
	if actor_id == -1:
		push_error("Selected a character but no actor selected. Something went wrong.")
		return
	for cname in character_names:
		var character = _project.characters[cname]
		character.actor_id = actor_id
	_update_characters_list()


func _on_ActorList_item_selected(index):
	var actor_id = _actor_list.get_item_metadata(index)
	_update_for_actor(actor_id)
	

func _update_for_actor(actor_id):
	print("Showing actor ", actor_id)
	var actor = _project.get_actor_by_id(actor_id)
	if actor == null:
		push_error("Actor {0} not found".format(actor_id))
		_properties_container.hide()
		_update_buttons_availability()
		return
	
	_properties_container.show()
	_update_buttons_availability()

	_name_edit.text = actor.name

	_update_characters_list()
	
	for i in _gender_selector.get_item_count():
		if _gender_selector.get_item_id(i) == actor.gender:
			print("Showing gender ", actor.gender, " (index ", i, ")")
			_gender_selector.selected = i
			break
	
	_notes_edit.text = actor.notes


func _on_AddActorButton_pressed():
	var actor = ScriptData.Actor.new()
	actor.id = _project.generate_actor_id()
	actor.name = "<UnnamedActor>"
	actor.gender = ScriptData.GENDER_OTHER
	_project.actors.append(actor)
	_update_actors_list()
	_select_actor_by_id(actor.id)


func _select_actor_by_id(p_id):
	for i in _actor_list.get_item_count():
		var id = _actor_list.get_item_metadata(i)
		if id == p_id:
			_actor_list.select(i)
			_update_for_actor(p_id)
			break


func _on_RemoveActorButton_pressed():
	var actor_id = _get_selected_actor_id()
	var actor = _project.get_actor_by_id(actor_id)
	if actor == null:
		push_error("Actor {0} not found".format([actor_id]))
		return
	_remove_actor_confirmation_dialog.dialog_text = "Remove actor {0}?".format([actor.name])
	_remove_actor_confirmation_dialog.popup_centered_minsize()
	_properties_container.hide()
	_update_buttons_availability()


func _on_RemoveActorConfirmationDialog_confirmed():
	var actor_id = _get_selected_actor_id()
	
	for character in _project.characters:
		if character.actor_id == actor_id:
			character.actor_id = -1
	
	for i in len(_project.actors):
		if _project.actors[i].id == actor_id:
			_project.actors.remove(i)
			break

	_update_actors_list()


func _on_ActorNameEdit_text_changed(new_text):
	var new_name = new_text.strip_edges()
	_set_actor_data_prop("name", new_name)

	var actor_id = _get_selected_actor_id()
	for i in _actor_list.get_item_count():
		if _actor_list.get_item_metadata(i) == actor_id:
			_actor_list.set_item_text(i, new_name)
			break


func _on_GenderSelector_item_selected(id):
	_set_actor_data_prop("gender", id)


func _set_actor_data_prop(key, value):
	var actor_id = _get_selected_actor_id()
	var actor = _project.get_actor_by_id(actor_id)
	if actor == null:
		push_error("Actor {0} not found".format([actor_id]))
		return
	actor.set(key, value)
	print("Set actor ", actor_id, " ", key, " to ", value)


func _on_Notes_text_changed():
	_set_actor_data_prop("notes", _notes_edit.text)


func _generate_statements_redux():
	var actor_id = _get_selected_actor_id()
	if actor_id == -1:
		return
	
	var text = ""
	
	var characters = []
	for character_name in _project.characters:
		var character = _project.characters[character_name]
		if character.actor_id == actor_id:
			characters.append(character_name)
	
	for character_name in characters:
		text += str(character_name, "\n===================\n\n")
		for ep in _project.episodes:
			var statements = []
			for scene in ep.scenes:
				for elem in scene.elements:
					if elem is ScriptData.Statement and elem.character_name == character_name:
						statements.append(elem)
			if len(statements) > 0:
				text += str(ep.title, "\n----------------\n\n")
				for s in statements:
					text += str(_statement_to_text(s), "\n\n")
	
	# TODO Show this in a TextEdit
	print(text)


static func _statement_to_text(s):
	if s.note != "":
		return str(s.character_name, ", ", s.note, " -- ", s.text)
	else:
		return str(s.character_name, " -- ", s.text)
	

func _on_StatementsReduxButton_pressed():
	_generate_statements_redux()
