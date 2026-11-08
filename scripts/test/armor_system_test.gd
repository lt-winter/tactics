class_name ArmorSystemTest
extends RefCounted


class RefusingZone:
	extends CardZoneManager
	var refuse_cost: bool = false

	func transfer_cards(moves: Array[Dictionary]) -> bool:
		for move: Dictionary in moves:
			if refuse_cost and move["from_zone"] == "equipment" and move["to_zone"] == "discard":
				return false
		return super.transfer_cards(moves)


static func run_all() -> void:
	_test_equip_and_schema()
	_test_black_shield()
	_test_barrel()
	_test_helmet()
	_test_chainmail()
	_test_aoe_and_weapon_continuations()
	_test_interruptions_and_cost_failure()
	_test_legacy_damage_entry()
	print("=== ALL ARMOR SYSTEM TESTS PASSED ===")


static func equip(combat: CombatController, owner: int, armor_id: String) -> CardInstance:
	var armor: CardInstance = AoeSystemTest.give(combat, owner, armor_id)
	if owner == combat.turn_manager.get_current_player().player_id:
		assert(combat.equip_armor(owner, armor.instance_id).valid)
	else:
		assert(combat.game_state.zone_manager.transfer_card(armor.instance_id, "hand", owner, "equipment", owner))
	return armor


static func decide(combat: CombatController, activate: bool) -> ActionResult:
	var pending: Dictionary = combat.get_pending_armor()
	assert(not pending.is_empty())
	return combat.resolve_armor(int(pending["actor_id"]), int(pending["decision_id"]), activate)


static func attack(combat: CombatController, target: int = 2, suit: CardInstance.Suit = CardInstance.Suit.HEARTS) -> CardInstance:
	var card: CardInstance = AoeSystemTest.give(combat, 1, "attack")
	card.suit = suit
	assert(combat.use_attack(1, target, card.instance_id).valid)
	return card


static func _test_equip_and_schema() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	var weapon: CardInstance = AoeSystemTest.give(combat, 1, "crossbow")
	assert(combat.equip_weapon(1, weapon.instance_id).valid)
	var previous: CardInstance = null
	for armor_id: String in ["black_shield", "barrel", "helmet", "chainmail"]:
		var armor: CardInstance = AoeSystemTest.give(combat, 1, armor_id)
		assert(not combat.equip_armor(2, armor.instance_id).valid)
		assert(not combat.equip_weapon(1, armor.instance_id).valid)
		assert(combat.equip_armor(1, armor.instance_id).valid)
		assert(combat.get_defense(1) == armor and combat.get_weapon(1) == weapon)
		assert(combat.game_state.get_player(1).equipment.size() == 2)
		if previous != null:
			assert(combat.game_state.deck.discard_pile.count(previous) == 1)
		previous = armor
	assert(combat.game_state.validate_state())
	var definition: Dictionary = {"effect_id": "cap_incoming_damage", "parameters": {"threshold": true, "max_damage": 1, "trigger": "before_damage", "optional": false}}
	assert(not ArmorEffectRegistry.valid_effect(definition))
	definition["parameters"]["threshold"] = 1
	assert(ArmorEffectRegistry.valid_effect(definition))
	definition["parameters"]["optional"] = "false"
	assert(not ArmorEffectRegistry.valid_effect(definition))
	print("[PASS] Own PLAY equip/replace, independent weapon/armor slots, old armor discarded once, strict descriptors and integrity")


