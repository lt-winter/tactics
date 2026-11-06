
class_name DamageRegistryTest
extends RefCounted


static func run_all() -> void:
	var card_db: CardDatabase = CardDatabase.new()
	assert(card_db.load_from_file("res://data/cards.json"))

	var deck_db: DeckDatabase = DeckDatabase.new(card_db)
	assert(deck_db.load_from_file(
		"res://data/decks/standard.json"
	))

	var cards: Array[CardInstance] = deck_db.create_instances()

	var player_a: Player = Player.new(1, "Player A", 4)
	var player_b: Player = Player.new(2, "Player B", 4)
	var player_c: Player = Player.new(3, "Player C", 4)

	var players: Array[Player] = [
		player_a,
		player_b,
		player_c
	]

	var game: GameState = GameState.new(cards, players)
	var resolver: EffectResolver = EffectResolver.new(game)
	var pipeline: DamagePipeline = DamagePipeline.new(resolver)

	print("=== DAMAGE REGISTRY TEST ===")

	# Test 1: Sát thương cơ bản
	assert(pipeline.process_damage(1, 2, 1))
	assert(player_b.hp == 3)

	player_b.hp = 4

	print("[PASS] Sát thương cơ bản")

	# Test 2: Đăng ký giáp cho Player B
	var armor: DamageModifier = DamageModifier.new(
		"armor_player_2",
		"defense_armor",
		2,
		RuleModifier.Source.CARD_EFFECT,
		DamageModifier.Role.DEFENDER,
		Callable(DamageRegistryTest, "_reduce_one")
	)

	assert(pipeline.register_modifier(armor))
	assert(not pipeline.register_modifier(armor))

	assert(pipeline.process_damage(1, 2, 1))
	assert(player_b.hp == 4)

	print("[PASS] Giáp giảm sát thương cho chủ sở hữu")

	# Test 3: Giáp của B không bảo vệ C
	assert(pipeline.process_damage(1, 3, 1))
	assert(player_c.hp == 3)

	player_c.hp = 4

	print("[PASS] Không áp dụng nhầm hiệu ứng phòng thủ")

	# Test 4: Kỹ năng tấn công của A
	var power: DamageModifier = DamageModifier.new(
		"power_player_1",
		"power_strike",
		1,
		RuleModifier.Source.CHARACTER_SKILL,
		DamageModifier.Role.ATTACKER,
		Callable(DamageRegistryTest, "_increase_one")
	)

	assert(pipeline.register_modifier(power))

	var context: DamageContext = DamageContext.new(1, 2, 1)
	var applicable: Array[DamageModifier] = (
		pipeline.registry.get_applicable(context)
	)

	assert(applicable.size() == 2)
	assert(applicable[0].modifier_id == "power_player_1")
	assert(applicable[1].modifier_id == "armor_player_2")

	print("[PASS] Ưu tiên kỹ năng tướng trước trang bị")

	# Test 5: Tăng 1 rồi giảm 1
	assert(pipeline.process_damage(1, 2, 1))
	assert(player_b.hp == 3)

	player_b.hp = 4

	print("[PASS] Kết hợp tăng và giảm sát thương")

	# Test 6: Kỹ năng A không tăng sát thương của C
	assert(pipeline.process_damage(3, 2, 1))
	assert(player_b.hp == 4)

	print("[PASS] Hiệu ứng tấn công đúng chủ sở hữu")

	# Test 7: Gỡ trang bị của B
	assert(pipeline.unregister_modifier("armor_player_2"))

	assert(pipeline.process_damage(1, 2, 1))
	assert(player_b.hp == 2)

	player_b.hp = 4

	print("[PASS] Gỡ trang bị cập nhật sát thương")

	# Test 8: Gỡ kỹ năng tướng
	assert(
		pipeline.registry.unregister_by_source("power_strike") == 1
	)

	assert(pipeline.process_damage(1, 2, 1))
	assert(player_b.hp == 3)

	print("[PASS] Gỡ kỹ năng tướng")

	# Test 9: Hiệu ứng miễn sát thương
	player_b.hp = 4

	var shield: DamageModifier = DamageModifier.new(
		"shield_player_2",
		"damage_immunity",
		2,
		RuleModifier.Source.CHARACTER_SKILL,
		DamageModifier.Role.DEFENDER,
		Callable(DamageRegistryTest, "_cancel_damage")
	)

	assert(pipeline.register_modifier(shield))
	assert(pipeline.process_damage(1, 2, 2))
	assert(player_b.hp == 4)

	print("[PASS] Miễn sát thương")

	assert(game.validate_state())
	print("[PASS] Bảo toàn trạng thái bài")

	print("=== ALL DAMAGE REGISTRY TESTS PASSED ===")


static func _reduce_one(context: DamageContext) -> void:
	context.reduce_damage(1)


static func _increase_one(context: DamageContext) -> void:
	context.increase_damage(1)


static func _cancel_damage(context: DamageContext) -> void:
	context.cancel_damage()
