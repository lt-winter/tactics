
class_name RuleContextTest
extends RefCounted


static func run_all() -> void:
	var engine: RuleEngine = RuleEngine.new()

	assert(
		engine.load_base_rules(
			"res://data/rules/base_rules.json"
		)
	)

	print("=== RULE CONTEXT TEST ===")

	var context_a: RuleContext = RuleContext.new(
		1, 2, 1, {"current_hp": 4}
	)

	var context_b: RuleContext = RuleContext.new(
		2, 1, 1, {"current_hp": 3}
	)

	var context_c: RuleContext = RuleContext.new(
		3, 0, 1, {"current_hp": 2}
	)

	assert(context_a.is_actor_turn())
	assert(not context_b.is_actor_turn())
	assert(context_a.has_target())
	assert(not context_c.has_target())

	print("[PASS] Khởi tạo RuleContext")

	# Player A có Liên kích
	var combo: RuleModifier = RuleModifier.new(
		"attack_limit_per_turn",
		"remove_limit",
		0,
		RuleModifier.Source.CHARACTER_SKILL,
		"combo_attack",
		1
	)

	engine.add_modifier(combo)

	# Player B có Song kích
	var double_shot: RuleModifier = RuleModifier.new(
		"attack_limit_per_turn",
		"set",
		2,
		RuleModifier.Source.CARD_EFFECT,
		"double_shot",
		2
	)

	engine.add_modifier(double_shot)

	var rule_a: Dictionary = engine.get_rule(
		"attack_limit_per_turn",
		{},
		context_a
	)

	assert(rule_a["unlimited"] == true)
	assert(rule_a["source"] == "combo_attack")

	print("[PASS] Player A có Liên kích")

	var rule_b: Dictionary = engine.get_rule(
		"attack_limit_per_turn",
		{},
		context_b
	)

	assert(rule_b["value"] == 2)
	assert(rule_b["unlimited"] == false)
	assert(rule_b["source"] == "double_shot")

	print("[PASS] Player B có Song kích")

	var rule_c: Dictionary = engine.get_rule(
		"attack_limit_per_turn",
		{},
		context_c
	)

	assert(rule_c["value"] == 1)
	assert(rule_c["unlimited"] == false)

	print("[PASS] Player C dùng luật cơ bản")

	# Hiệu ứng toàn cục: giới hạn Tấn công = 3
	var global_effect: RuleModifier = RuleModifier.new(
		"attack_limit_per_turn",
		"set",
		3,
		RuleModifier.Source.BASE_RULE,
		"global_attack_rule",
		0
	)

	engine.add_modifier(global_effect)

	rule_c = engine.get_rule(
		"attack_limit_per_turn",
		{},
		context_c
	)

	assert(rule_c["value"] == 3)
	assert(rule_c["source"] == "global_attack_rule")

	rule_a = engine.get_rule(
		"attack_limit_per_turn",
		{},
		context_a
	)

	assert(rule_a["unlimited"] == true)

	rule_b = engine.get_rule(
		"attack_limit_per_turn",
		{},
		context_b
	)

	assert(rule_b["value"] == 2)

	print("[PASS] Hiệu ứng toàn cục và ưu tiên")

	# Không có RuleContext thì chỉ áp dụng
	# các modifier toàn cục
	var global_rule: Dictionary = engine.get_rule(
		"attack_limit_per_turn"
	)

	assert(global_rule["value"] == 3)

	print("[PASS] Không rò rỉ hiệu ứng cá nhân")

	# Giới hạn bài trên tay theo HP
	var hand_rule: Dictionary = engine.get_rule(
		"hand_limit",
		context_b.values,
		context_b
	)

	assert(hand_rule["value"] == 3)

	print("[PASS] Luật sử dụng dữ liệu ngữ cảnh")

	# Gỡ kỹ năng của A
	engine.remove_modifier("combo_attack")

	rule_a = engine.get_rule(
		"attack_limit_per_turn",
		{},
		context_a
	)

	assert(rule_a["value"] == 3)
	assert(rule_a["unlimited"] == false)

	print("[PASS] Gỡ kỹ năng cá nhân")

	print("=== ALL RULE CONTEXT TESTS PASSED ===")
