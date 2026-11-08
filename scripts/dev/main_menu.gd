class_name MainMenu
extends Control

const GOLD: Color = Color("d4ad68")
const INK: Color = Color("eee2ca")
const FONT_SCALE: float = 0.94

var _content: VBoxContainer
var _panel: PanelContainer
var _catalog: MarginContainer


func _ready() -> void:
	theme = Theme.new()
	theme.default_font_size = 15
	if get_window().size.x < 1280 or get_window().size.y < 720:
		get_window().size = Vector2i(maxi(1280, get_window().size.x), maxi(720, get_window().size.y))
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_window().size_changed.connect(_sync_canvas_size)
	_sync_canvas_size()
	_build_menu()


func _sync_canvas_size() -> void:
	var window: Window = get_window()
	if window.content_scale_size != window.size:
		window.content_scale_size = window.size


func _style(background: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	box.content_margin_left = 14.0
	box.content_margin_right = 14.0
	box.content_margin_top = 12.0
	box.content_margin_bottom = 12.0
	return box


func _button(parent: Node, caption: String, handler: Callable) -> Button:
	var button: Button = Button.new()
	button.name = {"Chơi": "Play", "Danh mục bài": "CardCatalog", "Quay lại": "CatalogBack"}.get(caption, "MenuAction")
	button.text = caption
	button.custom_minimum_size = Vector2(220.0, 48.0)
	button.pressed.connect(handler)
	parent.add_child(button)
	return button


func _label(parent: Node, caption: String, size: int = 16) -> Label:
	var label: Label = Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", maxi(12, roundi(float(size) * FONT_SCALE)))
	parent.add_child(label)
	return label


func _build_menu() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color("151916")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	_panel = panel
	panel.custom_minimum_size = Vector2(420.0, 420.0)
	panel.add_theme_stylebox_override("panel", _style(Color("25251f"), Color("554a38")))
	center.add_child(panel)
	_content = VBoxContainer.new()
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_theme_constant_override("separation", 14)
	panel.add_child(_content)
	_label(_content, "TACTICS", 36).add_theme_color_override("font_color", GOLD)
	_label(_content, "Viễn Tây · chiến thuật và những lá bài", 16).add_theme_color_override("font_color", INK)
	_button(_content, "Chơi", _play)
	_button(_content, "Danh mục bài", _show_catalog)
	_label(_content, "Một người chơi · 2–6 ghế · offline", 13)


func _play() -> void:
	get_tree().change_scene_to_file("res://scenes/dev/playable_prototype.tscn")


func _show_catalog() -> void:
	if is_instance_valid(_catalog):
		return
	_panel.hide()
	_catalog = MarginContainer.new()
	_catalog.name = "CardCatalogView"
	_catalog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_catalog.offset_left = 120.0
	_catalog.offset_right = -120.0
	_catalog.offset_top = 70.0
	_catalog.offset_bottom = -70.0
	add_child(_catalog)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	_catalog.add_child(column)
	var header: HBoxContainer = HBoxContainer.new()
	column.add_child(header)
	_label(header, "DANH MỤC BÀI", 28).add_theme_color_override("font_color", GOLD)
	var back: Button = _button(header, "Quay lại", _close_catalog)
	back.custom_minimum_size = Vector2(140.0, 40.0)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "CatalogScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var entries: VBoxContainer = VBoxContainer.new()
	entries.name = "CatalogEntries"
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 8)
	scroll.add_child(entries)
	var database: CardDatabase = CardDatabase.new()
	var intro: Label = _label(entries, "", 14)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH):
		intro.text = "Không thể nạp danh mục: " + "; ".join(database.get_errors())
		return
	intro.text = "%d loại bài trong bộ dữ liệu hiện tại." % database.definitions.size()
	for card_id: String in database.definitions:
		var definition: CardDefinition = CardDefinition.new(database.definitions[card_id])
		var item: PanelContainer = PanelContainer.new()
		item.name = "CatalogCard_" + card_id
		item.set_meta("card_id", card_id)
		item.add_theme_stylebox_override("panel", _style(Color("25251f"), Color("554a38")))
		entries.add_child(item)
		var item_column: VBoxContainer = VBoxContainer.new()
		item.add_child(item_column)
		var title: Label = _label(item_column, definition.display_name, 18)
		title.add_theme_color_override("font_color", GOLD)
		var category: String = {"basic": "Cơ bản", "tool": "Công cụ", "equipment": "Trang bị"}.get(definition.category, definition.category)
		if definition.equipment_slot == "weapon":
			category += " · Vũ khí · Tầm %d" % definition.attack_range
		elif definition.equipment_slot in AccessoryEffects.SLOTS:
			category += " · Phụ kiện " + ("tấn công" if definition.equipment_slot == "offensive_accessory" else "phòng thủ")
		_label(item_column, category, 12)
		var description: Label = _label(item_column, definition.description, 14)
		description.name = "Description"
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _close_catalog() -> void:
	if is_instance_valid(_catalog):
		_catalog.queue_free()
	_catalog = null
	_panel.show()
