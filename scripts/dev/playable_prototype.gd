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
var _bot_cards: OptionButton
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
var _dying_rescuer_id: int = 0


func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	_build_ui()
	_build_choice_overlay()
	_new_table()


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
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var page: VBoxContainer = VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	margin.add_child(page)
	var header: HBoxContainer = HBoxContainer.new()
	page.add_child(header)
	_label(header, "TACTICS  /  SALOON", 26).add_theme_color_override("font_color", GOLD)
	_phase = _label(header, "", 18)
	_phase.name = "PhaseLabel"
	_phase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button(header, "Bàn mới", _new_table).name = "NewTable"
	_direction = _label(page, "", 14)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	page.add_child(body)
	var play: VBoxContainer = VBoxContainer.new()
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.add_theme_constant_override("separation", 8)
	body.add_child(play)
	var table: PanelContainer = PanelContainer.new()
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table.add_theme_stylebox_override("panel", _style(Color("20372e"), Color("8b7049")))
	play.add_child(table)
	var table_rows: VBoxContainer = VBoxContainer.new()
	table_rows.add_theme_constant_override("separation", 8)
	table.add_child(table_rows)
	_seats.resize(4)
	var top: CenterContainer = CenterContainer.new()
	table_rows.add_child(top)
	_create_seat(top, 3)
	var middle: HBoxContainer = HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_rows.add_child(middle)
	_create_seat(middle, 4)
	var center: VBoxContainer = VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_child(center)
	_piles = _label(center, "", 18)
	_piles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt = _label(center, "")
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_create_seat(middle, 2)
	var bottom: CenterContainer = CenterContainer.new()
	table_rows.add_child(bottom)
	_create_seat(bottom, 1)
	_selection = _label(play, "Chọn bài trên tay, rồi chọn người trên bàn.")
	var hand_scroll: ScrollContainer = ScrollContainer.new()
	hand_scroll.custom_minimum_size.y = 112.0
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	play.add_child(hand_scroll)
	_hand = HBoxContainer.new()
	_hand.add_theme_constant_override("separation", 8)
	hand_scroll.add_child(_hand)
	var actions: HBoxContainer = HBoxContainer.new()
	play.add_child(actions)
	_button(actions, "Đồng ý", _confirm_hand_action).name = "ActionConfirm"
	_button(actions, "Huỷ bỏ", _cancel_hand_action).name = "ActionCancel"
	_button(actions, "Kết thúc lượt", _end_current_turn).name = "EndTurn"
	var rescue_row: HBoxContainer = HBoxContainer.new()
	play.add_child(rescue_row)
	_button(rescue_row, "Chọn lá cứu", _rescue.bind(HUMAN_ID)).name = "HumanRescue"
	_button(rescue_row, "Finalize Dying", _finalize_dying).name = "FinalizeDying"
	_feedback = _label(play, "")
	_feedback.custom_minimum_size.y = 34.0
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_sidebar(body)


func _create_seat(parent: Node, player_id: int) -> void:
	var seat: Button = _button(parent, "", _select_target.bind(player_id))
	seat.name = "Seat%d" % player_id
	seat.custom_minimum_size = Vector2(190.0, 76.0)
	seat.add_theme_font_size_override("font_size", 14)
	seat.toggle_mode = true
	seat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_seats[player_id - 1] = seat


