
class_name TurnManagerTest
extends RefCounted


static func run_all() -> void:
	var card_db: CardDatabase = CardDatabase.new()

	if not card_db.load_from_file("res://data/cards.json"):
		push_error("Không thể nạp cards.json")
		return

	var deck_db: DeckDatabase = DeckDatabase.new(card_db)

	if not deck_db.load_from_file(
		"res://data/decks/standard.json"
	):
		for error in deck_db.get_errors():
			push_error(error)
		return

	var cards: Array[CardInstance] = deck_db.create_instances()

	var player_a: Player = Player.new(1, "Player A", 4)
	var player_b: Player = Player.new(2, "Player B", 4)

	var game: GameState = GameState.new(
		cards,
		[player_a, player_b]
	)

	var rules: RuleEngine = RuleEngine.new()
	assert(rules.load_base_rules("res://data/rules/base_rules.json"))
	var turns: TurnManager = TurnManager.new(game, [], rules)

	print("=== TURN MANAGER TEST ===")

	turns.start_game()

	assert(turns.turn_number == 1)
	assert(turns.get_current_player() == player_a)
	assert(turns.current_phase == TurnManager.Phase.START)

	turns.advance_phase()
	assert(turns.current_phase == TurnManager.Phase.JUDGMENT)

	turns.advance_phase()
	assert(turns.current_phase == TurnManager.Phase.DRAW)

	turns.advance_phase()
	assert(turns.current_phase == TurnManager.Phase.PLAY)
	assert(player_a.get_hand_count() == 2)
	assert(game.validate_state())

	print("[PASS] Player A rút 2 lá")

	turns.advance_phase()
	assert(turns.current_phase == TurnManager.Phase.PLAY)
	assert(turns.end_play(player_a.player_id).valid)
	assert(turns.current_phase == TurnManager.Phase.DISCARD)

	turns.advance_phase()
	assert(turns.current_phase == TurnManager.Phase.END)

	turns.advance_phase()
	assert(turns.turn_number == 2)
	assert(turns.get_current_player() == player_b)
	assert(turns.current_phase == TurnManager.Phase.START)

	print("[PASS] Chuyển lượt sang Player B")

	turns.advance_phase()
	turns.advance_phase()
	turns.advance_phase()

	assert(player_b.get_hand_count() == 2)
	assert(game.validate_state())

	print("[PASS] Player B rút 2 lá")
	print("[PASS] Bảo toàn trạng thái trận đấu")
	_test_counterclockwise_and_elimination()
	_test_auto_and_decisions()
	_test_window_guards()
	_test_discard_selection()
	_test_opening_draws()
	print("=== ALL TURN MANAGER TESTS PASSED ===")


static func _test_opening_draws() -> void:
	var combat: CombatController = _fixture(4, 2)
	assert(combat.start_match().valid)
	for player: Player in combat.game_state.players:
		assert(player.get_hand_count() == (6 if player.player_id == 1 else 4))
	var draw_count: int = combat.game_state.deck.get_draw_count()
	assert(combat.advance_until_decision().valid)
	assert(combat.game_state.deck.get_draw_count() == draw_count)
	assert(not combat.start_match().valid)
	for expected: int in [2, 3, 4, 1]:
		var actor_id: int = combat.turn_manager.get_current_player().player_id
		assert(combat.end_turn(actor_id).valid)
		for discarded: int in range(2):
			assert(combat.turn_manager.current_phase == TurnManager.Phase.DISCARD)
			var actor: Player = combat.game_state.get_player(actor_id)
			assert(combat.discard_for_turn(actor_id, actor.hand[0].instance_id).valid)
		assert(combat.turn_manager.get_current_player().player_id == expected)
		assert(combat.game_state.get_player(expected).get_hand_count() == 6)
	assert(combat.game_state.validate_state())
	var labels: Array[String] = ["Giai đoạn bắt đầu", "Giai đoạn phán xét", "Giai đoạn rút bài", "Giai đoạn sử dụng bài", "Giai đoạn bỏ bài", "Giai đoạn kết thúc"]
	for phase: TurnManager.Phase in [TurnManager.Phase.START, TurnManager.Phase.JUDGMENT, TurnManager.Phase.DRAW, TurnManager.Phase.PLAY, TurnManager.Phase.DISCARD, TurnManager.Phase.END]:
		assert(TurnManager.get_phase_display_name(phase) == labels[int(phase)])
	print("[PASS] Four opening cards plus first-turn DRAW for every seat; Vietnamese phase labels")


