
class_name DeckTest
extends RefCounted


static func run_all() -> void:
	var card_db := CardDatabase.new()

	assert(
		card_db.load_from_file("res://data/cards.json"),
        "Không thể nạp cards.json"
	)

	var deck_db := DeckDatabase.new(card_db)

	var loaded := deck_db.load_from_file(
        "res://data/decks/standard.json"
	)

	if not loaded:
		for error in deck_db.get_errors():
			push_error(error)
		return

	print("=== DECK SYSTEM TEST ===")

	var cards := deck_db.create_instances()
	var total := cards.size()

	# 1. Kiểm tra số lượng
	assert(total == deck_db.get_card_count())
	assert(total > 0)
	print("[PASS] Số lượng: ", total)

	# 2. Kiểm tra ID duy nhất
	var ids: Dictionary = {}

	for card in cards:
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
	var deck := Deck.new(cards)
	deck.shuffle()

	assert(deck.get_draw_count() == total)
	assert(deck.get_discard_count() == 0)

	print("[PASS] Khởi tạo và xáo bài")

	# 4. Rút hết bộ bài
	var drawn: Array[CardInstance] = []
	var drawn_ids: Dictionary = {}

	for i in range(total):
		var card := deck.draw()

		assert(card != null)
		assert(not drawn_ids.has(card.instance_id))

		drawn_ids[card.instance_id] = true
		drawn.append(card)

	assert(deck.get_draw_count() == 0)
	assert(deck.draw() == null)

	print("[PASS] Rút hết bài, không trùng ID")

	# 5. Chuyển toàn bộ bài sang chồng bỏ
	for card in drawn:
		deck.discard(card)

	assert(deck.get_discard_count() == total)
	assert(deck.get_draw_count() == 0)

	print("[PASS] Bỏ bài")

	# 6. Tái tạo chồng rút
	var recycled_card := deck.draw()

	assert(recycled_card != null)
	assert(deck.get_draw_count() == total - 1)
	assert(deck.get_discard_count() == 0)

	print("[PASS] Tái sử dụng chồng bỏ")

	# 7. Kiểm tra bảo toàn bài
	var final_ids: Dictionary = {}

	final_ids[recycled_card.instance_id] = true

	for card in deck.draw_pile:
		assert(not final_ids.has(card.instance_id))
		final_ids[card.instance_id] = true

	assert(final_ids.size() == total)

	print("[PASS] Bảo toàn toàn bộ lá bài")
	print("=== ALL DECK TESTS PASSED ===")
