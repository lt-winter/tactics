class_name DyingSystemTest
extends RefCounted


static func run_all() -> void:
	_test_nonlethal_damage()
	_test_dodge()
	_test_prevented_damage()
	_test_repeated_invalid_responses()
	_test_overkill_damage()
	_test_lethal_damage_and_rescue()
	_test_elimination()
	_test_dying_preempts_attack_response()
	_test_last_survivor_wins()
	print("=== ALL DYING SYSTEM TESTS PASSED ===")


static func _create_combat(target_hp: int) -> CombatController:
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	var attack: CardDefinition = database.get_definition("attack")
	var dodge: CardDefinition = database.get_definition("dodge")
	var heal: CardDefinition = database.get_definition("heal")
	var cards: Array[CardInstance] = [
		CardInstance.new(1, attack, CardInstance.Suit.SPADES, 7),
		CardInstance.new(2, attack, CardInstance.Suit.HEARTS, 7),
		CardInstance.new(3, dodge, CardInstance.Suit.CLUBS, 2)
	]
	for card_id: int in range(4, 12):
		cards.append(CardInstance.new(card_id, heal, CardInstance.Suit.HEARTS, 3))
	var players: Array[Player] = [
		Player.new(1, "Attacker", 4),
		Player.new(2, "Target", target_hp),
		Player.new(3, "Rescuer", 4),
		Player.new(4, "Other", 4)
	]
	var state: GameState = GameState.new(cards, players)
	assert(state.zone_manager.transfer_card(1, "draw", 0, "hand", 1))
	assert(state.zone_manager.transfer_card(2, "draw", 0, "hand", 1))
	assert(state.zone_manager.transfer_card(3, "draw", 0, "hand", 2))
	var turns: TurnManager = TurnManager.new(state)
	# Keep the fixture independent of automatic draws and deck recycling.
	turns.draw_count_per_turn = 0
	var rules: RuleEngine = RuleEngine.new()
	assert(rules.load_base_rules("res://data/rules/base_rules.json"))
	# A second attack would be legal without the Dying Window guard.
	rules.add_modifier(RuleModifier.new(
		"attack_limit_per_turn", "set", 2,
		RuleModifier.Source.CARD_EFFECT, "test_attack_limit", 1
	))
	var combat: CombatController = CombatController.new(state, turns, rules)
	assert(combat.start_game().valid)
	assert(turns.current_phase == TurnManager.Phase.PLAY)
	return combat


static func _give_heal(combat: CombatController, player_id: int) -> int:
	for card: CardInstance in combat.game_state.deck.draw_pile:
		if card.definition.has_effect("restore_hp"):
			assert(combat.game_state.zone_manager.transfer_card(card.instance_id, "draw", 0, "hand", player_id))
			return card.instance_id
	assert(false, "Missing heal fixture")
	return 0


static func _test_nonlethal_damage() -> void:
	var combat: CombatController = _create_combat(4)
	assert(combat.use_attack(1, 2, 1).valid)
	assert(combat.respond_to_attack(2).valid)
	var target: Player = combat.game_state.get_player(2)
	assert(target.hp == 3 and target.is_alive())
	assert(not combat.has_pending_response())
	assert(not combat.has_pending_dying())
	assert(combat.advance_phase().valid)
	assert(combat.game_state.validate_state())
	print("[PASS] Nonlethal damage does not open a Dying Window")


static func _test_dodge() -> void:
	var combat: CombatController = _create_combat(1)
	assert(combat.use_attack(1, 2, 1).valid)
	assert(not combat.respond_to_attack(3).valid)
	assert(combat.has_pending_response())
	assert(combat.respond_to_attack(2, 3).valid)
	var target: Player = combat.game_state.get_player(2)
	assert(target.hp == 1 and target.is_alive())
	assert(not combat.has_pending_response())
	assert(not combat.has_pending_dying())
	assert(combat.game_state.deck.get_discard_count() == 2)
	assert(combat.game_state.validate_state())
	print("[PASS] Dodge prevents lethal damage and the Dying Window")


