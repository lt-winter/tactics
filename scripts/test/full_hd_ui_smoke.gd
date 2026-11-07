extends SceneTree

var _ui: PlayablePrototype


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/dev/playable_prototype.tscn")
	_ui = scene.instantiate() as PlayablePrototype
	root.add_child(_ui)
	await process_frame
	_ui.get_window().size = Vector2i(1920, 1080)
	for count: int in range(2, 7):
		_ui._new_table(count)
		for frame: int in range(4):
			await process_frame
		assert(_ui.get_window().size == Vector2i(1920, 1080))
		assert(_ui.get_window().content_scale_size == Vector2i(1920, 1080))
		var board: Control = _ui.find_child("BotTable", true, false) as Control
		var hand: Control = _ui.find_child("HandScroll", true, false) as Control
		assert(hand.get_global_rect().position.y >= board.get_global_rect().end.y)
		assert(hand.get_global_rect().end.y <= 1080.0)
		for seat: Button in _ui._seats:
			assert(not seat.text.contains("Tầm") and not seat.text.contains("Vũ khí:"))
			assert(not seat.text.contains("Phòng ngự:"))
			assert(seat.get_theme_font_size("font_size") == 13)
		for node: Node in _ui.find_children("*", "Label", true, false):
			assert(not (node as Label).text.contains("Ngược chiều kim đồng hồ:"))
		for entry: String in _ui._events:
			assert(not entry.contains("Chia 4 lá/người"))
		var log_view: RichTextLabel = _ui.find_child("EventLog", true, false) as RichTextLabel
		assert(log_view.get_theme_font_size("normal_font_size") == 13)
	# Existing equipment is still shown, and removing it immediately clears its range.
	var weapon: CardInstance = _take_weapon()
	assert(_ui.combat.equip_weapon(1, weapon.instance_id).valid)
	_ui._refresh()
	var own_seat: Button = _ui.find_child("Seat1", true, false) as Button
	assert(own_seat.text.contains(weapon.definition.display_name + " · Tầm"))
	assert(not (_ui.find_child("Seat2", true, false) as Button).text.contains("Tầm"))
	assert(_ui.game_state.zone_manager.transfer_card(weapon.instance_id, "equipment", 1, "discard", 0))
	_ui._refresh()
	assert(not own_seat.text.contains("Tầm") and not own_seat.text.contains(weapon.definition.display_name))
	var cancel: Button = _ui.find_child("ActionCancel", true, false) as Button
	_ui._feedback.text = ""
	await process_frame
	var point: Vector2 = cancel.get_global_rect().get_center()
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
		await process_frame
	assert(_ui._feedback.text.contains("Đã huỷ lựa chọn"))
	assert(_ui.game_state.validate_state())
	_ui.queue_free()
	await process_frame
	print("=== FULL HD COMPACT UI SMOKE PASSED ===")
	quit()


func _take_weapon() -> CardInstance:
	for player: Player in _ui.game_state.players:
		for card: CardInstance in player.hand:
			if card.definition.equipment_slot == "weapon":
				if player.player_id != 1:
					assert(_ui.game_state.transfer_player_card(card.instance_id, player.player_id, "hand", 1, "hand"))
				return card
	for card: CardInstance in _ui.game_state.deck.draw_pile:
		if card.definition.equipment_slot == "weapon":
			assert(_ui.game_state.zone_manager.transfer_card(card.instance_id, "draw", 0, "hand", 1))
			return card
	assert(false, "Fixture deck needs an existing weapon")
	return null
