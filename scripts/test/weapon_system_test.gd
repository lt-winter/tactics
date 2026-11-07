class_name WeaponSystemTest
extends RefCounted


static func run_all() -> void:
	_test_pistol()
	_test_pistol_dying()
	_test_knife()
	_test_rifle()
	_test_slingshot()
	_test_guards_and_lifetime()
	_test_interruption_and_reentry()
	print("=== ALL WEAPON SYSTEM TESTS PASSED ===")


static func setup(weapon_id: String) -> CombatController:
	var combat: CombatController = AoeSystemTest.setup()
	var weapon: CardInstance = AoeSystemTest.give(combat, 1, weapon_id)
	assert(combat.equip_weapon(1, weapon.instance_id).valid)
	return combat


static func attack(combat: CombatController, target_id: int = 2) -> CardInstance:
	var card: CardInstance = AoeSystemTest.give(combat, 1, "attack")
	assert(combat.use_attack(1, target_id, card.instance_id).valid)
	assert(combat.respond_to_attack(target_id).valid)
	return card


static func choose(combat: CombatController, activate: bool, cards: Array[int] = [], target_id: int = 0) -> ActionResult:
	var decision: Dictionary = combat.get_pending_weapon()
	assert(not decision.is_empty())
	return combat.resolve_weapon(1, int(decision["decision_id"]), activate, cards, target_id)


static func _test_pistol() -> void:
	var combat: CombatController = setup("pistol")
	var card: CardInstance = AoeSystemTest.give(combat, 1, "attack")
	for candidate_targets: Array in [[], [2, 2], [1, 2], [2, 3, 4], [2, 999]]:
		var targets: Array[int] = []
		targets.assign(candidate_targets)
		assert(not combat.use_attack_targets(1, targets, card.instance_id).valid)
	assert(combat.executor.attacks_used == 0 and combat.game_state.get_player(1).hand.has(card))
	assert(combat.use_attack_targets(1, [4, 2], card.instance_id).valid)
	assert(combat.executor.pending_attack["target_id"] == 2)
	assert(not combat.respond_to_attack(4).valid)
	var dodge: CardInstance = AoeSystemTest.give(combat, 2, "dodge")
	assert(combat.respond_to_attack(2, dodge.instance_id).valid)
	assert(combat.executor.pending_attack["target_id"] == 4)
	assert(combat.respond_to_attack(4).valid)
	assert(combat.game_state.get_player(2).hp == 4 and combat.game_state.get_player(4).hp == 3)
	assert(combat.executor.attacks_used == 1 and combat.game_state.deck.discard_pile.count(card) == 1)
	assert(combat.executor.attack_resolution.get_context()["target_ids"] == [2, 4])
	assert(not combat.has_pending_response() and combat.game_state.validate_state())
	# Start the cycle from seat 3 rather than sorting by numeric IDs or click order.
	combat = AoeSystemTest.setup([3, 1, 4, 2])
	var weapon: CardInstance = AoeSystemTest.give(combat, 3, "pistol")
	card = AoeSystemTest.give(combat, 3, "attack")
	assert(combat.equip_weapon(3, weapon.instance_id).valid)
	assert(combat.use_attack_targets(3, [2, 1], card.instance_id).valid)
	assert(combat.executor.pending_attack["target_id"] == 1)
	assert(combat.respond_to_attack(1).valid and combat.respond_to_attack(2).valid)
	# Each target retains range validation before a single card is paid.
	combat = setup("pistol")
	card = AoeSystemTest.give(combat, 1, "attack")
	combat.executor.validator.rule_engine.add_modifier(RuleModifier.new("attack_range", "set", 1, RuleModifier.Source.CHARACTER_SKILL, "fixture_range", 1))
	assert(not combat.use_attack_targets(1, [2, 3], card.instance_id).valid)
	assert(combat.game_state.get_player(1).hand.has(card))
	print("[PASS] Pistol one payment/count, independent responses, cyclic seat order and atomic per-target validation")


