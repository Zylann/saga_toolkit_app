
const ACCENT_COLOR = Color(0.18, 0.42 ,0.58)
#const ACCENT_COLOR = Color(0.22, 0.50 ,0.32)


static func _set_border_width_individual(sb, left, top, right, bottom):
	sb.border_width_left = left
	sb.border_width_top = top
	sb.border_width_right = right
	sb.border_width_bottom = bottom


static func _set_content_margin_individual(sb, left, top, right, bottom):
	sb.content_margin_left = left
	sb.content_margin_top = top
	sb.content_margin_right = right
	sb.content_margin_bottom = bottom


static func _make_button_stylebox(color) -> StyleBox:
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(2)
	sb.shadow_color = Color(0, 0, 0, 0.8)
	sb.shadow_offset = Vector2(0, 0.5)
	sb.shadow_size = 2
	sb.bg_color = color
	sb.set_expand_margin_all(2)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb


static func _make_button_focus_stylebox():
	var button_focus = StyleBoxFlat.new()
	button_focus.draw_center = false
	button_focus.set_corner_radius_all(2)
	button_focus.set_border_width_all(1)
	button_focus.border_color = ACCENT_COLOR
	button_focus.set_expand_margin_all(2)
	return button_focus


static func make_button_styleboxes() -> Dictionary:
	return {
		"normal": _make_button_stylebox(_grey(0.2)),
		"hover": _make_button_stylebox(_grey(0.25)),
		"pressed": _make_button_stylebox(ACCENT_COLOR),
		"disabled": _make_button_stylebox(_grey(0.1)),
		"focus": _make_button_focus_stylebox()
	}


static func _make_panel_stylebox() -> StyleBox:
	var panel = StyleBoxFlat.new()
	panel.bg_color = _grey(0.14)
	return panel


static func _make_popup_stylebox() -> StyleBox:
	var sb = _make_panel_stylebox()
	sb.shadow_color = Color(0,0,0, 0.5)
	sb.shadow_size = 3
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


static func _grey(c) -> Color:
	return Color(c, c, c)


