class_name AttackResolution
extends RefCounted

const MAX_RESUME_STEPS: int = 16

var _state: GameState
var _turns: TurnManager
var _validator: ActionValidator
var _pipeline: DamagePipeline
var _dying: DyingManager
var _equipment: EquipmentSystem
var _context: AttackContext
var _decision: Dictionary = {}
var _executing: bool = false
var _serial: int = 0
var _last: Dictionary = {}
var _weapon_invalidated: bool = false
var _armor_decision: Dictionary = {}
var _last_damage: Dictionary = {}


func _init(state: GameState, turns: TurnManager, validator: ActionValidator, pipeline: DamagePipeline, dying: DyingManager, equipment: EquipmentSystem) -> void:
	_state = state
	_turns = turns
	_validator = validator
	_pipeline = pipeline
	_dying = dying
	_equipment = equipment
	_state.zone_manager.equipment_changed.connect(_on_equipment_changed)


func _on_equipment_changed() -> void:
	if _context == null:
		return
	var current: CardInstance = _equipment.get_weapon(_context.actor_id)
	if current == null or current.instance_id != _context.weapon_id:
		_weapon_invalidated = true


func clear() -> void:
	_context = null
	_decision.clear()
	_armor_decision.clear()
	_last_damage = {}


func is_busy() -> bool:
	return _executing or _context != null


func target_limit(actor_id: int) -> int:
	var weapon: CardInstance = _equipment.get_weapon(actor_id)
	if weapon != null:
		for effect: Dictionary in weapon.definition.effects:
			if effect.get("effect_id") == "additional_attack_target":
				return 1 + int(effect.get("parameters", {}).get("additional_targets", 0))
	return 1


func begin(actor_id: int, targets: Array[int], card_id: int, used: int) -> ActionResult:
	if is_busy() or _state.zone_manager.is_transfer_in_progress():
		return ActionResult.failure("Đang giải quyết Tấn công hoặc chuyển vùng bài.")
	if targets.is_empty() or targets.size() > target_limit(actor_id):
		return ActionResult.failure("Số mục tiêu Tấn công không hợp lệ.")
	var seen: Dictionary = {}
	for target_id: int in targets:
		if seen.has(target_id):
			return ActionResult.failure("Không thể chọn trùng mục tiêu.")
		seen[target_id] = true
		var validation: ActionResult = _validator.validate_attack(actor_id, target_id, card_id, used)
		if not validation.valid:
			return validation
	var card: CardInstance = null
	for candidate: CardInstance in _state.get_player(actor_id).hand:
		if candidate.instance_id == card_id:
			card = candidate
	var damage: int = 1
	for effect: Dictionary in card.definition.effects:
		if effect.get("effect_id") == "deal_attack":
			damage = int(effect.get("parameters", {}).get("damage", 1))
	if damage <= 0:
		return ActionResult.failure("Sát thương không hợp lệ.")
	var context: AttackContext = AttackContext.new()
	context.actor_id = actor_id
	context.card_id = card_id
	context.card_is_black = card.is_black()
	context.base_damage = damage
	var start: int = _turns.seat_order.find(actor_id)
	for offset: int in range(1, _turns.seat_order.size()):
		var target_id: int = _turns.seat_order[(start + offset) % _turns.seat_order.size()]
		if target_id in targets:
			context.target_ids.append(target_id)
	if context.target_ids.size() != targets.size():
		return ActionResult.failure("Mục tiêu không thuộc vòng chơi.")
	var weapon: CardInstance = _equipment.get_weapon(actor_id)
	if weapon != null:
		context.weapon_id = weapon.instance_id
		context.effects = weapon.definition.effects.duplicate(true)
	_executing = true
	_context = context
	_weapon_invalidated = false
	var paid: bool = _state.discard_card(actor_id, card_id)
	if not paid:
		clear()
	_executing = false
	if paid:
		resume()
	return ActionResult.success() if paid else ActionResult.failure("Không thể sử dụng lá Tấn công.")


func pending_response() -> Dictionary:
	if _context == null or _context.stage != "response":
		return {}
	return {"actor_id": _context.actor_id, "target_id": _target_id(), "card_id": _context.card_id, "damage": _context.base_damage}


