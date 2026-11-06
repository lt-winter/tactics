
class_name DamageModifierRegistry
extends RefCounted

var modifiers: Array[DamageModifier] = []


func register_modifier(modifier: DamageModifier) -> bool:
	if modifier == null:
		return false

	for existing in modifiers:
		if existing.modifier_id == modifier.modifier_id:
			return false

	modifiers.append(modifier)
	return true


func unregister_modifier(modifier_id: String) -> bool:
	for i in range(modifiers.size()):
		if modifiers[i].modifier_id == modifier_id:
			modifiers.remove_at(i)
			return true

	return false


func unregister_by_source(source_id: String) -> int:
	var removed_count: int = 0

	for i in range(modifiers.size() - 1, -1, -1):
		if modifiers[i].source_id == source_id:
			modifiers.remove_at(i)
			removed_count += 1

	return removed_count


func clear() -> void:
	modifiers.clear()


func get_applicable(
	context: DamageContext
) -> Array[DamageModifier]:
	var result: Array[DamageModifier] = []

	for modifier in modifiers:
		if modifier.applies_to(context):
			result.append(modifier)

	# Sắp xếp ổn định: priority cao trước.
	# Cùng priority giữ thứ tự đăng ký.
	for i in range(1, result.size()):
		var current: DamageModifier = result[i]
		var j: int = i - 1

		while j >= 0 and result[j].priority < current.priority:
			result[j + 1] = result[j]
			j -= 1

		result[j + 1] = current

	return result
