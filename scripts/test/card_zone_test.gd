
class_name CardZoneTest
extends RefCounted


static func run_all() -> void:
	var card_db: CardDatabase = CardDatabase.new()
	assert(card_db.load_from_file("res://data/cards.json"))

	var deck_db: DeckDatabase = DeckDatabase.new(card_db)

	assert(deck_db.load_from_file(
		"res://data/decks/standard.json"
	))

	var cards: Array[CardInstance] = deck_db.create_instances()
	var deck: Deck = Deck.new(cards)

	var player_a: Player = Player.new(1, "Người chơi A", 4)
	var player_b: Player = Player.new(2, "Người chơi B", 4)

	var manager: CardZoneManager = CardZoneManager.new(
		deck,
		[player_a, player_b]
	)

	var first_card: CardInstance = cards[0]
	var first_id: int = first_card.instance_id
	var total: int = cards.size()
	assert(manager.validate_integrity())

	# Chuyển một lá từ chồng rút sang tay A
	assert(
		manager.transfer_card(
			first_id,
			"draw", 0,
			"hand", 1
		)
	)

	assert(player_a.hand.size() == 1)
	assert(deck.get_draw_count() == total - 1)
	assert(player_a.hand[0] == first_card)
	assert(manager.validate_integrity())

	# A chuyển bài cho B
	assert(
		manager.transfer_card(
			first_id,
			"hand", 1,
			"hand", 2
		)
	)

	assert(player_a.hand.is_empty())
	assert(player_b.hand.size() == 1)
	assert(player_b.hand[0] == first_card)
	assert(manager.validate_integrity())

	# Không thể chuyển từ vùng cũ
	assert(
		not manager.transfer_card(
			first_id,
			"hand", 1,
			"discard", 0
		)
	)

	assert(player_a.hand.is_empty())
	assert(player_b.hand.size() == 1)
	assert(deck.get_discard_count() == 0)
	assert(manager.validate_integrity())

	# B bỏ bài
	assert(
		manager.transfer_card(
			first_id,
			"hand", 2,
			"discard", 0
		)
	)

	assert(player_b.hand.is_empty())
	assert(deck.get_discard_count() == 1)

	# Kiểm tra ID duy nhất, đúng bộ bài gốc và bảo toàn toàn bộ lá bài.
	assert(deck.get_draw_count() == total - 1)
	assert(deck.discard_pile[0] == first_card)
	assert(manager.validate_integrity())

	print("[PASS] Chuyển bài giữa các vùng")
	print("[PASS] Không chuyển từ vùng sai")
	print("[PASS] Không trùng instance_id")
	print("=== ALL CARD ZONE TESTS PASSED ===")
