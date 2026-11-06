class_name CombatController
extends RefCounted

const MAX_AUTO_STEPS: int = 32

var game_state: GameState
var turn_manager: TurnManager
var executor: ActionExecutor
var tracked_turn_number: int = -1
var tracked_player_id: int = -1
var auto_stop_reason: String = ""


func _init(state: GameState, turns: TurnManager, rules: RuleEngine) -> void:
	game_state = state
	turn_manager = turns
	executor = ActionExecutor.new(state, turns, rules)
	turn_manager.turn_started.connect(_on_turn_started)


func _on_turn_started(player_id: int, number: int) -> void:
	# Track direct TurnManager transitions too; never reset a counter again
	# after an action has already been executed through the direct executor API.
	tracked_player_id = player_id
	tracked_turn_number = number


func start_match(initial_cards: int = 4) -> ActionResult:
	var blocked: String = turn_manager.get_transition_block_reason()
	if not blocked.is_empty():
		return ActionResult.failure(blocked)
	var dealt: ActionResult = game_state.deal_initial_hands(initial_cards, turn_manager.seat_order)
	if not dealt.valid:
		return dealt
	return start_game()


func equip_weapon(actor_id: int, card_id: int) -> ActionResult:
	return executor.equip_weapon(actor_id, card_id)


func get_weapon(player_id: int) -> CardInstance:
	return executor.equipment_system.get_weapon(player_id)


func get_defense(player_id: int) -> CardInstance:
	return executor.equipment_system.get_defense(player_id)


func get_attack_range(player_id: int) -> Dictionary:
	var context: RuleContext = RuleContext.new(player_id)
	return executor.validator.rule_engine.get_rule("attack_range", {}, context)


func use_heal(actor_id: int, card_id: int) -> ActionResult:
	return executor.use_heal(actor_id, card_id)


func use_aoe(actor_id: int, card_id: int) -> ActionResult:
	return executor.use_aoe(actor_id, card_id)


func respond_to_aoe(target_id: int, response_card_id: int = 0) -> ActionResult:
	return _resume_after(executor.respond_to_aoe(target_id, response_card_id))


func has_pending_aoe() -> bool:
	return executor.has_pending_aoe()


func get_pending_aoe() -> Dictionary:
	executor.aoe_resolution.resume()
	return executor.aoe_resolution.get_pending()


func get_aoe_response_cards(target_id: int) -> Array[CardInstance]:
	executor.aoe_resolution.resume()
	return executor.aoe_resolution.get_response_cards(target_id)


func use_tool(actor_id: int, target_id: int, card_id: int, target_card_id: int, zone: String) -> ActionResult:
	return executor.use_tool(actor_id, target_id, card_id, target_card_id, zone)


func start_game() -> ActionResult:
	var blocked: String = turn_manager.get_transition_block_reason()
	if not blocked.is_empty():
		return ActionResult.failure(blocked)
	game_state.update_match_result()
	if game_state.match_over:
		return ActionResult.success()
	turn_manager.start_game()
	_sync_turn_counter()
	return advance_until_decision()


func advance_phase() -> ActionResult:
	# Compatibility entry point: resume automatic phases, never end PLAY.
	return advance_until_decision()


func get_status_message() -> String:
	var blocked: String = turn_manager.get_transition_block_reason()
	if not blocked.is_empty():
		return blocked
	return auto_stop_reason if not auto_stop_reason.is_empty() else turn_manager.get_wait_reason()


func advance_until_decision(max_steps: int = MAX_AUTO_STEPS) -> ActionResult:
	auto_stop_reason = ""
	if max_steps < 1 or max_steps > MAX_AUTO_STEPS:
		auto_stop_reason = "Giới hạn auto-advance phải trong 1..%d." % MAX_AUTO_STEPS
		return ActionResult.failure(auto_stop_reason)
	for step: int in range(max_steps):
		var blocked: String = turn_manager.get_transition_block_reason()
		if not blocked.is_empty():
			return ActionResult.failure(blocked)
		var player: Player = turn_manager.get_current_player()
		if player == null:
			return ActionResult.failure(turn_manager.get_wait_reason())
		var waiting: String = turn_manager.get_wait_reason()
		if not waiting.is_empty():
			# PLAY, DISCARD choice, or unsupported effect: stop without skipping.
			return ActionResult.success()
		var old_phase: TurnManager.Phase = turn_manager.current_phase
		var old_turn: int = turn_manager.turn_number
		turn_manager.advance_phase()
		_sync_turn_counter()
		if old_phase == turn_manager.current_phase and old_turn == turn_manager.turn_number:
			auto_stop_reason = turn_manager.get_wait_reason()
			if auto_stop_reason.is_empty():
				auto_stop_reason = "Auto-advance dừng vì không có tiến triển."
			return ActionResult.failure(auto_stop_reason)
	# A decision reached on the final allowed step is still a valid stop.
	var current: Player = turn_manager.get_current_player()
	if current != null and not current.is_eliminated() and not turn_manager.get_wait_reason().is_empty():
		return ActionResult.success()
	auto_stop_reason = "Auto-advance đạt giới hạn %d bước; đã dừng an toàn." % max_steps
	return ActionResult.failure(auto_stop_reason)


func end_turn(player_id: int) -> ActionResult:
	var result: ActionResult = turn_manager.end_play(player_id)
	return _resume_after(result)


func discard_for_turn(player_id: int, card_id: int) -> ActionResult:
	return _resume_after(executor.discard_for_turn(player_id, card_id))


func _resume_after(result: ActionResult) -> ActionResult:
	if result.valid and not game_state.match_over:
		# A completed action remains successful even if a later phase is held.
		# The hold/budget/no-player status is available through get_status_message().
		advance_until_decision()
	return result


func use_attack(actor_id: int, target_id: int, card_id: int) -> ActionResult:
	_sync_turn_counter()
	return executor.use_attack(actor_id, target_id, card_id)


func respond_to_attack(target_id: int, dodge_card_id: int = 0) -> ActionResult:
	return _resume_after(executor.respond_to_attack(target_id, dodge_card_id))


func has_pending_response() -> bool:
	return executor.has_pending_attack()


func _sync_turn_counter() -> void:
	var current_player: Player = turn_manager.get_current_player()
	if current_player == null:
		return
	var current_turn: int = turn_manager.turn_number
	var current_id: int = current_player.player_id
	if current_turn == tracked_turn_number and current_id == tracked_player_id:
		return
	if not turn_manager.get_transition_block_reason().is_empty():
		return
	executor.reset_turn_counters()
	tracked_turn_number = current_turn
	tracked_player_id = current_id


func has_pending_dying() -> bool:
	executor.dying_manager.ensure_pending_dying()
	return executor.dying_manager.has_pending_dying()


func rescue_player(rescuer_id: int, target_id: int, card_id: int = 0) -> ActionResult:
	executor.dying_manager.ensure_pending_dying()
	return _resume_after(executor.use_rescue(rescuer_id, target_id, card_id))


func finalize_dying() -> ActionResult:
	executor.dying_manager.ensure_pending_dying()
	var result: ActionResult = executor.dying_manager.finalize_dying()
	if result.valid and executor.has_pending_attack():
		var target_id: int = int(executor.pending_attack["target_id"])
		var target: Player = game_state.get_player(target_id)
		if target != null and target.is_eliminated():
			# Complete the stale attack through its guarded API, without spending Dodge.
			executor.respond_to_attack(target_id)
	return _resume_after(result)
