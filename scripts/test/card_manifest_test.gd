class_name CardManifestTest
extends RefCounted


static func run_all() -> void:
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	var original: Array[Dictionary] = database.get_all_cards()
	var prefix: String = "res://__card_manifest_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var manifest: String = prefix + "_manifest.json"
	var first: String = prefix + "_first.json"
	var second: String = prefix + "_second.json"
	var missing: String = prefix + "_missing.json"
	var attack: Dictionary = database.get_card("attack")
	var dodge: Dictionary = database.get_card("dodge")
	var existing: CardInstance = CardInstance.new(9001, database.get_definition("attack"), CardInstance.Suit.HEARTS, 7)
	_write(first, {"cards": [attack]})
	_write(second, {"cards": [dodge]})
	_write(manifest, {"files": [first, second]})
	assert(database.load_from_file(manifest))
	assert(database.get_all_cards() == [attack, dodge])
	assert(database.definitions.keys() == ["attack", "dodge"])
	assert(database.get_errors().is_empty())
	assert(database.load_from_file(manifest) and database.get_card_count() == 2)
	var detached: Dictionary = database.get_card("attack")
	detached["effects"][0]["parameters"]["damage"] = 100
	assert(database.get_card("attack") == attack)
	var detached_all: Array[Dictionary] = database.get_all_cards()
	detached_all[0]["name"] = "Changed copy"
	assert(database.get_card("attack") == attack)
	print("[PASS] Ordered manifest merge, repeated load and unchanged copy/query APIs")

	_expect_failure(database, missing, missing, original)
	for invalid_root: Variant in [[], true, {}, {"files": []}, {"files": true}, {"files": [null]}, {"files": [false]}, {"files": [42]}, {"files": [{}]}, {"files": [""]}, {"files": ["data/cards/basic.json"]}, {"files": ["res://group.txt"]}, {"files": [first], "cards": []}]:
		_write(manifest, invalid_root)
		_expect_failure(database, manifest, manifest, original)
	_write_text(manifest, "{")
	_expect_failure(database, manifest, manifest, original)
	_write(manifest, {"files": [first, missing]})
	_expect_failure(database, manifest, missing, original)
	print("[PASS] Missing/malformed manifest and invalid/missing source paths fail atomically")

	_write(manifest, {"files": [first, second]})
	for invalid_group: Variant in [[], false, {}, {"cards": true}, {"files": [first]}, {"cards": [], "files": [first]}, {"cards": [null]}, {"cards": [false]}, {"cards": [{"id": "invalid"}]}]:
		_write(second, invalid_group)
		_expect_failure(database, manifest, second, original)
	_write_text(second, "{")
	_expect_failure(database, manifest, second, original)
	var invalid_card: Dictionary = attack.duplicate(true)
	invalid_card["effects"][0]["effect_id"] = true
	_write(second, {"cards": [invalid_card]})
	_expect_failure(database, manifest, second + ".cards[0]", original)
	print("[PASS] Bad group JSON/root/schema never publishes prior valid groups or stale registry")

	_write(second, {"cards": [attack]})
	var message: String = _expect_failure(database, manifest, second, original)
	assert(message.contains("attack") and message.contains(first + ".cards[0]") and message.contains(second + ".cards[0]"))
	_write(first, {"cards": [attack, attack]})
	_write(manifest, {"files": [first]})
	message = _expect_failure(database, manifest, first, original)
	assert(message.contains(first + ".cards[0]") and message.contains(first + ".cards[1]"))
	_write(first, {"cards": [attack]})
	for repeated: String in [first, "res://./" + first.trim_prefix("res://")]:
		_write(manifest, {"files": [first, repeated]})
		_expect_failure(database, manifest, manifest, original)
	print("[PASS] Duplicate IDs report both card origins; repeated source paths are rejected")

	# Repair a failed source and reload the same database without sticky errors.
	_write(second, {"cards": [dodge]})
	_write(manifest, {"files": [second]})
	assert(database.load_from_file(manifest))
	assert(database.get_card_count() == 1 and database.has_card("dodge") and not database.has_card("attack"))
	assert(database.get_errors().is_empty())
	assert(database.load_from_file(first))
	assert(database.get_card_count() == 1 and database.get_card("attack") == attack)
	assert(existing.instance_id == 9001 and existing.rank == 7 and existing.suit == CardInstance.Suit.HEARTS)
	assert(existing.definition.id == "attack" and existing.definition.effects == attack["effects"])
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	assert(database.get_all_cards() == original)
	for path: String in [manifest, first, second]:
		assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
	print("[PASS] Repair/reload, removed definitions, single-group compatibility and existing CardInstance preservation")
	print("=== ALL CARD MANIFEST TESTS PASSED ===")


static func _expect_failure(database: CardDatabase, path: String, origin: String, original: Array[Dictionary]) -> String:
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	assert(not database.load_from_file(path))
	assert(database.get_card_count() == 0 and database.get_all_cards().is_empty())
	assert(not database.has_card("attack") and database.get_card("attack").is_empty() and database.get_definition("attack") == null)
	assert(not database.get_errors().is_empty())
	var message: String = "\n".join(database.get_errors())
	assert(message.contains(origin), message)
	var detached_errors: Array[String] = database.get_errors()
	detached_errors.clear()
	assert(not database.get_errors().is_empty())
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	assert(database.get_errors().is_empty() and database.get_all_cards() == original)
	return message


static func _write(path: String, value: Variant) -> void:
	_write_text(path, JSON.stringify(value))


static func _write_text(path: String, content: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(content)
	file.close()
