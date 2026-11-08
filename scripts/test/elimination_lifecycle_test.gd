class_name EliminationLifecycleTest
extends RefCounted


static func run_all() -> void:
	_test_cleanup_and_reward()
	_test_rescue_and_no_credit()
	_test_aoe_and_final_kill()
	print("=== ALL ELIMINATION LIFECYCLE TESTS PASSED ===")


static func _test_cleanup_and_reward() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	var hand: CardInstance = AoeSystemTest.give(combat, 2, "heal")
	var weapon: CardInstance = AoeSystemTest.give(combat, 2, "crossbow")
	var judgment: CardInstance = AoeSystemTest.give(combat, 2, "dodge")
	assert(combat.game_state.transfer_player_card(weapon.instance_id, 2, "hand", 2, "equipment"))
	assert(combat.game_state.transfer_player_card(judgment.instance_id, 2, "hand", 2, "judgment"))
	assert(bool(combat.executor.validator.rule_engine.get_rule("attack_limit_per_turn", {}, RuleContext.new(2))["unlimited"]))
	var rewards: Array[int] = []
	combat.game_state.kill_reward_drawn.connect(func(source: int, victim: int, count: int) -> void:
		assert(source == 1 and victim == 2)
		rewards.append(count))
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 4))
	assert(combat.has_pending_dying() and combat.game_state.get_lethal_source(2) == 1)
	assert(combat.game_state.get_player(2).hand.has(hand) and rewards.is_empty())
	var before: int = combat.game_state.get_player(1).get_hand_count()
	var on_discard: Callable = func(_names: PackedStringArray) -> void:
		assert(not combat.finalize_dying().valid)
		assert(not combat.end_turn(1).valid)
	combat.game_state.zone_manager.cards_discarded.connect(on_discard)
	assert(combat.finalize_dying().valid)
	combat.game_state.zone_manager.cards_discarded.disconnect(on_discard)
	assert(combat.game_state.get_player(2).is_eliminated())
	for zone: String in ["hand", "equipment", "judgment"]:
		assert(combat.game_state.get_player(2).get_zone(zone).is_empty())
	for card: CardInstance in [hand, weapon, judgment]:
		assert(combat.game_state.deck.discard_pile.count(card) == 1)
	assert(combat.get_weapon(2) == null)
	assert(not bool(combat.executor.validator.rule_engine.get_rule("attack_limit_per_turn", {}, RuleContext.new(2))["unlimited"]))
	assert(rewards == [2] and combat.game_state.get_player(1).get_hand_count() == before + 2)
	assert(combat.game_state.get_lethal_source(2) == 0)
	assert(not combat.finalize_dying().valid and rewards == [2])
	assert(combat.game_state.validate_state())
	print("[PASS] All death zones to discard once, weapon detach, exact-once credited reward and reentry guard")


static func _test_rescue_and_no_credit() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	var heal: CardInstance = AoeSystemTest.give(combat, 2, "heal")
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 4))
	assert(combat.rescue_player(2, 2, heal.instance_id).valid)
	assert(combat.game_state.get_lethal_source(2) == 0 and combat.game_state.get_player(1).hand.is_empty())
	# Unknown subsequent damage must not reuse the previously rescued killer.
	assert(combat.executor.resolver.deal_damage(2, 1))
	assert(combat.finalize_dying().valid)
	assert(combat.game_state.get_player(1).hand.is_empty())
	combat = AoeSystemTest.setup()
	assert(combat.executor.resolver.deal_damage(2, 4, 2))
	assert(combat.finalize_dying().valid and combat.game_state.get_player(2).hand.is_empty())
	combat = AoeSystemTest.setup()
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 4))
	assert(combat.executor.resolver.deal_damage(1, 4))
	# Resolve the unknown-source death first, then the previously credited target.
	assert(combat.executor.dying_manager.begin_dying(1).valid)
	assert(combat.finalize_dying().valid)
	assert(combat.game_state.get_player(1).hand.is_empty())
	assert(combat.finalize_dying().valid)
	assert(combat.game_state.validate_state())
	print("[PASS] Rescue clears lethal credit; unknown/self/eliminated source receives no reward")


static func _test_aoe_and_final_kill() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	var aoe: CardInstance = AoeSystemTest.give(combat, 1, "gatling")
	for target: int in [2, 3, 4]:
		assert(combat.executor.resolver.deal_damage(target, 3))
	var rewards: Array[int] = []
	combat.game_state.kill_reward_drawn.connect(func(_source: int, victim: int, count: int) -> void:
		assert(count == 2)
		rewards.append(victim))
	assert(combat.use_aoe(1, aoe.instance_id).valid)
	for target: int in [2, 3, 4]:
		assert(combat.respond_to_aoe(target).valid)
		assert(combat.finalize_dying().valid)
	assert(rewards == [2, 3, 4] and combat.game_state.get_player(1).get_hand_count() == 6)
	assert(combat.game_state.match_over and combat.game_state.winner_id == 1)
	assert(combat.game_state.validate_state())
	# Empty draw pile recycles the victim's discarded cards without creating copies.
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	var victim_cards: Array[CardInstance] = [CardInstance.new(1, database.get_definition("heal"), CardInstance.Suit.HEARTS, 1)]
	var state: GameState = GameState.new(victim_cards, [Player.new(1, "P1", 4), Player.new(2, "P2", 4)])
	var rules: RuleEngine = RuleEngine.new()
	assert(rules.load_base_rules("res://data/rules/base_rules.json"))
	combat = CombatController.new(state, TurnManager.new(state), rules)
	combat.turn_manager.draw_count_per_turn = 0
	assert(combat.start_game().valid)
	assert(state.zone_manager.transfer_card(1, "draw", 0, "hand", 2))
	var counts: Array[int] = []
	state.kill_reward_drawn.connect(func(_source: int, _target: int, count: int) -> void: counts.append(count))
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 4))
	assert(combat.finalize_dying().valid)
	assert(counts == [1] and state.get_player(1).hand == victim_cards)
	assert(state.match_over and state.deck.shuffle_count == 2 and state.validate_state())
	print("[PASS] AOE per-victim credit, final-kill reward before match end, depleted-deck recycling without duplication")
