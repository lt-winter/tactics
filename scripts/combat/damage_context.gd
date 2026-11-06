
class_name DamageContext
extends RefCounted

var source_id: int
var target_id: int
var original_damage: int
var final_damage: int
var cancelled: bool = false


func _init(
	new_source_id: int,
	new_target_id: int,
	new_damage: int
) -> void:
	assert(new_source_id > 0)
	assert(new_target_id > 0)
	assert(new_damage > 0)

	source_id = new_source_id
	target_id = new_target_id
	original_damage = new_damage
	final_damage = new_damage


func reduce_damage(amount: int) -> void:
	if amount <= 0:
		return

	final_damage = maxi(0, final_damage - amount)


func increase_damage(amount: int) -> void:
	if amount <= 0:
		return

	final_damage += amount


func cancel_damage() -> void:
	cancelled = true
	final_damage = 0
