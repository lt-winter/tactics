class_name CardDatabase
extends RefCounted

const VALID_CATEGORIES = [
	"basic",
	"tool",
    "equipment"
]

const VALID_ZONES = [
	"hand",
	"equipment",
    "judgment"
]

var definitions: Dictionary = {}
var errors: Array[String] = []


func load_from_file(path: String) -> bool:
	definitions.clear()
	errors.clear()

	if not FileAccess.file_exists(path):
		errors.append("Không tìm thấy file: " + path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		errors.append(
            "Không mở được file. Mã lỗi: %s"
			% FileAccess.get_open_error()
		)
		return false

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_error := json.parse(content)

	if parse_error != OK:
		errors.append(
            "Lỗi JSON dòng %d: %s"
			% [json.get_error_line(), json.get_error_message()]
		)
		return false

	var root: Variant = json.data

	if not (root is Dictionary):
		errors.append("Dữ liệu gốc phải là Object.")
		return false

	if not root.has("cards") or not (root["cards"] is Array):
		errors.append("Thiếu mảng cards.")
		return false

	var temporary: Dictionary = {}

	for i in range(root["cards"].size()):
		var card: Variant = root["cards"][i]
		var location := "cards[%d]" % i

		if not _validate_card(card, location):
			continue

		var card_id: String = card["id"]

		if temporary.has(card_id):
			errors.append("ID bị trùng: " + card_id)
			continue

		temporary[card_id] = card.duplicate(true)

	if not errors.is_empty():
		return false

	definitions = temporary
	return true


func _validate_card(card: Variant, location: String) -> bool:
	if not (card is Dictionary):
		errors.append(location + " phải là Object.")
		return false

	var valid := true

	for field in [
		"id", "name", "category",
		"subcategory", "description"
	]:
		if not card.has(field):
			errors.append(location + " thiếu " + field)
			valid = false
		elif not (card[field] is String):
			errors.append(location + "." + field + " phải là chuỗi.")
			valid = false
		elif card[field].strip_edges().is_empty():
			errors.append(location + "." + field + " không được rỗng.")
			valid = false

	if not valid:
		return false

	if not VALID_CATEGORIES.has(card["category"]):
		errors.append(
			location + " có category không hợp lệ: "
			+ card["category"]
		)
		valid = false

	if not card.has("effects") or not (card["effects"] is Array):
		errors.append(location + " thiếu mảng effects.")
		return false
	if card["category"] == "equipment" and card["subcategory"] == "weapon":
		var weapon_range: Variant = card.get("range")
		if card.get("equipment_slot") != "weapon" or not (weapon_range is int or weapon_range is float):
			errors.append(location + " cần equipment_slot=weapon và range nguyên dương.")
			return false
		var range_number: float = float(weapon_range)
		if not is_finite(range_number) or range_number < 1 or range_number != floor(range_number) or range_number > 2147483647:
			errors.append(location + " có range vũ khí không hợp lệ.")
			return false

	if card["effects"].is_empty():
		errors.append(location + " phải có ít nhất một effect.")
		valid = false

	for i in range(card["effects"].size()):
		var effect: Variant = card["effects"][i]
		var effect_path := "%s.effects[%d]" % [location, i]

		if not (effect is Dictionary):
			errors.append(effect_path + " phải là Object.")
			valid = false
			continue

		if not effect.has("effect_id"):
			errors.append(effect_path + " thiếu effect_id.")
			valid = false
		elif not (effect["effect_id"] is String):
			errors.append(effect_path + ".effect_id phải là chuỗi.")
			valid = false
		elif effect["effect_id"].strip_edges().is_empty():
			errors.append(effect_path + ".effect_id không được rỗng.")
			valid = false

		if not effect.has("parameters"):
			errors.append(effect_path + " thiếu parameters.")
			valid = false
			continue

		var params: Variant = effect["parameters"]

		if not (params is Dictionary):
			errors.append(effect_path + ".parameters phải là Object.")
			valid = false
			continue

		if params.has("target_zones"):
			var zones: Variant = params["target_zones"]

			if not (zones is Array):
				errors.append(
					effect_path + ".target_zones phải là Array."
				)
				valid = false
			else:
				for zone in zones:
					if not (zone is String):
						errors.append(
							effect_path + " chứa vùng không phải chuỗi."
						)
						valid = false
					elif not VALID_ZONES.has(zone):
						errors.append(
							effect_path + " có vùng không hợp lệ: "
							+ zone
						)
						valid = false

	return valid


func has_card(card_id: String) -> bool:
	return definitions.has(card_id)


func get_card(card_id: String) -> Dictionary:
	if not definitions.has(card_id):
		return {}

	return definitions[card_id].duplicate(true)


func get_all_cards() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for card_id in definitions:
		result.append(definitions[card_id].duplicate(true))

	return result


func get_card_count() -> int:
	return definitions.size()


func get_errors() -> Array[String]:
	return errors.duplicate()
	
# Kết nối CardDefinition với CardDatabase
func get_definition(card_id: String) -> CardDefinition:
	var data := get_card(card_id)

	if data.is_empty():
		return null

	return CardDefinition.new(data)
