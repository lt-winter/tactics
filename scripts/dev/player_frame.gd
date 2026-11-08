class_name PlayerFrame
extends Button

const INK: Color = Color("eee2ca")
const MUTED: Color = Color("8c9287")
const GOLD: Color = Color("d4ad68")

var _title: Label
var _status: Label
var _hand: Label
var _health: Label
var _distance: Label
var _accessories: HBoxContainer
var _ranks: Dictionary = {}
var _names: Dictionary = {}
var _cells: Dictionary = {}
var _occupied: Dictionary = {}


func _init() -> void:
	clip_text = true
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "FrameContent"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 3
	column.offset_top = 3
	column.offset_right = -3
	column.offset_bottom = -3
	column.add_theme_constant_override("separation", 1)
	add_child(column)
	_title = _label(_cell(column), "PlayerName", 24)
	_title.add_theme_font_size_override("font_size", 13)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var body: Control = Control.new()
	body.name = "PortraitArea"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size.y = 36
	column.add_child(body)
	_status = _label(body, "LifeState")
	_status.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_status.offset_left = 5
	_status.offset_right = -68
	_status.offset_top = 0
	_status.offset_bottom = 17
	_hand = _label(body, "HandCount")
	_hand.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_hand.offset_left = 5
	_hand.offset_right = -68
	_hand.offset_top = 18
	_hand.offset_bottom = 35
	_distance = _label(body, "EffectiveDistance")
	_distance.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_distance.offset_left = -66
	_distance.offset_top = 0
	_distance.offset_right = 0
	_distance.offset_bottom = 16
	_distance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hp_cell: PanelContainer = _cell(body)
	hp_cell.name = "HealthCell"
	hp_cell.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hp_cell.offset_left = -66
	hp_cell.offset_top = -20
	hp_cell.offset_right = 0
	hp_cell.offset_bottom = 0
	_health = _label(hp_cell, "Health")
	_health.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equipment_row(column, "weapon", "Vũ khí")
	_equipment_row(column, "armor", "Phòng ngự")
	var accessories: HBoxContainer = HBoxContainer.new()
	accessories.name = "AccessoryRow"
	_accessories = accessories
	accessories.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accessories.add_theme_constant_override("separation", 1)
	column.add_child(accessories)
	_equipment_row(accessories, "offensive_accessory", "Scope")
	_equipment_row(accessories, "defensive_accessory", "Mustang")
	_equipment_row(column, "special", "Đặc biệt")


func _cell(parent: Node) -> PanelContainer:
	var cell: PanelContainer = PanelContainer.new()
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("232c27")
	style.border_color = Color("746044")
	style.set_border_width_all(1)
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.set_corner_radius_all(2)
	cell.add_theme_stylebox_override("panel", style)
	parent.add_child(cell)
	return cell


func _label(parent: Node, node_name: String, height: float = 16) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size.y = height
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", INK)
	parent.add_child(label)
	return label


func _equipment_row(parent: Node, slot: String, placeholder: String) -> void:
	var cell: PanelContainer = _cell(parent)
	cell.name = slot + "Cell"
	cell.custom_minimum_size.y = 20
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	cell.add_child(row)
	var rank_cell: PanelContainer = _cell(row)
	rank_cell.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var divider: StyleBoxFlat = rank_cell.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	divider.border_width_left = 0
	divider.border_width_top = 0
	divider.border_width_bottom = 0
	divider.content_margin_left = 2
	rank_cell.add_theme_stylebox_override("panel", divider)
	var rank: Label = _label(rank_cell, slot + "Rank")
	rank.custom_minimum_size.x = 22
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var caption: Label = _label(row, slot + "Name")
	caption.text = placeholder
	caption.add_theme_color_override("font_color", MUTED)
	_ranks[slot] = rank
	_names[slot] = caption
	_cells[slot] = cell
	_occupied[slot] = false
	cell.modulate.a = 0.0


func display(view: Dictionary) -> void:
	_title.text = ("▶ " if bool(view["active"]) else "") + str(view["name"])
	_title.add_theme_color_override("font_color", GOLD if bool(view["active"]) else INK)
	_status.text = str(view["state"])
	_hand.text = "%d lá" % int(view["hand_count"])
	_distance.text = "Cách %d" % int(view["distance"]) if int(view.get("distance", -1)) >= 0 else ""
	_health.text = str(view["health"]) if int(view["hp"]) > 0 else "♥ %d/%d" % [int(view["hp"]), int(view["max_hp"])]
	_health.tooltip_text = ""
	var equipment: Dictionary = view["equipment"]
	for slot: String in _names:
		var rank: Label = _ranks[slot]
		var caption: Label = _names[slot]
		var equipped: Dictionary = equipment.get(slot, {})
		var cell: Control = _cells[slot]
		_occupied[slot] = not equipped.is_empty()
		# Transparent empty cells keep their fixed geometry without drawing placeholders.
		cell.modulate.a = 1.0 if is_slot_occupied(slot) else 0.0
		cell.mouse_filter = Control.MOUSE_FILTER_PASS if is_slot_occupied(slot) else Control.MOUSE_FILTER_IGNORE
		rank.text = str(equipped.get("rank_suit", ""))
		rank.add_theme_color_override("font_color", Color("f28b7b") if bool(equipped.get("red", false)) else INK)
		caption.text = str(equipped.get("name", ""))
		if slot == "weapon" and not equipped.is_empty():
			caption.text = "Tầm %s · %s" % [equipped["range"], caption.text]
		caption.add_theme_color_override("font_color", INK if not equipped.is_empty() else MUTED)
		cell.tooltip_text = str(equipped.get("description", ""))
		if slot == "weapon" and is_slot_occupied(slot):
			cell.tooltip_text += "\nTầm %s" % equipped["range"]
	_accessories.modulate.a = 1.0 if is_slot_occupied("offensive_accessory") or is_slot_occupied("defensive_accessory") else 0.0


func is_slot_occupied(slot: String) -> bool:
	return bool(_occupied.get(slot, false))


func get_slot_text(slot: String) -> String:
	if not _names.has(slot) or not is_slot_occupied(slot):
		return ""
	return (_ranks[slot] as Label).text + " " + (_names[slot] as Label).text


func get_display_text() -> String:
	var lines: PackedStringArray = [_title.text, _status.text, _hand.text, _health.text, _distance.text]
	for slot: String in _names:
		if not get_slot_text(slot).is_empty():
			lines.append(get_slot_text(slot))
	return "\n".join(lines)
