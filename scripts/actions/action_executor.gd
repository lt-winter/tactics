
class_name ActionExecutor
extends RefCounted

var game_state: GameState
var turn_manager: TurnManager
var validator: ActionValidator
var resolver: EffectResolver

var damage_pipeline: DamagePipeline

var attacks_used: int = 0
var pending_attack: Dictionary = {}

var dying_manager: DyingManager

func _init(
	state: GameState,
	turns: TurnManager,
	rules: RuleEngine
) -> void:
	game_state = state
	turn_manager = turns
	validator = ActionValidator.new(state, turns, rules)
	resolver = EffectResolver.new(state)
	damage_pipeline = DamagePipeline.new(resolver)
	dying_manager = DyingManager.new(state)

func reset_turn_counters() -> void:
	if not pending_attack.is_empty():
		push_error("Không thể reset khi đang chờ phản ứng.")
		return

	attacks_used = 0


func use_attack(
	actor_id: int,
	target_id: int,
	card_id: int
) -> ActionResult:
	
	if not pending_attack.is_empty():
		return ActionResult.failure(
			"Đang có một đòn Tấn công chờ phản ứng."
		)

	var validation: ActionResult = validator.validate_attack(
		actor_id,
		target_id,
		card_id,
		attacks_used
	)

	if not validation.valid:
		return validation

	var actor: Player = game_state.get_player(actor_id)

	if actor == null:
		return ActionResult.failure("Người chơi không tồn tại.")

	var attack_card: CardInstance = null

	for card in actor.hand:
		if card.instance_id == card_id:
			attack_card = card
			break

	if attack_card == null:
		return ActionResult.failure("Không tìm thấy lá Tấn công.")

	var damage: int = 1

	for effect in attack_card.definition.effects:
		if effect["effect_id"] == "deal_attack":
			var parameters: Dictionary = effect["parameters"]
			var damage_value: Variant = parameters.get("damage", 1)

			if damage_value is int or damage_value is float:
				damage = int(damage_value)

			break

	if damage <= 0:
		return ActionResult.failure("Sát thương không hợp lệ.")

	var moved: bool = game_state.discard_card(
		actor_id,
		card_id
	)

	if not moved:
		return ActionResult.failure("Không thể sử dụng lá Tấn công.")

	attacks_used += 1

	pending_attack = {
		"actor_id": actor_id,
		"target_id": target_id,
		"card_id": card_id,
		"damage": damage
	}

	return ActionResult.success()


func respond_to_attack(
	target_id: int,
	dodge_card_id: int = 0
) -> ActionResult:
	if pending_attack.is_empty():
		return ActionResult.failure("Không có đòn Tấn công đang chờ.")

	var expected_target: int = pending_attack["target_id"]

	if target_id != expected_target:
		return ActionResult.failure(
			"Không phải người đang bị Tấn công."
		)

	var target: Player = game_state.get_player(target_id)

	if target == null:
		return ActionResult.failure("Mục tiêu không tồn tại.")

	if dodge_card_id != 0:
		var dodge_card: CardInstance = null

		for card in target.hand:
			if card.instance_id == dodge_card_id:
				dodge_card = card
				break

		if dodge_card == null:
			return ActionResult.failure("Không sở hữu lá Né tránh.")

		if not dodge_card.definition.has_effect("block_attack"):
			return ActionResult.failure(
				"Lá bài không có hiệu ứng Né tránh."
			)

		var moved: bool = game_state.discard_card(
			target_id,
			dodge_card_id
		)

		if not moved:
			return ActionResult.failure("Không thể sử dụng Né tránh.")

		pending_attack.clear()
		return ActionResult.success()

	var damage: int = pending_attack["damage"]

	
	var source_id: int = int(pending_attack["actor_id"])

	if not damage_pipeline.process_damage(
		source_id,
		target_id,
		damage
	):
		return ActionResult.failure("Không thể xử lý sát thương.")

	pending_attack.clear()
	return ActionResult.success()


	
	pending_attack.clear()

	if target.is_dying():
		var dying_result: ActionResult = (
			dying_manager.begin_dying(target_id)
		)

		if not dying_result.valid:
			return dying_result

	return ActionResult.success()



func has_pending_attack() -> bool:
	return not pending_attack.is_empty()