static func _test_black_shield() -> void:
	for suit: CardInstance.Suit in [CardInstance.Suit.SPADES, CardInstance.Suit.CLUBS, CardInstance.Suit.HEARTS, CardInstance.Suit.DIAMONDS]:
		var combat: CombatController = AoeSystemTest.setup()
		var armor: CardInstance = equip(combat, 2, "black_shield")
		armor.definition.id = "renamed_armor"
		var card: CardInstance = AoeSystemTest.give(combat, 1, "attack")
		card.suit = suit
		card.definition.id = "renamed_attack"
		assert(combat.use_attack(1, 2, card.instance_id).valid)
		if card.is_black():
			assert(not combat.has_pending_response() and combat.game_state.get_player(2).hp == 4)
		else:
			assert(combat.has_pending_response() and combat.respond_to_attack(2).valid)
			assert(combat.game_state.get_player(2).hp == 3)
		assert(combat.executor.attacks_used == 1 and combat.game_state.deck.discard_pile.count(card) == 1)
		assert(combat.game_state.validate_state())
	var combat: CombatController = WeaponSystemTest.setup("pistol")
	equip(combat, 2, "black_shield")
	var card: CardInstance = AoeSystemTest.give(combat, 1, "attack")
	card.suit = CardInstance.Suit.CLUBS
	assert(combat.use_attack_targets(1, [4, 2], card.instance_id).valid)
	assert(combat.executor.pending_attack["target_id"] == 4)
	assert(combat.respond_to_attack(4).valid)
	assert(combat.game_state.get_player(2).hp == 4 and combat.game_state.get_player(4).hp == 3)
	assert(combat.game_state.validate_state())
	combat = AoeSystemTest.setup()
	equip(combat, 2, "black_shield")
	var notifications: Dictionary = {"count": 0}
	var on_shield: Callable = func(_owner: int, _effect: String, _details: Dictionary) -> void:
		notifications["count"] += 1
		assert(not combat.get_status_message().is_empty())
		assert(not combat.respond_to_attack(2).valid)
		assert(not combat.end_turn(1).valid)
	combat.executor.damage_pipeline.armor_effects.effect_resolved.connect(on_shield)
	attack(combat, 2, CardInstance.Suit.SPADES)
	combat.executor.damage_pipeline.armor_effects.effect_resolved.disconnect(on_shield)
	assert(notifications["count"] == 1 and not combat.has_pending_response())
	print("[PASS] Original physical Attack color, renamed definitions, per-target Shield and independent Pistol continuation")


static func _test_barrel() -> void:
	for suit: CardInstance.Suit in [CardInstance.Suit.HEARTS, CardInstance.Suit.DIAMONDS, CardInstance.Suit.CLUBS, CardInstance.Suit.SPADES]:
		var combat: CombatController = AoeSystemTest.setup()
		equip(combat, 2, "barrel")
		var dodge: CardInstance = AoeSystemTest.give(combat, 2, "dodge")
		attack(combat)
		assert(not combat.has_pending_response())
		var judgment: CardInstance = combat.game_state.deck.draw_pile.back()
		judgment.suit = suit
		var count: int = combat.game_state.deck.get_draw_count()
		var pending: Dictionary = combat.get_pending_armor()
		assert(not combat.resolve_armor(1, int(pending["decision_id"]), true).valid)
		assert(not combat.end_turn(1).valid)
		assert(decide(combat, true).valid)
		assert(combat.game_state.deck.get_draw_count() == count - 1)
		assert(combat.game_state.deck.discard_pile.count(judgment) == 1)
		assert(not combat.resolve_armor(2, int(pending["decision_id"]), true).valid)
		if suit == CardInstance.Suit.HEARTS:
			assert(not combat.has_pending_response() and combat.game_state.get_player(2).hand.has(dodge))
		else:
			assert(combat.has_pending_response() and combat.respond_to_attack(2, dodge.instance_id).valid)
		assert(combat.game_state.get_player(2).hp == 4 and combat.game_state.validate_state())
	var combat: CombatController = AoeSystemTest.setup()
	equip(combat, 2, "barrel")
	var used: CardInstance = attack(combat)
	var count: int = combat.game_state.deck.get_draw_count()
	assert(decide(combat, false).valid and combat.has_pending_response())
	assert(combat.game_state.deck.get_draw_count() == count)
	assert(combat.respond_to_attack(2).valid and combat.game_state.get_player(2).hp == 3)
	# Controlled depletion: the already-paid Attack can itself be the judgment on reshuffle.
	combat = AoeSystemTest.setup()
	equip(combat, 2, "barrel")
	used = attack(combat)
	for card: CardInstance in combat.game_state.deck.draw_pile.duplicate():
		assert(combat.game_state.zone_manager.transfer_card(card.instance_id, "draw", 0, "hand", 3))
	assert(decide(combat, true).valid)
	assert(combat.game_state.deck.reshuffle_count == 1 and combat.game_state.deck.discard_pile.count(used) == 1)
	assert(combat.game_state.validate_state())
	combat = AoeSystemTest.setup()
	equip(combat, 2, "barrel")
	used = attack(combat)
	for card: CardInstance in combat.game_state.deck.draw_pile.duplicate():
		assert(combat.game_state.zone_manager.transfer_card(card.instance_id, "draw", 0, "hand", 3))
	assert(combat.game_state.zone_manager.transfer_card(used.instance_id, "discard", 0, "hand", 3))
	assert(not decide(combat, true).valid and not combat.get_pending_armor().is_empty())
	assert(decide(combat, false).valid and combat.has_pending_response())
	assert(combat.game_state.validate_state())
	print("[PASS] Barrel explicit once-only judgment, every suit, failed/declined Dodge fallback, reshuffle/empty-deck policy and identity")


