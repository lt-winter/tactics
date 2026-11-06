
class_name DyingManager
extends RefCounted

var game_state: GameState
var dying_player_id: int = 0
var _finalizing: bool = false


func _init(state: GameState) -> void:
	game_state = state


func has_pending_dying() -> bool:
	return dying_player_id != 0


func ensure_pending_dying() -> void:
	# Adopt an existing DYING state when damage came from another engine API.
	# Keep an active window until it is explicitly rescued or finalized.
	if has_pending_dying():
		return
	for player: Player in game_state.players:
		if player.is_dying():
			dying_player_id = player.player_id
			return


func begin_dying(player_id: int) -> ActionResult:
	if _finalizing:
		return ActionResult.failure("Đang hoàn tất loại người chơi.")
	if has_pending_dying():
		return ActionResult.failure(
			"Đang có một người chơi chờ cứu."
		)

	var player: Player = game_state.get_player(player_id)

	if player == null:
		return ActionResult.failure("Người chơi không tồn tại.")

	if not player.is_dying():
		return ActionResult.failure(
			"Người chơi không ở trạng thái hấp hối."
		)

	dying_player_id = player_id
	return ActionResult.success()


func rescue_player(
	rescuer_id: int,
	target_id: int,
	heal_amount: int = 1
) -> ActionResult:
	if _finalizing:
		return ActionResult.failure("Đang hoàn tất loại người chơi.")
	if game_state.match_over:
		return ActionResult.failure("Trận đấu đã kết thúc.")
	if not has_pending_dying():
		return ActionResult.failure(
			"Không có người chơi đang chờ cứu."
		)

	if target_id != dying_player_id:
		return ActionResult.failure(
			"Không phải mục tiêu đang hấp hối."
		)

	if heal_amount <= 0:
		return ActionResult.failure("Lượng hồi máu không hợp lệ.")

	var rescuer: Player = game_state.get_player(rescuer_id)
	var target: Player = game_state.get_player(target_id)

	if rescuer == null or target == null:
		return ActionResult.failure("Người chơi không tồn tại.")

	if not rescuer.is_alive() and not (rescuer_id == target_id and rescuer.is_dying()):
		return ActionResult.failure(
			"Người cứu không thể thực hiện hành động."
		)

	if not target.is_dying():
		return ActionResult.failure(
			"Mục tiêu không còn hấp hối."
		)

	var previous_hp: int = target.hp
	target.hp = mini(target.max_hp, target.hp + heal_amount)
	game_state.healing_applied.emit(rescuer_id, target_id, target.hp - previous_hp)

	if target.hp > 0:
		if not target.recover_from_dying():
			return ActionResult.failure(
				"Không thể khôi phục trạng thái người chơi."
			)

		dying_player_id = 0
		game_state.clear_lethal_source(target_id)
		game_state.update_match_result()

	return ActionResult.success()


func finalize_dying() -> ActionResult:
	if _finalizing or game_state.zone_manager.is_transfer_in_progress():
		return ActionResult.failure("Đang hoàn tất loại người chơi hoặc chuyển vùng bài.")
	if game_state.match_over:
		return ActionResult.failure("Trận đấu đã kết thúc.")
	if not has_pending_dying():
		return ActionResult.failure(
			"Không có người chơi đang chờ xử lý."
		)

	var player: Player = game_state.get_player(dying_player_id)

	if player == null:
		return ActionResult.failure("Người chơi không tồn tại.")

	if not player.is_dying():
		return ActionResult.failure(
			"Trạng thái người chơi không hợp lệ."
		)

	var victim_id: int = player.player_id
	var killer_id: int = game_state.get_lethal_source(victim_id)
	var moves: Array[Dictionary] = []
	for zone: String in ["hand", "equipment", "judgment"]:
		for card: CardInstance in player.get_zone(zone):
			moves.append({"card_id": card.instance_id, "from_zone": zone, "from_player_id": victim_id, "to_zone": "discard", "to_player_id": 0})
	_finalizing = true
	if not moves.is_empty() and not game_state.zone_manager.transfer_cards(moves):
		_finalizing = false
		return ActionResult.failure("Không thể đưa bài của người bị loại vào chồng bỏ.")
	if not player.eliminate():
		_finalizing = false
		return ActionResult.failure(
			"Không thể loại người chơi."
		)

	game_state.clear_lethal_source(victim_id)
	game_state.player_eliminated.emit(victim_id, killer_id)
	var killer: Player = game_state.get_player(killer_id)
	if killer != null and killer_id != victim_id and not killer.is_eliminated():
		var drawn: int = 0
		for index: int in range(2):
			if game_state.draw_card(killer_id) == null:
				break
			drawn += 1
		game_state.kill_reward_drawn.emit(killer_id, victim_id, drawn)
	# Keep the Dying guard throughout cleanup and reward, including the final kill.
	dying_player_id = 0
	_finalizing = false
	game_state.update_match_result()
	return ActionResult.success()