static func _test_pistol_dying() -> void:
	for rescue: bool in [true, false]:
		var combat: CombatController = setup("pistol")
		var card: CardInstance = AoeSystemTest.give(combat, 1, "attack")
		var heal: CardInstance = AoeSystemTest.give(combat, 1, "heal")
		assert(combat.executor.resolver.deal_damage(2, 3))
		assert(combat.use_attack_targets(1, [4, 2], card.instance_id).valid)
		assert(combat.respond_to_attack(2).valid and combat.has_pending_dying())
		assert(not combat.respond_to_attack(4).valid and not combat.end_turn(1).valid)
		var weapon: CardInstance = combat.get_weapon(1)
		assert(combat.game_state.zone_manager.transfer_card(weapon.instance_id, "equipment", 1, "discard", 0))
		if rescue:
			assert(combat.rescue_player(1, 2, heal.instance_id).valid)
		else:
			assert(combat.finalize_dying().valid)
		assert(combat.executor.pending_attack["target_id"] == 4)
		assert(combat.respond_to_attack(4).valid and combat.game_state.get_player(4).hp == 3)
		assert(combat.executor.attacks_used == 1 and combat.game_state.validate_state())
	print("[PASS] Multi-target cursor survives rescue/elimination and loss of declared weapon without repeated payment")


static func _test_knife() -> void:
	for count: int in [0, 1, 2, 3]:
		var combat: CombatController = setup("butchers_knife")
		var cards: Array[int] = []
		for index: int in range(count):
			cards.append(AoeSystemTest.give(combat, 2, "dodge").instance_id)
		var modifiers_called: Dictionary = {"count": 0}
		combat.executor.damage_pipeline.add_modifier(func(context: DamageContext) -> void:
			modifiers_called["count"] += 1
			context.cancel_damage()
		)
		attack(combat)
		if count == 0:
			assert(combat.get_pending_weapon().is_empty() and modifiers_called["count"] == 1)
		else:
			assert(modifiers_called["count"] == 0, "Knife choice occurs before prevention")
			var selected: Array[int] = []
			for index: int in range(mini(count, 2)):
				selected.append(cards[index])
			assert(choose(combat, true, selected).valid)
			assert(modifiers_called["count"] == 0 and combat.game_state.get_player(2).get_hand_count() == maxi(0, count - 2))
		assert(combat.game_state.get_player(2).hp == 4 and combat.game_state.validate_state())
	var combat: CombatController = setup("butchers_knife")
	AoeSystemTest.give(combat, 2, "dodge")
	attack(combat)
	assert(choose(combat, false).valid and combat.game_state.get_player(2).hp == 3)
	assert(combat.game_state.get_player(2).get_hand_count() == 1)
	print("[PASS] Knife chooses before modifiers; zero/one/two cards, replacement excludes HP damage, normal-damage decline")


static func _test_rifle() -> void:
	for outcome: String in ["normal", "rescued", "eliminated", "prevented"]:
		var combat: CombatController = setup("rifle")
		var weapon: CardInstance = AoeSystemTest.give(combat, 2, "crossbow")
		assert(combat.game_state.zone_manager.transfer_card(weapon.instance_id, "hand", 2, "equipment", 2))
		if outcome in ["rescued", "eliminated"]:
			assert(combat.executor.resolver.deal_damage(2, 3))
		if outcome == "prevented":
			combat.executor.damage_pipeline.add_modifier(func(context: DamageContext) -> void: context.cancel_damage())
		attack(combat)
		if outcome == "rescued":
			assert(combat.get_pending_weapon().is_empty() and combat.has_pending_dying())
			var heal: CardInstance = AoeSystemTest.give(combat, 1, "heal")
			assert(combat.rescue_player(1, 2, heal.instance_id).valid)
		elif outcome == "eliminated":
			assert(combat.finalize_dying().valid)
		if outcome in ["normal", "rescued"]:
			assert(choose(combat, true, [weapon.instance_id]).valid)
			assert(combat.get_weapon(2) == null)
			var rule: Dictionary = combat.executor.validator.rule_engine.get_rule("attack_limit_per_turn", {}, RuleContext.new(2))
			assert(not rule["unlimited"])
		else:
			assert(combat.get_pending_weapon().is_empty())
		assert(combat.game_state.validate_state())
	var combat: CombatController = setup("rifle")
	attack(combat)
	assert(combat.get_pending_weapon().is_empty())
	print("[PASS] Rifle actual-damage gating, chosen equipment, synchronous modifier detach, rescue continuation and elimination skip")


