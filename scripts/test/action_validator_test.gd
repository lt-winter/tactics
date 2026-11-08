
class_name ActionValidatorTest
extends RefCounted


static func run_all() -> void:
	var card_db: CardDatabase = CardDatabase.new()

	assert(card_db.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))

	var deck_db: DeckDatabase = DeckDatabase.new(card_db)

	assert(
		deck_db.load_from_file(
			"res://data/decks/standard.json"
		)
	)

	var cards: Array[CardInstance] = deck_db.create_instances()

	var player_a: Player = Player.new(1, "Player A", 4)
	var player_b: Player = Player.new(2, "Player B", 4)
	var player_c: Player = Player.new(3, "Player C", 4)
	var player_d: Player = Player.new(4, "Player D", 4)

	var players: Array[Player] = [
		player_a,
		player_b,
		player_c,
		player_d
	]

	var game: GameState = GameState.new(cards, players)
	var turns: TurnManager = TurnManager.new(game)
	var rules: RuleEngine = RuleEngine.new()

	assert(
		rules.load_base_rules(
			"res://data/rules/base_rules.json"
		)
	)

	var validator: ActionValidator = ActionValidator.new(
		game,
		turns,
		rules
	)

	# Tìm một lá có hiệu ứng Tấn công
	var attack_card: CardInstance = null

	for card in cards:
		if card.definition.has_effect("deal_attack"):
			attack_card = card
			break

	assert(attack_card != null)

	# Đưa lá Tấn công vào tay Player A
	assert(
		game.zone_manager.transfer_card(
			attack_card.instance_id,
			"draw",
			0,
			"hand",
			1
		)
	)

	assert(game.validate_state())

	print("=== ACTION VALIDATOR TEST ===")

	# Test 1: Không thể Tấn công ngoài PLAY
	turns.start_game()

	var result: ActionResult = validator.validate_attack(
		1, 2, attack_card.instance_id, 0
	)

	assert(not result.valid)
	print("[PASS] Chặn Tấn công ngoài PLAY Phase")

	# Chuyển đến PLAY Phase
	turns.advance_phase()
	turns.advance_phase()
	turns.advance_phase()

	assert(turns.current_phase == TurnManager.Phase.PLAY)

	# Test 2: Tấn công hợp lệ
	result = validator.validate_attack(
		1, 2, attack_card.instance_id, 0
	)

	assert(result.valid)
	print("[PASS] Tấn công mục tiêu hợp lệ")

	# Test 3: Không phải lượt của Player B
	result = validator.validate_attack(
		2, 1, attack_card.instance_id, 0
	)

	assert(not result.valid)
	print("[PASS] Chặn người chơi không có lượt")

	# Test 4: Không thể tự Tấn công
	result = validator.validate_attack(
		1, 1, attack_card.instance_id, 0
	)

	assert(not result.valid)
	print("[PASS] Chặn tự Tấn công")

	# Test 5: Giới hạn 1 lần mỗi lượt
	result = validator.validate_attack(
		1, 2, attack_card.instance_id, 1
	)

	assert(not result.valid)
	print("[PASS] Giới hạn Tấn công cơ bản")

	# Test 6: Mục tiêu ngoài tầm
	assert(DistanceCalculator.calculate(players, 1, 3) == 2)

	result = validator.validate_attack(
		1, 3, attack_card.instance_id, 0
	)

	assert(not result.valid)
	print("[PASS] Chặn Tấn công ngoài tầm")

	# Test 7: Trang bị tăng giới hạn lên 2
	var equipment: RuleModifier = RuleModifier.new(
		"attack_limit_per_turn",
		"set",
		2,
		RuleModifier.Source.CARD_EFFECT,
		"double_shot",
		1
	)

	rules.add_modifier(equipment)

	result = validator.validate_attack(
		1, 2, attack_card.instance_id, 1
	)

	assert(result.valid)
	print("[PASS] Trang bị thay đổi giới hạn Tấn công")

	# Test 8: Kỹ năng Liên kích
	var combo: RuleModifier = RuleModifier.new(
		"attack_limit_per_turn",
		"remove_limit",
		0,
		RuleModifier.Source.CHARACTER_SKILL,
		"combo_attack",
		1
	)

	rules.add_modifier(combo)

	result = validator.validate_attack(
		1, 2, attack_card.instance_id, 10
	)

	assert(result.valid)
	print("[PASS] Liên kích bỏ giới hạn Tấn công")

	# Test 9: Liên kích không bỏ qua tầm đánh
	result = validator.validate_attack(
		1, 3, attack_card.instance_id, 10
	)

	assert(not result.valid)
	print("[PASS] Liên kích vẫn tuân thủ tầm đánh")

	# Test 10: Tăng tầm đánh lên 2
	var weapon: RuleModifier = RuleModifier.new(
		"attack_range",
		"set",
		2,
		RuleModifier.Source.CARD_EFFECT,
		"long_range_weapon",
		1
	)

	rules.add_modifier(weapon)

	result = validator.validate_attack(
		1, 3, attack_card.instance_id, 10
	)

	assert(result.valid)
	print("[PASS] Trang bị tăng tầm đánh")

	# Test 11: Mục tiêu đã chết
	player_c.hp = 0
	assert(player_c.enter_dying())
	assert(player_c.eliminate())

	result = validator.validate_attack(
		1, 3, attack_card.instance_id, 0
	)

	assert(not result.valid)
	print("[PASS] Chặn Tấn công người đã chết")

	assert(game.validate_state())
	print("[PASS] Không thay đổi trạng thái bài")
	print("=== ALL ACTION VALIDATOR TESTS PASSED ===")
