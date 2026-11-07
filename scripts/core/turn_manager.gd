class_name TurnManager
extends RefCounted

signal turn_started(player_id: int, number: int)

enum Phase { START, JUDGMENT, DRAW, PLAY, DISCARD, END }

const PHASE_LABELS: Dictionary = {
	Phase.START: "Giai đoạn bắt đầu",
	Phase.JUDGMENT: "Giai đoạn phán xét",
	Phase.DRAW: "Giai đoạn rút bài",
	Phase.PLAY: "Giai đoạn sử dụng bài",
	Phase.DISCARD: "Giai đoạn bỏ bài",
	Phase.END: "Giai đoạn kết thúc"
}

var game_state: GameState
var current_player_index: int = 0
var current_phase: Phase = Phase.START
var turn_number: int = 1
var draw_count_per_turn: int = 2
# User-confirmed seat order, independent of scene nodes and player-array indices.
var seat_order: Array[int] = []
var _executor_ref: WeakRef
var _rules: RuleEngine
var _phase_waits: Dictionary = {}


func _init(state: GameState, order: Array[int] = [], rules: RuleEngine = null) -> void:
	game_state = state
	_rules = rules
	if order.is_empty():
		for player: Player in state.players:
			seat_order.append(player.player_id)
	else:
		seat_order.assign(order)
	assert(seat_order.size() == state.players.size())
	var seen: Dictionary = {}
	for player_id: int in seat_order:
		assert(state.get_player(player_id) != null and not seen.has(player_id))
		seen[player_id] = true


func bind_combat(action_executor: ActionExecutor, rules: RuleEngine) -> void:
	_executor_ref = weakref(action_executor)
	_rules = rules


func get_current_player() -> Player:
	if current_player_index < 0 or current_player_index >= game_state.players.size():
		return null
	return game_state.players[current_player_index]


static func get_phase_display_name(phase: Phase) -> String:
	return str(PHASE_LABELS.get(phase, "Giai đoạn không xác định"))


func get_transition_block_reason() -> String:
	if game_state.match_over:
		var winner: Player = game_state.get_player(game_state.winner_id)
		return "Trận đấu đã kết thúc. %s thắng cuộc!" % winner.display_name
	var dying_reason: String = get_dying_block_reason()
	if not dying_reason.is_empty():
		return dying_reason
	if game_state.zone_manager.is_transfer_in_progress():
		return "Đang chuyển vùng bài; chờ hoàn tất trước khi tiếp tục."
	if _executor_ref != null:
		var action_executor: ActionExecutor = _executor_ref.get_ref() as ActionExecutor
		if action_executor != null:
			action_executor.damage_pipeline.resume_pending()
			dying_reason = get_dying_block_reason()
			if not dying_reason.is_empty():
				return dying_reason
			if action_executor.damage_pipeline.is_busy():
				return "Phải giải quyết lựa chọn phòng ngự trước."
			if action_executor.support_tools.has_pending():
				return "Phải hoàn tất lựa chọn công cụ hỗ trợ trước."
			action_executor.attack_resolution.resume()
			if action_executor.attack_resolution.is_busy():
				return "Phải giải quyết phản ứng Tấn công hoặc lựa chọn vũ khí trước."
			if action_executor.has_pending_aoe():
				return "Phải giải quyết phản ứng AOE trước."
	return ""


func get_dying_block_reason() -> String:
	if _executor_ref != null:
		var action_executor: ActionExecutor = _executor_ref.get_ref() as ActionExecutor
		if action_executor != null:
			action_executor.dying_manager.ensure_pending_dying()
			if action_executor.dying_manager.has_pending_dying():
				return "Phải giải quyết người đang hấp hối trước."
	for player: Player in game_state.players:
		if player.is_dying() or (not player.is_eliminated() and player.hp <= 0):
			return "Có người hấp hối chưa được giải quyết."
	return ""


func set_phase_wait(phase: Phase, reason: String) -> void:
	# Future effects can explicitly hold a phase instead of being skipped.
	if reason.is_empty():
		_phase_waits.erase(phase)
	else:
		_phase_waits[phase] = reason


