
class_name RuleModifier
extends RefCounted

enum Source {
	BASE_RULE = 100,
	CARD_EFFECT = 200,
	CHARACTER_SKILL = 300
}

var rule_id: String
var operation: String
var value: int
var priority: int
var source_id: String
var owner_id: int


func _init(
	new_rule_id: String,
	new_operation: String,
	new_value: int,
	new_priority: int,
	new_source_id: String,
	new_owner_id: int = 0
) -> void:
	assert(new_priority in [
		Source.BASE_RULE,
		Source.CARD_EFFECT,
		Source.CHARACTER_SKILL
	])

	assert(new_operation in [
		"set",
		"remove_limit"
	])

	assert(new_owner_id >= 0)
	assert(not new_rule_id.is_empty())
	assert(not new_source_id.is_empty())

	rule_id = new_rule_id
	operation = new_operation
	value = new_value
	priority = new_priority
	source_id = new_source_id
	owner_id = new_owner_id


func applies_to(player_id: int) -> bool:
	if owner_id == 0:
		return true

	return owner_id == player_id
