extends SceneTree

var _ui: PlayablePrototype


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	seed(5027)
	var scene: PackedScene = load("res://scenes/dev/playable_prototype.tscn")
	_ui = scene.instantiate() as PlayablePrototype
	root.add_child(_ui)
	await process_frame
	assert(_ui.game_state == null and _ui._setup_menu.visible)
	assert(not (_ui.find_child("CancelMatchSetup", true, false) as Button).visible)
	var count: SpinBox = _ui.find_child("MatchPlayerCount", true, false) as SpinBox
	assert(count.min_value == 2 and count.max_value == 6)
	for players: int in range(2, 7):
		if _ui.game_state != null:
			await _click("NewTable")
		count.value = players
		await _click("CreateMatch")
		assert(not _ui._setup_menu.visible and _ui.game_state.players.size() == players)
		assert(_ui._seats.size() == players)
		for player_id: int in range(1, players + 1):
			var player: Player = _ui.game_state.get_player(player_id)
			assert(player.display_name == "P%d" % player_id)
			assert(player.get_hand_count() == (6 if player_id == 1 else 4))
			assert((_ui.find_child("Seat%d" % player_id, true, false) as Button).text.contains("Phòng ngự: —"))
		await process_frame
		for first: int in range(1, _ui._seats.size()):
			for second: int in range(first + 1, _ui._seats.size()):
				assert(not _ui._seats[first].get_global_rect().intersects(_ui._seats[second].get_global_rect()))
		for expected: int in range(2, players + 2):
			_end_turn()
			assert(_ui.combat.turn_manager.get_current_player().player_id == (1 if expected > players else expected))
		assert(_ui.game_state.validate_state())
		var previous: GameState = _ui.game_state
		await _click("NewTable")
		count.value = 2
		await _click("CancelMatchSetup")
		assert(_ui.game_state == previous and _ui.game_state.players.size() == players)
		assert(not _ui._setup_menu.visible)
	# Reset to four players for interaction scenarios, using the public menu.
	await _click("NewTable")
	count.value = 4
	await _click("CreateMatch")
	_collect_cards()
	await _test_double_click()
	for player_id: int in range(2, 5):
		assert(_ui.combat.executor.resolver.deal_damage(player_id, 4))
		assert(_ui.combat.finalize_dying().valid)
	_ui._refresh()
	assert(_ui.game_state.match_over)
	await _click("NewTable")
	assert(not (_ui.find_child("CreateMatch", true, false) as Button).disabled)
	count.value = 2
	await _click("CreateMatch")
	assert(not _ui.game_state.match_over and _ui.game_state.players.size() == 2)
	_ui.queue_free()
	await process_frame
	print("=== MENU INTERACTION UI SMOKE PASSED ===")
	quit()


func _collect_cards() -> void:
	for player_id: int in range(2, 5):
		var cards: Array[CardInstance] = _ui.game_state.get_player(player_id).hand.duplicate()
		for card: CardInstance in cards:
			assert(_ui.game_state.transfer_player_card(card.instance_id, player_id, "hand", 1, "hand"))
	while _ui.game_state.deck.get_draw_count() > 0:
		assert(_ui.game_state.draw_card(1) != null)
	_ui._refresh()


func _card(effect_id: String) -> CardInstance:
	for card: CardInstance in _ui.game_state.get_player(1).hand:
		if card.definition.has_effect(effect_id):
			return card
	assert(false, effect_id)
	return null


func _end_turn() -> void:
	(_ui.find_child("EndTurn", true, false) as Button).pressed.emit()
	var budget: int = _ui.game_state.get_player(_ui.displayed_player_id).get_hand_count() + 1
	for step: int in range(budget):
		if _ui.combat.turn_manager.current_phase != TurnManager.Phase.DISCARD:
			break
		var card: CardInstance = _ui.game_state.get_player(_ui.displayed_player_id).hand[0]
		(_ui.find_child("Card%d" % card.instance_id, true, false) as Button).pressed.emit()
		(_ui.find_child("ActionConfirm", true, false) as Button).pressed.emit()
	assert(_ui.combat.turn_manager.current_phase == TurnManager.Phase.PLAY)


