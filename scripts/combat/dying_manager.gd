
class_name DyingManager
extends RefCounted

var game_state: GameState
var dying_player_id: int = 0


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

	target.hp = mini(target.max_hp, target.hp + heal_amount)

	if target.hp > 0:
		if not target.recover_from_dying():
			return ActionResult.failure(
				"Không thể khôi phục trạng thái người chơi."
			)

		dying_player_id = 0

	return ActionResult.success()


func finalize_dying() -> ActionResult:
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

	if not player.eliminate():
		return ActionResult.failure(
			"Không thể loại người chơi."
		)

	dying_player_id = 0
	return ActionResult.success()
