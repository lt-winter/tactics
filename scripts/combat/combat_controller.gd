
class_name CombatController
extends RefCounted

var game_state: GameState
var turn_manager: TurnManager
var executor: ActionExecutor

var tracked_turn_number: int = -1
var tracked_player_id: int = -1


func _init(
	state: GameState,
	turns: TurnManager,
	rules: RuleEngine
) -> void:
	game_state = state
	turn_manager = turns
	executor = ActionExecutor.new(state, turns, rules)


func start_game() -> ActionResult:
	if has_pending_dying():
		return ActionResult.failure(
			"Không thể bắt đầu lại khi đang có người hấp hối."
		)

	if executor.has_pending_attack():
		return ActionResult.failure(
			"Không thể bắt đầu lại khi đang chờ phản ứng."
		)

	turn_manager.start_game()
	_sync_turn_counter()

	return ActionResult.success()



func advance_phase() -> ActionResult:
	if executor.has_pending_attack():
		return ActionResult.failure(
			"Phải giải quyết Tấn công trước khi chuyển giai đoạn."
		)

	if has_pending_dying():
		return ActionResult.failure(
			"Phải giải quyết hấp hối trước khi chuyển giai đoạn."
		)

	turn_manager.advance_phase()
	_sync_turn_counter()

	return ActionResult.success()



func use_attack(
	actor_id: int,
	target_id: int,
	card_id: int
) -> ActionResult:
	_sync_turn_counter()

	return executor.use_attack(
		actor_id,
		target_id,
		card_id
	)


func respond_to_attack(
	target_id: int,
	dodge_card_id: int = 0
) -> ActionResult:
	return executor.respond_to_attack(
		target_id,
		dodge_card_id
	)


func has_pending_response() -> bool:
	return executor.has_pending_attack()


func _sync_turn_counter() -> void:
	var current_player: Player = turn_manager.get_current_player()

	if current_player == null:
		return

	var current_turn: int = turn_manager.turn_number
	var current_id: int = current_player.player_id

	if current_turn == tracked_turn_number \
	and current_id == tracked_player_id:
		return

	if executor.has_pending_attack():
		return

	executor.reset_turn_counters()

	tracked_turn_number = current_turn
	tracked_player_id = current_id


func has_pending_dying() -> bool:
	return executor.dying_manager.has_pending_dying()


func rescue_player(
	rescuer_id: int,
	target_id: int,
	heal_amount: int = 1
) -> ActionResult:
	return executor.dying_manager.rescue_player(
		rescuer_id,
		target_id,
		heal_amount
	)


func finalize_dying() -> ActionResult:
	return executor.dying_manager.finalize_dying()