func get_context() -> Dictionary:
	return _last.duplicate(true) if _context == null else _context.view()


func get_decision() -> Dictionary:
	resume()
	return _decision.duplicate(true)


func get_armor_decision() -> Dictionary:
	resume()
	return _armor_decision.duplicate(true)


func resolve_armor(owner_id: int, decision_id: int, activate: bool) -> ActionResult:
	if _executing or _pipeline.is_busy() or not _turns.get_dying_block_reason().is_empty() or _state.zone_manager.is_transfer_in_progress():
		return ActionResult.failure("Phải giải quyết hấp hối hoặc sát thương hiện tại trước.")
	resume()
	if _armor_decision.is_empty() or owner_id != int(_armor_decision["actor_id"]) or decision_id != int(_armor_decision["decision_id"]):
		return ActionResult.failure("Lựa chọn phòng ngự đã thay đổi hoặc không đúng người.")
	if activate:
		_executing = true
		var judgment: Dictionary = _pipeline.armor_effects.judge(_armor_decision)
		_executing = false
		if judgment.is_empty():
			return ActionResult.failure("Không có lá để phán xét hoặc trang bị không còn hợp lệ; có thể Bỏ qua.")
		_context.results.append({"target_id": owner_id, "judgment": judgment})
		if bool(judgment["success"]):
			_complete_target("armor_dodged")
		else:
			_context.stage = "response"
	else:
		_context.stage = "response"
	_armor_decision.clear()
	resume()
	return ActionResult.success()


func _target_id() -> int:
	return _context.target_ids[_context.cursor]


func _effect(effect_id: String) -> Dictionary:
	if _context == null or _weapon_invalidated:
		return {}
	var owner: Player = _state.get_player(_context.actor_id)
	var weapon: CardInstance = _equipment.get_weapon(_context.actor_id)
	if owner == null or not owner.is_alive() or weapon == null or weapon.instance_id != _context.weapon_id:
		return {}
	for effect: Dictionary in _context.effects:
		if effect.get("effect_id") == effect_id:
			return effect.get("parameters", {}).duplicate(true)
	return {}


func respond(target_id: int, dodge_id: int = 0) -> ActionResult:
	if _executing or _pipeline.is_busy() or _state.match_over or _state.zone_manager.is_transfer_in_progress() or not _turns.get_dying_block_reason().is_empty():
		return ActionResult.failure("Phải giải quyết hấp hối hoặc hành động hiện tại trước.")
	if _context == null or _context.stage != "response" or target_id != _target_id():
		return ActionResult.failure("Không phải người đang bị Tấn công.")
	var target: Player = _state.get_player(target_id)
	if target.is_eliminated():
		_complete_target("eliminated")
		resume()
		return ActionResult.success()
	if dodge_id != 0:
		var valid: bool = false
		for card: CardInstance in target.hand:
			if card.instance_id == dodge_id and card.definition.has_effect("block_attack"):
				valid = true
		if not valid:
			return ActionResult.failure("Không sở hữu lá Né tránh hợp lệ.")
		_executing = true
		var paid: bool = _state.discard_card(target_id, dodge_id)
		_executing = false
		if not paid:
			return ActionResult.failure("Không thể sử dụng Né tránh.")
		_complete_target("dodged")
	else:
		_context.stage = "before_damage"
	resume()
	return ActionResult.success()


