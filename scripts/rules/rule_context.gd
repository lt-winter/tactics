
class_name RuleContext
extends RefCounted

var actor_id: int
var target_id: int
var current_turn_player_id: int
var values: Dictionary


func _init(
	new_actor_id: int,
	new_target_id: int = 0,
	new_turn_player_id: int = 0,
	new_values: Dictionary = {}
) -> void:
	assert(new_actor_id > 0)
	assert(new_target_id >= 0)
	assert(new_turn_player_id >= 0)

	actor_id = new_actor_id
	target_id = new_target_id
	current_turn_player_id = new_turn_player_id
	values = new_values.duplicate(true)


func is_actor_turn() -> bool:
	return actor_id == current_turn_player_id


func has_target() -> bool:
	return target_id > 0


func get_value(key: String, default_value: Variant = null) -> Variant:
	return values.get(key, default_value)
