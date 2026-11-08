class_name PlayablePrototype
extends Control

const HUMAN_ID: int = 1
const GOLD: Color = Color("d4ad68")
const INK: Color = Color("eee2ca")
const FONT_SCALE: float = 0.94

var game_state: GameState
var combat: CombatController
var selected_target_id: int = 0
var selected_human_card_id: int = 0
var selected_bot_id: int = 2
var selected_bot_card_id: int = 0
var displayed_player_id: int = 0
var selected_hand_card_id: int = 0

var _seats: Array[Button] = []
var _hand: HBoxContainer
var _phase: Label
var _prompt: Label
var _feedback: Label
var _piles: Label
var _selection: Label

var _event_log: RichTextLabel
var _events: Array[String] = []
var _choice_overlay: Control
var _choice_title: Label
var _choice_cards: HBoxContainer
var _choice_confirm: Button
var _choice_cancel: Button
var _choice_kind: String = ""
var _choice_actor_id: int = 0
var _choice_target_id: int = 0
var _choice_played_card_id: int = 0
var _choice_selected_card_id: int = 0
var _choice_zone: String = ""
var _choice_card_count: int = 0
var _dying_rescuer_id: int = 0
var _setup_menu: MatchSetupMenu
var _game_page: Control
var _bot_layout: Control
var _human_info: VBoxContainer
var _player_count: int = 4
var _support_selected_ids: Array[int] = []
var _double_selected_hand_id: int = 0
var _double_selected_choices: Array[int] = []
var _played_card_slot: CenterContainer
var _played_by: Label
var _last_played_card_id: int = 0
var _attack_targets: Array[int] = []
var _extra_target_id: int = 0
var _picking_extra_target: bool = false
var _weapon_target_prompt: bool = false
var _weapon_decision_id: int = 0
var _weapon_target_id: int = 0
var _weapon_cards: Array[int] = []
var _hand_column: VBoxContainer
var _inline_choice_host: VBoxContainer
var _choice_content: VBoxContainer
var _choice_panel: PanelContainer
var _choice_scroll: ScrollContainer
var _choice_actions: HBoxContainer
var _inline_choice: bool = false
var _turn_discard_ids: Array[int] = []
var _armor_decision_id: int = 0


func _ready() -> void:
	if get_window().size.x < 1280 or get_window().size.y < 720:
		get_window().size = Vector2i(maxi(1280, get_window().size.x), maxi(720, get_window().size.y))
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_window().size_changed.connect(_sync_canvas_size)
	_sync_canvas_size()
	_build_ui()
	_build_choice_overlay()
	_setup_menu = MatchSetupMenu.new()
	_setup_menu.start_requested.connect(_new_table)
	_setup_menu.cancel_requested.connect(_cancel_setup)
	add_child(_setup_menu)
	_show_setup()


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
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box


func _label(parent: Node, caption: String, font_size: int = 16) -> Label:
	var label: Label = Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", maxi(12, roundi(float(font_size) * FONT_SCALE)))
	parent.add_child(label)
	return label


func _button(parent: Node, caption: String, handler: Callable) -> Button:
	var button: Button = Button.new()
	button.text = caption
	button.custom_minimum_size.y = 38.0
	button.pressed.connect(handler)
	parent.add_child(button)
	return button


func _build_ui() -> void:
	theme = Theme.new()
	theme.default_font_size = 15
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", Color("171b17"))
	theme.set_stylebox("normal", "Button", _style(Color("302c26"), Color("62503c")))
	theme.set_stylebox("hover", "Button", _style(Color("514332"), GOLD))
	theme.set_stylebox("pressed", "Button", _style(GOLD, GOLD))
	theme.set_stylebox("panel", "PanelContainer", _style(Color("25251f"), Color("554a38")))
	var background: ColorRect = ColorRect.new()
	background.color = Color("151916")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	_game_page = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	margin.add_child(columns)
	var page: VBoxContainer = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 8)
	columns.add_child(page)
	var sidebar: VBoxContainer = VBoxContainer.new()
	sidebar.name = "MatchSidebar"
	sidebar.custom_minimum_size.x = 240.0
	sidebar.add_theme_constant_override("separation", 8)
	columns.add_child(sidebar)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	page.add_child(header)
	var identity: VBoxContainer = VBoxContainer.new()
	identity.custom_minimum_size.x = 410.0
	header.add_child(identity)
	_label(identity, "TACTICS  /  SALOON", 22).add_theme_color_override("font_color", GOLD)
	_phase = _label(identity, "", 14)
	_phase.name = "PhaseLabel"
	_phase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var new_table: Button = _button(sidebar, "Bàn mới", _show_setup)
	new_table.name = "NewTable"
	new_table.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var table: PanelContainer = PanelContainer.new()
	table.name = "BotTable"
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table.add_theme_stylebox_override("panel", _style(Color("20372e"), Color("8b7049")))
	page.add_child(table)
	var layout: Control = Control.new()
	_bot_layout = layout
	layout.resized.connect(_layout_player_frames)
	layout.custom_minimum_size.y = 320.0
	table.add_child(layout)
	var center: VBoxContainer = VBoxContainer.new()
	center.name = "PlayedCardArea"
	center.anchor_left = 0.5
	center.anchor_right = 0.5
	center.anchor_top = 0.72
	center.anchor_bottom = 0.72
	center.offset_left = -100.0
	center.offset_right = 100.0
	center.offset_top = -64.0
	center.offset_bottom = 84.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(center)
	_played_card_slot = CenterContainer.new()
	_played_card_slot.custom_minimum_size = Vector2(88.0, 120.0)
	_played_card_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_played_card_slot)
	_played_by = _label(center, "Chưa có bài được đánh", 13)
	_played_by.name = "PlayedCardCaption"
	_played_by.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt = _label(page, "", 14)
	_prompt.name = "TablePrompt"
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback = _label(page, "", 14)
	_feedback.name = "TableNotice"
	_feedback.custom_minimum_size.y = 19.0
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.add_theme_color_override("font_color", GOLD)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var human_panel: PanelContainer = PanelContainer.new()
	human_panel.name = "HumanInfoPanel"
	var human_info: VBoxContainer = VBoxContainer.new()
	_human_info = human_info
	human_panel.add_child(human_info)
	_label(human_info, "NGƯỜI CHƠI CỦA BẠN", 13).add_theme_color_override("font_color", GOLD)
	var hand_column: VBoxContainer = VBoxContainer.new()
	_hand_column = hand_column
	hand_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(hand_column)
	_selection = _label(hand_column, "Chọn bài trên tay, rồi chọn mục tiêu.", 14)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.name = "HandActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_column.add_child(actions)
	_button(actions, "Đồng ý", _confirm_hand_action).name = "ActionConfirm"
	_button(actions, "Huỷ bỏ", _cancel_hand_action).name = "ActionCancel"
	_button(actions, "Kết thúc lượt", _end_current_turn).name = "EndTurn"
	var hand_scroll: ScrollContainer = ScrollContainer.new()
	hand_scroll.name = "HandScroll"
	hand_scroll.custom_minimum_size.y = 136.0
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_column.add_child(hand_scroll)
	_hand = HBoxContainer.new()
	_hand.add_theme_constant_override("separation", 10)
	hand_scroll.add_child(_hand)
	_inline_choice_host = VBoxContainer.new()
	_inline_choice_host.name = "InlineCardChoice"
	page.add_child(_inline_choice_host)
	_inline_choice_host.hide()
	var deck_info: PanelContainer = PanelContainer.new()
	deck_info.name = "DeckInfoPanel"
	sidebar.add_child(deck_info)
	_piles = _label(deck_info, "", 14)
	_piles.name = "DeckInfoLabel"
	_build_event_log(sidebar)
	sidebar.add_child(human_panel)


func _create_seat(parent: Node, player_id: int) -> void:
	var seat: PlayerFrame = PlayerFrame.new()
	parent.add_child(seat)
	seat.pressed.connect(_select_target.bind(player_id))
	seat.name = "Seat%d" % player_id
	seat.add_theme_font_size_override("font_size", 13)
	seat.toggle_mode = true
	if player_id == HUMAN_ID:
		seat.custom_minimum_size = Vector2(176.0, 224.0)
		seat.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_seats[player_id - 1] = seat
		return
	var position: Vector2 = Vector2(0.5, 0.0)
	if _player_count >= 5:
		var positions: Array[Vector2] = [Vector2(1, 1), Vector2(1, 0)]
		if _player_count == 6:
			positions.append(Vector2(0.5, 0))
		positions.append_array([Vector2(0, 0), Vector2(0, 1)])
		position = positions[player_id - 2]
	elif _player_count >= 3 and player_id == 2:
		position = Vector2(1.0, 0.5)
	elif player_id == _player_count and _player_count >= 3:
		position = Vector2(0.0, 0.5)
	seat.anchor_left = position.x
	seat.anchor_right = position.x
	seat.anchor_top = position.y
	seat.anchor_bottom = position.y
	seat.set_meta("seat_position", position)
	_seats[player_id - 1] = seat
	_layout_player_frames()


