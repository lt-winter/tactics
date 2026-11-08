class_name CardDatabase
extends RefCounted

const DEFAULT_MANIFEST_PATH: String = "res://data/cards_manifest.json"

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
	var root: Dictionary = _read_object(path)
	if not errors.is_empty():
		return false
	var temporary: Dictionary = {}
	var origins: Dictionary = {}
	if root.has("files"):
		if root.has("cards") or not root["files"] is Array or root["files"].is_empty():
			errors.append(path + ": manifest cần mảng files không rỗng, không kèm cards.")
			return false
		var seen_paths: Dictionary = {}
		for index: int in range(root["files"].size()):
			var entry: Variant = root["files"][index]
			var location: String = "%s.files[%d]" % [path, index]
			if not entry is String:
				errors.append(location + ": đường dẫn phải là chuỗi res:// tới file JSON.")
				continue
			var source_path: String = entry
			if not source_path.begins_with("res://") or not source_path.ends_with(".json"):
				errors.append(location + ": đường dẫn không hợp lệ: " + source_path)
				continue
			source_path = source_path.simplify_path()
			if seen_paths.has(source_path):
				errors.append(location + ": file nhóm bị lặp: " + source_path)
				continue
			seen_paths[source_path] = true
			var error_count: int = errors.size()
			var group: Dictionary = _read_object(source_path)
			if errors.size() == error_count:
				_merge_group(group, source_path, temporary, origins)
	else:
		# Retain single-group loading for schema fixtures and public API compatibility.
		_merge_group(root, path, temporary, origins)
	if not errors.is_empty():
		return false
	definitions = temporary
	return true


func _read_object(path: String) -> Dictionary:

	if not FileAccess.file_exists(path):
		errors.append("Không tìm thấy file: " + path)
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	if file == null:
		errors.append(
			"%s: không mở được file. Mã lỗi: %s"
			% [path, FileAccess.get_open_error()]
		)
		return {}

	var content: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_error: Error = json.parse(content)

	if parse_error != OK:
		errors.append(
			"%s: lỗi JSON dòng %d: %s"
			% [path, json.get_error_line(), json.get_error_message()]
		)
		return {}

	var root: Variant = json.data

	if not (root is Dictionary):
		errors.append(path + ": dữ liệu gốc phải là Object.")
		return {}
	return root


func _merge_group(root: Dictionary, path: String, temporary: Dictionary, origins: Dictionary) -> void:

	if root.has("files") or not root.has("cards") or not (root["cards"] is Array):
		errors.append(path + ": thiếu mảng cards.")
		return

	for i: int in range(root["cards"].size()):
		var card: Variant = root["cards"][i]
		var location: String = "%s.cards[%d]" % [path, i]

		if not _validate_card(card, location):
			continue

		var card_id: String = card["id"]

		if temporary.has(card_id):
			errors.append("ID bị trùng '%s': %s; đã khai báo tại %s." % [card_id, location, origins[card_id]])
			continue

		temporary[card_id] = card.duplicate(true)
		origins[card_id] = location


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
	if card["category"] == "equipment" and card.has("equipment_slot"):
		var slot: Variant = card["equipment_slot"]
		if not slot is String or slot not in CardDefinition.EQUIPMENT_SLOTS:
			errors.append(location + " có equipment_slot chưa được hỗ trợ.")
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
	if card["category"] == "equipment" and card["subcategory"] == "armor" and card.get("equipment_slot") != "armor":
		errors.append(location + " cần equipment_slot=armor.")
		return false
	if card["category"] == "equipment" and card.has("equipment_slot"):
		if card["equipment_slot"] == "armor" and card["subcategory"] != "armor":
			errors.append(location + " cần subcategory=armor cho slot phòng ngự.")
			return false

	if str(card.get("equipment_slot", "")) in AccessoryEffects.SLOTS or card["subcategory"] == "accessory":
		if card["category"] != "equipment" or card["subcategory"] != "accessory" or card["effects"].size() != 1 or not card["effects"][0] is Dictionary or not AccessoryEffects.valid_effect(card["effects"][0], str(card.get("equipment_slot", ""))):
			errors.append(location + " cần slot phụ kiện và hiệu ứng modify_distance hợp lệ.")
			return false

	if card["effects"].is_empty() and not (card["category"] == "equipment" and card.get("equipment_slot") == "armor"):
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
			continue
		elif not (effect["effect_id"] is String):
			errors.append(effect_path + ".effect_id phải là chuỗi.")
			valid = false
			continue
		elif effect["effect_id"].strip_edges().is_empty():
			errors.append(effect_path + ".effect_id không được rỗng.")
			valid = false
			continue

		if not effect.has("parameters"):
			errors.append(effect_path + " thiếu parameters.")
			valid = false
			continue

		var params: Variant = effect["parameters"]

		if not (params is Dictionary):
			errors.append(effect_path + ".parameters phải là Object.")
			valid = false
			continue

		if effect.get("effect_id") == "modify_distance" and (card["category"] != "equipment" or card["subcategory"] != "accessory" or card["effects"].size() != 1 or not AccessoryEffects.valid_effect(effect, str(card.get("equipment_slot", "")))):
			errors.append(effect_path + " có tham số khoảng cách phụ kiện không hợp lệ.")
			valid = false
		if effect.get("effect_id") == "aoe_response_damage":
			if card["category"] != "tool" or card["effects"].size() != 1 or not AoeResolution.valid_parameters(params):
				errors.append(effect_path + " có cấu hình AOE không được hỗ trợ.")
				valid = false
		if ArmorEffectRegistry.HOOKS.has(effect.get("effect_id")):
			if card["category"] != "equipment" or card.get("equipment_slot") != "armor" or card["effects"].size() != 1 or not ArmorEffectRegistry.valid_effect(effect):
				errors.append(effect_path + " có cấu hình trang bị phòng ngự không hợp lệ.")
				valid = false
		if effect.get("effect_id") in ["draw_cards", "heal_all_players"]:
			if card["category"] != "tool" or card["effects"].size() != 1 or not SupportToolResolution.valid_effect(effect):
				errors.append(effect_path + " có cấu hình công cụ hỗ trợ không hợp lệ.")
				valid = false

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