static func _fixture(count: int = 4, draws: int = 0, reverse_storage: bool = false) -> CombatController:
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file("res://data/cards.json"))
	var decks: DeckDatabase = DeckDatabase.new(database)
	assert(decks.load_from_file("res://data/decks/standard.json"))
	var players: Array[Player] = []
	var order: Array[int] = []
	for player_id: int in range(1, count + 1):
		players.append(Player.new(player_id, "Seat %d" % player_id, 4))
		order.append(player_id)
	if reverse_storage:
		players.reverse()
	var state: GameState = GameState.new(decks.create_instances(), players)
	var turns: TurnManager = TurnManager.new(state, order)
	turns.draw_count_per_turn = draws
	var rules: RuleEngine = RuleEngine.new()
	assert(rules.load_base_rules("res://data/rules/base_rules.json"))
	return CombatController.new(state, turns, rules)


static func _eliminate(combat: CombatController, player_id: int) -> void:
	assert(combat.executor.resolver.deal_damage(player_id, 4))
	assert(combat.executor.dying_manager.begin_dying(player_id).valid)
	assert(combat.executor.dying_manager.finalize_dying().valid)


static func _test_counterclockwise_and_elimination() -> void:
	for count: int in range(2, 6):
		var combat: CombatController = _fixture(count, 0, true)
		assert(combat.start_game().valid)
		for turn: int in range(count * 2):
			var expected: int = turn % count + 1
			assert(combat.turn_manager.get_current_player().player_id == expected)
			assert(combat.end_turn(expected).valid)
	var combat: CombatController = _fixture()
	_eliminate(combat, 2)
	_eliminate(combat, 4)
	assert(combat.start_game().valid)
	assert(combat.end_turn(1).valid)
	assert(combat.turn_manager.get_current_player().player_id == 3)
	assert(combat.end_turn(3).valid)
	assert(combat.turn_manager.get_current_player().player_id == 1)
	# Finalizing the current actor ends the match when exactly one survivor remains.
	assert(combat.executor.resolver.deal_damage(1, 4))
	assert(combat.executor.dying_manager.begin_dying(1).valid)
	assert(combat.finalize_dying().valid)
	assert(combat.game_state.match_over and combat.game_state.winner_id == 3)
	assert(not combat.end_turn(3).valid)
	assert(not combat.advance_until_decision().valid)
	assert(not combat.start_game().valid)
	var empty: CombatController = _fixture(0)
	assert(not empty.start_game().valid)
	assert(empty.turn_manager.get_current_player() == null)
	assert(not empty.game_state.match_over)
	print("[PASS] Counterclockwise 2–5 seats, eliminated/current/last seat and empty table")


