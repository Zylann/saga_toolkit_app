
const Errors = preload("res://util/errors.gd")
const ScriptData = preload("res://script_data.gd")

const TEMPLATES_PATH = "res://html_exporter/templates/"

var _statement_template = ""
var _root_template = ""
var _note_template = ""


func _init():
	_statement_template = _read_all_file(str(TEMPLATES_PATH, "statement.html"))
	_root_template = _read_all_file(str(TEMPLATES_PATH, "root.html"))
	_note_template = _read_all_file(str(TEMPLATES_PATH, "standalone_note.html"))


func export_script(script_data, output_path):
	print("Exporting script as HTML to ", output_path, "...")
	var time_before = OS.get_ticks_msec()
	
	var content = ""
	var statement_index = 1
	
	for scene_index in len(script_data.scenes):
		var scene = script_data.scenes[scene_index]
		
		content += "<h2 id=\"{0}\">{1}</h2>\n" \
			.format([scene_index, scene.title.xml_escape()])
		
		for e in scene.elements:
			
			if e is ScriptData.Statement:
				
				var note_html = ""
				if len(e.note) != 0:
					note_html = "<span class=\"note\">, {0}</span>" \
						.format([e.note.xml_escape()])
				
				content += _statement_template.format({
					"character_name": e.character_name.xml_escape(),
					"note": note_html,
					"text": e.text.xml_escape(),
					"statement_index": statement_index
				})
				
				statement_index += 1
			
			elif e is ScriptData.Note:
				content += _note_template.format({
					"text": e.text.xml_escape()
				})
			
			elif e is ScriptData.Description:
				# TODO Proper template
				content += _note_template.format({
					"text": e.text.xml_escape()
				})
				
	var full_text = _root_template.format({
		"title": script_data.title.xml_escape(),
		"content": content
	})
	
	var f = File.new()
	var err = f.open(output_path, File.WRITE)
	if err != OK:
		printerr("Could not save file ", output_path, ", ", Errors.get_message(err))
		return
	f.store_string(full_text)
	f.close()
	
	var time_spent = OS.get_ticks_msec() - time_before
	print("Took ", time_spent, "ms to export script as HTML")


static func _read_all_file(fpath):
	var f = File.new()
	var err = f.open(fpath, File.READ)
	if err != OK:
		printerr("Could not read template ", fpath, ", ", Errors.get_message(err))
	assert(err == OK)
	var text = f.get_as_text()
	f.close()
	return text
