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
	print("=== ALL DYING SYSTEM TESTS PASSED ===")


static func _create_combat(target_hp: int) -> CombatController:
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file("res://data/cards.json"))
	var attack: CardDefinition = database.get_definition("attack")
	var dodge: CardDefinition = database.get_definition("dodge")
	var cards: Array[CardInstance] = [
		CardInstance.new(1, attack, CardInstance.Suit.SPADES, 7),
		CardInstance.new(2, attack, CardInstance.Suit.HEARTS, 7),
		CardInstance.new(3, dodge, CardInstance.Suit.CLUBS, 2)
	]
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
	for phase_step: int in range(3):
		assert(combat.advance_phase().valid)
	assert(turns.current_phase == TurnManager.Phase.PLAY)
	return combat


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
	assert(combat.rescue_player(3, 2, 100).valid)
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
	assert(combat.rescue_player(3, 2).valid)
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
	assert(target.hp == 0 and target.is_dying())
	assert(combat.has_pending_dying())
	assert(not combat.has_pending_response())
	assert(not combat.advance_phase().valid)
	assert(combat.rescue_player(3, 2).valid)
	assert(target.hp == 1 and target.is_alive())
	assert(not combat.has_pending_dying())
	assert(combat.game_state.validate_state())
	print("[PASS] Overkill clamps HP to zero and opens a rescuable Dying Window")


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


static func _reduce_damage(context: DamageContext) -> void:
	context.reduce_damage(1)


static func _cancel_damage(context: DamageContext) -> void:
	context.cancel_damage()


static func _increase_damage(context: DamageContext) -> void:
	context.increase_damage(2)
