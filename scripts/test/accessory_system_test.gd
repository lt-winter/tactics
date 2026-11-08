class_name AccessorySystemTest
extends RefCounted


static func run_all() -> void:
	_test_distance_and_lifecycle()
	_test_actions_and_guards()
	_test_schema()
	print("=== ALL ACCESSORY SYSTEM TESTS PASSED ===")


static func equip(combat: CombatController, owner: int, definition_id: String) -> CardInstance:
	var card: CardInstance = AoeSystemTest.give(combat, owner, definition_id)
	if owner == combat.turn_manager.get_current_player().player_id:
		assert(combat.equip_accessory(owner, card.instance_id).valid)
	else:
		assert(combat.game_state.zone_manager.transfer_card(card.instance_id, "hand", owner, "equipment", owner))
	return card


static func _test_distance_and_lifecycle() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	assert(combat.get_effective_distance(1, 3) == 2)
	assert(combat.get_effective_distance(1, 1) == 0)
	assert(combat.get_effective_distance(1, 999) == -1)
	var scope: CardInstance = equip(combat, 1, "scope")
	assert(combat.get_effective_distance(1, 3) == 1)
	assert(combat.get_effective_distance(3, 1) == 2)
	var mustang: CardInstance = equip(combat, 3, "mustang")
	assert(combat.get_effective_distance(1, 3) == 2)
	assert(combat.get_effective_distance(2, 3) == 2)
	for index: int in range(10):
		combat.game_state.zone_manager.equipment_changed.emit()
		assert(combat.get_effective_distance(1, 3) == 2)
	var own_mustang: CardInstance = equip(combat, 1, "mustang")
	assert(combat.get_accessory(1, "offensive_accessory") == scope)
	assert(combat.get_accessory(1, "defensive_accessory") == own_mustang)
	assert(combat.get_effective_distance(3, 1) == 3)
	var replacement: CardInstance = equip(combat, 1, "scope")
	assert(combat.game_state.deck.discard_pile.count(scope) == 1)
	assert(combat.get_effective_distance(1, 3) == 2)
	assert(combat.game_state.discard_card(3, mustang.instance_id, "equipment"))
	assert(combat.get_effective_distance(1, 3) == 1)
	# Stealing moves into hand; it must not equip or retain the old owner's effect.
	assert(combat.game_state.zone_manager.transfer_card(replacement.instance_id, "equipment", 1, "hand", 2))
	assert(combat.get_effective_distance(1, 3) == 2)
	assert(combat.get_effective_distance(2, 4) == 2)
	assert(combat.get_accessory(1, "offensive_accessory") == null)
	# Same-slot direct zone insertion rejects atomically.
	var duplicate: CardInstance = AoeSystemTest.give(combat, 1, "mustang")
	assert(not combat.game_state.zone_manager.transfer_card(duplicate.instance_id, "hand", 1, "equipment", 1))
	assert(combat.game_state.get_player(1).hand.has(duplicate))
	assert(not combat.executor.equipment_system.commit_equip(1, duplicate.instance_id, "offensive_accessory").valid)
	assert(combat.game_state.validate_state())
	var old_defense: CardInstance = own_mustang
	own_mustang = equip(combat, 1, "mustang")
	assert(combat.game_state.deck.discard_pile.count(old_defense) == 1)
	assert(combat.get_effective_distance(3, 1) == 3)
	assert(combat.game_state.discard_card(1, own_mustang.instance_id, "equipment"))
	assert(combat.get_effective_distance(3, 1) == 2)
	# DYING still occupies its seat; elimination shrinks the base ring immediately.
	assert(combat.executor.resolver.deal_damage(2, 4))
	assert(combat.get_effective_distance(1, 3) == 2)
	assert(combat.finalize_dying().valid)
	assert(combat.get_effective_distance(1, 3) == 1)
	assert(combat.get_effective_distance(1, 2) == -1)
	assert(combat.game_state.validate_state())
	combat = AoeSystemTest.setup([1, 3, 2, 4])
	assert(combat.get_effective_distance(1, 2) == 2)
	equip(combat, 1, "scope")
	assert(combat.get_effective_distance(1, 2) == 1)
	print("[PASS] Accessory direction, clamp, live zones, replacement, no stacking, seat order, DYING and elimination")


