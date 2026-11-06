
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


func validate_equip_weapon(actor_id: int, card_id: int) -> ActionResult:
	var blocked: String = turn_manager.get_transition_block_reason()
	if blocked.is_empty():
		blocked = turn_manager.get_effect_wait_reason()
	if not blocked.is_empty():
		return ActionResult.failure(blocked)
	var actor: Player = turn_manager.get_current_player()
	if actor == null or actor.player_id != actor_id or not actor.is_alive() or turn_manager.current_phase != TurnManager.Phase.PLAY:
		return ActionResult.failure("Chỉ trang bị vũ khí cho bản thân trong giai đoạn sử dụng bài của mình.")
	for card: CardInstance in actor.hand:
		if card.instance_id == card_id:
			if card.definition.is_equipment() and card.definition.equipment_slot == "weapon" and card.definition.attack_range > 0:
				return ActionResult.success()
			return ActionResult.failure("Lá đã chọn không phải vũ khí hợp lệ.")
	return ActionResult.failure("Không sở hữu lá vũ khí đã chọn.")


func validate_rescue(rescuer_id: int, target_id: int, card_id: int) -> ActionResult:
	var rescuer: Player = game_state.get_player(rescuer_id)
	var target: Player = game_state.get_player(target_id)
	if rescuer == null or target == null or not target.is_dying():
		return ActionResult.failure("Người cứu hoặc người hấp hối không hợp lệ.")
	if not rescuer.is_alive() and not (rescuer_id == target_id and rescuer.is_dying()):
		return ActionResult.failure("Chỉ người còn sống hoặc chính người hấp hối được cứu.")
	# Rescue is a response to Dying and does not require the rescuer's turn.
	return validate_heal_card(rescuer_id, card_id)


func validate_heal(actor_id: int, card_id: int) -> ActionResult:
	var blocked: String = turn_manager.get_transition_block_reason()
	if blocked.is_empty():
		blocked = turn_manager.get_effect_wait_reason()
	if not blocked.is_empty():
		return ActionResult.failure(blocked)
	var current: Player = turn_manager.get_current_player()
	var actor: Player = game_state.get_player(actor_id)
	if turn_manager.current_phase != TurnManager.Phase.PLAY or current == null or current.player_id != actor_id:
		return ActionResult.failure("Chỉ tự hồi máu trong giai đoạn sử dụng bài của mình.")
	if actor == null or not actor.is_alive() or not actor.is_wounded():
		return ActionResult.failure("Chỉ hồi máu cho người còn sống và chưa đầy HP.")
	return validate_heal_card(actor_id, card_id)


func validate_heal_card(actor_id: int, card_id: int) -> ActionResult:
	var actor: Player = game_state.get_player(actor_id)
	if actor == null:
		return ActionResult.failure("Người chơi không tồn tại.")
	for card: CardInstance in actor.hand:
		if card.instance_id == card_id:
			if card.definition.effects.size() != 1 or not card.definition.has_effect("restore_hp"):
				return ActionResult.failure("Lá đã chọn không phải lá hồi máu được hỗ trợ.")
			var amount: Variant = card.definition.effects[0].get("parameters", {}).get("amount", 0)
			if not (amount is int or amount is float):
				return ActionResult.failure("Lượng hồi máu không hợp lệ.")
			var number: float = float(amount)
			if not is_finite(number) or number <= 0 or number != floor(number) or number > 2147483647:
				return ActionResult.failure("Lượng hồi máu không hợp lệ.")
			return ActionResult.success()
	return ActionResult.failure("Không sở hữu lá hồi máu đã chọn.")


func get_tool_effect(actor_id: int, card_id: int) -> Dictionary:
	var actor: Player = game_state.get_player(actor_id)
	if actor == null:
		return {}
	for card: CardInstance in actor.hand:
		if card.instance_id == card_id:
			for effect: Dictionary in card.definition.effects:
				if effect["effect_id"] in ["discard", "steal_card"]:
					return effect.duplicate(true)
	return {}


