
class_name EffectResolver
extends RefCounted

var game_state: GameState


func _init(state: GameState) -> void:
	game_state = state


func deal_damage(
	target_id: int,
	amount: int
) -> bool:
	var target: Player = game_state.get_player(target_id)

	if target == null:
		return false

	if not target.is_alive():
		return false

	if amount <= 0:
		return false

	target.hp -= amount

	if target.hp <= 0:
		target.enter_dying()

	return true


func restore_hp(
	target_id: int,
	amount: int
) -> bool:
	var target: Player = game_state.get_player(target_id)

	if target == null:
		return false

	if not target.is_alive():
		return false

	if amount <= 0:
		return false

	if not target.is_wounded():
		return false

	target.hp = mini(target.max_hp, target.hp + amount)
	return true
