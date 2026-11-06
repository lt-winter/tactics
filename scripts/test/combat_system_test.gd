
class_name CombatSystemTest
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

	var players: Array[Player] = [player_a, player_b]

	var game: GameState = GameState.new(cards, players)
	var turns: TurnManager = TurnManager.new(game)
	var rules: RuleEngine = RuleEngine.new()

	assert(rules.load_base_rules(
		"res://data/rules/base_rules.json"
	))

	var combat: CombatController = CombatController.new(
		game, turns, rules
	)

	var attack_card: CardInstance = null

	for card in cards:
		if card.definition.has_effect("deal_attack"):
			attack_card = card
			break

	assert(attack_card != null)

	assert(game.zone_manager.transfer_card(
		attack_card.instance_id,
		"draw",
		0,
		"hand",
		1
	))

	print("=== COMBAT SYSTEM TEST ===")

	var result: ActionResult = combat.start_game()
	assert(result.valid)

	# START -> JUDGMENT -> DRAW -> PLAY
	for i in range(3):
		result = combat.advance_phase()
		assert(result.valid)

	assert(turns.current_phase == TurnManager.Phase.PLAY)
	assert(combat.executor.attacks_used == 0)

	print("[PASS] Bắt đầu trận và đồng bộ lượt")

	# Tấn công hợp lệ
	result = combat.use_attack(
		1, 2, attack_card.instance_id
	)

	assert(result.valid)
	assert(combat.has_pending_response())
	assert(combat.executor.attacks_used == 1)

	print("[PASS] Tạo Response Window")

	# Không được chuyển Phase khi chờ phản ứng
	var old_phase: int = turns.current_phase

	result = combat.advance_phase()

	assert(not result.valid)
	assert(turns.current_phase == old_phase)

	print("[PASS] Khóa chuyển Phase")

	# Giảm sát thương đi 1
	combat.executor.damage_pipeline.add_modifier(
		Callable(CombatSystemTest, "_reduce_one")
	)

	result = combat.respond_to_attack(2)

	assert(result.valid)
	assert(not combat.has_pending_response())
	assert(player_b.hp == 4)

	print("[PASS] Damage Pipeline giảm sát thương")

	# Sau khi phản ứng xong, chuyển Phase bình thường
	result = combat.advance_phase()

	assert(result.valid)
	assert(turns.current_phase == TurnManager.Phase.DISCARD)
	assert(combat.executor.attacks_used == 1)

	print("[PASS] Mở khóa chuyển Phase")

	# DISCARD -> END -> lượt tiếp theo
	result = combat.advance_phase()
	assert(result.valid)

	result = combat.advance_phase()
	assert(result.valid)

	var current_player: Player = turns.get_current_player()

	assert(current_player != null)
	assert(current_player.player_id == 2)
	assert(combat.executor.attacks_used == 0)

	print("[PASS] Tự động reset bộ đếm Tấn công")

	assert(game.validate_state())
	print("[PASS] Bảo toàn trạng thái bài")

	print("=== ALL COMBAT SYSTEM TESTS PASSED ===")


static func _reduce_one(context: DamageContext) -> void:
	context.reduce_damage(1)