func _test_double_click() -> void:
	var initial_count: int = _ui.game_state.get_player(1).get_hand_count()
	var heal: CardInstance = _card("restore_hp")
	await _double_click("Card%d" % heal.instance_id)
	assert(_ui.game_state.get_player(1).get_hand_count() == initial_count and _ui.game_state.get_player(1).hp == 4)
	assert(_ui.combat.executor.resolver.deal_damage(1, 1))
	_ui._refresh()
	await _double_click("Card%d" % heal.instance_id)
	assert(_ui.game_state.get_player(1).hp == 4 and _ui.game_state.get_player(1).get_hand_count() == initial_count - 1)
	var weapon: CardInstance = _card("remove_attack_limit")
	await _double_click("Card%d" % weapon.instance_id)
	assert(_ui.combat.get_weapon(1) == weapon)
	var dodge: CardInstance = _card("block_attack")
	assert(_ui.game_state.transfer_player_card(dodge.instance_id, 1, "hand", 2, "hand"))
	var attack: CardInstance = _card("deal_attack")
	_ui._refresh()
	await _double_click("Card%d" % attack.instance_id)
	assert(not _ui.combat.has_pending_response() and _ui.game_state.get_player(1).hand.has(attack))
	await _double_click("Card%d" % attack.instance_id)
	assert(_ui.selected_hand_card_id == 0 and not _ui.combat.has_pending_response())
	await _click("Card%d" % attack.instance_id)
	await _click("Seat2")
	await _double_click("Card%d" % attack.instance_id)
	assert(_ui.combat.has_pending_response() and _ui.combat.executor.attacks_used == 1)
	# Opening/cancelling setup must retain the response and spent Attack.
	(_ui.find_child("NewTable", true, false) as Button).pressed.emit()
	await _click("CancelMatchSetup")
	assert(_ui._choice_kind == "response" and _ui._choice_overlay.visible)
	await _double_click("DodgeCard%d" % dodge.instance_id)
	assert(not _ui.combat.has_pending_response() and _ui.game_state.get_player(2).hp == 4)
	assert(_ui.game_state.deck.discard_pile.has(dodge))
	var victim: CardInstance = _card("restore_hp")
	assert(_ui.game_state.transfer_player_card(victim.instance_id, 1, "hand", 2, "hand"))
	_ui._refresh()
	var tool: CardInstance = _card("discard")
	await _double_click("Card%d" % tool.instance_id)
	assert(_ui._choice_kind == "tool")
	await _double_click("HiddenCard0")
	assert(_ui.game_state.deck.discard_pile.has(victim) and _ui.game_state.deck.discard_pile.has(tool))
	var aoe: CardInstance = _card("aoe_response_damage")
	var response: CardInstance = _card(str(aoe.definition.effects[0]["parameters"]["response_effect"]))
	assert(_ui.game_state.transfer_player_card(response.instance_id, 1, "hand", 2, "hand"))
	_ui._refresh()
	await _double_click("Card%d" % aoe.instance_id)
	assert(_ui._choice_kind == "aoe")
	await _double_click("AoeResponseCard%d" % response.instance_id)
	assert(_ui._choice_target_id == 3 and _ui.game_state.get_player(2).hp == 4)
	await _click("ChoiceCancel")
	await _click("ChoiceCancel")
	assert(not _ui.combat.has_pending_aoe())
	assert(_ui.combat.executor.resolver.deal_damage(2, 4))
	_ui._refresh()
	heal = _card("restore_hp")
	assert(_ui._dying_rescuer_id == 1)
	await _double_click("RescueCard%d" % heal.instance_id)
	assert(not _ui.combat.has_pending_dying() and _ui.game_state.get_player(2).hp == 1)
	await _click("EndTurn")
	assert(_ui.combat.turn_manager.current_phase == TurnManager.Phase.DISCARD)
	var before_discard: int = _ui.game_state.get_player(1).get_hand_count()
	dodge = _card("block_attack")
	await _double_click("Card%d" % dodge.instance_id)
	assert(_ui.game_state.get_player(1).get_hand_count() == before_discard - 1)
	assert(_ui.game_state.validate_state())


func _double_click(node_name: String) -> void:
	await _click(node_name)
	await _click(node_name, true)


func _click(node_name: String, double_click: bool = false) -> void:
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
		event.double_click = double_click and down
		root.push_input(event)
		await process_frame
