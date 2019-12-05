extends AcceptDialog

const UserPrefs = preload("./../util/userprefs.gd")

onready var _language_selector := get_node("GridContainer/LanguageSelector") as OptionButton


func _ready():
	# testing
	#show()
	
	var locales = TranslationServer.get_loaded_locales()
	var popup := _language_selector.get_popup()
	
	for locale in locales:
		var i = popup.get_item_count()
		var locale_name = TranslationServer.get_locale_name(locale)
		popup.add_item(locale_name)
		popup.set_item_metadata(i, locale)
	
	var current_language := TranslationServer.get_locale()
	for i in popup.get_item_count():
		if popup.get_item_metadata(i) == current_language:
			_language_selector.selected = i
			break


func _on_LanguageSelector_item_selected(id):
	var locale := ""
	var popup := _language_selector.get_popup()
	for i in popup.get_item_count():
		if popup.get_item_id(i) == id:
			locale = popup.get_item_metadata(i) as String
			break
	assert(locale != "")
	TranslationServer.set_locale(locale)
	UserPrefs.set_value("locale", locale)
