
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

	assert(database.get_card_count() == 5)
	assert(database.has_card("attack"))
	assert(database.has_card("dodge"))
	assert(database.has_card("heal"))
	assert(database.has_card("discard"))
	assert(database.has_card("steal"))

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

	print("PASS: CardDatabase")
