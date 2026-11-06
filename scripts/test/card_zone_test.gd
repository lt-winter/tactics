
class_name CardZoneTest
extends RefCounted


static func run_all() -> void:
	var card_db := CardDatabase.new()

	if not card_db.load_from_file("res://data/cards.json"):
		push_error("Không thể nạp cards.json")
		return

	var deck_db := DeckDatabase.new(card_db)

	if not deck_db.load_from_file(
		"res://data/decks/standard.json"
	):
		for error in deck_db.get_errors():
			push_error(error)
		return

	var cards := deck_db.create_instances()
	var deck := Deck.new(cards)

	var player_a := Player.new(1, "Người chơi A", 4)
	var player_b := Player.new(2, "Người chơi B", 4)

	var manager := CardZoneManager.new(
		deck,
		[player_a, player_b]
	)

	var first_card := cards[0]
	var first_id := first_card.instance_id
	var total := cards.size()

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

	# Không thể chuyển từ vùng cũ
	assert(
		not manager.transfer_card(
			first_id,
			"hand", 1,
			"discard", 0
		)
	)

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

	# Kiểm tra không trùng ID
	assert(manager.validate_unique_cards())

	print("[PASS] Chuyển bài giữa các vùng")
	print("[PASS] Không chuyển từ vùng sai")
	print("[PASS] Không trùng instance_id")
	print("=== ALL CARD ZONE TESTS PASSED ===")
