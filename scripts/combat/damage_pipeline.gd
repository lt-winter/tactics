
class_name DamagePipeline
extends RefCounted

var resolver: EffectResolver
var registry: DamageModifierRegistry

# Giữ tương thích với Combat System v0.2.
var damage_modifiers: Array[Callable] = []


func _init(effect_resolver: EffectResolver) -> void:
	resolver = effect_resolver
	registry = DamageModifierRegistry.new()


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
	amount: int
) -> bool:
	if resolver.game_state.match_over or amount <= 0:
		return false

	var source: Player = resolver.game_state.get_player(source_id)
	var target: Player = resolver.game_state.get_player(target_id)

	if source == null or target == null:
		return false

	if not target.is_alive():
		return false

	var context: DamageContext = DamageContext.new(
		source_id,
		target_id,
		amount
	)

	var applicable: Array[DamageModifier] = (
		registry.get_applicable(context)
	)

	# Hệ thống mới: xử lý theo priority.
	for modifier in applicable:
		modifier.execute(context)

		if context.cancelled:
			break

	# Callback cũ chỉ chạy nếu chưa bị hủy.
	# Giữ tương thích với bài kiểm thử v0.2.
	if not context.cancelled:
		for modifier in damage_modifiers:
			if not modifier.is_valid():
				continue

			modifier.call(context)

			if context.cancelled:
				break

	if context.cancelled or context.final_damage <= 0:
		return true

	return resolver.deal_damage(
		target_id,
		context.final_damage
	)
