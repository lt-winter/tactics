extends SceneTree

var _ui: PlayablePrototype


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/dev/playable_prototype.tscn")
	_ui = scene.instantiate() as PlayablePrototype
	root.add_child(_ui)
	await process_frame
	assert(_ui.game_state.players.size() == 4)
	assert(_ui.game_state.get_player(1).hand.is_empty())
	for step: int in range(3):
		_press("AdvancePhase")
	assert(_ui.game_state.get_player(1).get_hand_count() == 2)
	await process_frame
	var visible_card: CardInstance = _ui.game_state.get_player(1).hand[0]
	await _click("Card%d" % visible_card.instance_id)
	assert(_ui.selected_human_card_id == visible_card.instance_id)
	await _click("Seat2")
	assert(_ui.selected_target_id == 2)
	var actors: OptionButton = _ui.find_child("DebugActor", true, false) as OptionButton
	actors.select(1)
	actors.item_selected.emit(1)
	assert(_ui.selected_bot_id == 3)
	actors.select(0)
	actors.item_selected.emit(0)
	_draw_all_for_human()
	var unsupported: CardInstance = _first_card(1, "restore_hp")
	assert(unsupported != null)
	_press("Card%d" % unsupported.instance_id)
	_press("Seat2")
	_press("HumanAttack")
	assert(not _ui.combat.has_pending_response())
	assert(_ui.game_state.get_player(1).get_hand_count() == 12)
	var event_log: RichTextLabel = _ui.find_child("EventLog", true, false) as RichTextLabel
	assert(event_log.text.contains("Chưa có action API"))
	_select_human_attack()
	_press("Seat3")
	_press("HumanAttack")
	assert(not _ui.combat.has_pending_response())
	assert(_ui.game_state.get_player(1).get_hand_count() == 12)
	_test_lethal_and_rescue()
	_test_bot_attack_and_human_dodge()
	_press("NewTable")
	_draw_all_for_human()
	for step: int in range(3):
		_press("AdvancePhase")
	_make_target_dying()
	_press("FinalizeDying")
	assert(_ui.game_state.get_player(2).is_eliminated())
	assert(not _ui.combat.has_pending_dying())
	assert(_ui.game_state.validate_state())
	_test_bot_dodge()
	_ui.queue_free()
	await process_frame
	print("=== PLAYABLE PROTOTYPE UI SMOKE PASSED ===")
	quit()


func _press(node_name: String) -> void:
	var button: Button = _ui.find_child(node_name, true, false) as Button
	assert(button != null, node_name)
	button.pressed.emit()


func _click(node_name: String) -> void:
	var button: Button = _ui.find_child(node_name, true, false) as Button
	assert(button != null)
	var position_on_screen: Vector2 = button.get_global_rect().get_center()
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = position_on_screen
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
		await process_frame


func _first_card(player_id: int, effect_id: String) -> CardInstance:
	for card: CardInstance in _ui.game_state.get_player(player_id).hand:
		if card.definition.has_effect(effect_id):
			return card
	return null


func _draw_all_for_human() -> void:
	while _ui.game_state.deck.get_draw_count() > 0:
		_press("HumanDraw")
	assert(_ui.game_state.validate_state())


func _select_human_attack() -> void:
	var attack: CardInstance = _first_card(1, "deal_attack")
	assert(attack != null)
	_press("Card%d" % attack.instance_id)


func _make_target_dying() -> void:
	for hit: int in range(4):
		_select_human_attack()
		_press("Seat2")
		_press("HumanAttack")
		assert(_ui.combat.has_pending_response())
		var phase_before: TurnManager.Phase = _ui.combat.turn_manager.current_phase
		_press("AdvancePhase")
		assert(_ui.combat.turn_manager.current_phase == phase_before)
		_press("BotPass")
		assert(not _ui.combat.has_pending_response())
		assert(_ui.game_state.get_player(2).hp == 3 - hit)
		if hit < 3:
			for step: int in range(24):
				_press("AdvancePhase")
	assert(_ui.combat.has_pending_dying())
	assert(_ui.game_state.get_player(2).is_dying())
	assert(_ui.game_state.validate_state())


func _test_lethal_and_rescue() -> void:
	_make_target_dying()
	var phase_before: TurnManager.Phase = _ui.combat.turn_manager.current_phase
	var hand_before: int = _ui.game_state.get_player(1).get_hand_count()
	_press("AdvancePhase")
	_press("HumanDraw")
	assert(_ui.combat.turn_manager.current_phase == phase_before)
	assert(_ui.game_state.get_player(1).get_hand_count() == hand_before)
	_press("HumanRescue")
	assert(not _ui.combat.has_pending_dying())
	assert(_ui.game_state.get_player(2).is_alive())
	assert(_ui.game_state.get_player(2).hp == 1)


func _select_bot_card(effect_id: String) -> void:
	var card: CardInstance = _first_card(2, effect_id)
	assert(card != null)
	var options: OptionButton = _ui.find_child("DebugCard", true, false) as OptionButton
	for index: int in range(options.item_count):
		if options.get_item_id(index) == card.instance_id:
			options.select(index)
			options.item_selected.emit(index)
			return
	assert(false, "Bot card missing from the debug selector")


func _test_bot_attack_and_human_dodge() -> void:
	for step: int in range(6):
		_press("AdvancePhase")
	assert(_ui.combat.turn_manager.get_current_player().player_id == 2)
	_select_bot_card("deal_attack")
	_press("Seat1")
	_press("BotAttack")
	assert(_ui.combat.has_pending_response())
	var dodge: CardInstance = _first_card(1, "block_attack")
	assert(dodge != null)
	_press("Card%d" % dodge.instance_id)
	_press("HumanDodge")
	assert(not _ui.combat.has_pending_response())
	assert(_ui.game_state.get_player(1).hp == 4)
	assert(_ui.game_state.validate_state())


func _test_bot_dodge() -> void:
	_press("NewTable")
	_draw_all_for_human()
	# Fixture setup uses the existing transfer API; no HP/phase/window mutation.
	var dodge: CardInstance = _first_card(1, "block_attack")
	assert(dodge != null)
	assert(_ui.game_state.transfer_player_card(dodge.instance_id, 1, "hand", 2, "hand"))
	_ui._refresh()
	for step: int in range(3):
		_press("AdvancePhase")
	_select_human_attack()
	_press("Seat2")
	_press("HumanAttack")
	assert(_ui.combat.has_pending_response())
	_select_bot_card("block_attack")
	_press("BotDodge")
	assert(not _ui.combat.has_pending_response())
	assert(_ui.game_state.get_player(2).hp == 4)
	assert(_ui.game_state.validate_state())
