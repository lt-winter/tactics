
class_name RuleEngine
extends RefCounted

var base_rules: Dictionary = {}
var modifiers: Array[RuleModifier] = []


func load_base_rules(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("Không tìm thấy file luật: " + path)
		return false

	var file: FileAccess = FileAccess.open(
		path,
		FileAccess.READ
	)

	if file == null:
		return false

	var json: JSON = JSON.new()
	var content: String = file.get_as_text()
	file.close()

	if json.parse(content) != OK:
		push_error(json.get_error_message())
		return false

	var data: Variant = json.data

	if not (data is Dictionary):
		return false

	var parsed_data: Dictionary = data

	if not parsed_data.has("rules"):
		return false

	if not (parsed_data["rules"] is Dictionary):
		return false

	var parsed_rules: Dictionary = parsed_data["rules"]

	if not _validate_base_rules(parsed_rules):
		return false

	base_rules = parsed_rules.duplicate(true)
	return true


func _validate_base_rules(rules: Dictionary) -> bool:
	var required_rules: Array[String] = [
		"attack_limit_per_turn",
		"attack_range",
		"hand_limit"
	]

	for rule_id in required_rules:
		if not rules.has(rule_id):
			push_error("Thiếu luật: " + rule_id)
			return false

	for rule_id in ["attack_limit_per_turn", "attack_range"]:
		var value: Variant = rules[rule_id]

		if not _is_integer_value(value):
			push_error("Giá trị luật không hợp lệ: " + rule_id)
			return false

		if int(value) < 1:
			return false

	var hand_limit: Variant = rules["hand_limit"]

	if hand_limit is String:
		return hand_limit == "current_hp"

	if not _is_integer_value(hand_limit):
		return false

	return int(hand_limit) >= 0


func _is_integer_value(value: Variant) -> bool:
	if not (value is int or value is float):
		return false

	var number: float = float(value)

	return is_finite(number) and number == floor(number)


func add_modifier(modifier: RuleModifier) -> void:
	assert(modifier != null)
	modifiers.append(modifier)


func remove_modifier(source_id: String) -> void:
	for i in range(modifiers.size() - 1, -1, -1):
		if modifiers[i].source_id == source_id:
			modifiers.remove_at(i)


func clear_modifiers() -> void:
	modifiers.clear()


func get_rule(
	rule_id: String,
	context: Dictionary = {},
	rule_context: RuleContext = null
) -> Dictionary:
	if not base_rules.has(rule_id):
		return {}

	var base_value: Variant = base_rules[rule_id]

	if base_value is String:
		if base_value != "current_hp":
			return {}

		if not context.has("current_hp"):
			return {}

		var hp_value: Variant = context["current_hp"]

		if not _is_integer_value(hp_value):
			return {}

		if int(hp_value) < 0:
			return {}

		base_value = int(hp_value)

	var result: Dictionary = {
		"value": int(base_value),
		"unlimited": false,
		"source": "base_rule"
	}

	var selected: RuleModifier = null

	for modifier in modifiers:
		if modifier.rule_id != rule_id:
			continue

		if rule_context == null:
			if modifier.owner_id != 0:
				continue
		else:
			if not modifier.applies_to(rule_context.actor_id):
				continue

		if selected == null:
			selected = modifier
			continue

		if modifier.priority > selected.priority:
			selected = modifier

	if selected == null:
		return result

	match selected.operation:
		"set":
			result["value"] = selected.value
			result["unlimited"] = false
			result["source"] = selected.source_id

		"remove_limit":
			result["unlimited"] = true
			result["source"] = selected.source_id

	return result
