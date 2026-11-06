class_name DefenseFoundationTest
extends RefCounted


static func run_all() -> void:
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file("res://data/cards.json"))
	var armor_data: Dictionary = {"id": "armor_fixture", "name": "Phòng ngự mẫu", "category": "equipment", "subcategory": "armor", "description": "Chưa có hiệu ứng.", "equipment_slot": "armor", "effects": []}
	var fixture: String = "res://__defense_schema_%d.json" % Time.get_ticks_usec()
	var file: FileAccess = FileAccess.open(fixture, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify({"cards": [armor_data]}))
	file.close()
	var schema: CardDatabase = CardDatabase.new()
	assert(schema.load_from_file(fixture))
	assert(schema.get_definition("armor_fixture").has_equipment_slot())
	for invalid_slot: Variant in ["weapon", "unknown", null, 1]:
		var invalid: Dictionary = armor_data.duplicate(true)
		invalid["equipment_slot"] = invalid_slot
		file = FileAccess.open(fixture, FileAccess.WRITE)
		assert(file != null)
		file.store_string(JSON.stringify({"cards": [invalid]}))
		file.close()
		assert(not schema.load_from_file(fixture) and schema.get_card_count() == 0)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture)) == OK)
	var first: CardInstance = CardInstance.new(1, CardDefinition.new(armor_data), CardInstance.Suit.HEARTS, 1)
	var second: CardInstance = CardInstance.new(2, CardDefinition.new(armor_data), CardInstance.Suit.SPADES, 2)
	var weapon: CardInstance = CardInstance.new(3, database.get_definition("crossbow"), CardInstance.Suit.CLUBS, 3)
	var state: GameState = GameState.new([first, second, weapon], [Player.new(1, "P1", 4), Player.new(2, "P2", 4)])
	var rules: RuleEngine = RuleEngine.new()
	assert(rules.load_base_rules("res://data/rules/base_rules.json"))
	var combat: CombatController = CombatController.new(state, TurnManager.new(state), rules)
	combat.turn_manager.draw_count_per_turn = 0
	assert(combat.start_game().valid)
	for card: CardInstance in [first, second, weapon]:
		assert(state.zone_manager.transfer_card(card.instance_id, "draw", 0, "hand", 1))
	# Metadata/slot foundation only: armor use and its replacement policy remain unimplemented.
	assert(not combat.equip_weapon(1, first.instance_id).valid)
	assert(state.get_player(1).hand.has(first))
	assert(state.zone_manager.transfer_card(first.instance_id, "hand", 1, "equipment", 1))
	assert(combat.get_defense(1) == first and combat.get_weapon(1) == null)
	assert(combat.equip_weapon(1, weapon.instance_id).valid)
	assert(combat.get_defense(1) == first and combat.get_weapon(1) == weapon)
	assert(not state.zone_manager.transfer_card(second.instance_id, "hand", 1, "equipment", 1))
	assert(state.get_player(1).hand.has(second) and combat.get_defense(1) == first)
	assert(state.discard_card(1, first.instance_id, "equipment"))
	assert(combat.get_defense(1) == null and combat.get_weapon(1) == weapon)
	assert(bool(rules.get_rule("attack_limit_per_turn", {}, RuleContext.new(1))["unlimited"]))
	assert(state.zone_manager.transfer_card(second.instance_id, "hand", 1, "equipment", 2))
	assert(combat.get_defense(2) == second)
	assert(state.transfer_player_card(second.instance_id, 2, "equipment", 1, "equipment"))
	assert(combat.get_defense(1) == second and combat.get_defense(2) == null)
	assert(combat.executor.equipment_system.get_equipment(1, "unknown") == null)
	assert(state.validate_state())
	print("=== ALL DEFENSE FOUNDATION TESTS PASSED ===")