func _offer(effect_id: String, parameters: Dictionary) -> bool:
	var cards: Array[int] = []
	var targets: Array[int] = []
	var actor: Player = _state.get_player(_context.actor_id)
	var target: Player = _state.get_player(_target_id())
	match effect_id:
		"replace_attack_damage_with_discard":
			for card: CardInstance in target.hand:
				cards.append(card.instance_id)
			if cards.size() < int(parameters.get("min_target_cards", 1)):
				return false
			if not bool(parameters.get("allow_partial", false)) and cards.size() < int(parameters.get("discard_count", 2)):
				return false
		"discard_equipment_on_hit":
			for card: CardInstance in target.equipment:
				cards.append(card.instance_id)
			if cards.is_empty():
				return false
		"secondary_damage_on_hit":
			for card: CardInstance in actor.hand:
				cards.append(card.instance_id)
			var ordered: Array[Player] = []
			for player_id: int in _turns.seat_order:
				ordered.append(_state.get_player(player_id))
			for player: Player in ordered:
				if not player.is_alive() or player.player_id in [_context.actor_id, _target_id()]:
					continue
				var distance: int = DistanceCalculator.calculate(ordered, _target_id(), player.player_id)
				if distance > 0 and distance <= int(parameters.get("secondary_range", 1)):
					targets.append(player.player_id)
			if cards.size() < int(parameters.get("cost_discard", 1)) or targets.is_empty():
				return false
	_serial += 1
	_decision = {"decision_id": _serial, "effect_id": effect_id, "actor_id": _context.actor_id, "target_id": _target_id(), "weapon_id": _context.weapon_id, "card_ids": cards, "target_ids": targets, "parameters": parameters.duplicate(true)}
	return true


func resume() -> void:
	if _executing or _pipeline.is_busy() or _context == null or _state.zone_manager.is_transfer_in_progress():
		return
	if _state.match_over:
		clear()
		return
	_dying.ensure_pending_dying()
	if _dying.has_pending_dying():
		return
	for step: int in range(MAX_RESUME_STEPS):
		if _context == null:
			return
		if _dying.has_pending_dying():
			return
		var target: Player = _state.get_player(_target_id())
		if target.is_eliminated():
			_decision.clear()
			_complete_target("eliminated")
			continue
		if not _decision.is_empty():
			var effect_id: String = str(_decision["effect_id"])
			var parameters: Dictionary = _effect(effect_id)
			var decision_id: int = int(_decision["decision_id"])
			if not parameters.is_empty() and _offer(effect_id, parameters):
				_decision["decision_id"] = decision_id
				return
			# Losing the weapon cancels an uncommitted optional effect.
			_decision.clear()
			if _context.stage == "before_damage":
				_apply_primary()
			else:
				_complete_target("damaged")
			continue
		match _context.stage:
			"targeted":
				var shield: Dictionary = _pipeline.armor_effects.query(_target_id(), "attack_targeted", {"attack_color": "black" if _context.card_is_black else "red"})
				if not shield.is_empty():
					_executing = true
					_pipeline.armor_effects.effect_resolved.emit(_target_id(), str(shield["effect_id"]), {"source_id": _context.actor_id, "card_id": _context.card_id})
					_complete_target("armor_blocked")
					_executing = false
					continue
				var barrel: Dictionary = _pipeline.armor_effects.query(_target_id(), "before_response")
				if not barrel.is_empty():
					_armor_decision = barrel
					_armor_decision["decision_id"] = _pipeline.armor_effects.next_decision_id()
					_armor_decision["source_id"] = _context.actor_id
					_context.stage = "armor_response"
					return
				_context.stage = "response"
			"armor_response":
				if _pipeline.armor_effects.is_current(_armor_decision):
					return
				_armor_decision.clear()
				_context.stage = "response"
			"response":
				return
			"damage_wait":
				if bool(_last_damage.get("pending", false)):
					return
				if bool(_last_damage.get("processed", false)) and int(_last_damage.get("applied_amount", 0)) > 0:
					_context.stage = "after_damage"
				else:
					_complete_target("prevented")
				_last_damage = {}
			"before_damage":
				var replacement: Dictionary = _effect("replace_attack_damage_with_discard")
				if not replacement.is_empty() and _offer("replace_attack_damage_with_discard", replacement):
					return
				_apply_primary()
			"after_damage":
				for effect_id: String in ["secondary_damage_on_hit", "discard_equipment_on_hit"]:
					var parameters: Dictionary = _effect(effect_id)
					if not parameters.is_empty() and _offer(effect_id, parameters):
						return
				_complete_target("damaged")
			"after_secondary":
				_complete_target("damaged")
		if _dying.has_pending_dying():
			return
	push_error("Attack resolution exceeded its bounded step budget.")


