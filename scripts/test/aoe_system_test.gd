class_name AoeSystemTest
extends RefCounted


static func run_all() -> void:
	seed(4201)
	_test_responses_and_guards()
	_test_order_and_elimination()
	_test_dying_continuation()
	_test_negative_hp_and_stale_response()
	_test_interrupted_target_and_source()
	_test_damage_sources()
	_test_reentrant_notifications()
	_test_schema()
	print("=== ALL AOE SYSTEM TESTS PASSED ===")


static func setup(order: Array[int] = [1, 2, 3, 4]) -> CombatController:
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	var cards: Array[CardInstance] = []
	for definition: Dictionary in database.get_all_cards():
		for copy_index: int in range(6):
			cards.append(CardInstance.new(cards.size() + 1, CardDefinition.new(definition), CardInstance.Suit.HEARTS, copy_index + 1))
	# Player-array/node order must not determine AOE order.
	var players: Array[Player] = [Player.new(4, "Bot 3", 4), Player.new(2, "Bot 1", 4), Player.new(1, "Human", 4), Player.new(3, "Bot 2", 4)]
	var state: GameState = GameState.new(cards, players)
	var rules: RuleEngine = RuleEngine.new()
	assert(rules.load_base_rules("res://data/rules/base_rules.json"))
	var turns: TurnManager = TurnManager.new(state, order, rules)
	turns.draw_count_per_turn = 0
	var combat: CombatController = CombatController.new(state, turns, rules)
	assert(combat.start_game().valid)
	assert(turns.current_phase == TurnManager.Phase.PLAY)
	return combat


static func give(combat: CombatController, owner_id: int, definition_id: String) -> CardInstance:
	for card: CardInstance in combat.game_state.deck.draw_pile:
		if card.definition.id == definition_id:
			assert(combat.game_state.zone_manager.transfer_card(card.instance_id, "draw", 0, "hand", owner_id))
			return card
	assert(false, "Missing fixture card: " + definition_id)
	return null