static func _test_slingshot() -> void:
	for cancelled: bool in [true, false]:
		var combat: CombatController = setup("slingshot")
		var cost: CardInstance = AoeSystemTest.give(combat, 1, "dodge")
		var observed: Array[int] = []
		combat.executor.damage_pipeline.add_modifier(func(context: DamageContext) -> void:
			observed.append(context.source_kind)
			if cancelled and context.source_kind == DamageContext.SourceKind.WEAPON_EFFECT:
				context.cancel_damage()
		)
		attack(combat)
		var decision: Dictionary = combat.get_pending_weapon()
		assert(decision["target_ids"] == [3], "Origin is primary target, not attacker or player storage order")
		assert(not choose(combat, true, [cost.instance_id], 1).valid)
		assert(not choose(combat, true, [cost.instance_id], 2).valid)
		assert(choose(combat, true, [cost.instance_id], 3).valid)
		assert(combat.game_state.get_player(3).hp == (4 if cancelled else 3))
		assert(observed == [DamageContext.SourceKind.ATTACK, DamageContext.SourceKind.WEAPON_EFFECT])
		assert(combat.game_state.deck.discard_pile.count(cost) == 1 and combat.executor.attacks_used == 1)
		assert(not combat.has_pending_response() and combat.get_pending_weapon().is_empty())
		assert(combat.game_state.validate_state())
	var combat: CombatController = setup("slingshot")
	var cost: CardInstance = AoeSystemTest.give(combat, 1, "dodge")
	assert(combat.executor.resolver.deal_damage(2, 3))
	assert(combat.executor.resolver.deal_damage(3, 3))
	combat.get_weapon(1).definition.effects[0]["parameters"]["secondary_damage"] = 2
	attack(combat)
	assert(combat.has_pending_dying() and combat.get_pending_weapon().is_empty())
	var heal: CardInstance = AoeSystemTest.give(combat, 1, "heal")
	assert(combat.rescue_player(1, 2, heal.instance_id).valid)
	assert(choose(combat, true, [cost.instance_id], 3).valid)
	assert(combat.has_pending_dying() and combat.game_state.get_player(3).hp == -1)
	assert(combat.game_state.validate_state())
	for index: int in range(2):
		heal = AoeSystemTest.give(combat, 1, "heal")
		assert(combat.rescue_player(1, 3, heal.instance_id).valid)
	assert(not combat.has_pending_dying() and combat.get_pending_weapon().is_empty())
	assert(combat.turn_manager.current_phase == TurnManager.Phase.PLAY and combat.game_state.validate_state())
	print("[PASS] Slingshot explicit hand cost, primary-origin range, excludes source/primary, distinct damage/no response/no recursion, negative child HP and retained cancelled cost")


static func _test_guards_and_lifetime() -> void:
	var combat: CombatController = setup("rifle")
	var target_weapon: CardInstance = AoeSystemTest.give(combat, 2, "crossbow")
	assert(combat.game_state.zone_manager.transfer_card(target_weapon.instance_id, "hand", 2, "equipment", 2))
	var attack_card: CardInstance = attack(combat)
	var decision: Dictionary = combat.get_pending_weapon()
	assert(not combat.resolve_weapon(2, int(decision["decision_id"]), false).valid)
	assert(not combat.resolve_weapon(1, int(decision["decision_id"]) + 1, false).valid)
	assert(not choose(combat, true, [attack_card.instance_id]).valid)
	assert(not combat.end_turn(1).valid and not combat.advance_phase().valid)
	combat.turn_manager.advance_phase()
	combat.turn_manager.start_game()
	assert(combat.turn_manager.current_phase == TurnManager.Phase.PLAY and combat.turn_manager.turn_number == 1)
	var tool: CardInstance = AoeSystemTest.give(combat, 1, "draw_2")
	assert(not combat.use_support_tool(1, tool.instance_id).valid)
	assert(not combat.use_aoe(1, tool.instance_id).valid)
	assert(not combat.use_attack(1, 2, tool.instance_id).valid)
	var source_weapon: CardInstance = combat.get_weapon(1)
	assert(combat.game_state.zone_manager.transfer_card(source_weapon.instance_id, "equipment", 1, "discard", 0))
	assert(combat.game_state.zone_manager.transfer_card(source_weapon.instance_id, "discard", 0, "equipment", 1))
	assert(combat.get_pending_weapon().is_empty() and combat.get_weapon(2) == target_weapon)
	assert(not combat.resolve_weapon(1, int(decision["decision_id"]), true, [target_weapon.instance_id]).valid)
	assert(combat.game_state.validate_state())
	print("[PASS] Decisions guard direct phases/new actions; stale/foreign commands reject; weapon loss cancels uncommitted effect")


