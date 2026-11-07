class_name AttackContext
extends RefCounted

var actor_id: int
var card_id: int
var card_is_black: bool = false
var target_ids: Array[int] = []
var weapon_id: int = 0
var effects: Array[Dictionary] = []
var base_damage: int = 1
var cursor: int = 0
var stage: String = "targeted"
var results: Array[Dictionary] = []


func view() -> Dictionary:
	return {"actor_id": actor_id, "card_id": card_id, "target_ids": target_ids.duplicate(), "weapon_id": weapon_id, "base_damage": base_damage, "cursor": cursor, "stage": stage, "results": results.duplicate(true)}
