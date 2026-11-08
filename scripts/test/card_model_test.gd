
class_name CardModelTest
extends RefCounted


static func run_all() -> void:
	var database := CardDatabase.new()

	if not database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH):
		for error in database.get_errors():
			push_error(error)
		return

	# Kiểm tra định nghĩa
	var attack := database.get_definition("attack")

	assert(attack != null)
	assert(attack.is_basic())
	assert(attack.has_effect("deal_attack"))

	print("[PASS] CardDefinition")

	# Tạo hai lá bài cùng loại
	var card1 := CardInstance.new(
		1,
		attack,
		CardInstance.Suit.HEARTS,
		7
	)

	var card2 := CardInstance.new(
		2,
		attack,
		CardInstance.Suit.SPADES,
		13
	)

	assert(card1.instance_id != card2.instance_id)
	assert(card1.definition == card2.definition)

	assert(card1.get_display_name() == "Tấn công 7♥")
	assert(card2.get_display_name() == "Tấn công K♠")

	assert(card1.is_red())
	assert(card2.is_black())

	print("[PASS] CardInstance")
	print("[PASS] Chất và số bài")

	# Kiểm tra lá công cụ
	var steal := database.get_definition("steal")

	assert(steal != null)
	assert(steal.is_tool())
	assert(steal.has_effect("steal_card"))

	print("[PASS] Phân loại bài")

	print("=== ALL CARD MODEL TESTS PASSED ===")
