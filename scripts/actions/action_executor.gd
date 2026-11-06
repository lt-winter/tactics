
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
	turn_manager.bind_combat(self, rules)
	turn_manager.turn_started.connect(_on_turn_started)


func _on_turn_started(_player_id: int, _number: int) -> void:
	reset_turn_counters()


func use_rescue(rescuer_id: int, target_id: int, card_id: int) -> ActionResult:
	dying_manager.ensure_pending_dying()
	if not dying_manager.has_pending_dying() or dying_manager.dying_player_id != target_id:
		return ActionResult.failure("Phải cứu đúng người trong cửa sổ hấp hối hiện tại.")
	var validation: ActionResult = validator.validate_rescue(rescuer_id, target_id, card_id)
	if not validation.valid:
		return validation
	var amount: int = _get_heal_amount(rescuer_id, card_id)
	if not game_state.discard_card(rescuer_id, card_id):
		return ActionResult.failure("Không thể tiêu hao lá hồi máu để cứu.")
	var result: ActionResult = dying_manager.rescue_player(rescuer_id, target_id, amount)
	if not result.valid:
		var restored: bool = game_state.zone_manager.transfer_card(card_id, "discard", 0, "hand", rescuer_id)
		assert(restored)
	return result


func _get_heal_amount(actor_id: int, card_id: int) -> int:
	for card: CardInstance in game_state.get_player(actor_id).hand:
		if card.instance_id == card_id:
			return int(card.definition.effects[0]["parameters"]["amount"])
	return 0


func use_heal(actor_id: int, card_id: int) -> ActionResult:
	var validation: ActionResult = validator.validate_heal(actor_id, card_id)
	if not validation.valid:
		return validation
	var amount: int = _get_heal_amount(actor_id, card_id)
	if not game_state.discard_card(actor_id, card_id):
		return ActionResult.failure("Không thể tiêu hao lá hồi máu.")
	if not resolver.restore_hp(actor_id, amount):
		var restored: bool = game_state.zone_manager.transfer_card(card_id, "discard", 0, "hand", actor_id)
		assert(restored)
		return ActionResult.failure("Không thể hồi máu; đã hoàn trả lá bài.")
	return ActionResult.success()


func use_tool(actor_id: int, target_id: int, card_id: int, target_card_id: int, zone: String) -> ActionResult:
	var validation: ActionResult = validator.validate_tool_choice(actor_id, target_id, card_id, target_card_id, zone)
	if not validation.valid:
		return validation
	var effect: Dictionary = validator.get_tool_effect(actor_id, card_id)
	var stealing: bool = effect["effect_id"] == "steal_card"
	var destination: String = "hand" if stealing else "discard"
	var owner: int = actor_id if stealing else 0
	if not game_state.zone_manager.transfer_card(target_card_id, zone, target_id, destination, owner):
		return ActionResult.failure("Không thể di chuyển lá bài mục tiêu.")
	if not game_state.discard_card(actor_id, card_id):
		var restored: bool = game_state.zone_manager.transfer_card(target_card_id, destination, owner, zone, target_id)
		assert(restored)
		return ActionResult.failure("Không thể sử dụng công cụ; đã hoàn trả bài mục tiêu.")
	return ActionResult.success()


func discard_for_turn(player_id: int, card_id: int) -> ActionResult:
	var validation: ActionResult = validator.validate_turn_discard(player_id, card_id)
	if not validation.valid:
		return validation
	if not game_state.discard_card(player_id, card_id):
		return ActionResult.failure("Không thể bỏ lá bài đã chọn.")
	return ActionResult.success()

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
	if dying_manager.has_pending_dying():
		return ActionResult.failure(
			"Phải giải quyết hấp hối trước khi Tấn công."
		)

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
	var dying_reason: String = turn_manager.get_dying_block_reason()
	if not dying_reason.is_empty():
		return ActionResult.failure(dying_reason)
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
	if target.is_eliminated():
		# An interrupted attack cannot require a Dodge from an eliminated target.
		pending_attack.clear()
		return ActionResult.success()

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

	if target.is_dying():
		var dying_result: ActionResult = (
			dying_manager.begin_dying(target_id)
		)

		if not dying_result.valid:
			return dying_result

	return ActionResult.success()



func has_pending_attack() -> bool:
	return not pending_attack.is_empty()
