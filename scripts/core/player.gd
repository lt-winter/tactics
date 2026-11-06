
class_name Player
extends RefCounted

var player_id: int
var display_name: String

var max_hp: int
var hp: int

var hand: Array[CardInstance] = []
var equipment: Array[CardInstance] = []
var judgment: Array[CardInstance] = []


enum LifeState {
	ALIVE,
	DYING,
	ELIMINATED
}

var life_state: LifeState = LifeState.ALIVE



func _init(
	id: int,
	name: String,
	starting_hp: int
) -> void:
	assert(id > 0)
	assert(starting_hp > 0)

	player_id = id
	display_name = name
	max_hp = starting_hp
	hp = max_hp



func is_alive() -> bool:
	return life_state == LifeState.ALIVE and hp > 0


func is_dying() -> bool:
	return life_state == LifeState.DYING


func is_eliminated() -> bool:
	return life_state == LifeState.ELIMINATED


func is_wounded() -> bool:
	return is_alive() and hp < max_hp


func enter_dying() -> bool:
	if life_state != LifeState.ALIVE:
		return false

	if hp > 0:
		return false

	life_state = LifeState.DYING
	return true


func recover_from_dying() -> bool:
	if life_state != LifeState.DYING:
		return false

	if hp <= 0:
		return false

	life_state = LifeState.ALIVE
	return true


func eliminate() -> bool:
	if life_state != LifeState.DYING:
		return false

	life_state = LifeState.ELIMINATED
	hp = 0
	return true



func get_hand_count() -> int:
	return hand.size()


func get_zone(zone_name: String) -> Array[CardInstance]:
	match zone_name:
		"hand":
			return hand.duplicate()
		"equipment":
			return equipment.duplicate()
		"judgment":
			return judgment.duplicate()
		_:
			return []
