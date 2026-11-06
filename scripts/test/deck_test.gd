
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
	assert(deck.shuffle_count == 2)

	assert(deck.get_draw_count() == total)
	assert(deck.get_discard_count() == 0)
	assert(game.validate_state())
	deck.recycle_discard_pile()
	assert(deck.shuffle_count == 2)
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
	assert(deck.shuffle_count == 2)
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
	assert(deck.shuffle_count == 3)

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
	_test_suit_formats(card_db)
	print("=== ALL DECK TESTS PASSED ===")


static func _test_suit_formats(card_db: CardDatabase) -> void:
	var database: DeckDatabase = DeckDatabase.new(card_db)
	var valid_suits: Array[Variant] = [0, 1.0, 2, 3, "spades", "hearts", "diamonds", "clubs"]
	assert(_load_suit_fixture(database, valid_suits))
	var cards: Array[CardInstance] = database.create_instances()
	assert(cards.size() == 8)
	for index: int in range(cards.size()):
		assert(int(cards[index].suit) == index % 4)
		assert(cards[index].rank == 7)
		assert(cards[index].get_suit_name() == CardInstance.SUIT_NAMES[index % 4])
		assert(cards[index].is_red() == (index % 4 in [1, 2]))
	# Normalized entries retain the existing string-based public data format.
	assert(database.entries[0]["suit"] == "spades")
	assert(database.entries[1]["suit"] == "hearts")
	var invalid_suits: Array[Variant] = [-1, 4, 0.5, true, false, null, "1", "joker", {}, []]
	for invalid: Variant in invalid_suits:
		var suit_values: Array[Variant] = [0, invalid]
		assert(not _load_suit_fixture(database, suit_values))
		assert(not database.get_errors().is_empty())
		assert(database.get_card_count() == 0)
		assert(database.create_instances().is_empty())
	print("[PASS] Suit 0..3, legacy names, mixed data and invalid suit rejection")


static func _load_suit_fixture(database: DeckDatabase, suits: Array[Variant]) -> bool:
	var copies: Array[Dictionary] = []
	for suit_value: Variant in suits:
		copies.append({"suit": suit_value, "rank": 7})
	var path: String = OS.get_temp_dir().path_join("tactics_suits_%d_%d.json" % [OS.get_process_id(), Time.get_ticks_usec()])
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify({"deck_id": "suit_test", "cards": [{"card_id": "attack", "copies": copies}]}))
	file.close()
	var loaded: bool = database.load_from_file(path)
	assert(DirAccess.remove_absolute(path) == OK)
	return loaded