func _build_sidebar(parent: Node) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.x = 330.0
	parent.add_child(panel)
	var sidebar: VBoxContainer = VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 6)
	panel.add_child(sidebar)
	_label(sidebar, "ĐIỀU KHIỂN BOT · DEBUG", 18).add_theme_color_override("font_color", GOLD)
	var bots: OptionButton = OptionButton.new()
	bots.name = "DebugActor"
	for bot_id: int in range(2, 5):
		bots.add_item("Bot %d · điều khiển thủ công" % (bot_id - 1), bot_id)
	bots.item_selected.connect(_select_bot)
	sidebar.add_child(bots)
	_bot_cards = OptionButton.new()
	_bot_cards.name = "DebugCard"
	_bot_cards.clip_text = true
	_bot_cards.item_selected.connect(_select_bot_card)
	sidebar.add_child(_bot_cards)
	var attacks: HBoxContainer = HBoxContainer.new()
	sidebar.add_child(attacks)
	_button(attacks, "Bot: Dùng bài", _bot_attack).name = "BotAttack"
	_button(attacks, "Rút 1", _bot_draw).name = "BotDraw"
	var responses: HBoxContainer = HBoxContainer.new()
	sidebar.add_child(responses)
	_button(responses, "Bot: Né", _bot_dodge).name = "BotDodge"
	_button(responses, "Bot: Không Né", _bot_pass).name = "BotPass"
	var turn_actions: HBoxContainer = HBoxContainer.new()
	sidebar.add_child(turn_actions)
	_button(turn_actions, "Bot: Kết thúc lượt", _bot_end_turn).name = "BotEndTurn"
	_button(turn_actions, "Bỏ lá", _bot_discard).name = "BotDiscard"
	_button(sidebar, "Bot: Chọn lá cứu", _bot_rescue).name = "BotRescue"
	var debug_draws: HBoxContainer = HBoxContainer.new()
	sidebar.add_child(debug_draws)
	_button(debug_draws, "Human: Rút 1", _debug_draw.bind(HUMAN_ID)).name = "HumanDraw"
	_button(debug_draws, "Tiếp tục", _advance_phase).name = "DebugResume"
	var limits: Label = _label(sidebar, "Chia 4 lá; rút 2 lá ở giai đoạn rút bài.\nTay Bot hiện khi đến lượt · DEBUG.\nCứu bằng lá Hồi máu; HP > 0 mới sống.\nPhán xét / kiểm tra thắng chưa có.", 14)
	limits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(sidebar, "NHẬT KÝ BÀN CHƠI", 18).add_theme_color_override("font_color", GOLD)
	_event_log = RichTextLabel.new()
	_event_log.name = "EventLog"
	_event_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_event_log.custom_minimum_size.y = 80.0
	_event_log.scroll_following = true
	_event_log.selection_enabled = true
	_event_log.add_theme_font_size_override("normal_font_size", 14)
	sidebar.add_child(_event_log)


func _new_table() -> void:
	_choice_overlay.hide()
	_choice_kind = ""
	var database: CardDatabase = CardDatabase.new()
	if not database.load_from_file("res://data/cards.json"):
		_notify("Không nạp được bài: " + "; ".join(database.get_errors()))
		return
	var decks: DeckDatabase = DeckDatabase.new(database)
	if not decks.load_from_file("res://data/decks/standard.json"):
		_notify("Không nạp được bộ bài: " + "; ".join(decks.get_errors()))
		return
	var rules: RuleEngine = RuleEngine.new()
	if not rules.load_base_rules("res://data/rules/base_rules.json"):
		_notify("Không nạp được luật. Bàn chơi chưa sẵn sàng.")
		return
	var players: Array[Player] = [
		Player.new(1, "Human", 4), Player.new(2, "Bot 1", 4),
		Player.new(3, "Bot 2", 4), Player.new(4, "Bot 3", 4)
	]
	game_state = GameState.new(decks.create_instances(), players)
	var order: Array[int] = [1, 2, 3, 4]
	combat = CombatController.new(game_state, TurnManager.new(game_state, order), rules)
	selected_target_id = 0
	selected_human_card_id = 0
	selected_bot_card_id = 0
	displayed_player_id = 0
	selected_hand_card_id = 0
	_events.clear()
	var started: ActionResult = combat.start_match(4)
	if not started.valid:
		combat.turn_manager.set_phase_wait(TurnManager.Phase.START, started.reason)
	_record("Bàn mới: %d lá; chia 4 lá/người" % decks.get_card_count(), started)
	if started.valid:
		_notify("Đã chia 4 lá/người. Human rút thêm 2 lá ngay lượt đầu, có 6 lá để sử dụng.")


func _notify(message: String) -> void:
	_feedback.text = message
	_events.append(message)
	if _events.size() > 100:
		_events.pop_front()
	_event_log.text = "\n\n".join(_events)


func _record(action: String, result: ActionResult) -> void:
	_notify(action + (" → OK" if result.valid else " → " + result.reason))
	if combat.has_pending_dying():
		selected_target_id = combat.executor.dying_manager.dying_player_id
	_refresh()
	if combat.turn_manager.current_phase != TurnManager.Phase.PLAY:
		_notify(combat.get_status_message())


