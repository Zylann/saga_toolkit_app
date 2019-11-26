# Quite useless but fun experiment

extends AcceptDialog

const ScriptData = preload("./../script_data.gd")

onready var _surface = get_node("ColorRect")

var _project = null
var _episode_path := ""


func set_project(project):
	_project = project


func set_episode_path(ep_path: String):
	_episode_path = ep_path


func _on_ColorRect_draw():
	var ci = _surface
	
	var episode = _project.get_episode_from_path(_episode_path)
	if episode == null:
		return
	
	var lane_height = 10
	var item_color = Color(0.5, 0.5, 1)
	var lane_color1 = Color(0.1, 0.1, 0.1)
	var lane_color2 = Color(0.15, 0.15, 0.15)
	var scene_separator_color = Color(0.3, 0.3, 0.3)
	var lane_separation = 1
	var item_spacing = 2

	var character_indexes = {}
	
	# Draw lane backgrounds
	for cname in episode.character_occurrences:
		var char_index = -1
		if character_indexes.has(cname):
			char_index = character_indexes[cname]
		else:
			char_index = len(character_indexes)
			character_indexes[cname] = char_index
		var lane_color
		if char_index % 2 == 0:
			lane_color = lane_color1
		else:
			lane_color = lane_color2
		var y = char_index * (lane_height + lane_separation)
		ci.draw_rect(Rect2(0, y, ci.rect_size.x, lane_height + lane_separation), lane_color)

	# Calculate horizontal scale
	var total_word_count = 0
	for scene in episode.scenes:
		for element in scene.elements:
			if element is ScriptData.Statement:
				total_word_count += element.word_count + item_spacing

	var xscale = ci.rect_size.x / float(total_word_count + 1)
	ci.draw_set_transform(Vector2(), 0, Vector2(xscale, 1))		
	
	# Draw items
	var pos = 0
	var first = true
	for scene in episode.scenes:
		
		if not first:
			ci.draw_line(Vector2(pos, 0), Vector2(pos, ci.rect_size.y), scene_separator_color)
		else:
			first = false
		
		for element in scene.elements:
			if element is ScriptData.Statement:
				
				if not character_indexes.has(element.character_name):
					continue
				var char_index = character_indexes[element.character_name]
				
				var y = char_index * (lane_height + lane_separation) + lane_separation
				ci.draw_rect(Rect2(pos, y, element.word_count, lane_height), item_color)
				
				pos += element.word_count + item_spacing