func get_required_discards() -> int:
	var player: Player = get_current_player()
	if player == null or _rules == null:
		return -1
	var context: RuleContext = RuleContext.new(player.player_id, 0, player.player_id)
	var rule: Dictionary = _rules.get_rule("hand_limit", {"current_hp": player.hp}, context)
	if rule.is_empty():
		return -1
	if bool(rule["unlimited"]):
		return 0
	var limit: int = int(rule["value"])
	if limit < 0:
		return -1
	return maxi(0, player.get_hand_count() - limit)


func get_wait_reason() -> String:
	var blocked: String = get_transition_block_reason()
	if not blocked.is_empty():
		return blocked
	var player: Player = get_current_player()
	if player == null:
		return "Không còn người chơi đủ điều kiện; chưa có luật thắng/thua."
	if player.is_eliminated():
		return ""
	var effect_wait: String = get_effect_wait_reason()
	if not effect_wait.is_empty():
		return effect_wait
	if current_phase == Phase.PLAY:
		return "Chờ người đang lượt chọn Kết thúc lượt."
	if current_phase == Phase.DISCARD:
		var required: int = get_required_discards()
		if required < 0:
			return "Dừng ở giai đoạn bỏ bài: thiếu hoặc sai luật giới hạn bài trên tay."
		if required > 0:
			return "Chọn bỏ %d lá trên tay để kết thúc lượt." % required
	return ""


func get_effect_wait_reason() -> String:
	if _phase_waits.has(current_phase):
		return str(_phase_waits[current_phase])
	var player: Player = get_current_player()
	if player != null and current_phase == Phase.JUDGMENT and not player.judgment.is_empty():
		return "Dừng ở giai đoạn phán xét: chưa hỗ trợ xử lý bài phán xét."
	return ""


func start_game() -> void:
	if not get_transition_block_reason().is_empty():
		return
	turn_number = 1
	_select_next(-1, false)


func advance_phase() -> void:
	if not get_transition_block_reason().is_empty():
		return
	var player: Player = get_current_player()
	if player == null:
		return
	if player.is_eliminated():
		_next_player()
		return
	if not get_wait_reason().is_empty():
		return
	match current_phase:
		Phase.START:
			current_phase = Phase.JUDGMENT
		Phase.JUDGMENT:
			current_phase = Phase.DRAW
		Phase.DRAW:
			_execute_draw_phase()
			current_phase = Phase.PLAY
		Phase.DISCARD:
			current_phase = Phase.END
		Phase.END:
			_next_player()


func end_play(player_id: int) -> ActionResult:
	var blocked: String = get_transition_block_reason()
	if not blocked.is_empty():
		return ActionResult.failure(blocked)
	var player: Player = get_current_player()
	if current_phase != Phase.PLAY or player == null:
		return ActionResult.failure("Chỉ kết thúc lượt trong giai đoạn sử dụng bài.")
	if player.player_id != player_id or not player.is_alive():
		return ActionResult.failure("Không phải người đang lượt còn sống.")
	if _phase_waits.has(current_phase):
		return ActionResult.failure(str(_phase_waits[current_phase]))
	current_phase = Phase.DISCARD
	return ActionResult.success()


func _execute_draw_phase() -> void:
	var player: Player = get_current_player()
	if player == null or not player.is_alive():
		return
	for index: int in range(draw_count_per_turn):
		if game_state.draw_card(player.player_id) == null:
			break


func _next_player() -> void:
	var player: Player = get_current_player()
	var previous_seat: int = -1 if player == null else seat_order.find(player.player_id)
	_select_next(previous_seat, true)


func _select_next(previous_seat: int, increment_turn: bool) -> void:
	for offset: int in range(1, seat_order.size() + 1):
		var seat: int = (previous_seat + offset) % seat_order.size()
		var player: Player = game_state.get_player(seat_order[seat])
		if player != null and player.is_alive():
			current_player_index = game_state.players.find(player)
			current_phase = Phase.START
			if increment_turn:
				turn_number += 1
			turn_started.emit(player.player_id, turn_number)
			return
	current_player_index = -1
	current_phase = Phase.END


func print_turn_info() -> void:
	var player: Player = get_current_player()
	if player != null:
		print("Lượt %d | Người chơi: %s | %s" % [turn_number, player.display_name, get_phase_display_name(current_phase)])