func _refresh() -> void:
	var current: Player = combat.turn_manager.get_current_player()
	var names: Array[String] = []
	for player_id: int in combat.turn_manager.seat_order:
		names.append(_name(player_id))
	if not names.is_empty():
		names.append(names[0])
	_direction.text = "Ngược chiều kim đồng hồ: " + " → ".join(names)
	_phase.text = "Lượt %d · %s · %s" % [combat.turn_manager.turn_number, "không còn người hợp lệ" if current == null else current.display_name, TurnManager.get_phase_display_name(combat.turn_manager.current_phase)]
	_refresh_hand()
	for player: Player in game_state.players:
		var seat: Button = _seats[player.player_id - 1]
		seat.text = "%s%s\nHP %d / %d · %s\n%d lá trên tay" % ["▶ " if player == current else "", player.display_name, player.hp, player.max_hp, Player.LifeState.keys()[player.life_state], player.get_hand_count()]
		seat.set_pressed_no_signal(player.player_id == selected_target_id)
		seat.add_theme_stylebox_override("normal", _style(Color("3e4530") if player == current else Color("302c26"), GOLD if player == current else Color("62503c")))
	_piles.text = "CHỒNG RÚT %d   /   CHỒNG BỎ %d" % [game_state.deck.get_draw_count(), game_state.deck.get_discard_count()]
	_prompt.text = combat.get_status_message()
	if current != null and current.player_id != HUMAN_ID and combat.turn_manager.current_phase == TurnManager.Phase.PLAY:
		_prompt.text = "Lượt %s · DEBUG: chọn bài phía dưới và nhấn Đồng ý." % current.display_name
	if combat.has_pending_dying():
		_prompt.text = "%s đang hấp hối · ưu tiên xử lý trước mọi hành động." % _name(combat.executor.dying_manager.dying_player_id)
	elif combat.has_pending_response():
		var pending: Dictionary = combat.executor.pending_attack
		_prompt.text = "%s → %s\nĐang chờ Né / Không Né" % [_name(int(pending["actor_id"])), _name(int(pending["target_id"]))]
	_refresh_bot_cards()
	var unblocked: bool = combat.turn_manager.get_transition_block_reason().is_empty()
	var bot_turn: bool = current != null and current.player_id == selected_bot_id
	(find_child("EndTurn", true, false) as Button).disabled = not (unblocked and current != null and combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
	(find_child("BotEndTurn", true, false) as Button).disabled = not (unblocked and bot_turn and combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
	var discarding: bool = unblocked and combat.turn_manager.current_phase == TurnManager.Phase.DISCARD and combat.turn_manager.get_required_discards() > 0
	(find_child("BotDiscard", true, false) as Button).disabled = not (discarding and bot_turn)
	(find_child("ActionConfirm", true, false) as Button).disabled = not (unblocked and current != null and selected_hand_card_id != 0 and (combat.turn_manager.current_phase == TurnManager.Phase.PLAY or discarding))
	_selection.text = "Tay %s%s · %d lá   |   Mục tiêu: %s" % [_name(displayed_player_id), " · DEBUG" if displayed_player_id != HUMAN_ID else "", game_state.get_player(displayed_player_id).get_hand_count(), _name(selected_target_id)]
	if combat.has_pending_dying():
		var dying_id: int = combat.executor.dying_manager.dying_player_id
		if _choice_kind != "dying" or _choice_target_id != dying_id:
			_open_dying_choice(dying_id)
	elif combat.has_pending_response():
		var target_id: int = int(combat.executor.pending_attack["target_id"])
		if _choice_kind != "response" or _choice_target_id != target_id:
			_open_response_choice(target_id)
	elif _choice_kind in ["response", "dying"]:
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
	var player: Player = game_state.get_player(player_id)
	if player.hand.is_empty():
		_label(_hand, "Tay trống. Đợi giai đoạn rút bài hoặc dùng nút Debug.")
	for card: CardInstance in player.hand:
		var card_button: Button = _button(_hand, "%s\n%s%s" % [card.definition.display_name, card.get_rank_text(), CardInstance.SUIT_SYMBOLS[card.suit]], _select_hand_card.bind(card.instance_id))
		card_button.name = "Card%d" % card.instance_id
		card_button.custom_minimum_size = Vector2(112.0, 76.0)
		card_button.toggle_mode = true
		card_button.set_pressed_no_signal(card.instance_id == selected_hand_card_id)
		card_button.tooltip_text = card.definition.description


func _refresh_bot_cards() -> void:
	_bot_cards.clear()
	var bot: Player = game_state.get_player(selected_bot_id)
	if _find_card(selected_bot_id, selected_bot_card_id) == null:
		selected_bot_card_id = 0
	for card: CardInstance in bot.hand:
		_bot_cards.add_item(card.get_display_name(), card.instance_id)
		if selected_bot_card_id == 0:
			selected_bot_card_id = card.instance_id
		if card.instance_id == selected_bot_card_id:
			_bot_cards.select(_bot_cards.item_count - 1)
	if bot.hand.is_empty():
		_bot_cards.add_item("Bot chưa có bài", 0)


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
	selected_target_id = player_id
	_refresh()


func _select_hand_card(card_id: int) -> void:
	selected_hand_card_id = card_id
	if displayed_player_id == HUMAN_ID:
		selected_human_card_id = card_id
	var card: CardInstance = _find_card(displayed_player_id, card_id)
	if card == null:
		return
	_notify("Đã chọn " + card.get_display_name() + " · " + _card_usage(card))
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
	_notify("Đã huỷ lựa chọn; không tiêu hao bài.")
	_refresh()


func _end_current_turn() -> void:
	var current: Player = combat.turn_manager.get_current_player()
	if current != null:
		_end_turn(current.player_id)


func _select_bot(index: int) -> void:
	selected_bot_id = index + 2
	selected_bot_card_id = 0
	_refresh()


func _select_bot_card(index: int) -> void:
	selected_bot_card_id = _bot_cards.get_item_id(index)


func _attack(actor_id: int) -> void:
	if combat == null:
		return
	var card_id: int = selected_human_card_id if actor_id == HUMAN_ID else selected_bot_card_id
	var card: CardInstance = _find_card(actor_id, card_id)
	if card == null:
		_notify("Chọn một lá bài trước.")
		return
	if card.definition.has_effect("restore_hp"):
		_record("%s dùng %s để tự hồi máu" % [_name(actor_id), card.get_display_name()], combat.use_heal(actor_id, card_id))
		return
	if selected_target_id == 0:
		_notify("Chọn một lá bài và một mục tiêu trên bàn trước.")
		return
	if not card.definition.has_effect("deal_attack"):
		if card.definition.has_effect("discard") or card.definition.has_effect("steal_card"):
			_open_tool_choice(actor_id, selected_target_id, card_id)
			return
		_notify("Lá này không dùng để Attack. " + _card_usage(card) + ".")
		return
	_record("%s Tấn công %s bằng %s" % [_name(actor_id), _name(selected_target_id), card.get_display_name()], combat.use_attack(actor_id, selected_target_id, card_id))


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


func _advance_phase() -> void:
	if combat != null:
		_record("Debug: tiếp tục auto-advance", combat.advance_until_decision())


func _end_turn(player_id: int) -> void:
	if combat != null:
		_record(_name(player_id) + " kết thúc lượt", combat.end_turn(player_id))


func _discard(player_id: int) -> void:
	if combat != null:
		var card_id: int = selected_human_card_id if player_id == HUMAN_ID else selected_bot_card_id
		_record("%s chọn bỏ lá #%d" % [_name(player_id), card_id], combat.discard_for_turn(player_id, card_id))


func _rescue(rescuer_id: int) -> void:
	if combat != null and combat.has_pending_dying():
		_open_dying_choice(combat.executor.dying_manager.dying_player_id, rescuer_id)


func _finalize_dying() -> void:
	if combat != null:
		_record("Finalize Dying: " + _name(combat.executor.dying_manager.dying_player_id), combat.finalize_dying())


func _debug_draw(player_id: int) -> void:
	if combat == null:
		return
	if combat.has_pending_response() or combat.has_pending_dying():
		_notify("Debug rút bài tạm khóa trong cửa sổ phản ứng / hấp hối.")
		return
	if not game_state.get_player(player_id).is_alive():
		_notify("Không rút Debug cho người DYING / ELIMINATED.")
		return
	var card: CardInstance = game_state.draw_card(player_id)
	_notify("Debug: %s rút %s" % [_name(player_id), "thất bại: không còn bài khả dụng" if card == null else card.get_display_name()])
	_refresh()


func _bot_attack() -> void:
	_attack(selected_bot_id)


func _bot_draw() -> void:
	_debug_draw(selected_bot_id)


func _bot_dodge() -> void:
	_respond(selected_bot_id, true)


func _bot_pass() -> void:
	_respond(selected_bot_id, false)


func _bot_rescue() -> void:
	_rescue(selected_bot_id)


func _bot_end_turn() -> void:
	_end_turn(selected_bot_id)


func _bot_discard() -> void:
	_discard(selected_bot_id)


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
	_choice_confirm.text = "Đồng ý"
	_choice_confirm.disabled = true
	for child: Node in _choice_cards.get_children():
		_choice_cards.remove_child(child)
		child.queue_free()
	_choice_overlay.show()


func _add_choice_card(card_id: int, zone: String, caption: String, hidden: bool) -> void:
	var index: int = _choice_cards.get_child_count()
	var button: Button = _button(_choice_cards, caption, _select_choice_card.bind(card_id, zone, index))
	button.name = "HiddenCard%d" % index if hidden else ("RescueCard%d" % card_id if _choice_kind == "dying" else "DodgeCard%d" % card_id)
	button.custom_minimum_size = Vector2(135.0, 110.0)
	button.toggle_mode = true


func _select_choice_card(card_id: int, zone: String, index: int) -> void:
	_choice_selected_card_id = card_id
	_choice_zone = zone
	_choice_confirm.disabled = false
	for child: Node in _choice_cards.get_children():
		if child is Button:
			(child as Button).set_pressed_no_signal(child.get_index() == index)


func _open_dying_choice(target_id: int, preferred_rescuer: int = 0) -> void:
	_prepare_choice("dying", 0, target_id, 0)
	var player: Player = game_state.get_player(target_id)
	_choice_title.text = "%s đang hấp hối · HP %d/%d\nCần hồi ít nhất %d HP. Chọn người cứu và lá Hồi máu." % [player.display_name, player.hp, player.max_hp, 1 - player.hp]
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
			(_choice_cards.get_child(_choice_cards.get_child_count() - 1) as Button).tooltip_text = card.definition.description
	if _choice_cards.get_child_count() == 1:
		_label(_choice_cards, "Không có lá Hồi máu.\nCó thể chọn người cứu khác.")


func _select_dying_rescuer(index: int) -> void:
	var rescuers: OptionButton = _choice_cards.get_node("DyingRescuer") as OptionButton
	_open_dying_choice(_choice_target_id, rescuers.get_item_id(index))


func _open_response_choice(target_id: int) -> void:
	_prepare_choice("response", target_id, target_id, 0)
	_choice_title.text = "%s bị Tấn công: chọn lá Né rồi nhấn Đồng ý.\nBot được điều khiển thủ công." % _name(target_id)
	_choice_cancel.text = "Không Né"
	for card: CardInstance in game_state.get_player(target_id).hand:
		if card.definition.has_effect("block_attack"):
			_add_choice_card(card.instance_id, "hand", card.get_display_name(), false)
	if _choice_cards.get_child_count() == 0:
		_label(_choice_cards, "Không có lá Né. Chọn Không Né để nhận sát thương.")


func _open_tool_choice(actor_id: int, target_id: int, card_id: int) -> void:
	var validation: ActionResult = combat.executor.validator.validate_tool_use(actor_id, target_id, card_id)
	if not validation.valid:
		_notify(validation.reason)
		return
	var effect: Dictionary = combat.executor.validator.get_tool_effect(actor_id, card_id)
	var parameters: Dictionary = effect["parameters"]
	_prepare_choice("tool", actor_id, target_id, card_id)
	_choice_title.text = "%s: chọn một lá úp của %s rồi nhấn Đồng ý." % ["Cướp bài" if effect["effect_id"] == "steal_card" else "Hủy bài", _name(target_id)]
	_choice_cancel.text = "Huỷ bỏ"
	var zones: Array = parameters["target_zones"]
	for zone: String in zones:
		for card: CardInstance in game_state.get_player(target_id).get_zone(zone):
			var zone_label: String = "Trên tay"
			if zone == "equipment":
				zone_label = "Trang bị"
			elif zone == "judgment":
				zone_label = "Phán xét"
			_add_choice_card(card.instance_id, zone, "✦\nBÀI ÚP\n" + zone_label, true)


func _confirm_choice() -> void:
	if _choice_kind == "dying":
		if _choice_selected_card_id == 0:
			return
		var target_id: int = _choice_target_id
		var card_id: int = _choice_selected_card_id
		_choice_kind = ""
		_choice_overlay.hide()
		_record("%s dùng lá #%d cứu %s" % [_name(_dying_rescuer_id), card_id, _name(target_id)], combat.rescue_player(_dying_rescuer_id, target_id, card_id))
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
		_notify("Đã hủy chọn công cụ; không có lá bài nào bị tiêu hao.")
