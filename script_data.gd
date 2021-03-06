
# TOOD Rename ProjectData

const GENDER_UNKNOWN = -1
const GENDER_MALE = 0
const GENDER_FEMALE = 1
const GENDER_OTHER = 2


# TOOD Make this class the main script
class Project:
	signal modified
	
	var title := "Untitled"
	var synopsis := ""
	var episodes := []
	var characters := {}
	var actors := []
	var website := ""
	var next_actor_id := 1
	var post_banner_url := ""
	var netophonix_saga_id := -1
	
	# Transient
	var file_path := ""
	var modified := false
	
	func make_modified():
		if not modified:
			modified = true
			emit_signal("modified")

	func get_episode_index_from_path(fpath: String) -> int:
		for i in len(episodes):
			if episodes[i].file_path == fpath:
				return i
		return -1

	func get_episode_from_path(fpath: String) -> Episode:
		for e in episodes:
			if e.file_path == fpath:
				return e
		return null
	
	func get_actor_by_id(id: int) -> Actor:
		for a in actors:
			if a.id == id:
				return a
		return null
	
	func generate_actor_id() -> int:
		var id = next_actor_id
		next_actor_id += 1
		return id
	
	func clear():
		title = "Untitled"
		episodes.clear()
		characters.clear()
		actors.clear()
		next_actor_id = 1

	func get_word_count_totals() -> Dictionary:
		var word_count_totals := {}
		for ep in episodes:
			for cname in ep.character_occurrences:
				var wc = ep.character_occurrences[cname].word_count
				if word_count_totals.has(cname):
					var c = word_count_totals[cname]
					c += wc
					word_count_totals[cname] = c
				else:
					word_count_totals[cname] = wc
		return word_count_totals


class ScriptError:
	var line := -1
	var column := -1
	var message := ""
	var text := ""


class Episode:
	var title := ""
	var synopsis := ""
	var file_path := ""
	var scenes := []
	var character_occurrences := {} # name => occurence
	var text := ""
	var mp3_url := ""
	# Transient
	var errors = []


class CharacterOccurrence:
	# Persistent
	var recorded = false
	# Transient
	var image = null
	var texture = null
	var word_count = 0


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
	var word_count = 0


class Character:
	var name := ""
	var full_name := ""
	var gender := -1
	var description := ""
	# TODO Allow multiple actors so we can have crowd participation?
	var actor_id := -1


class Actor:
	var id := -1
	var name := ""
	var gender := -1
	var notes := ""


