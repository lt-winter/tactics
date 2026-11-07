extends SceneTree

var _ui: PlayablePrototype


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/dev/playable_prototype.tscn")
	_ui = scene.instantiate() as PlayablePrototype
	root.add_child(_ui)
	await process_frame
	_ui._new_table(4)
	_fixture(6)
	await _click("EndTurn")
	assert(_ui.combat.turn_manager.get_required_discards() == 2)
	var player: Player = _ui.game_state.get_player(1)
	var first: int = player.hand[0].instance_id
	var second: int = player.hand[1].instance_id
	var third: int = player.hand[2].instance_id
	var events_before: Array[String] = _ui._events.duplicate()
	await _click("Card%d" % first)
	await _click("Card%d" % second)
	assert(_ui._turn_discard_ids == [first, second] and player.get_hand_count() == 6)
	assert((_ui.find_child("Card%d" % third, true, false) as Button).disabled)
	assert((_ui.find_child("Card%d" % first, true, false) as Button).position.y == 0.0)
	assert((_ui.find_child("Card%d" % second, true, false) as Button).position.y == 0.0)
	assert(_ui._selection.text.contains("2/2") and _ui._events == events_before)
	await _click("ActionCancel")
	assert(_ui._turn_discard_ids.is_empty() and player.get_hand_count() == 6)
	assert(_ui._events == events_before)
	# Double-click only toggles the mandatory-discard draft; confirmation pays it.
	await _double_click("Card%d" % first)
	assert(_ui._turn_discard_ids == [first] and player.get_hand_count() == 6)
	await _double_click("Card%d" % first)
	assert(_ui._turn_discard_ids.is_empty() and player.get_hand_count() == 6)
	await _click("Card%d" % first)
	await _click("Card%d" % second)
	await _click("ActionConfirm")
	assert(player.get_hand_count() == 4 and _ui._turn_discard_ids.is_empty())
	assert(_ui.combat.turn_manager.get_current_player().player_id == 2)
	assert(_ui.game_state.deck.get_discard_count() == 2 and _ui.game_state.validate_state())
	_fixture(8)
	await _click("EndTurn")
	player = _ui.game_state.get_player(1)
	for pass_index: int in range(2):
		first = player.hand[0].instance_id
		second = player.hand[1].instance_id
		await _click("Card%d" % first)
		await _click("Card%d" % second)
		await _click("ActionConfirm")
		if pass_index == 0:
			assert(player.get_hand_count() == 6 and _ui.combat.turn_manager.current_phase == TurnManager.Phase.DISCARD)
			assert(_ui._turn_discard_ids.is_empty())
	assert(player.get_hand_count() == 4 and _ui.combat.turn_manager.get_current_player().player_id == 2)
	_fixture(6)
	await _click("EndTurn")
	player = _ui.game_state.get_player(1)
	first = player.hand[0].instance_id
	await _click("Card%d" % first)
	assert(_ui.combat.executor.resolver.deal_damage(2, 4))
	_ui._refresh()
	assert(_ui._choice_kind == "dying" and _ui._turn_discard_ids == [first])
	var heal: CardInstance = AoeSystemTest.give(_ui.combat, 3, "heal")
	assert(_ui.combat.rescue_player(3, 2, heal.instance_id).valid)
	_ui._refresh()
	assert(_ui._turn_discard_ids == [first] and not _ui.is_choice_visible())
	second = player.hand[1].instance_id
	await _click("Card%d" % second)
	await _click("ActionConfirm")
	assert(player.get_hand_count() == 4 and _ui.game_state.validate_state())
	_ui.queue_free()
	await process_frame
	print("=== MULTI DISCARD UI SMOKE PASSED ===")
	quit()


func _fixture(count: int) -> void:
	_ui.combat = MultiDiscardTest.setup(count)
	_ui.game_state = _ui.combat.game_state
	_ui.game_state.zone_manager.cards_discarded.connect(_ui._on_cards_discarded)
	_ui.game_state.match_finished.connect(_ui._on_match_finished)
	_ui.displayed_player_id = 0
	_ui.selected_hand_card_id = 0
	_ui.selected_target_id = 0
	_ui._turn_discard_ids.clear()
	_ui._choice_kind = ""
	_ui._hide_choice()
	_ui._events.clear()
	_ui._refresh()


func _double_click(node_name: String) -> void:
	await _click(node_name)
	await _click(node_name, true)


func _click(node_name: String, double_click: bool = false) -> void:
	await process_frame
	var button: Button = _ui.find_child(node_name, true, false) as Button
	assert(button != null and not button.disabled and button.is_visible_in_tree(), node_name)
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
