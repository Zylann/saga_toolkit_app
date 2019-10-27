
class Project:
	var title = "Untitled"
	var directory = ""
	var episodes = []
	var characters = {}


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

