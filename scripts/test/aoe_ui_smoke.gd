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
	for definition_id: String in ["gatling", "indian"]:
		_fixture()
		var aoe: CardInstance = AoeSystemTest.give(_ui.combat, 1, definition_id)
		var response: CardInstance = AoeSystemTest.give(_ui.combat, 2, "dodge" if definition_id == "gatling" else "attack")
		var wrong: CardInstance = AoeSystemTest.give(_ui.combat, 2, "attack" if definition_id == "gatling" else "dodge")
		_ui._refresh()
		var events_before: Array[String] = _ui._events.duplicate()
		await _click("Card%d" % aoe.instance_id)
		assert(not (_ui.find_child("ActionConfirm", true, false) as Button).disabled)
		assert(_ui.selected_target_id == 0 and _ui._events == events_before)
		await _click("ActionConfirm")
		assert(_ui._choice_kind == "aoe" and _ui._choice_target_id == 2)
		assert(_ui._choice_title.text.contains(aoe.definition.display_name) and _ui._choice_title.text.contains("Human") and _ui._choice_title.text.contains("Bot 1"))
		assert(_ui._choice_cancel.text == "Không phản ứng" and _ui._choice_confirm.text == "Đồng ý")
		assert(_ui._choice_confirm.disabled)
		assert(_ui.find_child("AoeResponseCard%d" % wrong.instance_id, true, false) == null)
		assert((_ui.find_child("EndTurn", true, false) as Button).disabled)
		assert((_ui.find_child("Card%d" % wrong.instance_id, true, false) as Button) == null)
		var hand_before: int = _ui.game_state.get_player(2).get_hand_count()
		await process_frame
		await process_frame
		assert(_ui.game_state.get_player(2).get_hand_count() == hand_before)
		var events_pending: Array[String] = _ui._events.duplicate()
		await _click("AoeResponseCard%d" % response.instance_id)
		assert(not _ui._choice_confirm.disabled and _ui._events == events_pending)
		assert(_ui.game_state.get_player(2).get_hand_count() == hand_before)
		await _click("ChoiceConfirm")
		assert(_ui.game_state.deck.discard_pile.has(response) and _ui.game_state.get_player(2).hp == 4)
		assert(_ui._choice_target_id == 3)
		assert(_ui._choice_confirm.disabled)
		await _click("ChoiceCancel")
		assert(_ui.game_state.get_player(3).hp == 3 and _ui._choice_target_id == 4)
		await _click("ChoiceCancel")
		assert(not _ui.combat.has_pending_aoe() and not _ui.is_choice_visible())
		assert(_ui.combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
		assert(_ui.combat.executor.attacks_used == 0 and _ui.game_state.validate_state())
	await _test_dying()
	await _test_human_response()
	_ui.queue_free()
	await process_frame
	print("=== AOE UI SMOKE PASSED ===")
	quit()


func _fixture(order: Array[int] = [1, 2, 3, 4]) -> void:
	# Isolated test deck, including AOE instances: never modifies standard.json.
	_ui.combat = AoeSystemTest.setup(order)
	_ui.game_state = _ui.combat.game_state
	_ui.game_state.zone_manager.cards_discarded.connect(_ui._on_cards_discarded)
	_ui.game_state.match_finished.connect(_ui._on_match_finished)
	_ui.selected_hand_card_id = 0
	_ui.selected_target_id = 0
	_ui.displayed_player_id = 0
	_ui._choice_kind = ""
	_ui._hide_choice()
	_ui._events.clear()
	_ui._refresh()


func _test_dying() -> void:
	_fixture()
	var aoe: CardInstance = AoeSystemTest.give(_ui.combat, 1, "gatling")
	var heal: CardInstance = AoeSystemTest.give(_ui.combat, 2, "heal")
	assert(_ui.combat.executor.resolver.deal_damage(2, 3))
	_ui._refresh()
	await _click("Card%d" % aoe.instance_id)
	await _click("ActionConfirm")
	await _click("ChoiceCancel")
	assert(_ui._choice_kind == "dying" and _ui._choice_target_id == 2)
	assert(_ui.combat.has_pending_aoe() and _ui.combat.get_pending_aoe()["index"] == 1)
	var options: OptionButton = _ui.find_child("DyingRescuer", true, false) as OptionButton
	for index: int in range(options.item_count):
		if options.get_item_id(index) == 2:
			options.select(index)
			options.item_selected.emit(index)
			break
	await _click("RescueCard%d" % heal.instance_id)
	await _click("ChoiceConfirm")
	assert(_ui.game_state.get_player(2).hp == 1 and _ui._choice_kind == "aoe" and _ui._choice_target_id == 3)
	await _click("ChoiceCancel")
	assert(_ui._choice_target_id == 4)
	await _click("ChoiceCancel")
	assert(not _ui.combat.has_pending_aoe() and _ui.game_state.validate_state())


func _test_human_response() -> void:
	_fixture([3, 4, 1, 2])
	var aoe: CardInstance = AoeSystemTest.give(_ui.combat, 3, "indian")
	var attack: CardInstance = AoeSystemTest.give(_ui.combat, 1, "attack")
	_ui._refresh()
	await _click("Card%d" % aoe.instance_id)
	await _click("ActionConfirm")
	assert(_ui._choice_target_id == 4)
	await _click("ChoiceCancel")
	assert(_ui._choice_target_id == 1 and _ui.game_state.get_player(1).hand.has(attack))
	await process_frame
	assert(_ui.game_state.get_player(1).hand.has(attack))
	await _click("AoeResponseCard%d" % attack.instance_id)
	await _click("ChoiceConfirm")
	assert(_ui.game_state.get_player(1).hp == 4 and _ui.game_state.deck.discard_pile.has(attack))
	await _click("ChoiceCancel")
	assert(not _ui.combat.has_pending_aoe() and _ui.combat.turn_manager.get_current_player().player_id == 3)
	assert(_ui.game_state.validate_state())


func _click(node_name: String) -> void:
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
		root.push_input(event)
		await process_frame
