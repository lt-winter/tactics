
class_name EffectResolver
extends RefCounted

var game_state: GameState
var _damage_pipeline_ref: WeakRef


func _init(state: GameState) -> void:
	game_state = state


func bind_damage_pipeline(pipeline: DamagePipeline) -> void:
	_damage_pipeline_ref = weakref(pipeline)


func draw_cards(player_id: int, count: int) -> int:
	var player: Player = game_state.get_player(player_id)
	if game_state.match_over or player == null or not player.is_alive() or count < 1:
		return 0
	var drawn: int = 0
	for index: int in range(count):
		if game_state.draw_card(player_id) == null:
			break
		drawn += 1
	return drawn


func heal_all_players(amount: int, source_id: int = 0) -> bool:
	if game_state.match_over or amount != 1:
		return false
	for player: Player in game_state.players:
		if player.is_alive() and player.is_wounded():
			restore_hp(player.player_id, amount, source_id)
	return true


func deal_damage(
	target_id: int,
	amount: int,
	source_id: int = 0
) -> bool:
	if _damage_pipeline_ref != null:
		var pipeline: DamagePipeline = _damage_pipeline_ref.get_ref() as DamagePipeline
		if pipeline != null:
			# This legacy primitive accepts an already-calculated amount. Apply
			# armor without repeating the ordered/legacy damage modifiers.
			return pipeline.process_resolved_damage(source_id, target_id, amount)
	return _apply_damage(target_id, amount, source_id)


func _apply_damage(
	target_id: int,
	amount: int,
	source_id: int = 0
) -> bool:
	if game_state.match_over:
		return false
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
	game_state.record_damage(source_id, target_id, amount)

	return true


func restore_hp(
	target_id: int,
	amount: int,
	source_id: int = 0
) -> bool:
	if game_state.match_over:
		return false
	var target: Player = game_state.get_player(target_id)

	if target == null:
		return false

	if not target.is_alive():
		return false

	if amount <= 0:
		return false

	if not target.is_wounded():
		return false

	var previous_hp: int = target.hp
	target.hp = mini(target.max_hp, target.hp + amount)
	game_state.healing_applied.emit(source_id, target_id, target.hp - previous_hp)
	return true