func _apply_primary() -> void:
	_executing = true
	var result: Dictionary = _pipeline.process_damage_result(_context.actor_id, _target_id(), _context.base_damage, DamageContext.SourceKind.ATTACK)
	_executing = false
	_context.results.append(result)
	if bool(result.get("pending", false)):
		_last_damage = result
		_context.stage = "damage_wait"
		return
	if not bool(result["processed"]) or int(result["applied_amount"]) == 0:
		_complete_target("prevented")
		return
	_context.stage = "after_damage"
	_dying.ensure_pending_dying()


func _complete_target(outcome: String) -> void:
	_context.results.append({"target_id": _target_id(), "outcome": outcome})
	_decision.clear()
	_armor_decision.clear()
	_context.cursor += 1
	if _context.cursor >= _context.target_ids.size():
		_context.stage = "resolved"
		_last = _context.view()
		_context = null
	else:
		_context.stage = "targeted"


func decide(actor_id: int, decision_id: int, activate: bool, card_ids: Array[int] = [], secondary_id: int = 0) -> ActionResult:
	if _executing or _pipeline.is_busy() or not _turns.get_dying_block_reason().is_empty() or _state.zone_manager.is_transfer_in_progress():
		return ActionResult.failure("Phải giải quyết hấp hối hoặc chuyển vùng bài trước.")
	resume()
	if _state.match_over or _decision.is_empty() or actor_id != int(_decision["actor_id"]) or decision_id != int(_decision["decision_id"]):
		return ActionResult.failure("Lựa chọn vũ khí đã thay đổi hoặc không đúng người.")
	var effect_id: String = _decision["effect_id"]
	if not activate:
		_decision.clear()
		if _context.stage == "before_damage":
			_apply_primary()
		else:
			_complete_target("damaged")
		resume()
		return ActionResult.success()
	var parameters: Dictionary = _effect(effect_id)
	if parameters.is_empty():
		return ActionResult.failure("Vũ khí không còn hiệu lực.")
	var owner_id: int = _target_id()
	var zone: String = "equipment" if effect_id == "discard_equipment_on_hit" else "hand"
	var required: int = int(parameters.get("discard_count", 1))
	if effect_id == "replace_attack_damage_with_discard":
		required = mini(int(parameters.get("discard_count", 2)), _state.get_player(owner_id).hand.size())
	elif effect_id == "secondary_damage_on_hit":
		required = int(parameters.get("cost_discard", 1))
		owner_id = actor_id
		if secondary_id not in _decision["target_ids"]:
			return ActionResult.failure("Mục tiêu phụ không hợp lệ.")
		# Rebuild current range/ownership candidates without committing any resource.
		var old_id: int = int(_decision["decision_id"])
		if not _offer(effect_id, parameters):
			return ActionResult.failure("Không còn mục tiêu hoặc chi phí hợp lệ.")
		_decision["decision_id"] = old_id
		if secondary_id not in _decision["target_ids"]:
			return ActionResult.failure("Mục tiêu phụ không còn trong tầm.")
	if required <= 0 or card_ids.size() != required:
		return ActionResult.failure("Chưa chọn đủ số lá cần thiết.")
	var moves: Array[Dictionary] = []
	var seen: Dictionary = {}
	for card_id: int in card_ids:
		var owned: bool = false
		for card: CardInstance in _state.get_player(owner_id).get_zone(zone):
			if card.instance_id == card_id:
				owned = true
		if not owned or seen.has(card_id):
			return ActionResult.failure("Lá đã chọn không hợp lệ hoặc bị trùng.")
		seen[card_id] = true
		moves.append({"card_id": card_id, "from_zone": zone, "from_player_id": owner_id, "to_zone": "discard", "to_player_id": 0})
	_executing = true
	var paid: bool = _state.zone_manager.transfer_cards(moves)
	if not paid:
		_executing = false
		return ActionResult.failure("Không thể bỏ các lá đã chọn.")
	_decision.clear()
	if effect_id == "secondary_damage_on_hit":
		_context.stage = "after_secondary"
		var damage: int = int(parameters.get("secondary_damage", 1))
		_context.results.append(_pipeline.process_damage_result(actor_id, secondary_id, damage, DamageContext.SourceKind.WEAPON_EFFECT))
		_dying.ensure_pending_dying()
	else:
		_complete_target("replaced" if effect_id == "replace_attack_damage_with_discard" else "damaged")
	_executing = false
	resume()
	return ActionResult.success()
