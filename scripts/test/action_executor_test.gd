
class_name ActionExecutorTest
extends RefCounted


static func run_all() -> void:
	var card_db: CardDatabase = CardDatabase.new()
	assert(card_db.load_from_file("res://data/cards.json"))

	var deck_db: DeckDatabase = DeckDatabase.new(card_db)
	assert(
		deck_db.load_from_file(
			"res://data/decks/standard.json"
		)
	)

	var cards: Array[CardInstance] = deck_db.create_instances()

	var player_a: Player = Player.new(1, "Player A", 4)
	var player_b: Player = Player.new(2, "Player B", 4)

	var players: Array[Player] = [player_a, player_b]

	var game: GameState = GameState.new(cards, players)
	var turns: TurnManager = TurnManager.new(game)
	var rules: RuleEngine = RuleEngine.new()

	assert(
		rules.load_base_rules(
			"res://data/rules/base_rules.json"
		)
	)

	var executor: ActionExecutor = ActionExecutor.new(
		game,
		turns,
		rules
	)

	var attack_cards: Array[CardInstance] = []
	var dodge_card: CardInstance = null

	for card in cards:
		if card.definition.has_effect("deal_attack"):
			attack_cards.append(card)

		if card.definition.has_effect("block_attack"):
			if dodge_card == null:
				dodge_card = card

	assert(attack_cards.size() >= 2)
	assert(dodge_card != null)

	# Chuẩn bị bài cho hai người chơi
	for card in attack_cards:
		assert(
			game.zone_manager.transfer_card(
				card.instance_id,
				"draw",
				0,
				"hand",
				1
			)
		)

	assert(
		game.zone_manager.transfer_card(
			dodge_card.instance_id,
			"draw",
			0,
			"hand",
			2
		)
	)

	assert(game.validate_state())

	turns.start_game()
	turns.advance_phase()
	turns.advance_phase()
	turns.advance_phase()

	assert(turns.current_phase == TurnManager.Phase.PLAY)

	print("=== ACTION EXECUTOR TEST ===")

	# Test 1: Bị chặn do không phải lượt
	var result: ActionResult = executor.use_attack(
		2,
		1,
		dodge_card.instance_id
	)

	assert(not result.valid)
	print("[PASS] Chặn hành động không hợp lệ")

	# Test 2: Player A sử dụng Tấn công
	var first_attack: CardInstance = attack_cards[0]

	result = executor.use_attack(
		1,
		2,
		first_attack.instance_id
	)

	assert(result.valid)
	assert(executor.has_pending_attack())
	assert(executor.attacks_used == 1)
	assert(player_b.hp == 4)
	assert(game.validate_state())

	print("[PASS] Tấn công tạo trạng thái chờ")

	# Test 3: Không cho Tấn công chồng lên nhau
	result = executor.use_attack(
		1,
		2,
		attack_cards[1].instance_id
	)

	assert(not result.valid)
	print("[PASS] Chặn Tấn công khi đang chờ phản ứng")

	# Test 4: Player B dùng Né tránh
	result = executor.respond_to_attack(
		2,
		dodge_card.instance_id
	)

	assert(result.valid)
	assert(not executor.has_pending_attack())
	assert(player_b.hp == 4)
	assert(game.validate_state())

	print("[PASS] Né tránh thành công")

	# Test 5: Giới hạn một lần Tấn công
	result = executor.use_attack(
		1,
		2,
		attack_cards[1].instance_id
	)

	assert(not result.valid)
	print("[PASS] Giới hạn Tấn công được ghi nhận")

	# Test 6: Thêm kỹ năng Liên kích
	var combo: RuleModifier = RuleModifier.new(
		"attack_limit_per_turn",
		"remove_limit",
		0,
		RuleModifier.Source.CHARACTER_SKILL,
		"combo_attack",
		1
	)

	rules.add_modifier(combo)

	result = executor.use_attack(
		1,
		2,
		attack_cards[1].instance_id
	)

	assert(result.valid)
	assert(executor.has_pending_attack())

	print("[PASS] Liên kích cho phép Tấn công tiếp")

	# Test 7: Player B không Né tránh
	result = executor.respond_to_attack(2)

	assert(result.valid)
	assert(not executor.has_pending_attack())
	assert(player_b.hp == 3)
	assert(game.validate_state())

	print("[PASS] Gây sát thương thành công")

	# Test 8: Hồi máu
	var healed: bool = executor.resolver.restore_hp(2, 1)

	assert(healed)
	assert(player_b.hp == 4)
	assert(game.validate_state())

	print("[PASS] Hồi máu không vượt HP tối đa")

	# Test 9: Không hồi máu khi đầy HP
	healed = executor.resolver.restore_hp(2, 1)

	assert(not healed)
	assert(player_b.hp == 4)

	print("[PASS] Chặn hồi máu khi đầy HP")

	print("=== ALL ACTION EXECUTOR TESTS PASSED ===")
