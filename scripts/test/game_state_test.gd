
class_name GameStateTest
extends RefCounted


static func run_all() -> void:
	var card_db := CardDatabase.new()

	assert(
		card_db.load_from_file("res://data/cards.json")
	)

	var deck_db := DeckDatabase.new(card_db)

	assert(
		deck_db.load_from_file(
			"res://data/decks/standard.json"
		)
	)

	var cards := deck_db.create_instances()
	var total := cards.size()

	var player_a := Player.new(1, "Player A", 4)
	var player_b := Player.new(2, "Player B", 4)

	var game := GameState.new(
		cards,
		[player_a, player_b]
	)

	print("=== GAME STATE TEST ===")

	# Kiểm tra trạng thái ban đầu
	assert(game.validate_state())
	assert(game.deck.get_draw_count() == total)

	print("[PASS] Khởi tạo GameState")

	# Người chơi A rút bài
	var card := game.draw_card(1)

	assert(card != null)
	assert(player_a.hand.size() == 1)
	assert(game.deck.get_draw_count() == total - 1)
	assert(game.validate_state())

	print("[PASS] Rút bài")

	# Chuyển bài từ A sang B
	assert(
		game.transfer_player_card(
			card.instance_id,
			1,
			"hand",
			2,
			"hand"
		)
	)

	assert(player_a.hand.is_empty())
	assert(player_b.hand.size() == 1)
	assert(game.validate_state())

	print("[PASS] Chuyển bài giữa người chơi")

	# B bỏ bài
	assert(
		game.discard_card(
			2,
			card.instance_id
		)
	)

	assert(player_b.hand.is_empty())
	assert(game.deck.get_discard_count() == 1)
	assert(game.validate_state())

	print("[PASS] Bỏ bài và bảo toàn số lượng")

	# Rút hết chồng bài
	while game.deck.get_draw_count() > 0:
		assert(game.draw_card(1) != null)

	assert(game.deck.get_draw_count() == 0)
	assert(game.validate_state())

	# Rút tiếp: tự động tái tạo chồng bỏ
	var recycled := game.draw_card(2)

	assert(recycled != null)
	assert(game.deck.get_discard_count() == 0)
	assert(game.validate_state())

	print("[PASS] Tái tạo chồng rút")
	print("[PASS] Bảo toàn toàn bộ CardInstance")
	print("=== ALL GAME STATE TESTS PASSED ===")
