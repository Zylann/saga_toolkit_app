# Super-lazy persistent global settings

const PATH = "user://userprefs.json"

const Errors = preload("errors.gd")


static func get_all():
	var f = File.new()
	if not f.file_exists(PATH):
		return {}
	var err = f.open(PATH, File.READ)
	if err != OK:
		printerr("Could not open ", PATH, ", ", Errors.get_message(err))
		return {}
	var text = f.get_as_text()
	f.close()
	var res = JSON.parse(text)
	if res.error != OK:
		printerr("Failed to parse ", PATH, ", ", res.error_string, ", at line ", res.error_line)
		return {}
	return res.result


static func save_all(d):
	var text = JSON.print(d)
	var f = File.new()
	var err = f.open(PATH, File.WRITE)
	if err != OK:
		printerr("Could not open ", PATH, ", ", Errors.get_message(err))
		return
	f.store_string(text)
	f.close()


static func get_value(key):
	var d = get_all()
	if d.has(key):
		return d[key]
	return null


static func set_value(key, value):
	var d = get_all()
	d[key] = value
	save_all(d)