static func _test_responses_and_guards() -> void:
	for card_name: String in ["gatling", "indian"]:
		var combat: CombatController = setup()
		var aoe: CardInstance = give(combat, 1, card_name)
		var attack: CardInstance = give(combat, 1, "attack")
		var heal: CardInstance = give(combat, 1, "heal")
		var weapon: CardInstance = give(combat, 1, "crossbow")
		var tool: CardInstance = give(combat, 1, "discard")
		var extra_aoe: CardInstance = give(combat, 1, card_name)
		var response: CardInstance = give(combat, 2, "dodge" if card_name == "gatling" else "attack")
		var wrong: CardInstance = give(combat, 2, "attack" if card_name == "gatling" else "dodge")
		var foreign: CardInstance = give(combat, 3, response.definition.id)
		assert(combat.use_attack(1, 2, attack.instance_id).valid)
		assert(not combat.use_aoe(1, aoe.instance_id).valid)
		assert(combat.respond_to_attack(2).valid)
		assert(combat.executor.attacks_used == 1)
		assert(not combat.use_aoe(2, aoe.instance_id).valid)
		assert(combat.use_aoe(1, aoe.instance_id).valid)
		assert(combat.get_pending_aoe()["targets"] == [2, 3, 4])
		assert(not combat.has_pending_response())
		assert(combat.game_state.deck.discard_pile.has(aoe))
		var snapshot: Dictionary = combat.get_pending_aoe()
		snapshot["targets"].clear()
		assert(combat.get_pending_aoe()["targets"].size() == 3)
		assert(not combat.use_aoe(1, extra_aoe.instance_id).valid)
		assert(not combat.executor.use_attack(1, 4, give(combat, 1, "attack").instance_id).valid)
		assert(not combat.use_heal(1, heal.instance_id).valid)
		assert(not combat.equip_weapon(1, weapon.instance_id).valid)
		assert(not combat.use_tool(1, 2, tool.instance_id, wrong.instance_id, "hand").valid)
		assert(not combat.discard_for_turn(1, tool.instance_id).valid)
		assert(not combat.end_turn(1).valid and not combat.advance_until_decision().valid)
		combat.turn_manager.advance_phase()
		combat.turn_manager.start_game()
		assert(combat.turn_manager.current_phase == TurnManager.Phase.PLAY and combat.turn_manager.turn_number == 1)
		assert(not combat.respond_to_aoe(3, foreign.instance_id).valid)
		assert(not combat.respond_to_aoe(2, wrong.instance_id).valid)
		assert(not combat.respond_to_aoe(2, foreign.instance_id).valid)
		assert(combat.game_state.get_player(2).hand.has(wrong))
		assert(combat.get_aoe_response_cards(2) == [response])
		assert(combat.respond_to_aoe(2, response.instance_id).valid)
		assert(combat.game_state.deck.discard_pile.has(response) and combat.game_state.get_player(2).hp == 3)
		assert(not combat.respond_to_aoe(2, response.instance_id).valid)
		assert(combat.respond_to_aoe(3).valid)
		assert(combat.game_state.get_player(3).hp == 3 and combat.game_state.get_player(3).hand.has(foreign))
		assert(combat.respond_to_aoe(4).valid)
		assert(not combat.has_pending_aoe() and combat.executor.attacks_used == 1)
		assert(combat.turn_manager.get_current_player().player_id == 1 and combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
		assert(not combat.respond_to_aoe(4).valid)
		assert(combat.game_state.validate_state())
	print("[PASS] Data-driven Dodge/Attack responses, payment, ownership, replay rejection, all guards and no Attack count")


static func _test_order_and_elimination() -> void:
	var combat: CombatController = setup([3, 4, 1, 2])
	assert(combat.executor.resolver.deal_damage(4, 4))
	assert(combat.finalize_dying().valid)
	var aoe: CardInstance = give(combat, 3, "gatling")
	assert(combat.use_aoe(3, aoe.instance_id).valid)
	assert(combat.get_pending_aoe()["targets"] == [1, 2])
	assert(combat.get_pending_aoe()["target_id"] == 1)
	assert(combat.respond_to_aoe(1).valid and combat.get_pending_aoe()["target_id"] == 2)
	assert(combat.respond_to_aoe(2).valid and not combat.has_pending_aoe())
	assert(combat.turn_manager.get_current_player().player_id == 3)
	assert(combat.game_state.validate_state())
	print("[PASS] Counterclockwise seat order independent of player array; source excluded, eliminated skipped, no distance")


static func _test_dying_continuation() -> void:
	for rescue: bool in [false, true]:
		var combat: CombatController = setup()
		assert(combat.executor.resolver.deal_damage(2, 3))
		var aoe: CardInstance = give(combat, 1, "gatling")
		var heal: CardInstance = give(combat, 2, "heal")
		assert(combat.use_aoe(1, aoe.instance_id).valid)
		assert(combat.respond_to_aoe(2).valid and combat.has_pending_dying())
		assert(combat.get_pending_aoe()["index"] == 1)
		assert(not combat.respond_to_aoe(3).valid)
		assert(combat.get_aoe_response_cards(3).is_empty())
		assert(not combat.advance_until_decision().valid)
		if rescue:
			assert(combat.rescue_player(2, 2, heal.instance_id).valid)
			assert(combat.game_state.get_player(2).hp == 1)
		else:
			assert(combat.finalize_dying().valid)
		assert(combat.get_pending_aoe()["target_id"] == 3)
		assert(combat.respond_to_aoe(3).valid)
		assert(combat.executor.resolver.deal_damage(4, 3))
		assert(combat.respond_to_aoe(4).valid and combat.has_pending_dying())
		assert(combat.has_pending_aoe(), "Last target's Dying must retain the AOE hold")
		assert(combat.finalize_dying().valid)
		assert(not combat.has_pending_aoe() and combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
		assert(combat.game_state.validate_state())
	print("[PASS] Lethal first/last target pauses AOE, rescue/elimination resumes once at saved cursor")


static func _test_interrupted_target_and_source() -> void:
	var combat: CombatController = setup()
	var aoe: CardInstance = give(combat, 1, "indian")
	assert(combat.use_aoe(1, aoe.instance_id).valid)
	# An external Dying before response resumes the same target if rescued.
	assert(combat.executor.resolver.deal_damage(2, 4))
	assert(not combat.respond_to_aoe(2).valid)
	var heal: CardInstance = give(combat, 2, "heal")
	assert(combat.rescue_player(2, 2, heal.instance_id).valid)
	assert(combat.get_pending_aoe()["index"] == 0)
	var response: CardInstance = give(combat, 2, "attack")
	assert(combat.respond_to_aoe(2, response.instance_id).valid)
	# Removing the source must not lose an already committed queue.
	assert(combat.executor.resolver.deal_damage(1, 4))
	assert(combat.finalize_dying().valid)
	assert(combat.has_pending_aoe() and combat.turn_manager.get_current_player().player_id == 1)
	assert(combat.respond_to_aoe(3).valid and combat.respond_to_aoe(4).valid)
	assert(not combat.has_pending_aoe() and combat.turn_manager.get_current_player().player_id == 2)
	assert(combat.game_state.validate_state())
	var winner: CombatController = setup()
	for target_id: int in [2, 3, 4]:
		assert(winner.executor.resolver.deal_damage(target_id, 3))
	assert(winner.use_aoe(1, give(winner, 1, "gatling").instance_id).valid)
	for target_id: int in [2, 3, 4]:
		assert(winner.respond_to_aoe(target_id).valid)
		assert(winner.finalize_dying().valid)
	assert(winner.game_state.match_over and winner.game_state.winner_id == 1 and not winner.has_pending_aoe())
	assert(winner.game_state.validate_state())
	print("[PASS] External Dying before response, source elimination continuation, last-survivor queue cleanup")


static func _test_negative_hp_and_stale_response() -> void:
	var combat: CombatController = setup()
	var aoe: CardInstance = give(combat, 1, "gatling")
	aoe.definition.effects[0]["parameters"]["damage"] = 2
	assert(combat.executor.resolver.deal_damage(2, 3))
	assert(combat.use_aoe(1, aoe.instance_id).valid)
	assert(combat.respond_to_aoe(2).valid)
	assert(combat.game_state.get_player(2).hp == -1)
	var heal: CardInstance = give(combat, 2, "heal")
	assert(combat.rescue_player(2, 2, heal.instance_id).valid)
	assert(combat.game_state.get_player(2).hp == 0 and combat.has_pending_dying())
	assert(not combat.respond_to_aoe(3).valid)
	heal = give(combat, 1, "heal")
	assert(combat.rescue_player(1, 2, heal.instance_id).valid)
	assert(combat.get_pending_aoe()["target_id"] == 3)
	var dodge: CardInstance = give(combat, 3, "dodge")
	assert(combat.game_state.discard_card(3, dodge.instance_id))
	assert(not combat.respond_to_aoe(3, dodge.instance_id).valid)
	assert(combat.get_pending_aoe()["target_id"] == 3 and combat.game_state.get_player(3).hp == 4)
	assert(combat.respond_to_aoe(3).valid and combat.respond_to_aoe(4).valid)
	assert(combat.game_state.get_player(3).hp == 2 and combat.game_state.get_player(4).hp == 2)
	assert(combat.game_state.validate_state())
	# Elimination before an unprocessed target's response skips that target once.
	combat = setup()
	assert(combat.use_aoe(1, give(combat, 1, "indian").instance_id).valid)
	assert(combat.executor.resolver.deal_damage(2, 4))
	assert(combat.finalize_dying().valid)
	assert(combat.get_pending_aoe()["target_id"] == 3)
	assert(combat.respond_to_aoe(3).valid and combat.respond_to_aoe(4).valid)
	assert(combat.game_state.validate_state())
	print("[PASS] Negative HP requires two rescues, stale/spent response is free rejection, eliminated pending target skipped")


static func _test_damage_sources() -> void:
	var combat: CombatController = setup()
	var seen: Dictionary = {"aoe": 0, "weapon": 0}
	var weapon_only: DamageModifier = DamageModifier.new("attack_only", "weapon_fixture", 1, RuleModifier.Source.CARD_EFFECT, DamageModifier.Role.ATTACKER,
		func(_context: DamageContext) -> void: seen["weapon"] += 1,
		[DamageContext.SourceKind.ATTACK])
	assert(combat.executor.damage_pipeline.register_modifier(weapon_only))
	var generic: DamageModifier = DamageModifier.new("armor_fixture", "armor", 0, RuleModifier.Source.CARD_EFFECT, DamageModifier.Role.ANY,
		func(context: DamageContext) -> void:
			assert(context.source_kind == DamageContext.SourceKind.AOE_TOOL)
			seen["aoe"] += 1
			context.cancel_damage())
	assert(combat.executor.damage_pipeline.register_modifier(generic))
	assert(combat.use_aoe(1, give(combat, 1, "gatling").instance_id).valid)
	for target_id: int in [2, 3, 4]:
		assert(combat.respond_to_aoe(target_id).valid)
		assert(combat.game_state.get_player(target_id).hp == 4)
	assert(seen["aoe"] == 3 and seen["weapon"] == 0 and not combat.has_pending_dying())
	assert(combat.game_state.validate_state())
	print("[PASS] AOE damage source, common DamagePipeline cancellation, no Attack-only weapon modifier")


static func _test_schema() -> void:
	var combat: CombatController = setup()
	var aoe: CardInstance = give(combat, 1, "gatling")
	var valid: Dictionary = aoe.definition.effects[0]["parameters"].duplicate(true)
	combat.turn_manager.set_phase_wait(TurnManager.Phase.PLAY, "Fixture unresolved choice")
	assert(not combat.use_aoe(1, aoe.instance_id).valid)
	combat.turn_manager.set_phase_wait(TurnManager.Phase.PLAY, "")
	for bad: Variant in [null, [], true, {}]:
		assert(not AoeResolution.valid_parameters(bad))
	for bad: Variant in [0, -1, 1.5, true, "1", null, INF, NAN]:
		var parameters: Dictionary = valid.duplicate(true)
		parameters["damage"] = bad
		assert(not AoeResolution.valid_parameters(parameters))
	for key: String in ["response_effect", "target_scope"]:
		var parameters: Dictionary = valid.duplicate(true)
		parameters[key] = "unsupported"
		assert(not AoeResolution.valid_parameters(parameters))
		aoe.definition.effects[0]["parameters"] = parameters
		assert(not combat.use_aoe(1, aoe.instance_id).valid)
		assert(combat.game_state.get_player(1).hand.has(aoe) and not combat.has_pending_aoe())
	# Renaming a definition does not change runtime behavior.
	aoe.definition.id = "arbitrary_tool_id"
	aoe.definition.display_name = "Fixture AOE"
	aoe.definition.effects[0]["parameters"] = valid
	assert(combat.use_aoe(1, aoe.instance_id).valid)
	for target_id: int in [2, 3, 4]:
		assert(combat.respond_to_aoe(target_id).valid)
	assert(combat.game_state.validate_state())
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	var fixture_path: String = "res://__aoe_schema_%d.json" % Time.get_ticks_usec()
	for parameters: Dictionary in [{"target_scope": "single", "response_effect": "block_attack", "damage": 1}, {"target_scope": "all_other_players", "response_effect": "restore_hp", "damage": 1}, {"target_scope": "all_other_players", "response_effect": "deal_attack", "damage": 1.5}]:
		var definition: Dictionary = database.get_card("gatling")
		definition["effects"][0]["parameters"] = parameters
		var file: FileAccess = FileAccess.open(fixture_path, FileAccess.WRITE)
		assert(file != null)
		file.store_string(JSON.stringify({"cards": [definition]}))
		file.close()
		var invalid: CardDatabase = CardDatabase.new()
		assert(not invalid.load_from_file(fixture_path) and invalid.get_card_count() == 0)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path)) == OK)
	print("[PASS] Strict parameters, invalid data rejected without cost, no name-based dispatch")


static func _test_reentrant_notifications() -> void:
	var combat: CombatController = setup()
	var aoe: CardInstance = give(combat, 1, "gatling")
	var dodge: CardInstance = give(combat, 2, "dodge")
	var seen: Dictionary = {"discard_notifications": 0}
	var on_discard: Callable = func(_names: PackedStringArray) -> void:
		seen["discard_notifications"] += 1
		assert(not combat.respond_to_aoe(2).valid)
		assert(not combat.end_turn(1).valid)
	combat.game_state.zone_manager.cards_discarded.connect(on_discard)
	assert(combat.use_aoe(1, aoe.instance_id).valid)
	assert(combat.respond_to_aoe(2, dodge.instance_id).valid)
	assert(seen["discard_notifications"] == 2 and combat.get_pending_aoe()["target_id"] == 3)
	combat.game_state.zone_manager.cards_discarded.disconnect(on_discard)
	assert(combat.respond_to_aoe(3).valid and combat.respond_to_aoe(4).valid)
	assert(combat.game_state.validate_state())
	print("[PASS] Synchronous discard notification cannot reenter response or advance phase")