func _layout_player_frames() -> void:
	if not is_instance_valid(_bot_layout):
		return
	var board_height: float = maxf(320.0, _bot_layout.size.y)
	var frame_height: float = minf(224.0, board_height * 0.72 - 76.0)
	if _player_count >= 5:
		frame_height = minf(frame_height, (board_height - 12.0) / 2.0)
	var frame_width: float = clampf(frame_height * 0.82, 176.0, 196.0)
	for seat: Button in _seats:
		if not is_instance_valid(seat) or not seat.has_meta("seat_position"):
			continue
		var position: Vector2 = seat.get_meta("seat_position")
		seat.offset_left = -frame_width * position.x
		seat.offset_right = frame_width * (1.0 - position.x)
		seat.offset_top = -frame_height * position.y
		seat.offset_bottom = frame_height * (1.0 - position.y)


func _build_event_log(parent: Node) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "EventLogPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 180.0
	parent.add_child(panel)
	var row: VBoxContainer = VBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	_label(row, "NHẬT KÝ VÁN ĐẤU", 14).add_theme_color_override("font_color", GOLD)
	_event_log = RichTextLabel.new()
	_event_log.name = "EventLog"
	_event_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_event_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_event_log.scroll_following = true
	_event_log.selection_enabled = true
	_event_log.add_theme_font_size_override("normal_font_size", 13)
	row.add_child(_event_log)

func _show_setup() -> void:
	_setup_menu.open(_player_count, game_state != null)
	_game_page.hide()


func _cancel_setup() -> void:
	if game_state == null:
		return
	_setup_menu.hide()
	_game_page.show()
	_refresh()


func _rebuild_seats(count: int) -> void:
	for seat: Button in _seats:
		seat.get_parent().remove_child(seat)
		seat.queue_free()
	_seats.clear()
	_seats.resize(count)
	_player_count = count
	_create_seat(_human_info, HUMAN_ID)
	for player_id: int in range(2, count + 1):
		_create_seat(_bot_layout, player_id)


func _new_table(player_count: int = 4) -> void:
	if player_count < 2 or player_count > 6:
		_setup_menu.show_error("Số người chơi phải từ 2 đến 6.")
		return
	var database: CardDatabase = CardDatabase.new()
	if not database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH):
		_setup_menu.show_error("Không nạp được bài: " + "; ".join(database.get_errors()))
		return
	var decks: DeckDatabase = DeckDatabase.new(database)
	if not decks.load_from_file("res://data/decks/standard.json"):
		_setup_menu.show_error("Không nạp được bộ bài: " + "; ".join(decks.get_errors()))
		return
	var rules: RuleEngine = RuleEngine.new()
	if not rules.load_base_rules("res://data/rules/base_rules.json"):
		_setup_menu.show_error("Không nạp được luật. Bàn chơi chưa sẵn sàng.")
		return
	if decks.get_card_count() < player_count * 4:
		_setup_menu.show_error("Bộ bài không đủ để chia 4 lá cho mỗi người.")
		return
	var players: Array[Player] = []
	_hide_choice()
	_choice_kind = ""
	var order: Array[int] = []
	for player_id: int in range(1, player_count + 1):
		players.append(Player.new(player_id, "P%d" % player_id, 4))
		order.append(player_id)
	game_state = GameState.new(decks.create_instances(), players)
	_connect_game_events()
	combat = CombatController.new(game_state, TurnManager.new(game_state, order), rules)
	combat.executor.damage_pipeline.armor_effects.effect_resolved.connect(_on_armor_effect)
	combat.turn_manager.turn_started.connect(_on_turn_logged)
	_rebuild_seats(player_count)
	_clear_played_card()
	_setup_menu.hide()
	_game_page.show()
	selected_target_id = 0
	selected_human_card_id = 0
	selected_bot_card_id = 0
	displayed_player_id = 0
	selected_hand_card_id = 0
	_events.clear()
	_turn_discard_ids.clear()
	for node: Node in find_children("*", "Button", true, false):
		(node as Button).disabled = false
	var started: ActionResult = combat.start_match(4)
	if not started.valid:
		combat.turn_manager.set_phase_wait(TurnManager.Phase.START, started.reason)
	_record("Bàn mới · %d người" % player_count, started)


func _on_cards_discarded(card_names: PackedStringArray) -> void:
	var groups: Dictionary = game_state.zone_manager.get_last_discard_groups()
	if groups.is_empty():
		_notify("Vào chồng bài bỏ: " + ", ".join(card_names))
	for owner_id: int in groups:
		_notify("%s bỏ: %s" % [_name(owner_id) if owner_id != 0 else "Bộ bài", ", ".join(groups[owner_id])])


func _on_armor_effect(owner_id: int, effect_id: String, details: Dictionary) -> void:
	match effect_id:
		"judgment_dodge":
			var symbol: String = CardInstance.SUIT_SYMBOLS[CardInstance.suit_from_name(str(details["suit"]))]
			_notify("%s phán xét %s %s%s: %s" % [_name(owner_id), details["card_name"], details["rank"], symbol, "Né thành công" if details["success"] else "thất bại"])
		"negate_attack_by_color":
			_notify("%s vô hiệu hóa Tấn công nhờ trang bị phòng ngự" % _name(owner_id))
		"cap_incoming_damage":
			_notify("%s giới hạn sát thương còn %d" % [_name(owner_id), int(details["amount"])])
		"prevent_lethal_damage":
			_notify("%s bỏ trang bị để ngăn sát thương kết liễu" % _name(owner_id))


func _on_turn_logged(player_id: int, _number: int) -> void:
	_notify("Lượt %s" % _name(player_id))


func _connect_game_events() -> void:
	game_state.zone_manager.cards_discarded.connect(_on_cards_discarded)
	game_state.match_finished.connect(_on_match_finished)
	game_state.damage_applied.connect(_on_damage_applied)
	game_state.healing_applied.connect(_on_healing_applied)
	game_state.player_eliminated.connect(_on_player_eliminated)
	game_state.kill_reward_drawn.connect(_on_kill_reward_drawn)


func _on_damage_applied(source_id: int, target_id: int, amount: int) -> void:
	_notify("%s gây %d sát thương cho %s" % [_name(source_id), amount, _name(target_id)] if source_id != 0 else "%s nhận %d sát thương (không rõ nguồn)" % [_name(target_id), amount])


func _on_healing_applied(source_id: int, target_id: int, amount: int) -> void:
	_notify("%s hồi %d HP cho %s" % [_name(source_id), amount, _name(target_id)] if source_id != 0 else "%s hồi %d HP" % [_name(target_id), amount])


func _on_player_eliminated(player_id: int, killer_id: int) -> void:
	_notify("%s bị loại%s" % [_name(player_id), " (bởi %s)" % _name(killer_id) if killer_id != 0 else ""])


func _on_kill_reward_drawn(killer_id: int, victim_id: int, count: int) -> void:
	_notify("%s rút %d lá thưởng hạ %s" % [_name(killer_id), count, _name(victim_id)])


func _on_match_finished(winner_id: int) -> void:
	_notify("Trận đấu kết thúc — %s thắng cuộc!" % _name(winner_id))


func _notify(message: String) -> void:
	_feedback.text = message
	_events.append(message)
	if _events.size() > 100:
		_events.pop_front()
	_event_log.text = "\n".join(_events)


func _record(action: String, result: ActionResult, played_card: CardInstance = null, actor_id: int = 0, target_id: int = 0) -> void:
	if result.valid:
		if not action.is_empty():
			_notify(action)
		if played_card != null:
			_show_played_card(played_card, actor_id, target_id)
	else:
		_feedback.text = result.reason
	if combat.has_pending_dying():
		selected_target_id = combat.executor.dying_manager.dying_player_id
	_refresh()


func _clear_played_card() -> void:
	for child: Node in _played_card_slot.get_children():
		_played_card_slot.remove_child(child)
		child.queue_free()
	_last_played_card_id = 0
	_played_by.text = "Chưa có bài được đánh"


func _show_played_card(card: CardInstance, actor_id: int, target_id: int) -> void:
	_clear_played_card()
	_last_played_card_id = card.instance_id
	var face: Button = _create_card_face(_played_card_slot, card, func() -> void: pass)
	face.custom_minimum_size = Vector2(104.0, 142.0)
	face.name = "CenterPlayedCard"
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.focus_mode = Control.FOCUS_NONE
	_played_by.text = _name(actor_id) + (" → " + _name(target_id) if target_id != 0 else "")


