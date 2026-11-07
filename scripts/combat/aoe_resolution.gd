class_name AoeResolution
extends RefCounted

# One committed tool, one bounded seat-order queue, no automatic response choice.
var _state: GameState
var _turns: TurnManager
var _pipeline: DamagePipeline
var _dying: DyingManager
var _pending: Dictionary = {}
var _resolving: bool = false
var _damage_result: Dictionary = {}


func _init(state: GameState, turns: TurnManager, pipeline: DamagePipeline, dying: DyingManager) -> void:
	_state = state
	_turns = turns
	_pipeline = pipeline
	_dying = dying


static func valid_parameters(parameters: Variant) -> bool:
	if not parameters is Dictionary:
		return false
	if parameters.get("target_scope") != "all_other_players":
		return false
	if parameters.get("response_effect") not in ["block_attack", "deal_attack"]:
		return false
	var damage: Variant = parameters.get("damage")
	if not (damage is int or damage is float):
		return false
	var amount: float = float(damage)
	return is_finite(amount) and amount >= 1.0 and amount == floor(amount) and amount <= 2147483647.0


func has_pending() -> bool:
	return not _pending.is_empty()


func clear() -> void:
	_pending.clear()
	_damage_result = {}


func get_pending() -> Dictionary:
	return _pending.duplicate(true)


func begin(actor_id: int, card: CardInstance, parameters: Dictionary) -> ActionResult:
	if has_pending() or _resolving:
		return ActionResult.failure("Đang giải quyết AOE.")
	var targets: Array[int] = []
	var start: int = _turns.seat_order.find(actor_id)
	if start < 0 or not valid_parameters(parameters):
		return ActionResult.failure("Cấu hình AOE không hợp lệ.")
	for offset: int in range(1, _turns.seat_order.size()):
		var target_id: int = _turns.seat_order[(start + offset) % _turns.seat_order.size()]
		var target: Player = _state.get_player(target_id)
		if target != null and not target.is_eliminated():
			targets.append(target_id)
	if targets.is_empty():
		return ActionResult.failure("Không có mục tiêu AOE hợp lệ.")
	_pending = {
		"actor_id": actor_id, "card_id": card.instance_id,
		"card_name": card.definition.display_name,
		"response_effect": parameters["response_effect"], "damage": int(parameters["damage"]),
		"targets": targets, "index": 0, "target_id": targets[0]
	}
	_resolving = true
	var paid: bool = _state.discard_card(actor_id, card.instance_id)
	_resolving = false
	if not paid:
		clear()
		return ActionResult.failure("Không thể tiêu hao lá AOE.")
	resume()
	return ActionResult.success()


func resume() -> void:
	if _resolving or _pipeline.is_busy() or not has_pending():
		return
	if _state.match_over:
		clear()
		return
	_dying.ensure_pending_dying()
	if _dying.has_pending_dying():
		return
	if not _damage_result.is_empty():
		if bool(_damage_result.get("pending", false)):
			return
		_pending["index"] = int(_pending["index"]) + 1
		_damage_result = {}
	var targets: Array[int] = _pending["targets"]
	# Cursor only moves forward; at most one pass through the captured seat list.
	while int(_pending["index"]) < targets.size():
		var target_id: int = targets[int(_pending["index"])]
		var target: Player = _state.get_player(target_id)
		if target != null and target.is_alive():
			_pending["target_id"] = target_id
			return
		_pending["index"] = int(_pending["index"]) + 1
	clear()


func get_response_cards(target_id: int) -> Array[CardInstance]:
	var result: Array[CardInstance] = []
	if not has_pending() or _pipeline.is_busy() or not _damage_result.is_empty() or _resolving or _state.match_over or target_id != int(_pending["target_id"]):
		return result
	if not _turns.get_dying_block_reason().is_empty():
		return result
	var target: Player = _state.get_player(target_id)
	if target == null or not target.is_alive():
		return result
	for card: CardInstance in target.hand:
		if card.definition.is_basic() and card.definition.has_effect(str(_pending["response_effect"])):
			result.append(card)
	return result


func respond(target_id: int, response_card_id: int = 0) -> ActionResult:
	if _resolving or _pipeline.is_busy() or _state.match_over:
		return ActionResult.failure("Không thể phản ứng AOE lúc này.")
	var blocked: String = _turns.get_dying_block_reason()
	if not blocked.is_empty():
		return ActionResult.failure(blocked)
	resume()
	if not has_pending() or target_id != int(_pending["target_id"]):
		return ActionResult.failure("Không phải mục tiêu AOE đang chờ phản ứng.")
	if response_card_id != 0:
		var owned: bool = false
		for card: CardInstance in get_response_cards(target_id):
			if card.instance_id == response_card_id:
				owned = true
				break
		if not owned:
			return ActionResult.failure("Không sở hữu lá phản ứng AOE hợp lệ.")
	_resolving = true
	var applied: bool
	if response_card_id != 0:
		applied = _state.discard_card(target_id, response_card_id)
	else:
		_damage_result = _pipeline.process_damage_result(int(_pending["actor_id"]), target_id, int(_pending["damage"]), DamageContext.SourceKind.AOE_TOOL)
		applied = bool(_damage_result["processed"])
	_resolving = false
	if not applied:
		_damage_result = {}
		return ActionResult.failure("Không thể xử lý phản ứng AOE; giữ nguyên mục tiêu.")
	if bool(_damage_result.get("pending", false)):
		return ActionResult.success()
	_damage_result = {}
	if has_pending():
		# Save continuation before Dying; never damage the same target on resume.
		_pending["index"] = int(_pending["index"]) + 1
	_dying.ensure_pending_dying()
	resume()
	return ActionResult.success()
