
class_name DamageModifier
extends RefCounted

enum Role {
	ANY,
	ATTACKER,
	DEFENDER
}

var modifier_id: String
var source_id: String
var owner_id: int
var priority: int
var role: Role
var callback: Callable
var source_kinds: Array[DamageContext.SourceKind] = []


func _init(
	new_modifier_id: String,
	new_source_id: String,
	new_owner_id: int,
	new_priority: int,
	new_role: Role,
	new_callback: Callable,
	new_source_kinds: Array[DamageContext.SourceKind] = []
) -> void:
	assert(not new_modifier_id.is_empty())
	assert(not new_source_id.is_empty())
	assert(new_owner_id >= 0)
	assert(new_priority in [
		RuleModifier.Source.BASE_RULE,
		RuleModifier.Source.CARD_EFFECT,
		RuleModifier.Source.CHARACTER_SKILL
	])
	assert(new_callback.is_valid())

	modifier_id = new_modifier_id
	source_id = new_source_id
	owner_id = new_owner_id
	priority = new_priority
	role = new_role
	callback = new_callback
	source_kinds.assign(new_source_kinds)


func applies_to(context: DamageContext) -> bool:
	if not source_kinds.is_empty() and context.source_kind not in source_kinds:
		return false
	if owner_id == 0:
		return true

	match role:
		Role.ATTACKER:
			return owner_id == context.source_id

		Role.DEFENDER:
			return owner_id == context.target_id

		Role.ANY:
			return (
				owner_id == context.source_id
				or owner_id == context.target_id
			)

	return false


func execute(context: DamageContext) -> void:
	if callback.is_valid():
		callback.call(context)
