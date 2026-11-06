
class_name DeckDatabase
extends RefCounted

var card_database: CardDatabase
var errors: Array[String] = []
var entries: Array[Dictionary] = []
var deck_id: String = ""


func _init(database: CardDatabase) -> void:
	card_database = database


func load_from_file(path: String) -> bool:
	errors.clear()
	entries.clear()
	deck_id = ""

	if card_database == null:
		errors.append("CardDatabase chưa được khởi tạo.")
		return false

	if not FileAccess.file_exists(path):
		errors.append("Không tìm thấy file: " + path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		errors.append("Không thể mở file: " + path)
		return false

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()

	if json.parse(content) != OK:
		errors.append(
            "Lỗi JSON dòng %d: %s"
			% [json.get_error_line(), json.get_error_message()]
		)
		return false

	var root: Variant = json.data

	if not (root is Dictionary):
		errors.append("Gốc JSON phải là Object.")
		return false

	if not root.has("deck_id") or not (
		root["deck_id"] is String
	):
		errors.append("Thiếu deck_id hợp lệ.")
		return false

	if root["deck_id"].strip_edges().is_empty():
		errors.append("deck_id không được rỗng.")
		return false

	if not root.has("cards") or not (
		root["cards"] is Array
	):
		errors.append("Thiếu mảng cards.")
		return false

	var temporary: Array[Dictionary] = []
	var seen_card_ids: Dictionary = {}

	for i in range(root["cards"].size()):
		var group: Variant = root["cards"][i]
		var location := "cards[%d]" % i

		if not (group is Dictionary):
			errors.append(location + " phải là Object.")
			continue

		var card_id: Variant = group.get("card_id")

		if not (card_id is String):
			errors.append(location + " thiếu card_id.")
			continue

		if not card_database.has_card(card_id):
			errors.append("Không tìm thấy loại bài: " + card_id)
			continue

		if seen_card_ids.has(card_id):
			errors.append("Nhóm card_id bị trùng: " + card_id)
			continue

		seen_card_ids[card_id] = true

		var copies: Variant = group.get("copies")

		if not (copies is Array):
			errors.append(location + " thiếu mảng copies.")
			continue

		if copies.is_empty():
			errors.append(location + " có copies rỗng.")
			continue

		for j in range(copies.size()):
			var copy_data: Variant = copies[j]
			var copy_path := "%s.copies[%d]" % [location, j]

			if not (copy_data is Dictionary):
				errors.append(copy_path + " phải là Object.")
				continue

			var suit_value: Variant = copy_data.get("suit")
			var rank_value: Variant = copy_data.get("rank")

			var suit_name: String = _parse_suit_name(suit_value)
			if suit_name.is_empty():
				errors.append(copy_path + " có suit không hợp lệ: dùng số nguyên 0..3 hoặc tên chất.")
				continue
			
			if not (rank_value is int or rank_value is float):
				errors.append(copy_path + " có rank không phải số.")
				continue

			if not is_finite(float(rank_value)):
				errors.append(copy_path + " có rank không hữu hạn.")
				continue

			if float(rank_value) != floor(float(rank_value)):
				errors.append(copy_path + " có rank không phải số nguyên.")
				continue

			if rank_value < 1 or rank_value > 13:
				errors.append(copy_path + " có rank ngoài 1..13.")
				continue

			temporary.append({
				"card_id": card_id,
				"suit": suit_name,
				"rank": rank_value
			})

	if not errors.is_empty():
		return false

	if temporary.is_empty():
		errors.append("Bộ bài không được rỗng.")
		return false

	entries = temporary
	deck_id = root["deck_id"]
	return true


func _parse_suit_name(value: Variant) -> String:
	if value is String:
		return value if CardInstance.is_valid_suit_name(value) else ""
	if not (value is int or value is float):
		return ""
	var number: float = float(value)
	if not is_finite(number) or number != floor(number):
		return ""
	if number < CardInstance.Suit.SPADES or number > CardInstance.Suit.CLUBS:
		return ""
	return CardInstance.SUIT_NAMES[int(number)]


func create_instances() -> Array[CardInstance]:
	var result: Array[CardInstance] = []
	var next_id := 1

	for entry in entries:
		var definition := card_database.get_definition(
			entry["card_id"]
		)

		var card := CardInstance.new(
			next_id,
			definition,
			CardInstance.suit_from_name(entry["suit"]),
			entry["rank"]
		)

		result.append(card)
		next_id += 1

	return result


func get_card_count() -> int:
	return entries.size()


func get_errors() -> Array[String]:
	return errors.duplicate()