static func _test_prevented_damage() -> void:
	for callback_name: String in ["_reduce_damage", "_cancel_damage"]:
		var combat: CombatController = _create_combat(1)
		combat.executor.damage_pipeline.add_modifier(
			Callable(DyingSystemTest, callback_name)
		)
		assert(combat.use_attack(1, 2, 1).valid)
		assert(combat.respond_to_attack(2).valid)
		var target: Player = combat.game_state.get_player(2)
		assert(target.hp == 1 and target.is_alive())
		assert(not combat.has_pending_response())
		assert(not combat.has_pending_dying())
		assert(combat.game_state.validate_state())
	print("[PASS] Reduced and cancelled damage do not open a Dying Window")


static func _test_lethal_damage_and_rescue() -> void:
	var combat: CombatController = _create_combat(1)
	var state: GameState = combat.game_state
	var target: Player = state.get_player(2)
	var manager: DyingManager = combat.executor.dying_manager
	assert(not manager.begin_dying(99).valid)
	assert(not manager.begin_dying(2).valid)
	assert(DistanceCalculator.calculate(state.players, 1, 3) == 2)
	assert(combat.use_attack(1, 2, 1).valid)
	assert(combat.respond_to_attack(2).valid)
	assert(target.hp == 0 and target.is_dying())
	assert(not combat.has_pending_response())
	assert(combat.has_pending_dying())
	assert(manager.dying_player_id == 2)
	assert(not manager.begin_dying(2).valid)
	assert(DistanceCalculator.calculate(state.players, 1, 3) == 2)
	assert(DistanceCalculator.calculate(state.players, 1, 2) == 1)
	assert(DistanceCalculator.calculate(state.players, 2, 2) == 0)
	assert(not combat.advance_phase().valid)
	assert(not combat.start_game().valid)
	assert(combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
	assert(combat.turn_manager.turn_number == 1)
	assert(not combat.use_attack(1, 4, 2).valid)
	assert(not combat.executor.use_attack(1, 4, 2).valid)
	assert(combat.executor.attacks_used == 1)
	assert(state.get_player(1).get_hand_count() == 1)
	assert(state.deck.get_discard_count() == 1)
	assert(not combat.respond_to_attack(2).valid)
	assert(not combat.rescue_player(3, 4).valid)
	assert(not combat.rescue_player(3, 2, 0).valid)
	assert(not combat.rescue_player(99, 2).valid)
	assert(target.hp == 0 and combat.has_pending_dying())
	assert(combat.rescue_player(3, 2, _give_heal(combat, 3)).valid)
	assert(target.hp == target.max_hp and target.is_alive())
	assert(not combat.has_pending_dying())
	assert(not combat.finalize_dying().valid)
	assert(not combat.rescue_player(3, 2).valid)
	assert(DistanceCalculator.calculate(state.players, 1, 3) == 2)
	assert(combat.use_attack(1, 4, 2).valid)
	assert(combat.respond_to_attack(4).valid)
	assert(combat.advance_phase().valid)
	assert(state.validate_state())
	print("[PASS] Lethal damage pauses combat; rescue restores play and seating")


static func _test_repeated_invalid_responses() -> void:
	var combat: CombatController = _create_combat(1)
	var state: GameState = combat.game_state
	var target: Player = state.get_player(2)
	# Give the target an owned card with no Dodge effect.
	assert(state.transfer_player_card(2, 1, "hand", 2, "hand"))
	assert(combat.use_attack(1, 2, 1).valid)
	var pending_before: Dictionary = combat.executor.pending_attack.duplicate(true)
	for attempt: int in range(3):
		assert(not combat.respond_to_attack(3).valid)
		assert(not combat.respond_to_attack(2, 999).valid)
		assert(not combat.respond_to_attack(2, 2).valid)
		assert(combat.executor.pending_attack == pending_before)
		assert(target.hp == 1 and target.is_alive())
		assert(not combat.has_pending_dying())
		assert(target.get_hand_count() == 2)
		assert(state.deck.get_discard_count() == 1)
		assert(combat.executor.attacks_used == 1)
		assert(state.validate_state())
	assert(combat.respond_to_attack(2).valid)
	for attempt: int in range(3):
		assert(not combat.respond_to_attack(2).valid)
		assert(not combat.respond_to_attack(2, 3).valid)
		assert(not combat.has_pending_response())
		assert(combat.has_pending_dying())
		assert(combat.executor.dying_manager.dying_player_id == 2)
		assert(target.hp == 0 and target.is_dying())
		assert(target.get_hand_count() == 2)
		assert(state.deck.get_discard_count() == 1)
		assert(state.validate_state())
	assert(combat.rescue_player(3, 2, _give_heal(combat, 3)).valid)
	assert(target.hp == 1 and target.is_alive())
	assert(not combat.has_pending_dying())
	assert(combat.advance_phase().valid)
	print("[PASS] Repeated invalid responses preserve attack and dying state")


static func _test_overkill_damage() -> void:
	var combat: CombatController = _create_combat(1)
	combat.executor.damage_pipeline.add_modifier(
		Callable(DyingSystemTest, "_increase_damage")
	)
	assert(combat.use_attack(1, 2, 1).valid)
	assert(combat.respond_to_attack(2).valid)
	var target: Player = combat.game_state.get_player(2)
	assert(target.hp == -2 and target.is_dying())
	assert(combat.has_pending_dying())
	assert(not combat.has_pending_response())
	assert(not combat.advance_phase().valid)
	var self_heal: int = _give_heal(combat, 2)
	assert(not combat.rescue_player(3, 2, self_heal).valid)
	assert(not combat.rescue_player(2, 2).valid)
	assert(not combat.rescue_player(2, 2, 3).valid)
	assert(combat.rescue_player(2, 2, self_heal).valid)
	assert(target.hp == -1 and target.is_dying() and combat.has_pending_dying())
	assert(not combat.rescue_player(2, 2, self_heal).valid)
	assert(combat.rescue_player(3, 2, _give_heal(combat, 3)).valid)
	assert(target.hp == 0 and target.is_dying() and combat.has_pending_dying())
	assert(not combat.end_turn(1).valid)
	assert(combat.rescue_player(2, 2, _give_heal(combat, 2)).valid)
	assert(target.hp == 1 and target.is_alive())
	assert(not combat.has_pending_dying())
	assert(combat.game_state.deck.get_discard_count() == 4)
	assert(combat.game_state.validate_state())
	print("[PASS] Negative HP and paid self/other rescue: -2 -> -1 -> 0 -> 1; no early resume or duplicate payment")


static func _test_elimination() -> void:
	var combat: CombatController = _create_combat(1)
	var state: GameState = combat.game_state
	var target: Player = state.get_player(2)
	assert(not combat.finalize_dying().valid)
	assert(combat.use_attack(1, 2, 1).valid)
	assert(combat.respond_to_attack(2).valid)
	assert(DistanceCalculator.calculate(state.players, 1, 3) == 2)
	assert(combat.finalize_dying().valid)
	assert(target.hp == 0 and target.is_eliminated())
	assert(not combat.has_pending_dying())
	assert(DistanceCalculator.calculate(state.players, 1, 3) == 1)
	assert(DistanceCalculator.calculate(state.players, 1, 2) == -1)
	assert(DistanceCalculator.calculate(state.players, 2, 3) == -1)
	assert(not combat.finalize_dying().valid)
	assert(not combat.rescue_player(3, 2).valid)
	assert(combat.advance_phase().valid)
	assert(state.validate_state())
	print("[PASS] Elimination closes the window and removes the seat from distance")


static func _test_dying_preempts_attack_response() -> void:
	var combat: CombatController = _create_combat(4)
	assert(combat.use_attack(1, 2, 1).valid)
	var pending: Dictionary = combat.executor.pending_attack.duplicate(true)
	# Another engine damage source can interrupt the pending response.
	assert(combat.executor.damage_pipeline.process_damage(1, 3, 4))
	assert(combat.game_state.get_player(3).hp == 0)
	assert(combat.has_pending_dying())
	assert(combat.executor.dying_manager.dying_player_id == 3)
	assert(combat.turn_manager.get_transition_block_reason().contains("hấp hối"))
	for dodge_id: int in [0, 3]:
		assert(not combat.respond_to_attack(2, dodge_id).valid)
		assert(combat.executor.pending_attack == pending)
		assert(combat.game_state.get_player(2).get_hand_count() == 1)
	assert(not combat.end_turn(1).valid)
	assert(not combat.advance_phase().valid)
	combat.turn_manager.advance_phase()
	assert(combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
	assert(combat.rescue_player(4, 3, _give_heal(combat, 4)).valid)
	assert(combat.has_pending_response())
	assert(combat.respond_to_attack(2, 3).valid)
	assert(not combat.has_pending_response())
	assert(combat.game_state.get_player(2).hp == 4)
	# If the victim dies to an interrupting source, no Dodge/deadlock remains.
	var eliminated: CombatController = _create_combat(4)
	assert(eliminated.use_attack(1, 2, 1).valid)
	assert(eliminated.executor.resolver.deal_damage(2, 10))
	assert(not eliminated.executor.respond_to_attack(2, 3).valid)
	assert(eliminated.has_pending_response() and eliminated.has_pending_dying())
	assert(eliminated.finalize_dying().valid)
	assert(eliminated.game_state.get_player(2).is_eliminated())
	assert(not eliminated.has_pending_dying() and not eliminated.has_pending_response())
	assert(eliminated.game_state.get_player(2).get_hand_count() == 0)
	assert(eliminated.game_state.deck.get_discard_count() == 2)
	assert(combat.game_state.validate_state() and eliminated.game_state.validate_state())
	print("[PASS] Dying preempts pending Dodge/damage/phase; rescue resumes and elimination cancels stale attack")


static func _test_last_survivor_wins() -> void:
	var combat: CombatController = _create_combat(1)
	var state: GameState = combat.game_state
	var winners: Array[int] = []
	state.match_finished.connect(func(winner_id: int) -> void:
		winners.append(winner_id)
	)
	for player_id: int in [4, 3]:
		assert(combat.executor.resolver.deal_damage(player_id, 4))
		assert(combat.finalize_dying().valid)
	assert(not state.match_over)
	assert(combat.use_attack(1, 2, 1).valid)
	assert(combat.respond_to_attack(2).valid)
	assert(state.get_player(2).is_dying())
	state.update_match_result()
	assert(not state.match_over and winners.is_empty())
	assert(combat.rescue_player(2, 2, _give_heal(combat, 2)).valid)
	assert(not state.match_over)
	assert(combat.use_attack(1, 2, 2).valid)
	assert(combat.respond_to_attack(2).valid)
	assert(combat.finalize_dying().valid)
	assert(state.match_over and state.winner_id == 1 and winners == [1])
	assert(not combat.has_pending_response() and not combat.has_pending_dying())
	var phase: TurnManager.Phase = combat.turn_manager.current_phase
	var turn_number: int = combat.turn_manager.turn_number
	assert(not combat.use_attack(1, 2, 1).valid)
	assert(not combat.equip_weapon(1, 99).valid)
	assert(not combat.use_heal(1, 99).valid)
	assert(not combat.use_tool(1, 2, 99, 99, "hand").valid)
	assert(not combat.discard_for_turn(1, 99).valid)
	assert(not combat.respond_to_attack(2).valid)
	assert(not combat.rescue_player(1, 2, 99).valid)
	assert(not combat.finalize_dying().valid)
	assert(not combat.end_turn(1).valid and not combat.advance_until_decision().valid)
	combat.turn_manager.advance_phase()
	combat.turn_manager.start_game()
	assert(combat.turn_manager.current_phase == phase and combat.turn_manager.turn_number == turn_number)
	assert(state.draw_card(1) == null)
	assert(not combat.executor.damage_pipeline.process_damage(1, 1, 1))
	assert(not combat.executor.resolver.deal_damage(1, 1))
	state.update_match_result()
	assert(winners == [1] and state.validate_state())
	print("[PASS] Last survivor wins once, after Dying is resolved; all normal gameplay/phase/damage stops")


static func _reduce_damage(context: DamageContext) -> void:
	context.reduce_damage(1)


static func _cancel_damage(context: DamageContext) -> void:
	context.cancel_damage()


static func _increase_damage(context: DamageContext) -> void:
	context.increase_damage(2)