static func _test_interruption_and_reentry() -> void:
	var combat: CombatController = setup("butchers_knife")
	var victim_card: CardInstance = AoeSystemTest.give(combat, 2, "dodge")
	var extra_attack: CardInstance = AoeSystemTest.give(combat, 1, "attack")
	attack(combat)
	var pending: Dictionary = combat.get_pending_weapon()
	var calls: Dictionary = {"count": 0}
	var on_discard: Callable = func(_names: PackedStringArray) -> void:
		calls["count"] += 1
		assert(not combat.resolve_weapon(1, int(pending["decision_id"]), true, [victim_card.instance_id]).valid)
		assert(not combat.use_attack(1, 3, extra_attack.instance_id).valid)
		assert(not combat.end_turn(1).valid)
	combat.game_state.zone_manager.cards_discarded.connect(on_discard)
	assert(choose(combat, true, [victim_card.instance_id]).valid)
	combat.game_state.zone_manager.cards_discarded.disconnect(on_discard)
	assert(calls["count"] == 1 and combat.game_state.get_player(2).hp == 4)
	assert(not combat.resolve_weapon(1, int(pending["decision_id"]), false).valid)
	assert(combat.game_state.validate_state())
	# An unrelated Dying Window suspends an offered effect without consuming its cost.
	combat = setup("slingshot")
	var cost: CardInstance = AoeSystemTest.give(combat, 1, "dodge")
	attack(combat)
	pending = combat.get_pending_weapon()
	pending["card_ids"].clear()
	assert(not combat.get_pending_weapon()["card_ids"].is_empty())
	assert(combat.executor.resolver.deal_damage(4, 4))
	assert(not choose(combat, true, [cost.instance_id], 3).valid)
	assert(combat.game_state.get_player(1).hand.has(cost))
	var heal: CardInstance = AoeSystemTest.give(combat, 1, "heal")
	assert(combat.rescue_player(1, 4, heal.instance_id).valid)
	assert(choose(combat, false).valid and combat.game_state.get_player(1).hand.has(cost))
	assert(combat.game_state.validate_state())
	# Source elimination removes the active ability but does not discard declared targets.
	combat = setup("pistol")
	extra_attack = AoeSystemTest.give(combat, 1, "attack")
	assert(combat.use_attack_targets(1, [4, 2], extra_attack.instance_id).valid)
	assert(combat.executor.resolver.deal_damage(1, 4))
	assert(combat.finalize_dying().valid)
	assert(combat.executor.pending_attack["target_id"] == 2)
	assert(combat.respond_to_attack(2).valid and combat.respond_to_attack(4).valid)
	assert(combat.turn_manager.get_current_player().player_id == 2)
	assert(combat.game_state.validate_state())
	combat = setup("pistol")
	extra_attack = AoeSystemTest.give(combat, 1, "attack")
	var unrelated: CardInstance = AoeSystemTest.give(combat, 3, "dodge")
	assert(combat.use_attack(1, 2, extra_attack.instance_id).valid)
	var during_transfer: Callable = func(_names: PackedStringArray) -> void:
		assert(not combat.respond_to_attack(2).valid)
	combat.game_state.zone_manager.cards_discarded.connect(during_transfer)
	assert(combat.game_state.discard_card(3, unrelated.instance_id))
	combat.game_state.zone_manager.cards_discarded.disconnect(during_transfer)
	assert(combat.game_state.get_player(2).hp == 4 and combat.has_pending_response())
	assert(combat.respond_to_attack(2).valid and combat.game_state.validate_state())
	print("[PASS] Atomic decision reentry/replay rejection, free decline, copied views, external Dying priority and eliminated-source continuation")
