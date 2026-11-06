
class_name CardDatabaseTest
extends RefCounted


static func run_all() -> void:
	var database := CardDatabase.new()

	var loaded := database.load_from_file(
        "res://data/cards.json"
	)

	if not loaded:
		print("=== CARD DATABASE ERRORS ===")

		for error in database.get_errors():
			push_error(error)

		return

	print("=== CARD DATABASE TEST ===")

	assert(database.get_card_count() == 10)
	assert(database.has_card("attack"))
	assert(database.has_card("dodge"))
	assert(database.has_card("heal"))
	assert(database.has_card("discard"))
	assert(database.has_card("steal"))
	var weapon_ids: Array[String] = ["crossbow", "butchers_knife", "slingshot", "pistol", "rifle"]
	for index: int in range(weapon_ids.size()):
		var weapon: CardDefinition = database.get_definition(weapon_ids[index])
		assert(weapon != null and weapon.is_equipment())
		assert(weapon.equipment_slot == "weapon" and weapon.attack_range == index + 1)

	var attack := database.get_card("attack")
	assert(attack["category"] == "basic")
	assert(attack["effects"][0]["effect_id"] == "deal_attack")

	var steal := database.get_card("steal")
	var params: Dictionary = steal["effects"][0]["parameters"]

	assert(params["max_distance"] == 1)
	assert(params["target_zones"].has("hand"))
	assert(params["target_zones"].has("equipment"))
	assert(params["target_zones"].has("judgment"))

	print("Số loại bài: ", database.get_card_count())

	for card in database.get_all_cards():
		print(
            "%s | %s | %s"
			% [card["id"], card["name"], card["category"]]
		)

	_test_weapon_schema(database)
	print("PASS: CardDatabase")


static func _test_weapon_schema(database: CardDatabase) -> void:
	var fixture_path: String = "res://__weapon_schema_%d.json" % Time.get_ticks_usec()
	for bad_range: Variant in [0, -1, 1.5, true, "2", null]:
		var weapon: Dictionary = database.get_card("crossbow")
		weapon["range"] = bad_range
		var file: FileAccess = FileAccess.open(fixture_path, FileAccess.WRITE)
		assert(file != null)
		file.store_string(JSON.stringify({"cards": [weapon]}))
		file.close()
		var invalid: CardDatabase = CardDatabase.new()
		assert(not invalid.load_from_file(fixture_path))
		assert(not invalid.get_errors().is_empty() and invalid.get_card_count() == 0)
	var weapon: Dictionary = database.get_card("crossbow")
	weapon["equipment_slot"] = "hand"
	var file: FileAccess = FileAccess.open(fixture_path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify({"cards": [weapon]}))
	file.close()
	var invalid: CardDatabase = CardDatabase.new()
	assert(not invalid.load_from_file(fixture_path))
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path)) == OK)
