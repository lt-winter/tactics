
class_name HuyenCard
extends RefCounted

enum CardType {
	ATTACK,
	DODGE,
	BEER,
	STEAL,
	SCOUT,
	WEAPON,
	ARMOR
}

var id: int
var type: CardType
var display_name: String


func _init(
	card_id: int,
	card_type: CardType,
	name: String
) -> void:
	id = card_id
	type = card_type
	display_name = name


func get_description() -> String:
	return "#%02d - %s" % [id, display_name]