static func _test_auto_and_decisions() -> void:
	var combat: CombatController = _fixture(4, 2)
	assert(combat.start_game().valid)
	var turns: TurnManager = combat.turn_manager
	assert(turns.current_phase == TurnManager.Phase.PLAY)
	assert(combat.game_state.get_player(1).get_hand_count() == 2)
	assert(combat.advance_until_decision().valid)
	turns.advance_phase()
	assert(turns.current_phase == TurnManager.Phase.PLAY)
	assert(combat.game_state.get_player(1).get_hand_count() == 2)
	assert(not combat.end_turn(2).valid)
	assert(combat.end_turn(1).valid)
	assert(turns.get_current_player().player_id == 2)
	assert(turns.current_phase == TurnManager.Phase.PLAY)
	assert(combat.game_state.get_player(2).get_hand_count() == 2)
	var held: CombatController = _fixture()
	held.turn_manager.set_phase_wait(TurnManager.Phase.START, "Unimplemented START choice")
	assert(held.start_game().valid)
	assert(held.turn_manager.current_phase == TurnManager.Phase.START)
	assert(held.get_status_message() == "Unimplemented START choice")
	held.turn_manager.set_phase_wait(TurnManager.Phase.START, "")
	assert(not held.advance_until_decision(1).valid)
	assert(held.turn_manager.current_phase == TurnManager.Phase.JUDGMENT)
	assert(not held.advance_until_decision(0).valid)
	assert(not held.advance_until_decision(1000000).valid)
	assert(held.advance_until_decision(2).valid)
	assert(held.turn_manager.current_phase == TurnManager.Phase.PLAY)
	var judgment: CombatController = _fixture(4, 2)
	var card: CardInstance = judgment.game_state.deck.draw_pile[0]
	assert(judgment.game_state.zone_manager.transfer_card(card.instance_id, "draw", 0, "judgment", 1))
	assert(judgment.start_game().valid)
	assert(judgment.turn_manager.current_phase == TurnManager.Phase.JUDGMENT)
	judgment.turn_manager.advance_phase()
	assert(judgment.turn_manager.current_phase == TurnManager.Phase.JUDGMENT)
	assert(judgment.game_state.get_player(1).hand.is_empty())
	assert(judgment.get_status_message().contains("chưa hỗ trợ"))
	print("[PASS] Automatic phases, explicit PLAY end, unknown effects and step budget")


static func _test_window_guards() -> void:
	var combat: CombatController = _fixture()
	assert(combat.start_game().valid)
	var attack_id: int = 0
	for card: CardInstance in combat.game_state.deck.draw_pile:
		if card.definition.has_effect("deal_attack"):
			attack_id = card.instance_id
			break
	assert(combat.game_state.zone_manager.transfer_card(attack_id, "draw", 0, "hand", 1))
	assert(combat.use_attack(1, 2, attack_id).valid)
	var turns: TurnManager = combat.turn_manager
	turns.advance_phase()
	turns.start_game()
	assert(turns.current_phase == TurnManager.Phase.PLAY and turns.turn_number == 1)
	assert(not turns.end_play(1).valid)
	assert(not combat.end_turn(1).valid)
	assert(not combat.advance_until_decision().valid)
	assert(combat.executor.attacks_used == 1)
	assert(combat.respond_to_attack(2).valid)
	assert(combat.executor.resolver.deal_damage(1, 4))
	assert(combat.executor.dying_manager.begin_dying(1).valid)
	turns.advance_phase()
	turns.start_game()
	assert(turns.current_phase == TurnManager.Phase.PLAY and turns.turn_number == 1)
	assert(not combat.end_turn(1).valid)
	assert(not combat.advance_until_decision().valid)
	var heal_id: int = 0
	for card: CardInstance in combat.game_state.deck.draw_pile:
		if card.definition.has_effect("restore_hp"):
			heal_id = card.instance_id
			break
	assert(heal_id != 0)
	assert(combat.game_state.zone_manager.transfer_card(heal_id, "draw", 0, "hand", 3))
	assert(combat.rescue_player(3, 1, heal_id).valid)
	assert(turns.get_current_player().player_id == 1)
	assert(combat.executor.attacks_used == 1)
	# Low-level callers also reset executor counters via turn_started.
	assert(turns.end_play(1).valid)
	turns.advance_phase()
	turns.advance_phase()
	assert(combat.executor.attacks_used == 0)
	assert(turns.get_current_player().player_id == 2)
	assert(combat.advance_until_decision().valid)
	var next_attacks: Array[CardInstance] = []
	for card: CardInstance in combat.game_state.deck.draw_pile:
		if card.definition.has_effect("deal_attack"):
			next_attacks.append(card)
	assert(next_attacks.size() >= 2)
	for index: int in range(2):
		assert(combat.game_state.zone_manager.transfer_card(next_attacks[index].instance_id, "draw", 0, "hand", 2))
	assert(combat.executor.use_attack(2, 3, next_attacks[0].instance_id).valid)
	assert(combat.executor.respond_to_attack(3).valid)
	# Mixing direct executor/controller APIs must not reset an already-used limit.
	assert(not combat.use_attack(2, 3, next_attacks[1].instance_id).valid)
	assert(combat.executor.attacks_used == 1)
	assert(combat.game_state.validate_state())
	print("[PASS] Direct TurnManager calls cannot bypass attack/dying windows")