static func _test_actions_and_guards() -> void:
	var combat: CombatController = AoeSystemTest.setup()
	var attack: CardInstance = AoeSystemTest.give(combat, 1, "attack")
	var steal: CardInstance = AoeSystemTest.give(combat, 1, "steal")
	var victim: CardInstance = AoeSystemTest.give(combat, 3, "heal")
	assert(not combat.executor.validator.validate_attack(1, 3, attack.instance_id, 0).valid)
	assert(not combat.executor.validator.validate_tool_use(1, 3, steal.instance_id).valid)
	var scope: CardInstance = equip(combat, 1, "scope")
	assert(combat.executor.validator.validate_attack(1, 3, attack.instance_id, 0).valid)
	assert(combat.executor.validator.validate_tool_use(1, 3, steal.instance_id).valid)
	assert(combat.use_tool(1, 3, steal.instance_id, victim.instance_id, "hand").valid)
	assert(combat.game_state.get_player(1).hand.has(victim))
	var mustang: CardInstance = equip(combat, 3, "mustang")
	assert(not combat.executor.validator.validate_attack(1, 3, attack.instance_id, 0).valid)
	var destroy: CardInstance = AoeSystemTest.give(combat, 1, "discard")
	assert(combat.use_tool(1, 3, destroy.instance_id, mustang.instance_id, "equipment").valid)
	assert(combat.executor.validator.validate_attack(1, 3, attack.instance_id, 0).valid)
	var extra: CardInstance = AoeSystemTest.give(combat, 1, "scope")
	assert(not combat.equip_accessory(2, extra.instance_id).valid)
	assert(not combat.equip_weapon(1, extra.instance_id).valid)
	assert(not combat.equip_armor(1, extra.instance_id).valid)
	assert(combat.use_attack(1, 3, attack.instance_id).valid)
	assert(not combat.equip_accessory(1, extra.instance_id).valid)
	assert(combat.get_accessory(1, "offensive_accessory") == scope)
	assert(combat.respond_to_attack(3).valid)
	assert(combat.executor.resolver.deal_damage(2, 4))
	assert(not combat.equip_accessory(1, extra.instance_id).valid)
	assert(combat.finalize_dying().valid)
	assert(combat.game_state.validate_state())
	# Limited-range weapon child uses the same effective API, from primary target.
	combat = AoeSystemTest.setup()
	var weapon: CardInstance = AoeSystemTest.give(combat, 1, "slingshot")
	assert(combat.equip_weapon(1, weapon.instance_id).valid)
	equip(combat, 3, "mustang")
	attack = AoeSystemTest.give(combat, 1, "attack")
	AoeSystemTest.give(combat, 1, "heal")
	assert(combat.use_attack(1, 2, attack.instance_id).valid)
	assert(combat.respond_to_attack(2).valid)
	assert(combat.get_pending_weapon().is_empty())
	assert(combat.game_state.validate_state())
	combat = AoeSystemTest.setup()
	weapon = AoeSystemTest.give(combat, 1, "slingshot")
	assert(combat.equip_weapon(1, weapon.instance_id).valid)
	equip(combat, 2, "scope")
	attack = AoeSystemTest.give(combat, 1, "attack")
	AoeSystemTest.give(combat, 1, "heal")
	assert(combat.use_attack(1, 2, attack.instance_id).valid)
	assert(combat.respond_to_attack(2).valid)
	assert(4 in combat.get_pending_weapon()["target_ids"])
	assert(combat.game_state.validate_state())
	print("[PASS] Attack/Steal/Slingshot share effective distance, destruction and pending guards")


static func _test_schema() -> void:
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	for definition_id: String in ["scope", "mustang"]:
		assert(AccessoryEffects.supports(database.get_definition(definition_id)))
	var original: Dictionary = database.get_card("scope")
	for bad_amount: Variant in [true, false, 0, 1, -2, -0.5, "-1", null]:
		var data: Dictionary = original.duplicate(true)
		data["effects"][0]["parameters"]["amount"] = bad_amount
		assert(not database._validate_card(data, "fixture"))
	for bad_slot: String in ["weapon", "armor", "defensive_accessory", "unknown"]:
		var data: Dictionary = original.duplicate(true)
		data["equipment_slot"] = bad_slot
		assert(not database._validate_card(data, "fixture"))
	for bad_direction: Variant in ["incoming", "both", "", true, null]:
		var data: Dictionary = original.duplicate(true)
		data["effects"][0]["parameters"]["direction"] = bad_direction
		assert(not database._validate_card(data, "fixture"))
	for field: String in ["category", "subcategory"]:
		var data: Dictionary = original.duplicate(true)
		data[field] = "tool"
		assert(not database._validate_card(data, "fixture"))
	for effects: Array in [[], [null], [{"effect_id": "modify_distance", "parameters": []}], [original["effects"][0], original["effects"][0]]]:
		var data: Dictionary = original.duplicate(true)
		data["effects"] = effects
		assert(not database._validate_card(data, "fixture"))
	var renamed: Dictionary = original.duplicate(true)
	renamed["id"] = "unrelated_id"
	renamed["name"] = "Unrelated display name"
	assert(database._validate_card(renamed, "fixture"))
	assert(AccessoryEffects.supports(CardDefinition.new(renamed)))
	print("[PASS] Accessory schema, invalid parameters and effect-based dispatch")