static func _test_helmet() -> void:
	for kind: DamageContext.SourceKind in [DamageContext.SourceKind.ATTACK, DamageContext.SourceKind.AOE_TOOL, DamageContext.SourceKind.WEAPON_EFFECT, DamageContext.SourceKind.GENERIC]:
		var combat: CombatController = AoeSystemTest.setup()
		equip(combat, 2, "helmet")
		var result: Dictionary = combat.executor.damage_pipeline.process_damage_result(1, 2, 9, kind)
		assert(result["processed"] and result["applied_amount"] == 1)
		assert(combat.game_state.get_player(2).hp == 3 and not combat.has_pending_dying())
		assert(combat.get_pending_armor().is_empty() and combat.game_state.validate_state())
	var combat: CombatController = AoeSystemTest.setup()
	equip(combat, 2, "helmet")
	combat.executor.damage_pipeline.add_modifier(func(context: DamageContext) -> void: context.cancel_damage())
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 9))
	assert(combat.game_state.get_player(2).hp == 4)
	combat = AoeSystemTest.setup()
	assert(combat.executor.resolver.deal_damage(2, 3))
	equip(combat, 2, "helmet")
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 8))
	assert(combat.has_pending_dying() and combat.game_state.get_player(2).hp == 0)
	combat = AoeSystemTest.setup()
	var helmet: CardInstance = equip(combat, 2, "helmet")
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 3))
	var tool: CardInstance = AoeSystemTest.give(combat, 1, "steal")
	assert(combat.use_tool(1, 2, tool.instance_id, helmet.instance_id, "equipment").valid)
	assert(combat.get_defense(2) == null and combat.game_state.get_player(1).hand.has(helmet))
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 3))
	assert(combat.game_state.get_player(2).hp == 0 and combat.has_pending_dying())
	print("[PASS] Helmet caps every pipeline source after modifiers, cancellation remains zero and no false Dying")


static func _test_chainmail() -> void:
	for activate: bool in [true, false]:
		var combat: CombatController = AoeSystemTest.setup()
		assert(combat.executor.resolver.deal_damage(2, 3))
		var armor: CardInstance = equip(combat, 2, "chainmail")
		attack(combat)
		assert(combat.respond_to_attack(2).valid)
		assert(combat.game_state.get_player(2).hp == 1 and not combat.has_pending_dying())
		var pending: Dictionary = combat.get_pending_armor()
		assert(pending["effect_id"] == "prevent_lethal_damage")
		assert(not combat.end_turn(1).valid and not combat.advance_phase().valid)
		combat.turn_manager.advance_phase()
		assert(combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
		assert(decide(combat, activate).valid)
		assert(not combat.resolve_armor(2, int(pending["decision_id"]), activate).valid)
		if activate:
			assert(combat.game_state.get_player(2).hp == 1 and combat.get_defense(2) == null)
			assert(combat.game_state.deck.discard_pile.count(armor) == 1 and not combat.has_pending_dying())
		else:
			assert(combat.game_state.get_player(2).hp == 0 and combat.has_pending_dying())
			assert(combat.get_defense(2) == armor)
		assert(combat.game_state.validate_state())
	var combat: CombatController = AoeSystemTest.setup()
	assert(combat.executor.resolver.deal_damage(2, 2))
	equip(combat, 2, "chainmail")
	combat.executor.damage_pipeline.add_modifier(func(context: DamageContext) -> void: context.reduce_damage(4))
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 5))
	assert(combat.game_state.get_player(2).hp == 1 and combat.get_pending_armor().is_empty())
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 4))
	assert(combat.get_pending_armor().is_empty())
	print("[PASS] Chainmail offers only post-reduction lethal damage, exact self-cost before prevention, decline/Dying and replay guards")


