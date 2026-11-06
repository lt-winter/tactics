class_name PlayablePrototype
extends Control

const HUMAN_ID: int = 1
const GOLD: Color = Color("d4ad68")
const INK: Color = Color("eee2ca")

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
var _direction: Label
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


func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	_build_ui()
	_build_choice_overlay()
	_setup_menu = MatchSetupMenu.new()
	_setup_menu.start_requested.connect(_new_table)
	_setup_menu.cancel_requested.connect(_cancel_setup)
	add_child(_setup_menu)
	_show_setup()


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
	label.add_theme_font_size_override("font_size", font_size)
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
	theme.default_font_size = 16
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
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var page: VBoxContainer = VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	margin.add_child(page)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	page.add_child(header)
	var identity: VBoxContainer = VBoxContainer.new()
	identity.custom_minimum_size.x = 410.0
	header.add_child(identity)
	_label(identity, "TACTICS  /  SALOON", 24).add_theme_color_override("font_color", GOLD)
	_phase = _label(identity, "", 16)
	_phase.name = "PhaseLabel"
	_phase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_direction = _label(identity, "", 13)
	_direction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_event_log(header)
	var new_table: Button = _button(header, "Bàn mới", _show_setup)
	new_table.name = "NewTable"
	new_table.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var table: PanelContainer = PanelContainer.new()
	table.name = "BotTable"
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table.add_theme_stylebox_override("panel", _style(Color("20372e"), Color("8b7049")))
	page.add_child(table)
	var layout: Control = Control.new()
	_bot_layout = layout
	layout.custom_minimum_size.y = 250.0
	table.add_child(layout)
	var center: VBoxContainer = VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 240.0
	center.offset_right = -240.0
	center.offset_top = 110.0
	center.offset_bottom = -110.0
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(center)
	_prompt = _label(center, "")
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var personal_row: HBoxContainer = HBoxContainer.new()
	personal_row.add_theme_constant_override("separation", 16)
	page.add_child(personal_row)
	var human_panel: PanelContainer = PanelContainer.new()
	human_panel.name = "HumanInfoPanel"
	personal_row.add_child(human_panel)
	var human_info: VBoxContainer = VBoxContainer.new()
	_human_info = human_info
	human_panel.add_child(human_info)
	_label(human_info, "NGƯỜI CHƠI CỦA BẠN", 13).add_theme_color_override("font_color", GOLD)
	var hand_column: VBoxContainer = VBoxContainer.new()
	hand_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	personal_row.add_child(hand_column)
	_selection = _label(hand_column, "Chọn bài trên tay, rồi chọn mục tiêu.", 14)
	var hand_scroll: ScrollContainer = ScrollContainer.new()
	hand_scroll.name = "HandScroll"
	hand_scroll.custom_minimum_size.y = 148.0
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_column.add_child(hand_scroll)
	_hand = HBoxContainer.new()
	_hand.add_theme_constant_override("separation", 10)
	hand_scroll.add_child(_hand)
	var actions: HBoxContainer = HBoxContainer.new()
	page.add_child(actions)
	_button(actions, "Đồng ý", _confirm_hand_action).name = "ActionConfirm"
	_button(actions, "Huỷ bỏ", _cancel_hand_action).name = "ActionCancel"
	_button(actions, "Kết thúc lượt", _end_current_turn).name = "EndTurn"
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	var deck_info: PanelContainer = PanelContainer.new()
	deck_info.name = "DeckInfoPanel"
	actions.add_child(deck_info)
	_piles = _label(deck_info, "", 14)
	_piles.name = "DeckInfoLabel"
	_feedback = _label(page, "", 14)
	_feedback.custom_minimum_size.y = 34.0
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _create_seat(parent: Node, player_id: int) -> void:
	var seat: Button = _button(parent, "", _select_target.bind(player_id))
	seat.name = "Seat%d" % player_id
	seat.add_theme_font_size_override("font_size", 14)
	seat.toggle_mode = true
	if player_id == HUMAN_ID:
		seat.custom_minimum_size = Vector2(216.0, 112.0)
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
	seat.offset_left = -216.0 * position.x
	seat.offset_right = 216.0 * (1.0 - position.x)
	seat.offset_top = -112.0 * position.y
	seat.offset_bottom = 112.0 * (1.0 - position.y)
	_seats[player_id - 1] = seat


