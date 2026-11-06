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


func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	_build_ui()
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
	_phase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button(header, "Bàn mới", _new_table).name = "NewTable"
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
	_create_seat(middle, 2)
	var center: VBoxContainer = VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_child(center)
	_piles = _label(center, "", 18)
	_piles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt = _label(center, "")
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_create_seat(middle, 4)
	var bottom: CenterContainer = CenterContainer.new()
	table_rows.add_child(bottom)
	_create_seat(bottom, 1)
	_selection = _label(play, "Chọn bài trên tay, rồi chọn người trên bàn.")
	var hand_scroll: ScrollContainer = ScrollContainer.new()
	hand_scroll.custom_minimum_size.y = 124.0
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	play.add_child(hand_scroll)
	_hand = HBoxContainer.new()
	_hand.add_theme_constant_override("separation", 8)
	hand_scroll.add_child(_hand)
	var actions: HBoxContainer = HBoxContainer.new()
	play.add_child(actions)
	_button(actions, "Tấn công", _attack.bind(HUMAN_ID)).name = "HumanAttack"
	_button(actions, "Né bằng bài đã chọn", _respond.bind(HUMAN_ID, true)).name = "HumanDodge"
	_button(actions, "Không Né", _respond.bind(HUMAN_ID, false)).name = "HumanPass"
	_button(actions, "Chuyển phase →", _advance_phase).name = "AdvancePhase"
	var rescue_row: HBoxContainer = HBoxContainer.new()
	play.add_child(rescue_row)
	_button(rescue_row, "Cứu +1 · mô phỏng", _rescue.bind(HUMAN_ID)).name = "HumanRescue"
	_button(rescue_row, "Finalize Dying", _finalize_dying).name = "FinalizeDying"
	_button(rescue_row, "Debug: Rút 1 cho Human", _debug_draw.bind(HUMAN_ID)).name = "HumanDraw"
	_feedback = _label(play, "")
	_feedback.custom_minimum_size.y = 40.0
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_sidebar(body)
	_label(page, "PROTOTYPE v0.1   •   Không có AI / vai trò / điều kiện thắng.   •   Chọn mục tiêu bằng cách bấm ghế.", 14)


func _create_seat(parent: Node, player_id: int) -> void:
	var seat: Button = _button(parent, "", _select_target.bind(player_id))
	seat.name = "Seat%d" % player_id
	seat.custom_minimum_size = Vector2(190.0, 84.0)
	seat.toggle_mode = true
	seat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_seats[player_id - 1] = seat


func _build_sidebar(parent: Node) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.x = 330.0
	parent.add_child(panel)
	var sidebar: VBoxContainer = VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 8)
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
	_button(attacks, "Bot: Attack", _bot_attack).name = "BotAttack"
	_button(attacks, "Rút 1", _bot_draw).name = "BotDraw"
	var responses: HBoxContainer = HBoxContainer.new()
	sidebar.add_child(responses)
	_button(responses, "Bot: Né", _bot_dodge).name = "BotDodge"
	_button(responses, "Bot: Không Né", _bot_pass).name = "BotPass"
	_button(sidebar, "Bot: Cứu +1 · mô phỏng", _bot_rescue).name = "BotRescue"
	var limits: Label = _label(sidebar, "Cứu chưa tốn bài. Bot chưa tự hành động.\nHồi máu / Hủy / Cướp chưa có action API.\nChưa chia bài đầu; dùng DRAW hoặc Debug.\nChưa bỏ lượt người bị loại / kiểm tra thắng.", 14)
	limits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(sidebar, "NHẬT KÝ BÀN CHƠI", 18).add_theme_color_override("font_color", GOLD)
	_event_log = RichTextLabel.new()
	_event_log.name = "EventLog"
	_event_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_event_log.custom_minimum_size.y = 130.0
	_event_log.scroll_following = true
	_event_log.selection_enabled = true
	_event_log.add_theme_font_size_override("normal_font_size", 14)
	sidebar.add_child(_event_log)


func _new_table() -> void:
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
	combat = CombatController.new(game_state, TurnManager.new(game_state), rules)
	selected_target_id = 0
	selected_human_card_id = 0
	selected_bot_card_id = 0
	_events.clear()
	_record("Bàn dev mới: 4 người, 4 HP; bộ bài 12 lá", combat.start_game())
	_notify("Bấm Chuyển phase 3 lần để tới PLAY và rút 2 lá. Chưa có chia bài đầu.")


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