static func _test_aoe_and_weapon_continuations() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	assert(combat.executor.resolver.deal_damage(2, 3))
	equip(combat, 2, "chainmail")
	equip(combat, 3, "helmet")
	equip(combat, 4, "black_shield")
	var tool: CardInstance = AoeSystemTest.give(combat, 1, "gatling")
	tool.definition.effects[0]["parameters"]["damage"] = 2
	assert(combat.use_aoe(1, tool.instance_id).valid and combat.respond_to_aoe(2).valid)
	assert(combat.get_pending_aoe()["target_id"] == 2 and not combat.respond_to_aoe(2).valid)
	assert(decide(combat, true).valid and combat.get_pending_aoe()["target_id"] == 3)
	assert(combat.respond_to_aoe(3).valid and combat.game_state.get_player(3).hp == 3)
	assert(combat.respond_to_aoe(4).valid and combat.game_state.get_player(4).hp == 2)
	assert(not combat.has_pending_aoe() and combat.executor.attacks_used == 0)
	assert(combat.game_state.validate_state())
	combat = AoeSystemTest.setup()
	assert(combat.executor.resolver.deal_damage(2, 3))
	equip(combat, 2, "chainmail")
	tool = AoeSystemTest.give(combat, 1, "gatling")
	assert(combat.use_aoe(1, tool.instance_id).valid and combat.respond_to_aoe(2).valid)
	assert(decide(combat, false).valid and combat.has_pending_dying())
	assert(combat.get_pending_aoe()["target_id"] == 2)
	var heal: CardInstance = AoeSystemTest.give(combat, 3, "heal")
	assert(combat.rescue_player(3, 2, heal.instance_id).valid)
	assert(combat.get_pending_aoe()["target_id"] == 3)
	assert(combat.respond_to_aoe(3).valid and combat.respond_to_aoe(4).valid)
	assert(not combat.has_pending_aoe() and combat.game_state.get_player(2).hp == 1)
	assert(combat.game_state.validate_state())
	combat = WeaponSystemTest.setup("slingshot")
	assert(combat.executor.resolver.deal_damage(3, 3))
	equip(combat, 3, "chainmail")
	var cost: CardInstance = AoeSystemTest.give(combat, 1, "dodge")
	attack(combat)
	assert(combat.respond_to_attack(2).valid)
	assert(WeaponSystemTest.choose(combat, true, [cost.instance_id], 3).valid)
	assert(combat.get_pending_armor()["source_kind"] == DamageContext.SourceKind.WEAPON_EFFECT)
	assert(decide(combat, true).valid and combat.game_state.get_player(3).hp == 1)
	assert(combat.get_pending_weapon().is_empty() and combat.executor.attacks_used == 1)
	assert(combat.game_state.deck.discard_pile.count(cost) == 1 and combat.game_state.validate_state())
	combat = WeaponSystemTest.setup("butchers_knife")
	assert(combat.executor.resolver.deal_damage(2, 3))
	equip(combat, 2, "chainmail")
	var victim: CardInstance = AoeSystemTest.give(combat, 2, "dodge")
	attack(combat)
	assert(combat.respond_to_attack(2).valid and combat.get_pending_armor().is_empty())
	assert(WeaponSystemTest.choose(combat, true, [victim.instance_id]).valid)
	assert(combat.game_state.get_player(2).hp == 1 and combat.get_pending_armor().is_empty())
	assert(combat.get_defense(2) != null and combat.game_state.validate_state())
	print("[PASS] AOE cursor waits for armor, Helmet/Shield source boundaries, weapon child damage and Knife replacement ordering")


