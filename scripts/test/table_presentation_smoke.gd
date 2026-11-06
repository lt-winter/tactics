extends SceneTree

var _ui: PlayablePrototype


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/dev/playable_prototype.tscn")
	_ui = scene.instantiate() as PlayablePrototype
	root.add_child(_ui)
	await process_frame
	var count: SpinBox = _ui.find_child("MatchPlayerCount", true, false) as SpinBox
	for players: int in range(2, 7):
		if _ui.game_state != null:
			await _click("NewTable")
		count.value = players
		await _click("CreateMatch")
		assert(_ui._last_played_card_id == 0)
		assert(_ui.find_child("CenterPlayedCard", true, false) == null)
		var attack: CardInstance = _give(1, "deal_attack")
		var dodge: CardInstance = _give(2, "block_attack")
		_ui._refresh()
		await _click("Card%d" % attack.instance_id)
		assert(_ui._last_played_card_id == 0)
		await _click("Seat2")
		await _click("ActionConfirm")
		assert(_ui._last_played_card_id == attack.instance_id)
		assert(_ui._played_by.text == "P1 → P2")
		_assert_layout()
		var center_card: Button = _ui.find_child("CenterPlayedCard", true, false) as Button
		assert((center_card.find_child("CardTitle", true, false) as Label).text == attack.definition.display_name.to_upper())
		assert(center_card.mouse_filter == Control.MOUSE_FILTER_IGNORE and center_card.focus_mode == Control.FOCUS_NONE)
		var events: Array[String] = _ui._events.duplicate()
		_ui._record("Không hợp lệ", ActionResult.failure("Lựa chọn không hợp lệ."), dodge, 2)
		assert(_ui._last_played_card_id == attack.instance_id and _ui._events == events)
		assert(_ui._feedback.text == "Lựa chọn không hợp lệ.")
		await _click("DodgeCard%d" % dodge.instance_id)
		assert(_ui._last_played_card_id == attack.instance_id)
		await _click("ChoiceConfirm")
		assert(_ui._last_played_card_id == dodge.instance_id and _ui._played_by.text == "P2")
		var heal: CardInstance = _give(1, "restore_hp")
		_ui._refresh()
		await _click("Card%d" % heal.instance_id) # Disabled at full HP; no new played card.
		assert(_ui._last_played_card_id == dodge.instance_id)
		assert(_ui.combat.executor.resolver.deal_damage(1, 1))
		_ui._refresh()
		await _click("Card%d" % heal.instance_id)
		await _click("ActionConfirm")
		assert(_ui._last_played_card_id == heal.instance_id)
		assert(_ui.game_state.deck.discard_pile.has(heal))
		for entry: String in _ui._events:
			assert(not entry.contains("→ OK") and not entry.is_empty())
		assert(not _ui._event_log.text.contains("\n\n"))
		_assert_layout()
		assert(_ui.game_state.validate_state())
	_ui.queue_free()
	await process_frame
	print("=== TABLE PRESENTATION UI SMOKE PASSED ===")
	quit()


func _assert_layout() -> void:
	var board: Control = _ui.find_child("BotTable", true, false) as Control
	var sidebar: Control = _ui.find_child("MatchSidebar", true, false) as Control
	var human: Control = _ui.find_child("HumanInfoPanel", true, false) as Control
	var log_panel: Control = _ui.find_child("EventLogPanel", true, false) as Control
	var hand: Control = _ui.find_child("HandScroll", true, false) as Control
	var face: Control = _ui.find_child("CenterPlayedCard", true, false) as Control
	assert(sidebar.get_global_rect().position.x >= board.get_global_rect().end.x)
	assert(sidebar.is_ancestor_of(human) and sidebar.is_ancestor_of(log_panel))
	assert(log_panel.get_global_rect().end.y <= human.get_global_rect().position.y)
	assert(hand.get_global_rect().position.y >= board.get_global_rect().end.y)
	assert(hand.get_global_rect().end.y <= 720 and human.get_global_rect().end.y <= 720)
	assert(absf(face.get_global_rect().get_center().x - board.get_global_rect().get_center().x) < 2.0)
	assert(board.get_global_rect().encloses(face.get_global_rect()))
	for seat: Button in _ui._seats:
		assert(not seat.get_global_rect().intersects(face.get_global_rect()))


func _give(owner: int, effect: String) -> CardInstance:
	for player: Player in _ui.game_state.players:
		for card: CardInstance in player.hand:
			if card.definition.has_effect(effect):
				if owner != player.player_id:
					assert(_ui.game_state.transfer_player_card(card.instance_id, player.player_id, "hand", owner, "hand"))
				return card
	for card: CardInstance in _ui.game_state.deck.draw_pile:
		if card.definition.has_effect(effect):
			assert(_ui.game_state.zone_manager.transfer_card(card.instance_id, "draw", 0, "hand", owner))
			return card
	assert(false, effect)
	return null


func _click(node_name: String) -> void:
	var button: Button = _ui.find_child(node_name, true, false) as Button
	assert(button != null, node_name)
	await process_frame
	var ancestor: Node = button.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			(ancestor as ScrollContainer).ensure_control_visible(button)
			await process_frame
			break
		ancestor = ancestor.get_parent()
	var point: Vector2 = button.get_global_rect().get_center()
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
		await process_frame
