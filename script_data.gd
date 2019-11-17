
# TOOD Rename ProjectData

# TOOD Make this class the main script
class Project:
	var title = "Untitled"
	var episodes = []
	var characters = {}

	func get_episode_index_from_path(fpath):
		for i in len(episodes):
			if episodes[i].file_path == fpath:
				return i
		return -1

	func get_episode_from_path(fpath):
		for e in episodes:
			if e.file_path == fpath:
				return e
		return null
	
	func clear():
		title = "Untitled"
		episodes.clear()
		characters.clear()


class Episode:
	var title = ""
	var file_path = ""
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


class Character:
	var name = ""