static func _test_interruptions_and_cost_failure() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	assert(combat.executor.resolver.deal_damage(2, 3))
	var armor: CardInstance = equip(combat, 2, "chainmail")
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 1))
	var pending: Dictionary = combat.get_pending_armor()
	# Fixture-only external state interruption; public damage entry is correctly locked by pending armor.
	assert(not combat.executor.resolver.deal_damage(3, 4))
	assert(combat.executor.resolver._apply_damage(3, 4))
	assert(not decide(combat, true).valid)
	var heal: CardInstance = AoeSystemTest.give(combat, 4, "heal")
	assert(combat.rescue_player(4, 3, heal.instance_id).valid)
	# Removing/re-equipping the same armor invalidates the old decision; lethal fallback opens Dying before any phase can advance.
	assert(combat.game_state.discard_card(2, armor.instance_id, "equipment"))
	assert(combat.game_state.zone_manager.transfer_card(armor.instance_id, "discard", 0, "equipment", 2))
	assert(not combat.advance_phase().valid and combat.has_pending_dying())
	assert(combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
	assert(not combat.resolve_armor(2, int(pending["decision_id"]), true).valid)
	# A real transfer failure must neither discard the armor nor prevent/pay the hit.
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	var cards: Array[CardInstance] = [CardInstance.new(1, database.get_definition("attack"), CardInstance.Suit.HEARTS, 1), CardInstance.new(2, database.get_definition("chainmail"), CardInstance.Suit.CLUBS, 2)]
	var players: Array[Player] = [Player.new(1, "P1", 4), Player.new(2, "P2", 1), Player.new(3, "P3", 4)]
	var state: GameState = GameState.new(cards, players)
	var zones: RefusingZone = RefusingZone.new(state.deck, players)
	state.zone_manager = zones
	var rules: RuleEngine = RuleEngine.new()
	assert(rules.load_base_rules("res://data/rules/base_rules.json"))
	var turns: TurnManager = TurnManager.new(state, [1, 2, 3], rules)
	turns.draw_count_per_turn = 0
	combat = CombatController.new(state, turns, rules)
	assert(combat.start_game().valid)
	assert(zones.transfer_card(2, "draw", 0, "equipment", 2))
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 1))
	zones.refuse_cost = true
	assert(not decide(combat, true).valid and state.get_player(2).hp == 1)
	assert(combat.get_defense(2) == cards[1] and not combat.get_pending_armor().is_empty())
	zones.refuse_cost = false
	assert(decide(combat, true).valid and state.get_player(2).hp == 1)
	assert(state.deck.discard_pile.count(cards[1]) == 1 and state.validate_state())
	print("[PASS] Dying priority, armor generation invalidation, lethal resume guard and failed self-discard remain transactional")


static func _test_legacy_damage_entry() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	equip(combat, 2, "helmet")
	var calls: Dictionary = {"count": 0}
	combat.executor.damage_pipeline.add_modifier(func(context: DamageContext) -> void:
		calls["count"] += 1
		context.increase_damage(4)
	)
	assert(combat.executor.resolver.deal_damage(2, 8))
	assert(combat.game_state.get_player(2).hp == 3 and calls["count"] == 0)
	assert(combat.executor.damage_pipeline.process_damage(1, 2, 3))
	assert(combat.game_state.get_player(2).hp == 2 and calls["count"] == 1)
	combat = AoeSystemTest.setup()
	assert(combat.executor.resolver.deal_damage(2, 3))
	equip(combat, 2, "chainmail")
	assert(combat.executor.resolver.deal_damage(2, 1))
	assert(combat.game_state.get_player(2).hp == 1 and combat.get_pending_armor()["source_id"] == 0)
	assert(decide(combat, true).valid and combat.game_state.get_player(2).hp == 1)
	assert(not combat.has_pending_dying() and combat.game_state.validate_state())
	print("[PASS] Legacy resolved-damage API respects armor and unknown source credit without repeating modifiers")
