extends SceneTree

var _ui: PlayablePrototype


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/dev/playable_prototype.tscn")
	_ui = scene.instantiate() as PlayablePrototype
	root.add_child(_ui)
	await process_frame
	(_ui.find_child("CreateMatch", true, false) as Button).pressed.emit()
	_ui.combat = AoeSystemTest.setup()
	_ui.game_state = _ui.combat.game_state
	for player: Player in _ui.game_state.players:
		player.display_name = "P%d" % player.player_id
	_ui._connect_game_events()
	_ui._events.clear()
	var attack: CardInstance = AoeSystemTest.give(_ui.combat, 1, "attack")
	AoeSystemTest.give(_ui.combat, 1, "heal")
	var victim_card: CardInstance = AoeSystemTest.give(_ui.combat, 2, "heal")
	var weapon: CardInstance = AoeSystemTest.give(_ui.combat, 2, "crossbow")
	assert(_ui.game_state.transfer_player_card(weapon.instance_id, 2, "hand", 2, "equipment"))
	assert(_ui.combat.executor.resolver.deal_damage(2, 3))
	_ui._refresh()
	await process_frame
	var actions: Control = _ui.find_child("HandActions", true, false) as Control
	var hand: Control = _ui.find_child("HandScroll", true, false) as Control
	assert(actions.get_global_rect().end.y <= hand.get_global_rect().position.y)
	assert(absf(actions.get_global_rect().get_center().x - hand.get_global_rect().get_center().x) < 2.0)
	var events_before: Array[String] = _ui._events.duplicate()
	await _double_click("Card%d" % attack.instance_id)
	assert(_ui.selected_hand_card_id == attack.instance_id and not _ui.combat.has_pending_response())
	await _double_click("Card%d" % attack.instance_id)
	assert(_ui.selected_hand_card_id == 0 and _ui._events == events_before)
	await _click("Card%d" % attack.instance_id)
	await _click("Seat2")
	await _click("ActionConfirm")
	await _click("ChoiceCancel")
	assert(_ui._choice_kind == "dying")
	var source_before: int = _ui.game_state.get_player(1).get_hand_count()
	await _click("ChoiceCancel")
	assert(_ui.game_state.get_player(2).is_eliminated() and _ui.game_state.get_player(2).hand.is_empty())
	assert(_ui.game_state.get_player(2).equipment.is_empty() and _ui.combat.get_weapon(2) == null)
	assert(_ui.game_state.deck.discard_pile.has(victim_card) and _ui.game_state.deck.discard_pile.has(weapon))
	assert(_ui.game_state.get_player(1).get_hand_count() == source_before + 2)
	var log_text: String = "\n".join(_ui._events)
	assert(log_text.contains("P1 gây 1 sát thương cho P2"))
	assert(log_text.contains("P1 rút 2 lá thưởng hạ P2"))
	assert(log_text.contains("P2 bỏ:"))
	assert(log_text.contains("P1 dùng " + attack.definition.display_name + " lên P2"))
	assert((_ui.find_child("Seat2", true, false) as Button).disabled)
	assert(_ui.combat.executor.resolver.deal_damage(3, 1))
	var saloon: CardInstance = AoeSystemTest.give(_ui.combat, 1, "saloon")
	_ui._refresh()
	await _double_click("Card%d" % saloon.instance_id)
	assert("\n".join(_ui._events).contains("P1 hồi 1 HP cho P3"))
	var exchange: CardInstance = AoeSystemTest.give(_ui.combat, 1, "exchange")
	_ui._refresh()
	await _double_click("Card%d" % exchange.instance_id)
	assert(_ui._choice_kind == "support")
	var first: int = _ui.game_state.get_player(1).hand[0].instance_id
	var second: int = _ui.game_state.get_player(1).hand[1].instance_id
	events_before = _ui._events.duplicate()
	await _double_click("SupportDiscardCard%d" % first)
	assert(_ui._support_selected_ids == [first])
	await _double_click("SupportDiscardCard%d" % first)
	assert(_ui._support_selected_ids.is_empty() and _ui._events == events_before)
	assert(_ui.combat.has_pending_support())
	await _click("SupportDiscardCard%d" % first)
	await _click("SupportDiscardCard%d" % second)
	await _click("ChoiceConfirm")
	assert(not _ui.combat.has_pending_support() and _ui.game_state.validate_state())
	_ui.queue_free()
	await process_frame
	print("=== ELIMINATION UI SMOKE PASSED ===")
	quit()


func _double_click(node_name: String) -> void:
	await _click(node_name)
	await _click(node_name, true)


func _click(node_name: String, double_click: bool = false) -> void:
	var button: Button = _ui.find_child(node_name, true, false) as Button
	assert(button != null and not button.disabled, node_name)
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
		event.double_click = double_click and down
		root.push_input(event)
		await process_frame