static func get_theme() -> Theme:
	var theme = Theme.new()

	theme.set_color("accent_color", "App", ACCENT_COLOR)

	# Button
	
	var button_styles = make_button_styleboxes()
	for k in button_styles:
		theme.set_stylebox(k, "Button", button_styles[k])
	
	# Panel
	
	theme.set_stylebox("panel", "Panel", _make_panel_stylebox())
	
	# Popup
	
	theme.set_stylebox("panel", "PopupPanel", _make_popup_stylebox())
	
	# PopupMenu
	
	var menu_hover = StyleBoxFlat.new()
	menu_hover.bg_color = ACCENT_COLOR
	menu_hover.expand_margin_left = 4
	menu_hover.expand_margin_right = 4
	
	theme.set_stylebox("panel", "PopupMenu", _make_popup_stylebox())
	theme.set_stylebox("hover", "PopupMenu", menu_hover)
	
	#theme.set_constant("hseparation", "PopupMenu", 8)
	theme.set_constant("vseparation", "PopupMenu", 8)
	
	# MenuButton
	
	var menu_button_normal = StyleBoxEmpty.new()
	menu_button_normal.content_margin_left = button_styles.normal.content_margin_left
	menu_button_normal.content_margin_top = button_styles.normal.content_margin_top
	menu_button_normal.content_margin_right = button_styles.normal.content_margin_right
	menu_button_normal.content_margin_bottom = button_styles.normal.content_margin_bottom
	
	theme.set_stylebox("normal", "MenuButton", menu_button_normal)
	theme.set_stylebox("hover", "MenuButton", button_styles.normal)
	theme.set_stylebox("pressed", "MenuButton", button_styles.normal)
	
	# ItemList
	
	var list_panel = StyleBoxFlat.new()
	list_panel.bg_color = _grey(0.12)
	list_panel.set_border_width_all(1)
	list_panel.border_color = _grey(0.05)
	list_panel.content_margin_left = 8
	list_panel.content_margin_right = 8
	list_panel.content_margin_top = 4
	list_panel.content_margin_bottom = 4
	list_panel.set_corner_radius_all(4)
	list_panel.border_blend = true
	
	var list_focus = StyleBoxFlat.new()
	list_focus.set_border_width_all(2)
	list_focus.border_color = ACCENT_COLOR
	list_focus.draw_center = false
	list_focus.set_corner_radius_all(4)
	list_focus.border_blend = true
	
	var item_selected_not_focused = menu_hover.duplicate()
	item_selected_not_focused.bg_color = _grey(0.25)
	
	theme.set_stylebox("bg", "ItemList", list_panel)
	theme.set_stylebox("bg_focus", "ItemList", list_focus)
	theme.set_constant("icon_margin", "ItemList", 4)
	theme.set_constant("hseparation", "ItemList", 4)
	theme.set_constant("vseparation", "ItemList", 4)
	theme.set_stylebox("selected", "ItemList", item_selected_not_focused)
	theme.set_stylebox("selected_focus", "ItemList", menu_hover)
	
	# Tree
	
	var tree_item_selected_not_focused = item_selected_not_focused.duplicate()
	tree_item_selected_not_focused.expand_margin_left = 32
	var tree_item_selected_focused = menu_hover.duplicate()
	tree_item_selected_focused.expand_margin_left = tree_item_selected_not_focused.expand_margin_left
	theme.set_stylebox("bg", "Tree", list_panel)
	theme.set_stylebox("bg_focus", "Tree", list_focus)
	theme.set_stylebox("selected", "Tree", tree_item_selected_not_focused)
	theme.set_stylebox("selected_focus", "Tree", tree_item_selected_focused)
	
	# TextEdit
	
	theme.set_stylebox("normal", "TextEdit", list_panel)
	theme.set_stylebox("focus", "TextEdit", list_focus)
	
	# HBoxContainer
	
	theme.set_constant("separation", "HBoxContainer", 6)

	# VBoxContainer

	theme.set_constant("separation", "VBoxContainer", 8)
	
	# TabContainer
	
	var tab_fg = StyleBoxFlat.new()
	tab_fg.corner_radius_top_right = 4
	tab_fg.corner_radius_top_left = 4
	tab_fg.corner_radius_bottom_left = 0
	tab_fg.corner_radius_bottom_right = 0
	tab_fg.bg_color = _grey(0.25)
	tab_fg.set_expand_margin_individual(0, 2, 0, -1)
	_set_content_margin_individual(tab_fg, 16, 6, 16, 8)
	tab_fg.shadow_size = 0
	_set_border_width_individual(tab_fg, 1, 1, 1, 0)
	tab_fg.border_color = ACCENT_COLOR

	var tab_bg = tab_fg.duplicate()
	tab_bg.set_expand_margin_individual(0, 0, 0, -3)
	_set_content_margin_individual(tab_bg, 16, 4, 16, 6)
	tab_bg.corner_radius_bottom_left = 0
	tab_bg.corner_radius_bottom_right = 0
	tab_bg.bg_color = _grey(0.2)
	tab_bg.border_color = _grey(0.15)
	_set_border_width_individual(tab_bg, 0, 0, 0, 1)
	
	var tab_panel = _make_panel_stylebox()
	tab_panel.bg_color = tab_fg.bg_color
	tab_panel.set_expand_margin_all(3)
	tab_panel.border_color = ACCENT_COLOR
	tab_panel.border_width_top = 1
	tab_panel.corner_radius_top_left = 4
	tab_panel.corner_radius_top_right = 4
	_set_content_margin_individual(tab_panel, 5, 6, 5, 5)
	
	theme.set_stylebox("tab_fg", "TabContainer", tab_fg)
	theme.set_stylebox("tab_bg", "TabContainer", tab_bg)
	theme.set_stylebox("panel", "TabContainer", tab_panel)
	
	# Separators
	
	var line = StyleBoxLine.new()
	line.color = _grey(0.5)
	theme.set_stylebox("separator", "HSeparator", line)
	
	line = StyleBoxLine.new()
	line.color = _grey(0.5)
	line.vertical = true
	theme.set_stylebox("separator", "VSeparator", line)
	
	# Dialogs

	theme.set_constant("margin", "Dialogs", 8)
	theme.set_constant("button_margin", "Dialogs", 32)
	
	# WindowDialog
	
	var window_panel = _make_panel_stylebox()
	window_panel.bg_color = _grey(0.25)
	window_panel.set_expand_margin_all(3)
	window_panel.set_corner_radius_all(4)
	window_panel.shadow_color = Color(0,0,0,0.5)
	window_panel.shadow_offset = Vector2(0, 2)
	window_panel.border_color = _grey(0.8)
	window_panel.shadow_size = 8
	window_panel.border_width_top = 26
	window_panel.expand_margin_top = window_panel.border_width_top
	_set_content_margin_individual(tab_panel, 5, 6, 5, 5)
	
	theme.set_stylebox("panel", "WindowDialog", window_panel)

	theme.set_color("title_color", "WindowDialog", Color(0, 0, 0))
	theme.set_constant("title_height", "WindowDialog", 26)
	theme.set_constant("close_h_ofs", "WindowDialog", 22)
	theme.set_constant("close_v_ofs", "WindowDialog", 20)
	theme.set_constant("title_height", "WindowDialog", 24)
	
	# FileDialog
	
	theme.set_color("folder_icon_modulate", "FileDialog", Color(1, 1, 1));
	theme.set_color("files_disabled", "FileDialog", Color(0, 0, 0, 0.7));
	
	# Tooltip
	
	var tooltip = _make_panel_stylebox()
	tooltip.bg_color = _grey(0.75)
	tooltip.shadow_color = Color(0,0,0,0.5)
	tooltip.shadow_size = 2
	tooltip.shadow_offset = Vector2(1, 1)
	tooltip.set_corner_radius_all(2)
	tooltip.set_expand_margin_all(4)
	theme.set_stylebox("panel", "TooltipPanel", tooltip)
	
	# SplitContainer
	
	var split = StyleBoxFlat.new()
	split.bg_color = Color(1,0,0)
	
	theme.set_stylebox("bg", "VSplitContainer", split)
	theme.set_stylebox("bg", "HSplitContainer", split)
	
	# GridContainer
	
	theme.set_constant("hseparation", "GridContainer", 8)
	theme.set_constant("vseparation", "GridContainer", 8)
	
	# LineEdit
	
	var line_edit = list_panel.duplicate()
	line_edit.set_corner_radius_all(4)
	line_edit.border_blend = true
	
	theme.set_stylebox("normal", "LineEdit", line_edit)
	theme.set_stylebox("focus", "LineEdit", list_focus)
	
	# Scollbar
	
	var scrollbar = StyleBoxFlat.new()
	scrollbar.bg_color = _grey(0.09)
	scrollbar.set_corner_radius_all(5)
	_set_content_margin_individual(scrollbar, 6, 0, 6, 0)
	
	var grabber = StyleBoxFlat.new()
	grabber.bg_color = _grey(0.3)
	grabber.set_corner_radius_all(5)

	var grabber_highlight = grabber.duplicate()
	grabber_highlight.bg_color = _grey(0.4)

	var grabber_pressed = grabber.duplicate()
	grabber_pressed.bg_color = ACCENT_COLOR
	
	theme.set_stylebox("scroll", "VScrollBar", scrollbar)
	theme.set_stylebox("scroll_focus", "VScrollBar", scrollbar)
	
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber_highlight)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber_pressed)

	return theme
	
