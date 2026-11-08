class_name SupportToolsTest
extends RefCounted


static func run_all() -> void:
	_test_draw_and_exchange()
	_test_exchange_can_discard_equipment()
	_test_reshuffle_and_exhaustion()
	_test_saloon()
	_test_restrictions()
	_test_schema_and_reentry()
	print("=== ALL SUPPORT TOOLS TESTS PASSED ===")


static func _test_exchange_can_discard_equipment() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	var exchange: CardInstance = _give(combat, 1, "exchange")
	var weapon: CardInstance = _give(combat, 1, "crossbow")
	assert(combat.equip_weapon(1, weapon.instance_id).valid)
	assert(combat.get_weapon(1) == weapon)
	assert(combat.use_support_tool(1, exchange.instance_id).valid)
	assert(combat.has_pending_support())
	var pending: Dictionary = combat.get_pending_support()
	assert(pending["discard_zones"].has("equipment"))
	var hand_card: CardInstance = combat.game_state.get_player(1).hand[0]
	var foreign: CardInstance = _give(combat, 2, "rifle")
	var judgment: CardInstance = _give(combat, 1, "dodge")
	assert(combat.game_state.zone_manager.transfer_card(judgment.instance_id, "hand", 1, "judgment", 1))
	assert(not combat.discard_for_support(1, [weapon.instance_id, weapon.instance_id]).valid)
	assert(not combat.discard_for_support(1, [weapon.instance_id, foreign.instance_id]).valid)
	assert(not combat.discard_for_support(1, [weapon.instance_id, judgment.instance_id]).valid)
	assert(combat.get_weapon(1) == weapon and combat.game_state.get_player(1).hand.has(hand_card))
	pending["discard_zones"].clear()
	assert(combat.get_pending_support()["discard_zones"] == ["hand", "equipment"])
	assert(combat.discard_for_support(1, [weapon.instance_id, hand_card.instance_id]).valid)
	assert(combat.get_weapon(1) == null)
	var limit: Dictionary = combat.executor.validator.rule_engine.get_rule("attack_limit_per_turn", {}, RuleContext.new(1))
	assert(not limit["unlimited"] and int(limit["value"]) == 1)
	assert(combat.game_state.deck.discard_pile.count(weapon) == 1)
	assert(combat.game_state.validate_state())
	assert(not combat.discard_for_support(1, [weapon.instance_id, hand_card.instance_id]).valid)
	# Preflight must count equipment when the draw pile cannot supply two cards.
	combat = _small("exchange", 2)
	# Use owned hand/equipment fixtures without creating any additional instance.
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	for remaining: CardInstance in combat.game_state.deck.draw_pile:
		remaining.definition = database.get_definition("crossbow" if remaining.instance_id == 2 else "dodge")
	assert(combat.game_state.zone_manager.transfer_card(2, "draw", 0, "hand", 1))
	assert(combat.game_state.zone_manager.transfer_card(3, "draw", 0, "hand", 1))
	assert(combat.equip_weapon(1, 2).valid)
	assert(combat.use_support_tool(1, 1).valid)
	assert(combat.discard_for_support(1, [2, 3]).valid)
	assert(combat.game_state.validate_state())
	print("[PASS] Exchange hand/equipment, atomic rejection, foreign/judgment/duplicate/replay guards and depleted-deck preflight")


static func _give(combat: CombatController, owner: int, definition_id: String) -> CardInstance:
	return AoeSystemTest.give(combat, owner, definition_id)