func _refresh() -> void:
	var current: Player = combat.turn_manager.get_current_player()
	_phase.text = "Lượt %d · %s · %s" % [combat.turn_manager.turn_number, current.display_name, TurnManager.Phase.keys()[combat.turn_manager.current_phase]]
	for player: Player in game_state.players:
		var seat: Button = _seats[player.player_id - 1]
		seat.text = "%s%s\nHP %d / %d · %s\n%d lá trên tay" % ["▶ " if player == current else "", player.display_name, player.hp, player.max_hp, Player.LifeState.keys()[player.life_state], player.get_hand_count()]
		seat.set_pressed_no_signal(player.player_id == selected_target_id)
	_piles.text = "CHỒNG RÚT %d   /   CHỒNG BỎ %d" % [game_state.deck.get_draw_count(), game_state.deck.get_discard_count()]
	_prompt.text = "Chọn bài và mục tiêu để Tấn công trong PLAY."
	if combat.has_pending_response():
		var pending: Dictionary = combat.executor.pending_attack
		_prompt.text = "%s → %s\nĐang chờ Né / Không Né" % [_name(int(pending["actor_id"])), _name(int(pending["target_id"]))]
	elif combat.has_pending_dying():
		_prompt.text = "%s đang DYING\nCứu mô phỏng hoặc Finalize Dying" % _name(combat.executor.dying_manager.dying_player_id)
	elif current.is_eliminated():
		_prompt.text = "Engine chưa bỏ lượt ELIMINATED.\nCó thể chuyển phase thủ công hoặc mở bàn mới."
	_refresh_hand()
	_refresh_bot_cards()
	_selection.text = "Tay Human · %d lá   |   Mục tiêu: %s" % [game_state.get_player(HUMAN_ID).get_hand_count(), _name(selected_target_id)]


func _refresh_hand() -> void:
	for child: Node in _hand.get_children():
		_hand.remove_child(child)
		child.queue_free()
	var human: Player = game_state.get_player(HUMAN_ID)
	if _find_card(HUMAN_ID, selected_human_card_id) == null:
		selected_human_card_id = 0
	if human.hand.is_empty():
		_label(_hand, "Tay trống. Tới DRAW để rút bài hoặc dùng nút Debug.")
	for card: CardInstance in human.hand:
		var card_button: Button = _button(_hand, "%s\n%s%s\n%s" % [card.definition.display_name, card.get_rank_text(), CardInstance.SUIT_SYMBOLS[card.suit], _card_usage(card)], _select_human_card.bind(card.instance_id))
		card_button.name = "Card%d" % card.instance_id
		card_button.custom_minimum_size = Vector2(145.0, 102.0)
		card_button.toggle_mode = true
		card_button.set_pressed_no_signal(card.instance_id == selected_human_card_id)
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
	if card.definition.has_effect("deal_attack"):
		return "PLAY · Tấn công"
	if card.definition.has_effect("block_attack"):
		return "PHẢN ỨNG · Né"
	return "Chưa có action API"


func _select_target(player_id: int) -> void:
	selected_target_id = player_id
	_refresh()


func _select_human_card(card_id: int) -> void:
	selected_human_card_id = card_id
	var card: CardInstance = _find_card(HUMAN_ID, card_id)
	_notify("Đã chọn " + card.get_display_name() + " · " + _card_usage(card))
	_refresh()


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
	if card == null or selected_target_id == 0:
		_notify("Chọn một lá bài và một mục tiêu trên bàn trước.")
		return
	if not card.definition.has_effect("deal_attack"):
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
		_record("Chuyển phase", combat.advance_phase())
		if combat.turn_manager.current_phase in [TurnManager.Phase.JUDGMENT, TurnManager.Phase.DISCARD]:
			_notify("Phase này chưa có xử lý đầy đủ trong engine; tiếp tục thủ công.")


func _rescue(rescuer_id: int) -> void:
	if combat != null:
		_record("%s cứu %s +1 HP (mô phỏng, chưa tốn bài)" % [_name(rescuer_id), _name(selected_target_id)], combat.rescue_player(rescuer_id, selected_target_id))


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