func validate_tool_use(actor_id: int, target_id: int, card_id: int) -> ActionResult:
	var blocked: String = turn_manager.get_transition_block_reason()
	if blocked.is_empty():
		blocked = turn_manager.get_effect_wait_reason()
	if not blocked.is_empty():
		return ActionResult.failure(blocked)
	var current: Player = turn_manager.get_current_player()
	var actor: Player = game_state.get_player(actor_id)
	var target: Player = game_state.get_player(target_id)
	if turn_manager.current_phase != TurnManager.Phase.PLAY or current == null or current.player_id != actor_id:
		return ActionResult.failure("Chỉ người đang lượt dùng công cụ trong giai đoạn sử dụng bài.")
	if actor == null or target == null or not actor.is_alive() or not target.is_alive() or actor_id == target_id:
		return ActionResult.failure("Mục tiêu công cụ không hợp lệ.")
	var effect: Dictionary = get_tool_effect(actor_id, card_id)
	if effect.is_empty():
		return ActionResult.failure("Không sở hữu lá Hủy/Cướp hợp lệ.")
	var parameters: Dictionary = effect["parameters"]
	if parameters.get("card_count", 0) != 1:
		return ActionResult.failure("Chỉ hỗ trợ công cụ chọn đúng một lá.")
	if parameters.has("max_distance"):
		var maximum: Variant = parameters["max_distance"]
		if not (maximum is int or maximum is float):
			return ActionResult.failure("Tầm công cụ không hợp lệ.")
		var number: float = float(maximum)
		if not is_finite(number) or number < 0 or number != floor(number):
			return ActionResult.failure("Tầm công cụ không hợp lệ.")
		var distance: int = DistanceCalculator.calculate(game_state.players, actor_id, target_id)
		if distance < 0 or distance > number:
			return ActionResult.failure("Mục tiêu nằm ngoài tầm công cụ.")
	var zones: Array = parameters.get("target_zones", [])
	for zone: Variant in zones:
		if zone is String and zone in ["hand", "equipment", "judgment"]:
			if not target.get_zone(zone).is_empty():
				return ActionResult.success()
	return ActionResult.failure("Mục tiêu không có bài trong vùng được phép.")


func validate_tool_choice(actor_id: int, target_id: int, card_id: int, target_card_id: int, zone: String) -> ActionResult:
	var validation: ActionResult = validate_tool_use(actor_id, target_id, card_id)
	if not validation.valid:
		return validation
	var parameters: Dictionary = get_tool_effect(actor_id, card_id)["parameters"]
	if zone not in ["hand", "equipment", "judgment"] or not parameters.get("target_zones", []).has(zone):
		return ActionResult.failure("Không được chọn bài ở vùng này.")
	for card: CardInstance in game_state.get_player(target_id).get_zone(zone):
		if card.instance_id == target_card_id:
			return ActionResult.success()
	return ActionResult.failure("Lá bài đã chọn không còn thuộc mục tiêu.")


func validate_turn_discard(player_id: int, card_id: int) -> ActionResult:
	var blocked: String = turn_manager.get_transition_block_reason()
	if not blocked.is_empty():
		return ActionResult.failure(blocked)
	var effect_wait: String = turn_manager.get_effect_wait_reason()
	if not effect_wait.is_empty():
		return ActionResult.failure(effect_wait)
	var player: Player = turn_manager.get_current_player()
	if player == null or player.player_id != player_id or not player.is_alive():
		return ActionResult.failure("Chỉ người đang lượt được bỏ bài.")
	if turn_manager.current_phase != TurnManager.Phase.DISCARD:
		return ActionResult.failure("Chỉ bỏ bài giới hạn trong giai đoạn bỏ bài.")
	if turn_manager.get_required_discards() <= 0:
		return ActionResult.failure("Không cần bỏ thêm bài hoặc thiếu luật giới hạn.")
	for card: CardInstance in player.hand:
		if card.instance_id == card_id:
			return ActionResult.success()
	return ActionResult.failure("Không sở hữu lá bài đã chọn.")


func validate_attack(
	actor_id: int,
	target_id: int,
	card_id: int,
	attacks_used: int
) -> ActionResult:
	var blocked: String = turn_manager.get_transition_block_reason()
	if not blocked.is_empty():
		return ActionResult.failure(blocked)
	var effect_wait: String = turn_manager.get_effect_wait_reason()
	if not effect_wait.is_empty():
		return ActionResult.failure(effect_wait)
	if turn_manager.current_phase != TurnManager.Phase.PLAY:
		return ActionResult.failure(
			"Chỉ được Tấn công trong giai đoạn sử dụng bài."
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
