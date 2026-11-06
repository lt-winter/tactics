
class_name DeckTest
extends RefCounted


static func run_all() -> void:
	var card_db: CardDatabase = CardDatabase.new()

	assert(
		card_db.load_from_file("res://data/cards.json"),
		"Không thể nạp cards.json"
	)

	var deck_db: DeckDatabase = DeckDatabase.new(card_db)

	var loaded: bool = deck_db.load_from_file(
		"res://data/decks/standard.json"
	)
	assert(loaded, "Không thể nạp standard.json")

	print("=== DECK SYSTEM TEST ===")

	var cards: Array[CardInstance] = deck_db.create_instances()
	var total: int = cards.size()

	# 1. Kiểm tra số lượng
	assert(total == deck_db.get_card_count())
	assert(total > 0)
	print("[PASS] Số lượng: ", total)

	# 2. Kiểm tra ID duy nhất
	var ids: Dictionary = {}

	for card: CardInstance in cards:
		assert(not ids.has(card.instance_id))
		ids[card.instance_id] = true

		assert(card.rank >= 1 and card.rank <= 13)
		assert(
			CardInstance.is_valid_suit_name(
				card.get_suit_name()
			)
		)

	assert(ids.size() == total)
	print("[PASS] ID duy nhất, chất và số hợp lệ")

	# 3. Khởi tạo và xáo bài
	# GameState owns draw/discard transfers so cards remain in tracked zones.
	var player: Player = Player.new(1, "Deck test player", 4)
	var players: Array[Player] = [player]
	var game: GameState = GameState.new(cards, players)
	var deck: Deck = game.deck
	deck.rng.seed = 12345
	deck.shuffle()

	assert(deck.get_draw_count() == total)
	assert(deck.get_discard_count() == 0)
	assert(game.validate_state())
	deck.recycle_discard_pile()
	assert(deck.get_draw_count() == total)
	assert(game.draw_card(999) == null)
	assert(deck.get_draw_count() == total)
	assert(game.validate_state())

	print("[PASS] Khởi tạo và xáo bài")

	# 4. Rút hết bộ bài
	var drawn: Array[CardInstance] = []
	var drawn_ids: Dictionary = {}

	for i: int in range(total):
		var card: CardInstance = game.draw_card(player.player_id)

		assert(card != null)
		assert(not drawn_ids.has(card.instance_id))

		drawn_ids[card.instance_id] = true
		drawn.append(card)
		assert(player.get_hand_count() == i + 1)
		assert(game.validate_state())

	assert(deck.get_draw_count() == 0)
	assert(game.draw_card(player.player_id) == null)
	assert(player.get_hand_count() == total)
	assert(game.validate_state())

	print("[PASS] Rút hết bài, không trùng ID")

	# 5. Chuyển toàn bộ bài sang chồng bỏ
	for card: CardInstance in drawn:
		assert(game.discard_card(player.player_id, card.instance_id))
		assert(not game.discard_card(player.player_id, card.instance_id))
		assert(game.validate_state())

	assert(deck.get_discard_count() == total)
	assert(deck.get_draw_count() == 0)
	assert(player.hand.is_empty())

	print("[PASS] Bỏ bài")

	# 6. Tái tạo chồng rút
	var recycled_card: CardInstance = game.draw_card(player.player_id)

	assert(recycled_card != null)
	assert(deck.get_draw_count() == total - 1)
	assert(deck.get_discard_count() == 0)
	assert(player.get_hand_count() == 1)
	assert(player.hand[0] == recycled_card)
	assert(game.validate_state())

	print("[PASS] Tái sử dụng chồng bỏ")

	# 7. Kiểm tra bảo toàn bài
	var final_ids: Dictionary = {}

	final_ids[recycled_card.instance_id] = true

	for card: CardInstance in deck.draw_pile:
		assert(not final_ids.has(card.instance_id))
		final_ids[card.instance_id] = true

	assert(final_ids.size() == total)
	for original_id: int in ids:
		assert(final_ids.has(original_id))

	print("[PASS] Bảo toàn toàn bộ lá bài")
	print("=== ALL DECK TESTS PASSED ===")