func _refresh() -> void:
	if selected_hand_card_id == 0:
		_attack_targets.clear()
	var selected_player: Player = game_state.get_player(selected_target_id)
	if selected_player != null and selected_player.is_eliminated():
		selected_target_id = 0
	var current: Player = combat.turn_manager.get_current_player()
	_phase.text = "Lượt %d · %s · %s" % [combat.turn_manager.turn_number, "không còn người hợp lệ" if current == null else current.display_name, TurnManager.get_phase_display_name(combat.turn_manager.current_phase)]
	if game_state.match_over:
		_phase.text = "Trận đấu kết thúc · %s thắng cuộc!" % _name(game_state.winner_id)
	_refresh_hand()
	if selected_target_id != 0 and not _is_target_available(selected_target_id):
		selected_target_id = 0
	var targeting_card: CardInstance = _find_card(displayed_player_id, selected_hand_card_id)
	for player: Player in game_state.players:
		var seat: Button = _seats[player.player_id - 1]
		var state_text: String = "Hấp hối" if player.is_dying() else ("Đã loại" if player.is_eliminated() else "Đang chơi")
		var equipment: Dictionary = {}
		for slot: String in CardDefinition.EQUIPMENT_SLOTS:
			var card: CardInstance = combat.executor.equipment_system.get_equipment(player.player_id, slot)
			if card == null:
				continue
			var entry: Dictionary = {"name": card.definition.display_name, "rank_suit": card.get_rank_text() + CardInstance.SUIT_SYMBOLS[card.suit], "red": card.is_red(), "description": card.get_display_name() + "\n" + card.definition.description}
			if slot == "weapon":
				var range_rule: Dictionary = combat.get_attack_range(player.player_id)
				entry["range"] = "?" if range_rule.is_empty() else ("∞" if range_rule["unlimited"] else str(range_rule["value"]))
			equipment[slot] = entry
		var distance: int = -1
		if targeting_card != null and _card_requires_target(targeting_card) and combat.turn_manager.current_phase == TurnManager.Phase.PLAY and player.player_id != displayed_player_id and not player.is_eliminated():
			distance = combat.get_effective_distance(displayed_player_id, player.player_id)
		var frame: PlayerFrame = seat as PlayerFrame
		frame.display({"name": player.display_name, "state": state_text, "hand_count": player.get_hand_count(), "health": _health_text(player), "hp": player.hp, "max_hp": player.max_hp, "active": player == current and not game_state.match_over, "equipment": equipment, "distance": distance})
		seat.tooltip_text = ""
		seat.disabled = not _is_target_available(player.player_id)
		seat.modulate = Color("777777") if seat.disabled else Color.WHITE
		seat.set_pressed_no_signal(player.player_id == selected_target_id or player.player_id in _attack_targets)
		seat.add_theme_stylebox_override("normal", _style(Color("3e4530") if player == current else Color("302c26"), GOLD if player == current else Color("62503c")))
	_piles.text = "Chồng rút: %d · Bỏ: %d\nXào lại: %d lần" % [game_state.deck.get_draw_count(), game_state.deck.get_discard_count(), game_state.deck.reshuffle_count]
	_prompt.text = combat.get_status_message()
	if combat.has_pending_dying():
		_prompt.text = "%s đang hấp hối · ưu tiên xử lý trước mọi hành động." % _name(combat.executor.dying_manager.dying_player_id)
	elif not combat.get_pending_armor().is_empty():
		_prompt.text = "Chờ lựa chọn trang bị phòng ngự."
	elif combat.has_pending_response():
		var pending: Dictionary = combat.executor.pending_attack
		_prompt.text = "%s → %s\nĐang chờ Né / Không Né" % [_name(int(pending["actor_id"])), _name(int(pending["target_id"]))]
	elif combat.has_pending_aoe():
		var aoe: Dictionary = combat.get_pending_aoe()
		_prompt.text = "%s dùng %s → chờ %s phản ứng" % [_name(int(aoe["actor_id"])), aoe["card_name"], _name(int(aoe["target_id"]))]
	elif combat.has_pending_support():
		_prompt.text = "Chọn đủ bài để hoàn tất công cụ hỗ trợ."
	elif not combat.get_pending_weapon().is_empty():
		_prompt.text = "Chờ lựa chọn hiệu ứng vũ khí."
	var unblocked: bool = combat.turn_manager.get_transition_block_reason().is_empty()
	(find_child("EndTurn", true, false) as Button).disabled = not (unblocked and current != null and combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
	var discarding: bool = unblocked and combat.turn_manager.current_phase == TurnManager.Phase.DISCARD and combat.turn_manager.get_required_discards() > 0
	var selected_card: CardInstance = _find_card(displayed_player_id, selected_hand_card_id)
	var needs_target: bool = selected_card != null and _card_requires_target(selected_card) and combat.turn_manager.current_phase == TurnManager.Phase.PLAY
	var target_ready: bool = not needs_target or (selected_target_id != 0 and _is_target_available(selected_target_id))
	(find_child("ActionConfirm", true, false) as Button).disabled = not (unblocked and current != null and selected_hand_card_id != 0 and target_ready and (combat.turn_manager.current_phase == TurnManager.Phase.PLAY or discarding))
	if discarding:
		(find_child("ActionConfirm", true, false) as Button).disabled = _turn_discard_ids.is_empty() or _turn_discard_ids.size() > combat.turn_manager.get_required_discards()
	_selection.text = "Tay %s · %d lá   |   Mục tiêu: %s" % [_name(displayed_player_id), game_state.get_player(displayed_player_id).get_hand_count(), _name(selected_target_id)]
	if discarding:
		_selection.text = "Tay %s · Chọn bài để bỏ: %d/%d lá" % [_name(displayed_player_id), _turn_discard_ids.size(), combat.turn_manager.get_required_discards()]
	if needs_target and selected_card.definition.has_effect("deal_attack") and combat.get_attack_target_limit(displayed_player_id) > 1:
		_selection.text += " · Xác nhận mục tiêu chính trước."
	if game_state.match_over:
		_prompt.text = "%s thắng cuộc!" % _name(game_state.winner_id)
		_choice_kind = ""
		_hide_choice()
		for node: Node in find_children("*", "Button", true, false):
			if node.name not in ["NewTable", "CenterPlayedCard"] and not _setup_menu.is_ancestor_of(node):
				(node as Button).disabled = true
		return
	if combat.has_pending_dying():
		var dying_id: int = combat.executor.dying_manager.dying_player_id
		if _choice_kind != "dying" or _choice_target_id != dying_id:
			_open_dying_choice(dying_id)
	elif not combat.get_pending_armor().is_empty():
		var armor: Dictionary = combat.get_pending_armor()
		if _choice_kind != "armor" or _armor_decision_id != int(armor["decision_id"]):
			_open_armor_choice(armor)
	elif combat.has_pending_response():
		var target_id: int = int(combat.executor.pending_attack["target_id"])
		if _choice_kind != "response" or _choice_target_id != target_id:
			_open_response_choice(target_id)
	elif combat.has_pending_aoe():
		var aoe: Dictionary = combat.get_pending_aoe()
		if _choice_kind != "aoe" or _choice_target_id != int(aoe["target_id"]) or _choice_played_card_id != int(aoe["card_id"]):
			_open_aoe_choice(aoe)
	elif combat.has_pending_support():
		var support: Dictionary = combat.get_pending_support()
		if _choice_kind != "support" or _choice_actor_id != int(support["actor_id"]) or _choice_played_card_id != int(support["card_id"]):
			_open_support_choice(support)
	elif not combat.get_pending_weapon().is_empty():
		var decision: Dictionary = combat.get_pending_weapon()
		if _choice_kind != "weapon" or _weapon_decision_id != int(decision["decision_id"]):
			_open_weapon_choice(decision)
	elif _choice_kind in ["response", "dying", "aoe", "support", "weapon", "armor"] or _inline_choice:
		_choice_kind = ""
		_hide_choice()


func _refresh_hand() -> void:
	for child: Node in _hand.get_children():
		_hand.remove_child(child)
		child.queue_free()
	var current: Player = combat.turn_manager.get_current_player()
	var player_id: int = HUMAN_ID if current == null else current.player_id
	if displayed_player_id != player_id:
		_attack_targets.clear()
		_turn_discard_ids.clear()
		displayed_player_id = player_id
		selected_hand_card_id = 0
		selected_target_id = 0
	if combat.turn_manager.current_phase != TurnManager.Phase.DISCARD:
		_turn_discard_ids.clear()
	for index: int in range(_turn_discard_ids.size() - 1, -1, -1):
		if _find_card(player_id, _turn_discard_ids[index]) == null:
			_turn_discard_ids.remove_at(index)
	if not _turn_discard_ids.is_empty():
		selected_hand_card_id = _turn_discard_ids.back()
	if _find_card(player_id, selected_hand_card_id) == null:
		selected_hand_card_id = 0
		_attack_targets.clear()
	var selected_card: CardInstance = _find_card(player_id, selected_hand_card_id)
	if selected_card != null and not _can_select_card(player_id, selected_card):
		selected_hand_card_id = 0
	if selected_hand_card_id == 0:
		_double_selected_hand_id = 0
	var player: Player = game_state.get_player(player_id)
	if player.hand.is_empty():
		_label(_hand, "Tay trống. Đợi giai đoạn rút bài.")
	for card: CardInstance in player.hand:
		var slot: Control = _create_card_slot(_hand)
		var card_button: Button = _create_card_face(slot, card, _select_hand_card.bind(card.instance_id))
		card_button.gui_input.connect(_on_card_double_click.bind(card_button, card.instance_id, false))
		card_button.name = "Card%d" % card.instance_id
		card_button.disabled = not _can_select_card(player_id, card)
		var turn_discard: bool = combat.turn_manager.current_phase == TurnManager.Phase.DISCARD
		_set_card_selection(card_button, card.instance_id in _turn_discard_ids if turn_discard else card.instance_id == selected_hand_card_id, not _turn_discard_ids.is_empty() if turn_discard else selected_hand_card_id != 0)


func _health_text(player: Player) -> String:
	var filled: int = clampi(player.hp, 0, player.max_hp)
	return "♥".repeat(filled) + "♡".repeat(player.max_hp - filled) + (" · %d" % player.hp if player.hp < 0 else "")


func _can_select_card(player_id: int, card: CardInstance) -> bool:
	if game_state.match_over or not combat.turn_manager.get_transition_block_reason().is_empty():
		return false
	var validator: ActionValidator = combat.executor.validator
	if combat.turn_manager.current_phase == TurnManager.Phase.DISCARD:
		return validator.validate_turn_discard(player_id, card.instance_id).valid and (card.instance_id in _turn_discard_ids or _turn_discard_ids.size() < combat.turn_manager.get_required_discards())
	if not SupportToolResolution.get_effect(card.definition).is_empty():
		return validator.validate_support_tool(player_id, card.instance_id).valid
	if card.definition.has_effect("aoe_response_damage"):
		return validator.validate_aoe_use(player_id, card.instance_id).valid
	if card.definition.has_effect("restore_hp"):
		return validator.validate_heal(player_id, card.instance_id).valid
	if card.definition.is_equipment():
		if card.definition.equipment_slot in AccessoryEffects.SLOTS:
			return validator.validate_equip_accessory(player_id, card.instance_id).valid
		if card.definition.equipment_slot == "armor":
			return validator.validate_equip_armor(player_id, card.instance_id).valid
		return validator.validate_equip_weapon(player_id, card.instance_id).valid
	for target: Player in game_state.players:
		if card.definition.has_effect("deal_attack"):
			if validator.validate_attack(player_id, target.player_id, card.instance_id, combat.executor.attacks_used).valid:
				return true
		elif card.definition.has_effect("discard") or card.definition.has_effect("steal_card"):
			if validator.validate_tool_use(player_id, target.player_id, card.instance_id).valid:
				return true
	return false


func _card_requires_target(card: CardInstance) -> bool:
	return card.definition.has_effect("deal_attack") or card.definition.has_effect("discard") or card.definition.has_effect("steal_card")


func _is_target_available(player_id: int) -> bool:
	var target: Player = game_state.get_player(player_id)
	if target == null or target.is_eliminated() or game_state.match_over:
		return false
	var card: CardInstance = _find_card(displayed_player_id, selected_hand_card_id)
	if card == null or combat.turn_manager.current_phase != TurnManager.Phase.PLAY:
		return true
	var validator: ActionValidator = combat.executor.validator
	if card.definition.has_effect("deal_attack"):
		if _attack_targets.size() >= combat.get_attack_target_limit(displayed_player_id) and player_id not in _attack_targets:
			return false
		return validator.validate_attack(displayed_player_id, player_id, card.instance_id, combat.executor.attacks_used).valid
	if card.definition.has_effect("discard") or card.definition.has_effect("steal_card"):
		return validator.validate_tool_use(displayed_player_id, player_id, card.instance_id).valid
	return true


func _create_card_slot(parent: Node) -> Control:
	var slot: Control = Control.new()
	slot.custom_minimum_size = Vector2(88.0, 132.0)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(slot)
	return slot


func _on_card_double_click(event: InputEvent, button: Button, card_id: int, modal: bool) -> void:
	if not event is InputEventMouseButton or button.disabled or _setup_menu.visible:
		return
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.pressed or not mouse.double_click:
		return
	button.accept_event()
	# Suppress the old button's release; confirmation can replace the whole view.
	button.disabled = true
	if not modal and combat.turn_manager.current_phase == TurnManager.Phase.DISCARD:
		# First click toggles the draft; suppress the second release, without payment.
		_refresh.call_deferred()
		return
	if modal:
		var selected_ids: Array[int] = _weapon_cards if _choice_kind == "weapon" else _support_selected_ids
		if _choice_kind in ["support", "weapon"] and card_id in _double_selected_choices:
			_double_selected_choices.erase(card_id)
			if card_id in selected_ids:
				_select_choice_card(card_id, str(button.get_meta("choice_zone")), 0)
			_restore_support_button.call_deferred(button, card_id)
			return
		if _choice_kind not in ["support", "weapon"] or card_id not in selected_ids:
			_select_choice_card(card_id, str(button.get_meta("choice_zone")), 0)
		_confirm_choice()
		if _choice_kind in ["support", "weapon"]:
			_double_selected_choices.append(card_id)
			_restore_support_button.call_deferred(button, card_id)
	else:
		if _double_selected_hand_id == card_id and selected_hand_card_id == card_id:
			_cancel_hand_action()
			return
		_select_hand_card(card_id)
		_confirm_hand_action()
		if selected_hand_card_id == card_id:
			_double_selected_hand_id = card_id


func _restore_support_button(button: Button, card_id: int) -> void:
	if not is_instance_valid(button) or button.is_queued_for_deletion() or _choice_kind not in ["support", "weapon"]:
		return
	button.disabled = false
	var selected_ids: Array[int] = _weapon_cards if _choice_kind == "weapon" else _support_selected_ids
	_set_card_selection(button, card_id in selected_ids, not selected_ids.is_empty())


func _set_card_selection(button: Button, selected: bool, has_selection: bool) -> void:
	button.set_pressed_no_signal(selected)
	button.position.y = 0.0 if selected else 12.0
	button.modulate = Color("999999") if button.disabled else (Color("aaaaaa") if has_selection and not selected else Color.WHITE)


func _create_card_face(parent: Node, card: CardInstance, handler: Callable) -> Button:
	var button: Button = _button(parent, "", handler)
	button.custom_minimum_size = Vector2(88.0, 120.0)
	button.toggle_mode = true
	button.tooltip_text = card.definition.description
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var background: Color = Color("eee3cb")
		var border: Color = Color("9e8052")
		if state == "hover":
			background = Color("fff1cf")
		elif state == "pressed":
			background = Color("e1be75")
			border = Color("ffe5a4")
		elif state == "disabled":
			background = Color("95998e")
			border = Color("61695f")
		var box: StyleBoxFlat = _style(background, border)
		box.set_border_width_all(2)
		button.add_theme_stylebox_override(state, box)
	var ink: Color = Color("a83c37") if card.is_red() else Color("293029")
	var top: Label = _label(button, card.get_rank_text() + CardInstance.SUIT_SYMBOLS[card.suit], 14)
	top.name = "RankTop"
	top.position = Vector2(7.0, 5.0)
	top.add_theme_color_override("font_color", ink)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center: VBoxContainer = VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 6.0
	center.offset_right = -6.0
	center.offset_top = 26.0
	center.offset_bottom = -12.0
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(center)
	var title: Label = _label(center, card.definition.display_name.to_upper(), 13)
	title.name = "CardTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", Color("293029"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return button


func _name(player_id: int) -> String:
	var player: Player = game_state.get_player(player_id)
	return "chưa chọn" if player == null else player.display_name


func _find_card(player_id: int, card_id: int) -> CardInstance:
	for card: CardInstance in game_state.get_player(player_id).hand:
		if card.instance_id == card_id:
			return card
	return null


func _card_usage(card: CardInstance) -> String:
	return card.definition.description


func _select_target(player_id: int) -> void:
	var player: Player = game_state.get_player(player_id)
	if player == null or not _is_target_available(player_id):
		return
	_attack_targets.clear()
	selected_target_id = player_id
	_refresh()


func _select_hand_card(card_id: int) -> void:
	if selected_hand_card_id != card_id:
		_attack_targets.clear()
	if _double_selected_hand_id != card_id:
		_double_selected_hand_id = 0
	var card: CardInstance = _find_card(displayed_player_id, card_id)
	if card == null or not _can_select_card(displayed_player_id, card):
		_feedback.text = "Chưa thể sử dụng lá này ở thời điểm hiện tại."
		return
	if combat.turn_manager.current_phase == TurnManager.Phase.DISCARD:
		if card_id in _turn_discard_ids:
			_turn_discard_ids.erase(card_id)
		else:
			_turn_discard_ids.append(card_id)
		selected_hand_card_id = 0 if _turn_discard_ids.is_empty() else _turn_discard_ids.back()
		_feedback.text = "Đã chọn %d lá để bỏ. Nhấn Đồng ý để xác nhận." % _turn_discard_ids.size()
		_refresh()
		return
	selected_hand_card_id = card_id
	if displayed_player_id == HUMAN_ID:
		selected_human_card_id = card_id
	_feedback.text = "Đã chọn " + card.definition.display_name
	_refresh()


func _select_human_card(card_id: int) -> void:
	selected_human_card_id = card_id
	if displayed_player_id == HUMAN_ID:
		_select_hand_card(card_id)


func _confirm_hand_action() -> void:
	var current: Player = combat.turn_manager.get_current_player()
	if current == null or current.player_id != displayed_player_id or selected_hand_card_id == 0:
		return
	if displayed_player_id == HUMAN_ID:
		selected_human_card_id = selected_hand_card_id
	else:
		selected_bot_id = displayed_player_id
		selected_bot_card_id = selected_hand_card_id
	if combat.turn_manager.current_phase == TurnManager.Phase.DISCARD:
		_discard(displayed_player_id)
	else:
		_attack(displayed_player_id)


func _cancel_hand_action() -> void:
	if _choice_kind == "attack_targets":
		_choice_kind = ""
		_hide_choice()
	_turn_discard_ids.clear()
	_attack_targets.clear()
	_double_selected_hand_id = 0
	selected_hand_card_id = 0
	selected_human_card_id = 0
	selected_bot_card_id = 0
	selected_target_id = 0
	_feedback.text = "Đã huỷ lựa chọn; không tiêu hao bài."
	_refresh()


func _end_current_turn() -> void:
	var current: Player = combat.turn_manager.get_current_player()
	if current != null:
		_end_turn(current.player_id)


func _attack(actor_id: int) -> void:
	if combat == null:
		return
	var card_id: int = selected_human_card_id if actor_id == HUMAN_ID else selected_bot_card_id
	var card: CardInstance = _find_card(actor_id, card_id)
	if card == null:
		_feedback.text = "Chọn một lá bài trước."
		return
	if not SupportToolResolution.get_effect(card.definition).is_empty():
		_record("%s dùng %s" % [_name(actor_id), card.definition.display_name], combat.use_support_tool(actor_id, card_id), card, actor_id)
		return
	if card.definition.has_effect("aoe_response_damage"):
		_record("%s dùng %s" % [_name(actor_id), card.definition.display_name], combat.use_aoe(actor_id, card_id), card, actor_id)
		return
	if card.definition.is_equipment():
		var equipped: ActionResult
		if card.definition.equipment_slot in AccessoryEffects.SLOTS:
			equipped = combat.equip_accessory(actor_id, card_id)
		else:
			equipped = combat.equip_armor(actor_id, card_id) if card.definition.equipment_slot == "armor" else combat.equip_weapon(actor_id, card_id)
		_record("%s trang bị %s" % [_name(actor_id), card.definition.display_name], equipped, card, actor_id)
		return
	if card.definition.has_effect("restore_hp"):
		_record("%s dùng %s" % [_name(actor_id), card.definition.display_name], combat.use_heal(actor_id, card_id), card, actor_id)
		return
	if selected_target_id == 0:
		_feedback.text = "Chọn một lá bài và một mục tiêu trên bàn trước."
		return
	if not card.definition.has_effect("deal_attack"):
		if card.definition.has_effect("discard") or card.definition.has_effect("steal_card"):
			_open_tool_choice(actor_id, selected_target_id, card_id)
			return
		_feedback.text = "Không thể dùng %s bằng thao tác này." % card.definition.display_name
		return
	_attack_targets.assign([selected_target_id])
	_offer_next_attack_target(actor_id, card_id)


func _extra_attack_targets(actor_id: int, card_id: int) -> Array[int]:
	var targets: Array[int] = []
	if _attack_targets.size() >= combat.get_attack_target_limit(actor_id):
		return targets
	for player_id: int in combat.turn_manager.seat_order:
		if player_id not in _attack_targets and combat.executor.validator.validate_attack(actor_id, player_id, card_id, combat.executor.attacks_used).valid:
			targets.append(player_id)
	return targets


func _offer_next_attack_target(actor_id: int, card_id: int) -> void:
	if _extra_attack_targets(actor_id, card_id).is_empty():
		_commit_attack_targets(actor_id, card_id)
		return
	_prepare_choice("attack_targets", actor_id, _attack_targets[0], card_id)
	_picking_extra_target = false
	_extra_target_id = 0
	_choice_title.text = "Đã xác nhận %s. Bạn có muốn chọn thêm mục tiêu?" % _name(_attack_targets.back())
	_choice_confirm.text = "Thêm mục tiêu"
	_choice_confirm.disabled = false
	_choice_cancel.text = "Không thêm"
	_button(_choice_cards, "Huỷ dùng bài", _cancel_hand_action).name = "CancelTargetDraft"


func _pick_extra_attack_target() -> void:
	var actor_id: int = _choice_actor_id
	var card_id: int = _choice_played_card_id
	_prepare_choice("attack_targets", actor_id, _attack_targets[0], card_id)
	_picking_extra_target = true
	_extra_target_id = 0
	_choice_title.text = "Chọn mục tiêu tiếp theo · Mục tiêu chính: %s" % _name(_attack_targets[0])
	_choice_cancel.text = "Không thêm"
	for player_id: int in _extra_attack_targets(actor_id, card_id):
		var target: Button = _button(_choice_cards, "%s · Cách %d" % [_name(player_id), combat.get_effective_distance(actor_id, player_id)], _select_extra_attack_target.bind(player_id))
		target.name = "ExtraTarget%d" % player_id
		target.toggle_mode = true
	_button(_choice_cards, "Huỷ dùng bài", _cancel_hand_action).name = "CancelTargetDraft"


func _select_extra_attack_target(player_id: int) -> void:
	if player_id not in _extra_attack_targets(_choice_actor_id, _choice_played_card_id):
		return
	_extra_target_id = player_id
	_choice_confirm.disabled = false
	for node: Node in _choice_cards.get_children():
		if node is Button and str(node.name).begins_with("ExtraTarget"):
			(node as Button).set_pressed_no_signal(str(node.name) == "ExtraTarget%d" % player_id)


func _commit_attack_targets(actor_id: int, card_id: int) -> void:
	var targets: Array[int] = _attack_targets.duplicate()
	var card: CardInstance = _find_card(actor_id, card_id)
	_choice_kind = ""
	_hide_choice()
	_attack_targets.clear()
	if card == null or targets.is_empty():
		_feedback.text = "Lựa chọn không còn hợp lệ; chưa sử dụng bài."
		_refresh()
		return
	var names: Array[String] = []
	var start_seat: int = combat.turn_manager.seat_order.find(actor_id)
	for offset: int in range(1, combat.turn_manager.seat_order.size()):
		var player_id: int = combat.turn_manager.seat_order[(start_seat + offset) % combat.turn_manager.seat_order.size()]
		if player_id in targets:
			names.append(_name(player_id))
	_record("%s dùng %s lên %s" % [_name(actor_id), card.definition.display_name, ", ".join(names)], combat.use_attack_targets(actor_id, targets, card_id), card, actor_id, targets[0])


func _respond(player_id: int, use_dodge: bool) -> void:
	if combat == null:
		return
	var card_id: int = 0
	if use_dodge:
		card_id = selected_human_card_id if player_id == HUMAN_ID else selected_bot_card_id
		if card_id == 0:
			_notify("Chọn lá Né của người đang phản ứng trước.")
			return
	_record("%s %s" % [_name(player_id), "dùng Né" if use_dodge else "không Né"], combat.respond_to_attack(player_id, card_id))
	var player: Player = game_state.get_player(player_id)
	_notify("%s: HP %d/%d · %s" % [player.display_name, player.hp, player.max_hp, Player.LifeState.keys()[player.life_state]])


func _end_turn(player_id: int) -> void:
	if combat != null:
		_record(_name(player_id) + " kết thúc lượt", combat.end_turn(player_id))


func _discard(player_id: int) -> void:
	if combat != null:
		var selected: Array[int] = _turn_discard_ids.duplicate()
		if selected.is_empty():
			selected.append(selected_human_card_id if player_id == HUMAN_ID else selected_bot_card_id)
		var names: Array[String] = []
		for card_id: int in selected:
			var card: CardInstance = _find_card(player_id, card_id)
			if card != null:
				names.append(card.definition.display_name)
		var result: ActionResult = combat.discard_cards_for_turn(player_id, selected)
		if result.valid:
			_turn_discard_ids.clear()
			selected_hand_card_id = 0
		_record("%s chọn bỏ %s" % [_name(player_id), ", ".join(names)], result)


func _rescue(rescuer_id: int) -> void:
	if combat != null and combat.has_pending_dying():
		_open_dying_choice(combat.executor.dying_manager.dying_player_id, rescuer_id)


func _finalize_dying() -> void:
	if combat != null:
		_record("Finalize Dying: " + _name(combat.executor.dying_manager.dying_player_id), combat.finalize_dying())


func _build_choice_overlay() -> void:
	_choice_overlay = Control.new()
	_choice_overlay.name = "CardChoiceOverlay"
	_choice_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_choice_overlay)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_choice_overlay.add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_choice_overlay.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	_choice_panel = panel
	panel.custom_minimum_size = Vector2(600.0, 270.0)
	center.add_child(panel)
	var content: VBoxContainer = VBoxContainer.new()
	_choice_content = content
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	_choice_title = _label(content, "", 20)
	_choice_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll: ScrollContainer = ScrollContainer.new()
	_choice_scroll = scroll
	scroll.name = "ChoiceHandScroll"
	scroll.custom_minimum_size = Vector2(570.0, 135.0)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_choice_cards = HBoxContainer.new()
	_choice_cards.add_theme_constant_override("separation", 10)
	scroll.add_child(_choice_cards)
	var actions: HBoxContainer = HBoxContainer.new()
	_choice_actions = actions
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(actions)
	_choice_confirm = _button(actions, "Đồng ý", _confirm_choice)
	_choice_confirm.name = "ChoiceConfirm"
	_choice_cancel = _button(actions, "Huỷ bỏ", _cancel_choice)
	_choice_cancel.name = "ChoiceCancel"
	_hide_choice()


func _prepare_choice(kind: String, actor_id: int, target_id: int, card_id: int) -> void:
	_weapon_cards.clear()
	_weapon_target_id = 0
	_support_selected_ids.clear()
	_double_selected_choices.clear()
	_choice_kind = kind
	_choice_actor_id = actor_id
	_choice_target_id = target_id
	_choice_played_card_id = card_id
	_choice_selected_card_id = 0
	_choice_zone = ""
	_choice_card_count = 0
	_choice_confirm.text = "Đồng ý"
	_choice_confirm.disabled = true
	_choice_cancel.disabled = false
	for child: Node in _choice_cards.get_children():
		_choice_cards.remove_child(child)
		child.queue_free()
	_present_choice(kind in ["support", "response", "aoe", "dying", "armor"])


func is_choice_visible() -> bool:
	return _choice_overlay.is_visible_in_tree() or _inline_choice_host.is_visible_in_tree()


func _present_choice(inline: bool) -> void:
	_inline_choice = inline
	var inline_width: float = _hand_column.get_parent_control().size.x
	if inline:
		_inline_choice_host.size.x = inline_width
	var parent: Node = _inline_choice_host if inline else _choice_panel
	if _choice_content.get_parent() != parent:
		_choice_content.reparent(parent)
	if inline:
		# Avoid a one-pixel wrap before the hidden host's first container layout.
		_choice_content.size.x = inline_width
		_choice_title.size.x = inline_width
	_choice_title.add_theme_font_size_override("font_size", 13 if inline else 19)
	_choice_content.add_theme_constant_override("separation", 4 if inline else 14)
	_choice_content.move_child(_choice_actions, 1 if inline else 2)
	_choice_scroll.custom_minimum_size = Vector2(0.0 if inline else 570.0, 136.0)
	_choice_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_inline_choice_host.visible = inline
	_hand_column.visible = not inline
	_choice_overlay.visible = not inline
	_prompt.visible = not inline


func _hide_choice() -> void:
	_inline_choice = false
	_choice_overlay.hide()
	_inline_choice_host.hide()
	_hand_column.show()
	_prompt.show()


func _add_choice_card(card_id: int, zone: String, caption: String, hidden: bool, row: HBoxContainer = null) -> void:
	var index: int = _choice_card_count
	_choice_card_count += 1
	var parent: HBoxContainer = _choice_cards if row == null else row
	var slot: Control = _create_card_slot(parent)
	var handler: Callable = _select_choice_card.bind(card_id, zone, index)
	var button: Button
	if hidden:
		button = _button(slot, caption, handler)
		button.custom_minimum_size = Vector2(88.0, 120.0)
		button.add_theme_font_size_override("font_size", 12)
	else:
		var owner_id: int = _dying_rescuer_id if _choice_kind == "dying" else _choice_target_id
		if _choice_kind == "weapon" and combat.get_pending_weapon().get("effect_id") == "secondary_damage_on_hit":
			owner_id = _choice_actor_id
		var card: CardInstance = null
		for candidate: CardInstance in game_state.get_player(owner_id).get_zone(zone):
			if candidate.instance_id == card_id:
				card = candidate
				break
		if card == null:
			return
		button = _create_card_face(slot, card, handler)
	button.name = "HiddenCard%d" % index if hidden else ("EquipmentCard%d" % card_id if _choice_kind == "tool" else ("RescueCard%d" % card_id if _choice_kind == "dying" else "DodgeCard%d" % card_id))
	if _choice_kind == "aoe":
		button.name = "AoeResponseCard%d" % card_id
	elif _choice_kind == "support":
		button.name = "SupportDiscardCard%d" % card_id
	elif _choice_kind == "weapon":
		button.name = "WeaponCard%d" % card_id
	elif _choice_kind == "armor":
		button.name = "ArmorCard%d" % card_id
	button.toggle_mode = true
	button.set_meta("choice_card_id", card_id)
	button.set_meta("choice_zone", zone)
	button.gui_input.connect(_on_card_double_click.bind(button, card_id, true))
	_set_card_selection(button, false, false)


func _select_choice_card(card_id: int, zone: String, _index: int) -> void:
	if _choice_kind == "weapon":
		if card_id in _weapon_cards:
			_weapon_cards.erase(card_id)
		else:
			_weapon_cards.append(card_id)
		_update_weapon_choice()
		return
	if _choice_kind == "support":
		if card_id in _support_selected_ids:
			_support_selected_ids.erase(card_id)
		else:
			_support_selected_ids.append(card_id)
		var pending: Dictionary = combat.get_pending_support()
		_choice_confirm.disabled = pending.is_empty() or _support_selected_ids.size() != int(pending["discard_count"])
		for node: Node in _choice_cards.find_children("*", "Button", true, false):
			if node.has_meta("choice_card_id"):
				_set_card_selection(node as Button, int(node.get_meta("choice_card_id")) in _support_selected_ids, not _support_selected_ids.is_empty())
		return
	_choice_selected_card_id = card_id
	_choice_zone = zone
	_choice_confirm.disabled = false
	for child: Node in _choice_cards.find_children("*", "Button", true, false):
		if child.has_meta("choice_card_id"):
			_set_card_selection(child as Button, child.get_meta("choice_card_id") == card_id and child.get_meta("choice_zone") == zone, true)


func _open_dying_choice(target_id: int, preferred_rescuer: int = 0) -> void:
	_prepare_choice("dying", 0, target_id, 0)
	var player: Player = game_state.get_player(target_id)
	_choice_title.text = "%s hấp hối · %s · Cần hồi %d HP: chọn người cứu và lá Hồi máu." % [player.display_name, _health_text(player), 1 - player.hp]
	_choice_cancel.text = "Không cứu · loại người chơi"
	if preferred_rescuer == 0:
		preferred_rescuer = _dying_rescuer_id
	_dying_rescuer_id = 0
	var rescuers: OptionButton = OptionButton.new()
	rescuers.name = "DyingRescuer"
	rescuers.custom_minimum_size = Vector2(180.0, 45.0)
	rescuers.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_choice_cards.add_child(rescuers)
	for candidate: Player in game_state.players:
		if candidate.is_alive() or candidate.player_id == target_id:
			rescuers.add_item(candidate.display_name, candidate.player_id)
			if _dying_rescuer_id == 0:
				_dying_rescuer_id = candidate.player_id
			if candidate.player_id == preferred_rescuer:
				rescuers.select(rescuers.item_count - 1)
				_dying_rescuer_id = candidate.player_id
	rescuers.item_selected.connect(_select_dying_rescuer)
	for card: CardInstance in game_state.get_player(_dying_rescuer_id).hand:
		if card.definition.has_effect("restore_hp"):
			_add_choice_card(card.instance_id, "hand", card.get_display_name(), false)
	if _choice_cards.get_child_count() == 1:
		_label(_choice_cards, "Không có lá Hồi máu.\nCó thể chọn người cứu khác.")
	_show_unavailable_hand_cards(_dying_rescuer_id)


func _select_dying_rescuer(index: int) -> void:
	var rescuers: OptionButton = _choice_cards.get_node("DyingRescuer") as OptionButton
	_open_dying_choice(_choice_target_id, rescuers.get_item_id(index))


func _show_unavailable_hand_cards(player_id: int) -> void:
	var selectable: Dictionary = {}
	for node: Node in _choice_cards.find_children("*", "Button", true, false):
		if node.has_meta("choice_card_id"):
			selectable[int(node.get_meta("choice_card_id"))] = true
	for card: CardInstance in game_state.get_player(player_id).hand:
		if selectable.has(card.instance_id):
			continue
		var slot: Control = _create_card_slot(_choice_cards)
		var button: Button = _create_card_face(slot, card, func() -> void: pass)
		button.name = "UnavailableCard%d" % card.instance_id
		button.disabled = true
		_set_card_selection(button, false, false)


func _open_armor_choice(decision: Dictionary) -> void:
	var owner_id: int = int(decision["actor_id"])
	_prepare_choice("armor", owner_id, owner_id, int(decision["armor_id"]))
	_armor_decision_id = int(decision["decision_id"])
	_choice_title.text = "%s · %s: %s" % [_name(owner_id), decision["armor_name"], "Phán xét 1 lá; Cơ thì Né thành công?" if decision["effect_id"] == "judgment_dodge" else "Bỏ trang bị này để ngăn %d sát thương?" % int(decision.get("damage", 0))]
	_choice_cancel.text = "Bỏ qua"
	_add_choice_card(int(decision["armor_id"]), "equipment", str(decision["armor_name"]), false)
	_show_unavailable_hand_cards(owner_id)
	_choice_confirm.disabled = false


func _open_weapon_choice(decision: Dictionary, ask_secondary: bool = true) -> void:
	var actor_id: int = int(decision["actor_id"])
	var target_id: int = int(decision["target_id"])
	_prepare_choice("weapon", actor_id, target_id, 0)
	_weapon_decision_id = int(decision["decision_id"])
	var effect_id: String = decision["effect_id"]
	_weapon_target_prompt = effect_id == "secondary_damage_on_hit" and ask_secondary
	_present_choice(effect_id == "secondary_damage_on_hit")
	var weapon: CardInstance = combat.get_weapon(actor_id)
	var weapon_name: String = "Vũ khí" if weapon == null else weapon.definition.display_name
	_choice_title.text = "%s · %s → %s" % [weapon_name, _name(actor_id), _name(target_id)]
	_choice_cancel.text = "Bỏ qua"
	if _weapon_target_prompt:
		_choice_title.text = "%s · Mục tiêu chính: %s. Bạn có muốn chọn mục tiêu phụ?" % [weapon_name, _name(target_id)]
		_choice_confirm.disabled = false
		return
	var zone: String = "equipment" if effect_id == "discard_equipment_on_hit" else "hand"
	var hidden: bool = effect_id == "replace_attack_damage_with_discard"
	match effect_id:
		"replace_attack_damage_with_discard":
			var count: int = mini(int(decision["parameters"].get("discard_count", 2)), decision["card_ids"].size())
			_choice_title.text += "\nChọn %d lá úp để bỏ thay sát thương." % count
			_choice_cancel.text = "Gây sát thương"
		"secondary_damage_on_hit":
			_choice_title.text = "%s · %s: bỏ 1 lá và chọn mục tiêu phụ trong tầm 1 từ %s." % [weapon_name, _name(actor_id), _name(target_id)]
			for player_id: int in decision["target_ids"]:
				var target_button: Button = _button(_choice_cards, _name(player_id), _select_weapon_target.bind(player_id))
				target_button.name = "WeaponTarget%d" % player_id
		"discard_equipment_on_hit":
			_choice_title.text += "\nChọn 1 trang bị của mục tiêu để bỏ."
	for card_id: int in decision["card_ids"]:
		_add_choice_card(card_id, zone, "✦\nBÀI ÚP", hidden)
	_update_weapon_choice()


func _select_weapon_target(player_id: int) -> void:
	_weapon_target_id = player_id
	_update_weapon_choice()


func _update_weapon_choice() -> void:
	var decision: Dictionary = combat.get_pending_weapon()
	if decision.is_empty():
		_refresh()
		return
	var replacement: bool = decision["effect_id"] == "replace_attack_damage_with_discard"
	var required: int = mini(int(decision["parameters"].get("discard_count", 2)), decision["card_ids"].size()) if replacement else 1
	var needs_target: bool = decision["effect_id"] == "secondary_damage_on_hit"
	_choice_confirm.disabled = _weapon_cards.size() != required or (needs_target and _weapon_target_id == 0)
	for node: Node in _choice_cards.find_children("*", "Button", true, false):
		if node.has_meta("choice_card_id"):
			_set_card_selection(node as Button, int(node.get_meta("choice_card_id")) in _weapon_cards, not _weapon_cards.is_empty())
		elif str(node.name).begins_with("WeaponTarget"):
			(node as Button).modulate = Color.WHITE if str(node.name) == "WeaponTarget%d" % _weapon_target_id else Color("aaaaaa")


func _open_support_choice(pending: Dictionary) -> void:
	var actor_id: int = int(pending["actor_id"])
	_prepare_choice("support", actor_id, actor_id, int(pending["card_id"]))
	_choice_title.text = "%s · %s: chọn đúng %d lá trên tay hoặc trang bị để bỏ." % [_name(actor_id), pending["card_name"], int(pending["discard_count"])]
	_choice_cancel.text = "Chọn lại"
	var discard_zones: Array = pending.get("discard_zones", ["hand"])
	for zone: String in discard_zones:
		var cards: Array[CardInstance] = game_state.get_player(actor_id).get_zone(zone)
		if cards.is_empty():
			continue
		var section: PanelContainer = PanelContainer.new()
		section.name = "SupportZone_" + zone
		section.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		_choice_cards.add_child(section)
		var column: VBoxContainer = VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		section.add_child(column)
		_label(column, "TRÊN TAY" if zone == "hand" else "TRANG BỊ", 13).add_theme_color_override("font_color", GOLD)
		var row: HBoxContainer = HBoxContainer.new()
		column.add_child(row)
		for card: CardInstance in cards:
			_add_choice_card(card.instance_id, zone, card.get_display_name(), false, row)


func _open_aoe_choice(pending: Dictionary) -> void:
	var target_id: int = int(pending["target_id"])
	_prepare_choice("aoe", int(pending["actor_id"]), target_id, int(pending["card_id"]))
	var response_name: String = "Né tránh" if pending["response_effect"] == "block_attack" else "Tấn công"
	_choice_title.text = "%s dùng %s → %s: chọn %s hoặc Không phản ứng." % [_name(_choice_actor_id), pending["card_name"], _name(target_id), response_name]
	_choice_cancel.text = "Không phản ứng"
	for card: CardInstance in combat.get_aoe_response_cards(target_id):
		_add_choice_card(card.instance_id, "hand", card.get_display_name(), false)
	if _choice_card_count == 0:
		_label(_choice_cards, "Không có lá phản ứng hợp lệ.\nChọn Không phản ứng để nhận sát thương.")
	_show_unavailable_hand_cards(target_id)


func _open_response_choice(target_id: int) -> void:
	_prepare_choice("response", target_id, target_id, 0)
	_choice_title.text = "%s bị Tấn công: chọn lá Né rồi Đồng ý, hoặc Không Né." % _name(target_id)
	_choice_cancel.text = "Không Né"
	for card: CardInstance in game_state.get_player(target_id).hand:
		if card.definition.has_effect("block_attack"):
			_add_choice_card(card.instance_id, "hand", card.get_display_name(), false)
	if _choice_cards.get_child_count() == 0:
		_label(_choice_cards, "Không có lá Né. Chọn Huỷ bỏ để nhận sát thương.")
	_show_unavailable_hand_cards(target_id)


func _open_tool_choice(actor_id: int, target_id: int, card_id: int) -> void:
	var validation: ActionResult = combat.executor.validator.validate_tool_use(actor_id, target_id, card_id)
	if not validation.valid:
		_feedback.text = validation.reason
		return
	var effect: Dictionary = combat.executor.validator.get_tool_effect(actor_id, card_id)
	var parameters: Dictionary = effect["parameters"]
	_prepare_choice("tool", actor_id, target_id, card_id)
	_choice_title.text = "%s: chọn bài của %s rồi nhấn Đồng ý.\nTrang bị ngửa; bài trên tay úp." % ["Cướp bài" if effect["effect_id"] == "steal_card" else "Hủy bài", _name(target_id)]
	_choice_cancel.text = "Huỷ bỏ"
	var zones: Array = parameters["target_zones"]
	var sections: VBoxContainer = VBoxContainer.new()
	sections.name = "ToolZones"
	sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sections.add_theme_constant_override("separation", 10)
	_choice_cards.add_child(sections)
	var zone_count: int = 0
	for zone: String in ["hand", "equipment", "judgment"]:
		if zone not in zones:
			continue
		var cards: Array[CardInstance] = game_state.get_player(target_id).get_zone(zone)
		if cards.is_empty():
			continue
		zone_count += 1
		var zone_label: String = "TRÊN TAY" if zone == "hand" else ("TRANG BỊ" if zone == "equipment" else "PHÁN XÉT")
		var section: PanelContainer = PanelContainer.new()
		section.name = "ToolZone_" + zone
		sections.add_child(section)
		var column: VBoxContainer = VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		section.add_child(column)
		_label(column, "%s · %d LÁ" % [zone_label, cards.size()], 13).add_theme_color_override("font_color", GOLD)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		column.add_child(row)
		for card: CardInstance in cards:
			var face_up: bool = zone == "equipment"
			_add_choice_card(card.instance_id, zone, card.get_display_name() if face_up else "✦\nBÀI ÚP", not face_up, row)
	_choice_scroll.custom_minimum_size.y = minf(450.0, float(zone_count * 190))
	_choice_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO


func _confirm_choice() -> void:
	if _choice_kind == "attack_targets":
		if not _picking_extra_target:
			_pick_extra_attack_target()
		elif _extra_target_id in _extra_attack_targets(_choice_actor_id, _choice_played_card_id):
			_attack_targets.append(_extra_target_id)
			_offer_next_attack_target(_choice_actor_id, _choice_played_card_id)
		return
	if _choice_kind == "armor":
		var owner_id: int = _choice_actor_id
		var decision_id: int = _armor_decision_id
		_choice_kind = ""
		_hide_choice()
		_record("", combat.resolve_armor(owner_id, decision_id, true))
		return
	if _choice_kind == "weapon":
		if _weapon_target_prompt:
			var pending_weapon: Dictionary = combat.get_pending_weapon()
			if pending_weapon.is_empty() or int(pending_weapon["decision_id"]) != _weapon_decision_id:
				_refresh()
				return
			_open_weapon_choice(pending_weapon, false)
			return
		if _choice_confirm.disabled:
			return
		var actor_id: int = _choice_actor_id
		var weapon_id: int = _weapon_decision_id
		var cards: Array[int] = _weapon_cards.duplicate()
		var target_id: int = _weapon_target_id
		var weapon: CardInstance = combat.get_weapon(actor_id)
		var weapon_name: String = "vũ khí" if weapon == null else weapon.definition.display_name
		var recipient: int = _choice_target_id if target_id == 0 else target_id
		_choice_kind = ""
		_hide_choice()
		_record("%s dùng %s lên %s" % [_name(actor_id), weapon_name, _name(recipient)], combat.resolve_weapon(actor_id, weapon_id, true, cards, target_id))
		return
	if _choice_kind == "support":
		var pending: Dictionary = combat.get_pending_support()
		if pending.is_empty() or _support_selected_ids.size() != int(pending["discard_count"]):
			return
		var actor_id: int = _choice_actor_id
		var selected: Array[int] = _support_selected_ids.duplicate()
		_choice_kind = ""
		_hide_choice()
		var names: Array[String] = []
		for selected_id: int in selected:
			for zone: String in pending.get("discard_zones", ["hand"]):
				for selected_card: CardInstance in game_state.get_player(actor_id).get_zone(zone):
					if selected_card.instance_id == selected_id:
						names.append(selected_card.definition.display_name)
		_record("%s bỏ %s để hoàn tất %s" % [_name(actor_id), ", ".join(names), pending["card_name"]], combat.discard_for_support(actor_id, selected))
		return
	if _choice_kind == "aoe":
		if _choice_selected_card_id == 0:
			return
		var responder_id: int = _choice_target_id
		var response_id: int = _choice_selected_card_id
		var responding_card: CardInstance = _find_card(responder_id, response_id)
		var aoe: Dictionary = combat.get_pending_aoe()
		_choice_kind = ""
		_hide_choice()
		_record("%s dùng %s đáp %s" % [_name(responder_id), "bài" if responding_card == null else responding_card.definition.display_name, aoe.get("card_name", "AOE")], combat.respond_to_aoe(responder_id, response_id), responding_card, responder_id)
		return
	if _choice_kind == "dying":
		if _choice_selected_card_id == 0:
			return
		var target_id: int = _choice_target_id
		var card_id: int = _choice_selected_card_id
		var card: CardInstance = _find_card(_dying_rescuer_id, card_id)
		_choice_kind = ""
		_hide_choice()
		_record("%s dùng %s cứu %s" % [_name(_dying_rescuer_id), "bài" if card == null else card.definition.display_name, _name(target_id)], combat.rescue_player(_dying_rescuer_id, target_id, card_id), card, _dying_rescuer_id, target_id)
		return
	if _choice_kind not in ["response", "tool"] or _choice_selected_card_id == 0:
		return
	var response: bool = _choice_kind == "response"
	var result: ActionResult
	var action: String
	var chosen_card: CardInstance = null
	for candidate: CardInstance in game_state.get_player(_choice_target_id).get_zone(_choice_zone):
		if candidate.instance_id == _choice_selected_card_id:
			chosen_card = candidate
			break
	var chosen_name: String = "lá đã chọn" if chosen_card == null else chosen_card.definition.display_name
	var played_card: CardInstance = chosen_card if response else null
	if response:
		action = "%s dùng %s né %s" % [_name(_choice_target_id), chosen_name, _name(int(combat.executor.pending_attack.get("actor_id", 0)))]
		result = combat.respond_to_attack(_choice_target_id, _choice_selected_card_id)
	else:
		var played: CardInstance = _find_card(_choice_actor_id, _choice_played_card_id)
		played_card = played
		action = "%s dùng %s lên %s: %s (%s)" % [_name(_choice_actor_id), "công cụ" if played == null else played.definition.display_name, _name(_choice_target_id), chosen_name, {"hand": "trên tay", "equipment": "trang bị", "judgment": "phán xét"}.get(_choice_zone, _choice_zone)]
		result = combat.use_tool(_choice_actor_id, _choice_target_id, _choice_played_card_id, _choice_selected_card_id, _choice_zone)
	_choice_kind = ""
	_hide_choice()
	_record(action, result, played_card, _choice_actor_id, 0 if response else _choice_target_id)


func _cancel_choice() -> void:
	if _choice_kind == "attack_targets":
		_commit_attack_targets(_choice_actor_id, _choice_played_card_id)
		return
	if _choice_kind == "armor":
		var owner_id: int = _choice_actor_id
		var decision_id: int = _armor_decision_id
		_choice_kind = ""
		_hide_choice()
		_record("%s bỏ qua hiệu ứng phòng ngự" % _name(owner_id), combat.resolve_armor(owner_id, decision_id, false))
		return
	if _choice_kind == "weapon":
		var actor_id: int = _choice_actor_id
		var decision_id: int = _weapon_decision_id
		_choice_kind = ""
		_hide_choice()
		_record("%s bỏ qua hiệu ứng vũ khí" % _name(actor_id), combat.resolve_weapon(actor_id, decision_id, false))
		return
	if _choice_kind == "support":
		var pending: Dictionary = combat.get_pending_support()
		if not pending.is_empty():
			_open_support_choice(pending)
		return
	if _choice_kind == "aoe":
		var responder_id: int = _choice_target_id
		var aoe: Dictionary = combat.get_pending_aoe()
		_choice_kind = ""
		_hide_choice()
		_record("%s không phản ứng với %s của %s" % [_name(responder_id), aoe.get("card_name", "AOE"), _name(_choice_actor_id)], combat.respond_to_aoe(responder_id))
		return
	if _choice_kind == "dying":
		_choice_kind = ""
		_hide_choice()
		_record("", combat.finalize_dying())
		return
	var response: bool = _choice_kind == "response"
	_choice_kind = ""
	_hide_choice()
	if response:
		_record(_name(_choice_target_id) + " chọn Không Né", combat.respond_to_attack(_choice_target_id))
	else:
		_feedback.text = "Đã hủy chọn công cụ; không có lá bài nào bị tiêu hao."
