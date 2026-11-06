
class_name RuleEngineTest
extends RefCounted


static func run_all() -> void:
	var engine: RuleEngine = RuleEngine.new()

	assert(
		engine.load_base_rules(
			"res://data/rules/base_rules.json"
		)
	)

	print("=== RULE ENGINE TEST ===")

	# Test 1: Luật cơ bản
	var rule: Dictionary = engine.get_rule(
		"attack_limit_per_turn"
	)

	assert(rule["value"] == 1)
	assert(rule["unlimited"] == false)

	print("[PASS] Luật cơ bản")

	# Test 2: Hiệu ứng trang bị
	var equipment: RuleModifier = RuleModifier.new(
		"attack_limit_per_turn",
		"set",
		2,
		RuleModifier.Source.CARD_EFFECT,
		"double_shot"
	)

	engine.add_modifier(equipment)

	rule = engine.get_rule("attack_limit_per_turn")

	assert(rule["value"] == 2)
	assert(rule["source"] == "double_shot")

	print("[PASS] Hiệu ứng trang bị")

	# Test 3: Kỹ năng tướng ghi đè trang bị
	var character_skill: RuleModifier = RuleModifier.new(
		"attack_limit_per_turn",
		"remove_limit",
		0,
		RuleModifier.Source.CHARACTER_SKILL,
		"combo_attack"
	)

	engine.add_modifier(character_skill)

	rule = engine.get_rule("attack_limit_per_turn")

	assert(rule["unlimited"] == true)
	assert(rule["source"] == "combo_attack")

	print("[PASS] Kỹ năng tướng ưu tiên cao hơn")

	# Test 4: Kỹ năng không ảnh hưởng luật khác
	rule = engine.get_rule("attack_range")

	assert(rule["value"] == 1)
	assert(rule["unlimited"] == false)

	print("[PASS] Modifier chỉ tác động đúng luật")

	# Test 5: Gỡ kỹ năng tướng
	engine.remove_modifier("combo_attack")

	rule = engine.get_rule("attack_limit_per_turn")

	assert(rule["value"] == 2)
	assert(rule["unlimited"] == false)

	print("[PASS] Gỡ kỹ năng tướng")

	# Test 6: Gỡ trang bị
	engine.remove_modifier("double_shot")

	rule = engine.get_rule("attack_limit_per_turn")

	assert(rule["value"] == 1)

	print("[PASS] Khôi phục luật cơ bản")

	# Test 7: Giới hạn bài theo HP
	rule = engine.get_rule(
		"hand_limit",
		{"current_hp": 3}
	)

	assert(rule["value"] == 3)

	print("[PASS] Giới hạn bài theo HP")

	# Test 8: Không có HP trong context
	rule = engine.get_rule("hand_limit")

	assert(rule.is_empty())

	print("[PASS] Không sử dụng context thiếu dữ liệu")

	# Test 9: Luật không tồn tại
	rule = engine.get_rule("unknown_rule")

	assert(rule.is_empty())

	print("[PASS] Xử lý luật không tồn tại")

	print("=== ALL RULE ENGINE TESTS PASSED ===")