func _build_event_log(parent: Node) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "EventLogPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 82.0
	parent.add_child(panel)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)
	_label(row, "NHẬT KÝ\nVÁN ĐẤU", 14).add_theme_color_override("font_color", GOLD)
	_event_log = RichTextLabel.new()
	_event_log.name = "EventLog"
	_event_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_event_log.scroll_following = true
	_event_log.selection_enabled = true
	_event_log.add_theme_font_size_override("normal_font_size", 14)
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
	if not database.load_from_file("res://data/cards.json"):
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
	_choice_overlay.hide()
	_choice_kind = ""
	var order: Array[int] = []
	for player_id: int in range(1, player_count + 1):
		players.append(Player.new(player_id, "P%d" % player_id, 4))
		order.append(player_id)
	game_state = GameState.new(decks.create_instances(), players)
	game_state.zone_manager.cards_discarded.connect(_on_cards_discarded)
	game_state.match_finished.connect(_on_match_finished)
	combat = CombatController.new(game_state, TurnManager.new(game_state, order), rules)
	_rebuild_seats(player_count)
	_setup_menu.hide()
	_game_page.show()
	selected_target_id = 0
	selected_human_card_id = 0
	selected_bot_card_id = 0
	displayed_player_id = 0
	selected_hand_card_id = 0
	_events.clear()
	for node: Node in find_children("*", "Button", true, false):
		(node as Button).disabled = false
	var started: ActionResult = combat.start_match(4)
	if not started.valid:
		combat.turn_manager.set_phase_wait(TurnManager.Phase.START, started.reason)
	_record("Bàn mới: %d lá; chia 4 lá/người" % decks.get_card_count(), started)
	if started.valid:
		_notify("Đã chia 4 lá/người. P1 rút thêm 2 lá trong giai đoạn rút bài, có 6 lá để sử dụng.")


func _on_cards_discarded(card_names: PackedStringArray) -> void:
	_notify("Vào chồng bài bỏ: " + ", ".join(card_names))


func _on_match_finished(winner_id: int) -> void:
	_notify("Trận đấu kết thúc — %s thắng cuộc!" % _name(winner_id))


func _notify(message: String) -> void:
	_feedback.text = message
	_events.append(message)
	if _events.size() > 100:
		_events.pop_front()
	_event_log.text = "\n".join(_events)


func _record(action: String, result: ActionResult) -> void:
	_notify(action + (" → OK" if result.valid else " → " + result.reason))
	if combat.has_pending_dying():
		selected_target_id = combat.executor.dying_manager.dying_player_id
	_refresh()
	if combat.turn_manager.current_phase != TurnManager.Phase.PLAY:
		_notify(combat.get_status_message())