static func _test_discard_selection() -> void:
	var combat: CombatController = _fixture()
	assert(combat.start_game().valid)
	var player: Player = combat.game_state.get_player(1)
	for index: int in range(6):
		assert(combat.game_state.draw_card(1) != null)
	assert(not combat.discard_for_turn(1, player.hand[0].instance_id).valid)
	assert(combat.end_turn(1).valid)
	assert(combat.turn_manager.current_phase == TurnManager.Phase.DISCARD)
	assert(combat.turn_manager.get_required_discards() == 2)
	combat.turn_manager.advance_phase()
	assert(combat.turn_manager.current_phase == TurnManager.Phase.DISCARD)
	assert(not combat.discard_for_turn(2, player.hand[0].instance_id).valid)
	assert(not combat.discard_for_turn(1, 99999).valid)
	assert(player.get_hand_count() == 6)
	combat.turn_manager.set_phase_wait(TurnManager.Phase.DISCARD, "Pending discard trigger")
	assert(not combat.discard_for_turn(1, player.hand[0].instance_id).valid)
	assert(player.get_hand_count() == 6)
	combat.turn_manager.set_phase_wait(TurnManager.Phase.DISCARD, "")
	var first_id: int = player.hand[0].instance_id
	assert(combat.discard_for_turn(1, first_id).valid)
	assert(combat.turn_manager.current_phase == TurnManager.Phase.DISCARD)
	assert(combat.turn_manager.get_required_discards() == 1)
	assert(not combat.discard_for_turn(1, first_id).valid)
	assert(combat.discard_for_turn(1, player.hand[0].instance_id).valid)
	assert(player.get_hand_count() == 4)
	assert(combat.turn_manager.get_current_player().player_id == 2)
	assert(combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
	assert(combat.game_state.validate_state())
	var unlimited: CombatController = _fixture()
	unlimited.executor.validator.rule_engine.add_modifier(RuleModifier.new(
		"hand_limit", "remove_limit", 0, RuleModifier.Source.CHARACTER_SKILL, "test_unlimited_hand", 1
	))
	assert(unlimited.start_game().valid)
	for index: int in range(6):
		assert(unlimited.game_state.draw_card(1) != null)
	assert(unlimited.end_turn(1).valid)
	assert(unlimited.turn_manager.get_current_player().player_id == 2)
	assert(unlimited.game_state.get_player(1).get_hand_count() == 6)
	var eliminated: CombatController = _fixture()
	assert(eliminated.start_game().valid)
	for index: int in range(6):
		assert(eliminated.game_state.draw_card(1) != null)
	assert(eliminated.end_turn(1).valid)
	assert(eliminated.turn_manager.current_phase == TurnManager.Phase.DISCARD)
	assert(eliminated.executor.resolver.deal_damage(1, 4))
	assert(eliminated.executor.dying_manager.begin_dying(1).valid)
	assert(eliminated.finalize_dying().valid)
	assert(eliminated.turn_manager.get_current_player().player_id == 2)
	assert(eliminated.game_state.get_player(1).get_hand_count() == 6)
	print("[PASS] DISCARD waits for validated choices; no automatic card loss")
