extends AcceptDialog

const Accents = preload("./../util/accents.gd")

onready var _format_selector = get_node("VBoxContainer/HBoxContainer/Format")
onready var _text_edit = get_node("VBoxContainer/TextEdit")

const FORMAT_BBCODE = 0
#const FORMAT_HTML = 1
#const FORMAT_MARKDOWN = 2


var _project = null
var _episode_path = ""


func _ready():
	_format_selector.get_popup().add_item("BBCode (Netophonix)", FORMAT_BBCODE)
#	_format_selector.get_popup().add_item("HTML", FORMAT_HTML)
#	_format_selector.get_popup().add_item("Markdown", FORMAT_MARKDOWN)
	_format_selector.select(0)
	_format_selector.get_popup().connect("id_pressed", self, "_on_Format_id_pressed")


func configure(project, episode_path):
	_project = project
	_episode_path = episode_path
	_generate()


func _get_format():
	var i = _format_selector.selected
	return _format_selector.get_popup().get_item_id(i)


func _on_Format_id_pressed(id):
	_generate(id)


func _generate(format = -1):
	
	if format == -1:
		format = _get_format()
	
	var episode = _project.get_episode_from_path(_episode_path)
	assert(episode != null)
	
	var text = ""
	
	match format:
		FORMAT_BBCODE:
			text = _generate_bbcode(episode)
#		FORMAT_HTML:
#			_generate_html(episode)
#		FORMAT_MARKDOWN:
#			_generate_markdown(episode)
	
	_text_edit.text = text


func _get_actors(episode):
	var actors_dict = {}
	for character_name in episode.character_occurrences:
		var character = _project.characters[character_name]
		if character.actor_id != -1:
			var actor = _project.get_actor_by_id(character.actor_id)
			if actor != null:
				if actors_dict.has(actor):
					actors_dict[actor].append(character)
				else:
					actors_dict[actor] = [character]
	var actors = []
	for a in actors_dict:
		actors.append({
			"actor": a,
			"characters": actors_dict[a]
		})
	return actors


func _generate_bbcode(episode):
	
	var unsupported_audio_tag = tr("Your browser does not support the audio tag.")
	
	var root_template = \
		  "[u][size=150]{title}[/size][/u]\n" \
		+ "\n" \
		+ "[img]{banner_url}[/img]\n" \
		+ "\n" \
		+ "[i]{synopsis}[/i]\n" \
		+ "\n" \
		+ "[u][size=150]{listen}[/size][/u]\n" \
		+ "\n" \
	+ "<audio controls><source src=\"{mp3_url}\"/>" + unsupported_audio_tag + "</audio>\n" \
		+ "[url={website_url}]{website}[/url] | [bravo]{saga_id}[/bravo]\n" \
		+ "\n" \
		+ "[u][size=150]{actors}[/size][/u]\n" \
		+ "\n" \
		+ "[spoiler]{actors_list}[/spoiler]\n" \
		+ "\n"

#		+ "[mp3]{mp3_url}[/mp3]\n" \

#		+ "\n" \
#		+ "[size=150]{musics}[/size]\n" \
#		+ "\n" \
#		+ "[spoiler]{music_list}[/spoiler]\n" \
	
	var list_template = "[list]\n{items}\n[/list]"
	var list_item_template = "[*]{text}\n"
	# TODO Custom link
	var actor_name_template = "[b][url={url}]{name}[/url][/b]"
	
	var actors = _get_actors(episode)
	var actors_text = ""
	for a in actors:
		
		var chars = ""
		for i in len(a.characters):
			if i > 0:
				chars += ", "
			var character = a.characters[i]
			chars += character.name.capitalize()
		
		# TODO Custom link
		# Generate netowiki link
		var url = "https://wiki.netophonix.com/" + a.actor.name.percent_encode()
		
		var line = str(actor_name_template.format(
			{"url": url, "name": a.actor.name}), " : ", chars)
		
		actors_text += list_item_template.format({"text": line})
	
	actors_text = list_template.format({"items": actors_text})
	
	var text = root_template.format({
		"title": episode.title,
		"banner_url": _project.post_banner_url,
		"synopsis": episode.synopsis,
		"listen": tr("Listen"),
		"mp3_url": episode.mp3_url,
		"website_url": _project.website,
		"website": tr("Website"),
		"saga_id": _project.netophonix_saga_id,
		"actors": tr("Actors"),
		"actors_list": actors_text
	})
	
	return text


#func _generate_html(episode):
#	pass
#
#
#func _generate_markdown(episode):
#	pass


