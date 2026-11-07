
class_name DamagePipeline
extends RefCounted

var resolver: EffectResolver
var registry: DamageModifierRegistry
var armor_effects: ArmorEffectRegistry
var _pending_context: DamageContext
var _pending_result: Dictionary = {}
var _pending_armor: Dictionary = {}
var _processing: bool = false

# Giữ tương thích với Combat System v0.2.
var damage_modifiers: Array[Callable] = []


func _init(effect_resolver: EffectResolver, effects: ArmorEffectRegistry = null) -> void:
	resolver = effect_resolver
	registry = DamageModifierRegistry.new()
	armor_effects = ArmorEffectRegistry.new(resolver.game_state) if effects == null else effects
	resolver.bind_damage_pipeline(self)


func add_modifier(modifier: Callable) -> void:
	if modifier.is_valid():
		damage_modifiers.append(modifier)


func clear_modifiers() -> void:
	damage_modifiers.clear()


func register_modifier(modifier: DamageModifier) -> bool:
	return registry.register_modifier(modifier)


func unregister_modifier(modifier_id: String) -> bool:
	return registry.unregister_modifier(modifier_id)


func process_damage(
	source_id: int,
	target_id: int,
	amount: int,
	source_kind: DamageContext.SourceKind = DamageContext.SourceKind.GENERIC
) -> bool:
	return bool(process_damage_result(source_id, target_id, amount, source_kind)["processed"])


func process_damage_result(
	source_id: int,
	target_id: int,
	amount: int,
	source_kind: DamageContext.SourceKind = DamageContext.SourceKind.GENERIC,
	apply_modifiers: bool = true
) -> Dictionary:
	var result: Dictionary = {"source_id": source_id, "target_id": target_id, "source_kind": source_kind, "processed": false, "applied_amount": 0, "pending": false}
	if resolver.game_state.match_over or amount <= 0 or is_busy() or resolver.game_state.zone_manager.is_transfer_in_progress():
		return result

	var source: Player = resolver.game_state.get_player(source_id)
	var target: Player = resolver.game_state.get_player(target_id)

	if (source == null and source_id != 0) or (source_id == 0 and source_kind != DamageContext.SourceKind.GENERIC) or target == null:
		return result

	if not target.is_alive():
		return result
	_processing = true

	var context: DamageContext = DamageContext.new(
		source_id,
		target_id,
		amount,
		source_kind
	)

	var applicable: Array[DamageModifier] = []
	if apply_modifiers:
		applicable = registry.get_applicable(context)

	# Hệ thống mới: xử lý theo priority.
	for modifier in applicable:
		modifier.execute(context)

		if context.cancelled:
			break

	# Callback cũ chỉ chạy nếu chưa bị hủy.
	# Giữ tương thích với bài kiểm thử v0.2.
	if apply_modifiers and not context.cancelled:
		for modifier in damage_modifiers:
			if not modifier.is_valid():
				continue

			modifier.call(context)

			if context.cancelled:
				break

	if context.cancelled or context.final_damage <= 0:
		result["processed"] = true
		_processing = false
		return result
	var capped: Dictionary = armor_effects.query(target_id, "damage_reduction", {"context": context})
	if not capped.is_empty():
		armor_effects.effect_resolved.emit(target_id, str(capped["effect_id"]), {"amount": context.final_damage})
	var protection: Dictionary = armor_effects.query(target_id, "before_damage_commit", {"context": context})
	if not protection.is_empty():
		_pending_context = context
		_pending_result = result
		_pending_armor = protection
		_pending_armor["decision_id"] = armor_effects.next_decision_id()
		_pending_armor["damage"] = context.final_damage
		_pending_armor["source_id"] = source_id
		_pending_armor["source_kind"] = source_kind
		result["processed"] = true
		result["pending"] = true
	else:
		_commit(context, result)
	_processing = false
	return result


func is_busy() -> bool:
	return _processing or _pending_context != null


func process_resolved_damage(source_id: int, target_id: int, amount: int) -> bool:
	return bool(process_damage_result(source_id, target_id, amount, DamageContext.SourceKind.GENERIC, false)["processed"])


func _has_dying() -> bool:
	for player: Player in resolver.game_state.players:
		if player.is_dying():
			return true
	return false


func _commit(context: DamageContext, result: Dictionary) -> void:
	result["pending"] = false
	if context.cancelled or context.final_damage <= 0:
		result["processed"] = true
		return
	result["processed"] = resolver._apply_damage(context.target_id, context.final_damage, context.source_id)
	result["applied_amount"] = context.final_damage if bool(result["processed"]) else 0


func clear() -> void:
	if not _pending_result.is_empty():
		_pending_result["pending"] = false
		_pending_result["processed"] = false
	_pending_context = null
	_pending_result = {}
	_pending_armor = {}


func resume_pending() -> void:
	if _processing or _pending_context == null or resolver.game_state.zone_manager.is_transfer_in_progress():
		return
	if resolver.game_state.match_over:
		clear()
		return
	if _has_dying():
		return
	var target: Player = resolver.game_state.get_player(_pending_context.target_id)
	if armor_effects.is_current(_pending_armor) and target.is_alive() and _pending_context.final_damage >= target.hp:
		return
	_processing = true
	_commit(_pending_context, _pending_result)
	_pending_context = null
	_pending_result = {}
	_pending_armor = {}
	_processing = false


func get_pending_armor() -> Dictionary:
	resume_pending()
	return _pending_armor.duplicate(true)


func resolve_armor(owner_id: int, decision_id: int, activate: bool) -> ActionResult:
	if _processing or _has_dying() or resolver.game_state.zone_manager.is_transfer_in_progress():
		return ActionResult.failure("Phải giải quyết hấp hối hoặc hành động hiện tại trước.")
	resume_pending()
	if _pending_context == null or owner_id != int(_pending_armor["actor_id"]) or decision_id != int(_pending_armor["decision_id"]):
		return ActionResult.failure("Lựa chọn phòng ngự đã thay đổi hoặc không đúng người.")
	_processing = true
	if activate:
		var armor_id: int = int(_pending_armor["armor_id"])
		if not resolver.game_state.discard_card(owner_id, armor_id, "equipment"):
			_processing = false
			return ActionResult.failure("Không thể bỏ chính trang bị; chưa ngăn sát thương.")
		_pending_context.cancel_damage()
		armor_effects.effect_resolved.emit(owner_id, "prevent_lethal_damage", {"armor_id": armor_id})
	_commit(_pending_context, _pending_result)
	_pending_context = null
	_pending_result = {}
	_pending_armor = {}
	_processing = false
	return ActionResult.success()
