
class_name CardDefinition
extends RefCounted

var id: String
var display_name: String
var category: String
var subcategory: String
var description: String
var effects: Array[Dictionary] = []


func _init(data: Dictionary) -> void:
	id = data["id"]
	display_name = data["name"]
	category = data["category"]
	subcategory = data["subcategory"]
	description = data["description"]

	for effect in data["effects"]:
		effects.append(effect.duplicate(true))


func is_basic() -> bool:
	return category == "basic"


func is_tool() -> bool:
	return category == "tool"


func is_equipment() -> bool:
	return category == "equipment"


func has_effect(effect_id: String) -> bool:
	for effect in effects:
		if effect["effect_id"] == effect_id:
			return true

	return false
