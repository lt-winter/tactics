
class_name TurnManagerTest
extends RefCounted


static func run_all() -> void:
	var card_db: CardDatabase = CardDatabase.new()

	if not card_db.load_from_file("res://data/cards.json"):
		push_error("Không thể nạp cards.json")
		return

	var deck_db: DeckDatabase = DeckDatabase.new(card_db)

	if not deck_db.load_from_file(
		"res://data/decks/standard.json"
	):
		for error in deck_db.get_errors():
			push_error(error)
		return

	var cards: Array[CardInstance] = deck_db.create_instances()

	var player_a: Player = Player.new(1, "Player A", 4)
	var player_b: Player = Player.new(2, "Player B", 4)

	var game: GameState = GameState.new(
		cards,
		[player_a, player_b]
	)

	var turns: TurnManager = TurnManager.new(game)

	print("=== TURN MANAGER TEST ===")

	turns.start_game()

	assert(turns.turn_number == 1)
	assert(turns.get_current_player() == player_a)
	assert(turns.current_phase == TurnManager.Phase.START)

	turns.advance_phase()
	assert(turns.current_phase == TurnManager.Phase.JUDGMENT)

	turns.advance_phase()
	assert(turns.current_phase == TurnManager.Phase.DRAW)

	turns.advance_phase()
	assert(turns.current_phase == TurnManager.Phase.PLAY)
	assert(player_a.get_hand_count() == 2)
	assert(game.validate_state())

	print("[PASS] Player A rút 2 lá")

	turns.advance_phase()
	assert(turns.current_phase == TurnManager.Phase.DISCARD)

	turns.advance_phase()
	assert(turns.current_phase == TurnManager.Phase.END)

	turns.advance_phase()
	assert(turns.turn_number == 2)
	assert(turns.get_current_player() == player_b)
	assert(turns.current_phase == TurnManager.Phase.START)

	print("[PASS] Chuyển lượt sang Player B")

	turns.advance_phase()
	turns.advance_phase()
	turns.advance_phase()

	assert(player_b.get_hand_count() == 2)
	assert(game.validate_state())

	print("[PASS] Player B rút 2 lá")
	print("[PASS] Bảo toàn trạng thái trận đấu")
	print("=== ALL TURN MANAGER TESTS PASSED ===")