func _refresh() -> void:
	var selected_player: Player = game_state.get_player(selected_target_id)
	if selected_player != null and selected_player.is_eliminated():
		selected_target_id = 0
	var current: Player = combat.turn_manager.get_current_player()
	var names: Array[String] = []
	for player_id: int in combat.turn_manager.seat_order:
		names.append(_name(player_id))
	if not names.is_empty():
		names.append(names[0])
	_direction.text = "Ngược chiều kim đồng hồ: " + " → ".join(names)
	_phase.text = "Lượt %d · %s · %s" % [combat.turn_manager.turn_number, "không còn người hợp lệ" if current == null else current.display_name, TurnManager.get_phase_display_name(combat.turn_manager.current_phase)]
	if game_state.match_over:
		_phase.text = "Trận đấu kết thúc · %s thắng cuộc!" % _name(game_state.winner_id)
	_refresh_hand()
	if selected_target_id != 0 and not _is_target_available(selected_target_id):
		selected_target_id = 0
	for player: Player in game_state.players:
		var seat: Button = _seats[player.player_id - 1]
		var state_text: String = "Hấp hối" if player.is_dying() else ("Đã loại" if player.is_eliminated() else "Đang chơi")
		seat.text = "%s%s · %s\n%s\n%d lá trên tay" % ["▶ " if player == current and not game_state.match_over else "", player.display_name, state_text, _health_text(player), player.get_hand_count()]
		var weapon: CardInstance = combat.get_weapon(player.player_id)
		var attack_range: Dictionary = combat.get_attack_range(player.player_id)
		var range_text: String = "?" if attack_range.is_empty() else ("∞" if attack_range["unlimited"] else str(attack_range["value"]))
		seat.text += "\n%s · Tầm %s" % ["Vũ khí: —" if weapon == null else weapon.definition.display_name, range_text]
		var defense: CardInstance = combat.get_defense(player.player_id)
		seat.text += "\nPhòng ngự: " + ("—" if defense == null else defense.definition.display_name)
		seat.tooltip_text = "Máu %d/%d" % [player.hp, player.max_hp] + ("" if weapon == null else "\n" + weapon.definition.description)
		seat.disabled = not _is_target_available(player.player_id)
		seat.modulate = Color("777777") if seat.disabled else Color.WHITE
		seat.set_pressed_no_signal(player.player_id == selected_target_id)
		seat.add_theme_stylebox_override("normal", _style(Color("3e4530") if player == current else Color("302c26"), GOLD if player == current else Color("62503c")))
	_piles.text = "Chồng rút: %d · Chồng bỏ: %d · Xào: %d lần" % [game_state.deck.get_draw_count(), game_state.deck.get_discard_count(), game_state.deck.shuffle_count]
	_prompt.text = combat.get_status_message()
	if current != null and current.player_id != HUMAN_ID and combat.turn_manager.current_phase == TurnManager.Phase.PLAY:
		_prompt.text = "Lượt %s · điều khiển thủ công qua tay bài phía dưới." % current.display_name
	if combat.has_pending_dying():
		_prompt.text = "%s đang hấp hối · ưu tiên xử lý trước mọi hành động." % _name(combat.executor.dying_manager.dying_player_id)
	elif combat.has_pending_response():
		var pending: Dictionary = combat.executor.pending_attack
		_prompt.text = "%s → %s\nĐang chờ Né / Không Né" % [_name(int(pending["actor_id"])), _name(int(pending["target_id"]))]
	elif combat.has_pending_aoe():
		var aoe: Dictionary = combat.get_pending_aoe()
		_prompt.text = "%s dùng %s → chờ %s phản ứng" % [_name(int(aoe["actor_id"])), aoe["card_name"], _name(int(aoe["target_id"]))]
	var unblocked: bool = combat.turn_manager.get_transition_block_reason().is_empty()
	(find_child("EndTurn", true, false) as Button).disabled = not (unblocked and current != null and combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
	var discarding: bool = unblocked and combat.turn_manager.current_phase == TurnManager.Phase.DISCARD and combat.turn_manager.get_required_discards() > 0
	var selected_card: CardInstance = _find_card(displayed_player_id, selected_hand_card_id)
	var needs_target: bool = selected_card != null and _card_requires_target(selected_card) and combat.turn_manager.current_phase == TurnManager.Phase.PLAY
	var target_ready: bool = not needs_target or (selected_target_id != 0 and _is_target_available(selected_target_id))
	(find_child("ActionConfirm", true, false) as Button).disabled = not (unblocked and current != null and selected_hand_card_id != 0 and target_ready and (combat.turn_manager.current_phase == TurnManager.Phase.PLAY or discarding))
	_selection.text = "Tay %s%s · %d lá   |   Mục tiêu: %s" % [_name(displayed_player_id), " · thủ công" if displayed_player_id != HUMAN_ID else "", game_state.get_player(displayed_player_id).get_hand_count(), _name(selected_target_id)]
	if game_state.match_over:
		_prompt.text = "%s thắng cuộc!" % _name(game_state.winner_id)
		_choice_kind = ""
		_choice_overlay.hide()
		for node: Node in find_children("*", "Button", true, false):
			if node.name != "NewTable" and not _setup_menu.is_ancestor_of(node):
				(node as Button).disabled = true
		return
	if combat.has_pending_dying():
		var dying_id: int = combat.executor.dying_manager.dying_player_id
		if _choice_kind != "dying" or _choice_target_id != dying_id:
			_open_dying_choice(dying_id)
	elif combat.has_pending_response():
		var target_id: int = int(combat.executor.pending_attack["target_id"])
		if _choice_kind != "response" or _choice_target_id != target_id:
			_open_response_choice(target_id)
	elif combat.has_pending_aoe():
		var aoe: Dictionary = combat.get_pending_aoe()
		if _choice_kind != "aoe" or _choice_target_id != int(aoe["target_id"]) or _choice_played_card_id != int(aoe["card_id"]):
			_open_aoe_choice(aoe)
	elif _choice_kind in ["response", "dying", "aoe"]:
		_choice_kind = ""
		_choice_overlay.hide()


func _refresh_hand() -> void:
	for child: Node in _hand.get_children():
		_hand.remove_child(child)
		child.queue_free()
	var current: Player = combat.turn_manager.get_current_player()
	var player_id: int = HUMAN_ID if current == null else current.player_id
	if displayed_player_id != player_id:
		displayed_player_id = player_id
		selected_hand_card_id = 0
		selected_target_id = 0
	if _find_card(player_id, selected_hand_card_id) == null:
		selected_hand_card_id = 0
	var selected_card: CardInstance = _find_card(player_id, selected_hand_card_id)
	if selected_card != null and not _can_select_card(player_id, selected_card):
		selected_hand_card_id = 0
	var player: Player = game_state.get_player(player_id)
	if player.hand.is_empty():
		_label(_hand, "Tay trống. Đợi giai đoạn rút bài.")
	for card: CardInstance in player.hand:
		var slot: Control = _create_card_slot(_hand)
		var card_button: Button = _create_card_face(slot, card, _select_hand_card.bind(card.instance_id))
		card_button.gui_input.connect(_on_card_double_click.bind(card_button, card.instance_id, false))
		card_button.name = "Card%d" % card.instance_id
		card_button.disabled = not _can_select_card(player_id, card)
		if card.definition.equipment_slot == "armor":
			card_button.tooltip_text += "\nSlot phòng ngự đã sẵn sàng; chưa triển khai sử dụng/hiệu ứng."
		_set_card_selection(card_button, card.instance_id == selected_hand_card_id, selected_hand_card_id != 0)


func _health_text(player: Player) -> String:
	var filled: int = clampi(player.hp, 0, player.max_hp)
	return "♥".repeat(filled) + "♡".repeat(player.max_hp - filled) + (" · %d" % player.hp if player.hp < 0 else "")


func _can_select_card(player_id: int, card: CardInstance) -> bool:
	if game_state.match_over or not combat.turn_manager.get_transition_block_reason().is_empty():
		return false
	var validator: ActionValidator = combat.executor.validator
	if combat.turn_manager.current_phase == TurnManager.Phase.DISCARD:
		return validator.validate_turn_discard(player_id, card.instance_id).valid
	if card.definition.has_effect("aoe_response_damage"):
		return validator.validate_aoe_use(player_id, card.instance_id).valid
	if card.definition.has_effect("restore_hp"):
		return validator.validate_heal(player_id, card.instance_id).valid
	if card.definition.is_equipment():
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
	if modal:
		_select_choice_card(card_id, str(button.get_meta("choice_zone")), 0)
		_confirm_choice()
	else:
		_select_hand_card(card_id)
		_confirm_hand_action()


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
	selected_target_id = player_id
	_refresh()


func _select_hand_card(card_id: int) -> void:
	var card: CardInstance = _find_card(displayed_player_id, card_id)
	if card == null or not _can_select_card(displayed_player_id, card):
		_feedback.text = "Chưa thể sử dụng lá này ở thời điểm hiện tại."
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
	if card.definition.has_effect("aoe_response_damage"):
		_record("%s dùng %s" % [_name(actor_id), card.definition.display_name], combat.use_aoe(actor_id, card_id))
		return
	if card.definition.is_equipment():
		var equipped: ActionResult = combat.equip_weapon(actor_id, card_id)
		_record("%s trang bị %s" % [_name(actor_id), card.definition.display_name], equipped)
		if equipped.valid and not card.definition.has_effect("remove_attack_limit"):
			_notify("Tầm vũ khí đã có hiệu lực. Hiệu ứng riêng của %s chưa được triển khai." % card.definition.display_name)
		return
	if card.definition.has_effect("restore_hp"):
		_record("%s dùng %s để tự hồi máu" % [_name(actor_id), card.definition.display_name], combat.use_heal(actor_id, card_id))
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
	_record("%s Tấn công %s bằng %s" % [_name(actor_id), _name(selected_target_id), card.definition.display_name], combat.use_attack(actor_id, selected_target_id, card_id))


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
		var card_id: int = selected_human_card_id if player_id == HUMAN_ID else selected_bot_card_id
		var card: CardInstance = _find_card(player_id, card_id)
		_record("%s chọn bỏ %s" % [_name(player_id), "bài" if card == null else card.definition.display_name], combat.discard_for_turn(player_id, card_id))


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
	panel.custom_minimum_size = Vector2(600.0, 270.0)
	center.add_child(panel)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	_choice_title = _label(content, "", 20)
	_choice_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(570.0, 135.0)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_choice_cards = HBoxContainer.new()
	_choice_cards.add_theme_constant_override("separation", 10)
	scroll.add_child(_choice_cards)
	var actions: HBoxContainer = HBoxContainer.new()
	content.add_child(actions)
	_choice_confirm = _button(actions, "Đồng ý", _confirm_choice)
	_choice_confirm.name = "ChoiceConfirm"
	_choice_cancel = _button(actions, "Huỷ bỏ", _cancel_choice)
	_choice_cancel.name = "ChoiceCancel"
	_choice_overlay.hide()


func _prepare_choice(kind: String, actor_id: int, target_id: int, card_id: int) -> void:
	_choice_kind = kind
	_choice_actor_id = actor_id
	_choice_target_id = target_id
	_choice_played_card_id = card_id
	_choice_selected_card_id = 0
	_choice_zone = ""
	_choice_card_count = 0
	_choice_confirm.text = "Đồng ý"
	_choice_confirm.disabled = true
	for child: Node in _choice_cards.get_children():
		_choice_cards.remove_child(child)
		child.queue_free()
	_choice_overlay.show()


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
	button.toggle_mode = true
	button.set_meta("choice_card_id", card_id)
	button.set_meta("choice_zone", zone)
	button.gui_input.connect(_on_card_double_click.bind(button, card_id, true))
	_set_card_selection(button, false, false)


func _select_choice_card(card_id: int, zone: String, _index: int) -> void:
	_choice_selected_card_id = card_id
	_choice_zone = zone
	_choice_confirm.disabled = false
	for child: Node in _choice_cards.find_children("*", "Button", true, false):
		if child.has_meta("choice_card_id"):
			_set_card_selection(child as Button, child.get_meta("choice_card_id") == card_id and child.get_meta("choice_zone") == zone, true)


func _open_dying_choice(target_id: int, preferred_rescuer: int = 0) -> void:
	_prepare_choice("dying", 0, target_id, 0)
	var player: Player = game_state.get_player(target_id)
	_choice_title.text = "%s đang hấp hối · %s\nCần hồi ít nhất %d HP. Chọn người cứu và lá Hồi máu." % [player.display_name, _health_text(player), 1 - player.hp]
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


func _select_dying_rescuer(index: int) -> void:
	var rescuers: OptionButton = _choice_cards.get_node("DyingRescuer") as OptionButton
	_open_dying_choice(_choice_target_id, rescuers.get_item_id(index))


func _open_aoe_choice(pending: Dictionary) -> void:
	var target_id: int = int(pending["target_id"])
	_prepare_choice("aoe", int(pending["actor_id"]), target_id, int(pending["card_id"]))
	var response_name: String = "Né tránh" if pending["response_effect"] == "block_attack" else "Tấn công"
	_choice_title.text = "%s dùng %s → %s\nChọn %s rồi nhấn Đồng ý, hoặc Không phản ứng." % [_name(_choice_actor_id), pending["card_name"], _name(target_id), response_name]
	_choice_cancel.text = "Không phản ứng"
	for card: CardInstance in combat.get_aoe_response_cards(target_id):
		_add_choice_card(card.instance_id, "hand", card.get_display_name(), false)
	if _choice_card_count == 0:
		_label(_choice_cards, "Không có lá phản ứng hợp lệ.\nChọn Không phản ứng để nhận sát thương.")


func _open_response_choice(target_id: int) -> void:
	_prepare_choice("response", target_id, target_id, 0)
	_choice_title.text = "%s bị Tấn công: chọn lá Né rồi nhấn Đồng ý.\nBot được điều khiển thủ công." % _name(target_id)
	_choice_cancel.text = "Huỷ bỏ"
	for card: CardInstance in game_state.get_player(target_id).hand:
		if card.definition.has_effect("block_attack"):
			_add_choice_card(card.instance_id, "hand", card.get_display_name(), false)
	if _choice_cards.get_child_count() == 0:
		_label(_choice_cards, "Không có lá Né. Chọn Huỷ bỏ để nhận sát thương.")


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
	for zone: String in zones:
		var cards: Array[CardInstance] = game_state.get_player(target_id).get_zone(zone)
		if cards.is_empty():
			continue
		var zone_label: String = "TRÊN TAY" if zone == "hand" else ("TRANG BỊ" if zone == "equipment" else "PHÁN XÉT")
		var section: PanelContainer = PanelContainer.new()
		section.name = "ToolZone_" + zone
		_choice_cards.add_child(section)
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


func _confirm_choice() -> void:
	if _choice_kind == "aoe":
		if _choice_selected_card_id == 0:
			return
		var responder_id: int = _choice_target_id
		var response_id: int = _choice_selected_card_id
		_choice_kind = ""
		_choice_overlay.hide()
		_record("%s đồng ý phản ứng AOE" % _name(responder_id), combat.respond_to_aoe(responder_id, response_id))
		return
	if _choice_kind == "dying":
		if _choice_selected_card_id == 0:
			return
		var target_id: int = _choice_target_id
		var card_id: int = _choice_selected_card_id
		var card: CardInstance = _find_card(_dying_rescuer_id, card_id)
		_choice_kind = ""
		_choice_overlay.hide()
		_record("%s dùng %s cứu %s" % [_name(_dying_rescuer_id), "bài" if card == null else card.definition.display_name, _name(target_id)], combat.rescue_player(_dying_rescuer_id, target_id, card_id))
		return
	if _choice_kind not in ["response", "tool"] or _choice_selected_card_id == 0:
		return
	var response: bool = _choice_kind == "response"
	var result: ActionResult
	if response:
		result = combat.respond_to_attack(_choice_target_id, _choice_selected_card_id)
	else:
		result = combat.use_tool(_choice_actor_id, _choice_target_id, _choice_played_card_id, _choice_selected_card_id, _choice_zone)
	_choice_kind = ""
	_choice_overlay.hide()
	_record("%s đồng ý %s" % [_name(_choice_actor_id), "Né" if response else "Hủy/Cướp lá đã chọn"], result)


func _cancel_choice() -> void:
	if _choice_kind == "aoe":
		var responder_id: int = _choice_target_id
		_choice_kind = ""
		_choice_overlay.hide()
		_record("%s chọn Không phản ứng" % _name(responder_id), combat.respond_to_aoe(responder_id))
		return
	if _choice_kind == "dying":
		_choice_kind = ""
		_choice_overlay.hide()
		_record("Không cứu: xử lý loại người hấp hối", combat.finalize_dying())
		return
	var response: bool = _choice_kind == "response"
	_choice_kind = ""
	_choice_overlay.hide()
	if response:
		_record(_name(_choice_target_id) + " chọn Không Né", combat.respond_to_attack(_choice_target_id))
	else:
		_feedback.text = "Đã hủy chọn công cụ; không có lá bài nào bị tiêu hao."