static func _test_draw_and_exchange() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	var draw: CardInstance = _give(combat, 1, "draw_2")
	draw.definition.id = "renamed_support"
	assert(combat.use_support_tool(1, draw.instance_id).valid)
	assert(combat.game_state.get_player(1).get_hand_count() == 2)
	assert(combat.game_state.deck.discard_pile.count(draw) == 1 and not combat.has_pending_support())
	assert(not combat.use_support_tool(1, draw.instance_id).valid)
	var exchange: CardInstance = _give(combat, 1, "exchange")
	var previous: int = combat.game_state.get_player(1).get_hand_count()
	assert(combat.use_support_tool(1, exchange.instance_id).valid)
	assert(combat.game_state.get_player(1).get_hand_count() == previous + 2)
	assert(combat.game_state.deck.discard_pile.count(exchange) == 1)
	assert(combat.has_pending_support())
	var snapshot: Dictionary = combat.get_pending_support()
	snapshot["discard_count"] = 99
	assert(combat.get_pending_support()["discard_count"] == 2)
	var hand: Array[CardInstance] = combat.game_state.get_player(1).hand.duplicate()
	var first_id: int = hand[0].instance_id
	var second_id: int = hand[1].instance_id
	assert(not combat.discard_for_support(2, [first_id, second_id]).valid)
	assert(not combat.discard_for_support(1, [first_id]).valid)
	assert(not combat.discard_for_support(1, [first_id, first_id]).valid)
	assert(not combat.discard_for_support(1, [first_id, exchange.instance_id]).valid)
	assert(combat.game_state.get_player(1).get_hand_count() == previous + 2)
	assert(combat.game_state.transfer_player_card(second_id, 1, "hand", 2, "hand"))
	assert(not combat.discard_for_support(1, [first_id, second_id]).valid)
	assert(combat.game_state.get_player(1).hand.has(hand[0]))
	second_id = combat.game_state.get_player(1).hand[1].instance_id
	assert(combat.discard_for_support(1, [first_id, second_id]).valid)
	assert(not combat.has_pending_support() and not combat.discard_for_support(1, [first_id, second_id]).valid)
	assert(combat.executor.attacks_used == 0 and combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
	assert(combat.game_state.validate_state())
	print("[PASS] Draw 2, Exchange draw 3, exact atomic discard choice, stale/duplicate/wrong-owner rejection, snapshot and card integrity")


static func _small(definition_id: String, extra_cards: int, player_count: int = 2) -> CombatController:
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	var cards: Array[CardInstance] = [CardInstance.new(1, database.get_definition(definition_id), CardInstance.Suit.HEARTS, 1)]
	for index: int in range(extra_cards):
		cards.append(CardInstance.new(index + 2, database.get_definition("attack"), CardInstance.Suit.CLUBS, index % 13 + 1))
	var players: Array[Player] = []
	for player_id: int in range(1, player_count + 1):
		players.append(Player.new(player_id, "P%d" % player_id, 4))
	var state: GameState = GameState.new(cards, players)
	var rules: RuleEngine = RuleEngine.new()
	assert(rules.load_base_rules("res://data/rules/base_rules.json"))
	var turns: TurnManager = TurnManager.new(state, [], rules)
	turns.draw_count_per_turn = 0
	var combat: CombatController = CombatController.new(state, turns, rules)
	assert(combat.start_game().valid)
	assert(state.zone_manager.transfer_card(1, "draw", 0, "hand", 1))
	return combat


static func _test_reshuffle_and_exhaustion() -> void:
	var combat: CombatController = _small("draw_2", 2)
	assert(combat.game_state.zone_manager.transfer_card(2, "draw", 0, "discard", 0))
	var shuffles: int = combat.game_state.deck.shuffle_count
	assert(combat.use_support_tool(1, 1).valid)
	assert(combat.game_state.get_player(1).get_hand_count() == 2)
	assert(combat.game_state.deck.shuffle_count == shuffles + 1)
	assert(combat.game_state.deck.get_discard_count() == 1 and combat.game_state.deck.discard_pile[0].instance_id == 1)
	assert(combat.game_state.validate_state())
	for available: int in [0, 1]:
		combat = _small("draw_2", available)
		assert(combat.use_support_tool(1, 1).valid)
		assert(combat.game_state.get_player(1).get_hand_count() == available)
		assert(combat.game_state.deck.get_discard_count() == 1)
		assert(combat.game_state.validate_state())
	combat = _small("exchange", 1)
	assert(not combat.use_support_tool(1, 1).valid)
	assert(combat.game_state.get_player(1).get_hand_count() == 1 and combat.game_state.deck.get_draw_count() == 1)
	combat = _small("exchange", 2)
	assert(combat.use_support_tool(1, 1).valid and combat.has_pending_support())
	assert(combat.game_state.get_player(1).get_hand_count() == 2)
	assert(combat.discard_for_support(1, [2, 3]).valid)
	assert(combat.game_state.deck.get_discard_count() == 3 and combat.game_state.validate_state())
	combat = _small("exchange", 3)
	assert(combat.game_state.zone_manager.transfer_card(2, "draw", 0, "discard", 0))
	assert(combat.game_state.zone_manager.transfer_card(3, "draw", 0, "discard", 0))
	assert(combat.use_support_tool(1, 1).valid)
	assert(combat.game_state.get_player(1).get_hand_count() == 3 and combat.game_state.deck.shuffle_count == 2)
	assert(combat.discard_for_support(1, [2, 3]).valid and combat.game_state.validate_state())
	print("[PASS] Existing reshuffle, zero/partial draws, source excluded from own draw, depleted Exchange preflight and finite conservation")


static func _test_saloon() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	assert(combat.executor.resolver.deal_damage(1, 2))
	assert(combat.executor.resolver.deal_damage(2, 1))
	assert(combat.executor.resolver.deal_damage(4, 4))
	assert(combat.finalize_dying().valid)
	var saloon: CardInstance = _give(combat, 1, "saloon")
	assert(not combat.executor.validator.validate_heal_card(1, saloon.instance_id).valid)
	assert(combat.use_support_tool(1, saloon.instance_id).valid)
	assert(combat.game_state.get_player(1).hp == 3 and combat.game_state.get_player(2).hp == 4 and combat.game_state.get_player(3).hp == 4)
	assert(combat.game_state.get_player(4).is_eliminated() and combat.game_state.get_player(4).hp == 0)
	saloon = _give(combat, 1, "saloon")
	assert(combat.use_support_tool(1, saloon.instance_id).valid and combat.game_state.get_player(1).hp == 4)
	saloon = _give(combat, 1, "saloon")
	assert(combat.use_support_tool(1, saloon.instance_id).valid, "All-full Saloon remains usable")
	assert(combat.game_state.deck.discard_pile.count(saloon) == 1)
	assert(combat.game_state.validate_state())
	print("[PASS] Saloon includes source/all living, heals exactly 1 to max, skips eliminated, all-full use, no Rescue classification")
	combat = _small("saloon", 0, 6)
	for player_id: int in range(1, 7):
		assert(combat.executor.resolver.deal_damage(player_id, 1))
	assert(combat.use_support_tool(1, 1).valid)
	for player: Player in combat.game_state.players:
		assert(player.hp == 4)
	assert(combat.game_state.validate_state())


static func _test_restrictions() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	var draw: CardInstance = _give(combat, 1, "draw_2")
	var saloon: CardInstance = _give(combat, 1, "saloon")
	var exchange: CardInstance = _give(combat, 1, "exchange")
	var attack: CardInstance = _give(combat, 1, "attack")
	var weapon: CardInstance = _give(combat, 1, "crossbow")
	var heal: CardInstance = _give(combat, 1, "heal")
	var aoe: CardInstance = _give(combat, 1, "gatling")
	var tool: CardInstance = _give(combat, 1, "discard")
	assert(not combat.use_support_tool(2, draw.instance_id).valid)
	combat.turn_manager.set_phase_wait(TurnManager.Phase.PLAY, "Fixture decision")
	assert(not combat.use_support_tool(1, draw.instance_id).valid)
	combat.turn_manager.set_phase_wait(TurnManager.Phase.PLAY, "")
	assert(combat.use_attack(1, 2, attack.instance_id).valid)
	assert(not combat.use_support_tool(1, draw.instance_id).valid)
	assert(combat.respond_to_attack(2).valid)
	assert(combat.use_aoe(1, aoe.instance_id).valid)
	assert(not combat.use_support_tool(1, draw.instance_id).valid)
	for target: int in [2, 3, 4]:
		assert(combat.respond_to_aoe(target).valid)
	assert(combat.executor.resolver.deal_damage(2, 4))
	assert(not combat.use_support_tool(1, draw.instance_id).valid)
	assert(not combat.use_support_tool(1, saloon.instance_id).valid)
	assert(not combat.rescue_player(1, 2, saloon.instance_id).valid)
	assert(combat.finalize_dying().valid)
	assert(combat.use_support_tool(1, exchange.instance_id).valid)
	assert(not combat.use_support_tool(1, draw.instance_id).valid)
	assert(not combat.equip_weapon(1, weapon.instance_id).valid and not combat.use_heal(1, heal.instance_id).valid)
	assert(not combat.use_tool(1, 3, tool.instance_id, 0, "hand").valid)
	assert(not combat.end_turn(1).valid and not combat.advance_until_decision().valid)
	combat.turn_manager.advance_phase()
	combat.turn_manager.start_game()
	assert(combat.turn_manager.turn_number == 1 and combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
	assert(combat.executor.resolver.deal_damage(3, 4))
	assert(not combat.discard_for_support(1, [draw.instance_id, heal.instance_id]).valid)
	assert(combat.finalize_dying().valid)
	assert(combat.has_pending_support())
	assert(combat.discard_for_support(1, [draw.instance_id, heal.instance_id]).valid)
	assert(combat.end_turn(1).valid)
	assert(not combat.use_support_tool(1, saloon.instance_id).valid)
	assert(combat.game_state.validate_state())
	combat = AoeSystemTest.setup()
	exchange = _give(combat, 1, "exchange")
	assert(combat.use_support_tool(1, exchange.instance_id).valid)
	assert(combat.executor.resolver.deal_damage(1, 4))
	assert(combat.finalize_dying().valid)
	assert(not combat.has_pending_support() and combat.turn_manager.get_current_player().player_id == 2)
	assert(combat.game_state.validate_state())
	combat = AoeSystemTest.setup()
	saloon = _give(combat, 1, "saloon")
	for target: int in [2, 3, 4]:
		assert(combat.executor.resolver.deal_damage(target, 4))
		assert(combat.finalize_dying().valid)
	assert(combat.game_state.match_over and not combat.use_support_tool(1, saloon.instance_id).valid)
	assert(combat.game_state.get_player(1).hand.has(saloon))
	print("[PASS] Own PLAY, ownership, effect waits, Attack/AOE/Dying, no Saloon rescue, Exchange decision and direct phase guards")


static func _test_schema_and_reentry() -> void:
	for zones: Variant in [["hand", "hand"], ["judgment"], [], "equipment", [1]]:
		assert(not SupportToolResolution.valid_effect({"effect_id": "draw_cards", "parameters": {"count": 3, "discard_count": 2, "discard_zones": zones}}))
	for bad: Variant in [0, -1, 1.5, true, "2", null, INF, NAN]:
		assert(not SupportToolResolution.valid_effect({"effect_id": "draw_cards", "parameters": {"count": bad}}))
	assert(not SupportToolResolution.valid_effect({"effect_id": "heal_all_players", "parameters": {"amount": 2}}))
	assert(not SupportToolResolution.valid_effect({"effect_id": "draw_cards", "parameters": {"count": 3, "discard_count": -1}}))
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	var fixture: String = "res://__support_schema_%d.json" % Time.get_ticks_usec()
	for bad: Variant in [0, true, "3", null, 1.5]:
		var definition: Dictionary = database.get_card("exchange")
		definition["effects"][0]["parameters"]["count"] = bad
		var file: FileAccess = FileAccess.open(fixture, FileAccess.WRITE)
		assert(file != null)
		file.store_string(JSON.stringify({"cards": [definition]}))
		file.close()
		var invalid: CardDatabase = CardDatabase.new()
		assert(not invalid.load_from_file(fixture) and invalid.get_card_count() == 0)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture)) == OK)
	var combat: CombatController = AoeSystemTest.setup()
	var draw: CardInstance = _give(combat, 1, "draw_2")
	var heal: CardInstance = _give(combat, 1, "saloon")
	var calls: Dictionary = {"count": 0}
	var on_discard: Callable = func(_names: PackedStringArray) -> void:
		calls["count"] += 1
		assert(not combat.use_support_tool(1, heal.instance_id).valid)
		assert(not combat.end_turn(1).valid)
	combat.game_state.zone_manager.cards_discarded.connect(on_discard)
	assert(combat.use_support_tool(1, draw.instance_id).valid)
	combat.game_state.zone_manager.cards_discarded.disconnect(on_discard)
	assert(calls["count"] == 1 and combat.game_state.get_player(1).hand.has(heal))
	# Reject use entered from an unrelated transfer notification before any HP changes.
	assert(combat.executor.resolver.deal_damage(1, 1))
	var discarded: CardInstance = _give(combat, 1, "attack")
	var hp_before: int = combat.game_state.get_player(1).hp
	var external_discard: Callable = func(_names: PackedStringArray) -> void:
		assert(not combat.use_support_tool(1, heal.instance_id).valid)
	combat.game_state.zone_manager.cards_discarded.connect(external_discard)
	assert(combat.game_state.discard_card(1, discarded.instance_id))
	combat.game_state.zone_manager.cards_discarded.disconnect(external_discard)
	assert(combat.game_state.get_player(1).hp == hp_before and combat.game_state.get_player(1).hand.has(heal))
	assert(combat.game_state.validate_state())
	print("[PASS] Strict effect parameters and synchronous notification reentry without extra payment/healing")
