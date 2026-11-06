
class_name ActionValidator
extends RefCounted

var game_state: GameState
var turn_manager: TurnManager
var rule_engine: RuleEngine


func _init(
	state: GameState,
	turns: TurnManager,
	rules: RuleEngine
) -> void:
	game_state = state
	turn_manager = turns
	rule_engine = rules


func validate_attack(
	actor_id: int,
	target_id: int,
	card_id: int,
	attacks_used: int
) -> ActionResult:
	if turn_manager.current_phase != TurnManager.Phase.PLAY:
		return ActionResult.failure(
			"Chỉ được Tấn công trong PLAY Phase."
		)

	var current_player: Player = turn_manager.get_current_player()

	if current_player == null:
		return ActionResult.failure("Không có người đang lượt.")

	if current_player.player_id != actor_id:
		return ActionResult.failure("Không phải lượt của người chơi.")

	var actor: Player = game_state.get_player(actor_id)
	var target: Player = game_state.get_player(target_id)

	if actor == null or target == null:
		return ActionResult.failure("Người chơi không tồn tại.")

	if not actor.is_alive() or not target.is_alive():
		return ActionResult.failure("Người chơi đã bị loại.")

	if actor_id == target_id:
		return ActionResult.failure("Không thể tự Tấn công.")

	if attacks_used < 0:
		return ActionResult.failure("Bộ đếm Tấn công không hợp lệ.")

	var selected_card: CardInstance = null

	for card in actor.hand:
		if card.instance_id == card_id:
			selected_card = card
			break

	if selected_card == null:
		return ActionResult.failure("Không sở hữu lá bài.")

	if not selected_card.definition.has_effect("deal_attack"):
		return ActionResult.failure("Lá bài không có hiệu ứng Tấn công.")

	var context: RuleContext = RuleContext.new(
		actor_id,
		target_id,
		current_player.player_id,
		{"current_hp": actor.hp}
	)

	var limit_rule: Dictionary = rule_engine.get_rule(
		"attack_limit_per_turn",
		context.values,
		context
	)

	if limit_rule.is_empty():
		return ActionResult.failure("Không tìm thấy luật giới hạn Tấn công.")

	var unlimited: bool = limit_rule["unlimited"]

	if not unlimited:
		var attack_limit: int = limit_rule["value"]

		if attacks_used >= attack_limit:
			return ActionResult.failure(
				"Đã đạt giới hạn Tấn công trong lượt."
			)

	var range_rule: Dictionary = rule_engine.get_rule(
		"attack_range",
		context.values,
		context
	)

	if range_rule.is_empty():
		return ActionResult.failure("Không tìm thấy luật tầm đánh.")

	var distance: int = DistanceCalculator.calculate(
		game_state.players,
		actor_id,
		target_id
	)

	if distance < 0:
		return ActionResult.failure("Không thể tính khoảng cách.")

	var attack_range: int = range_rule["value"]

	if not range_rule["unlimited"] and distance > attack_range:
		return ActionResult.failure("Mục tiêu nằm ngoài tầm đánh.")

	return ActionResult.success()
