class_name MultiDiscardTest
extends RefCounted


static func setup(hand_count: int = 8) -> CombatController:
	var combat: CombatController = AoeSystemTest.setup()
	for index: int in range(hand_count):
		AoeSystemTest.give(combat, 1, "attack" if index % 2 == 0 else "dodge")
	return combat


static func run_all() -> void:
	_test_atomic_batch()
	_test_dying_and_limits()
	print("=== ALL MULTI DISCARD TESTS PASSED ===")


static func _test_atomic_batch() -> void:
	var combat: CombatController = setup()
	var player: Player = combat.game_state.get_player(1)
	var first: int = player.hand[0].instance_id
	var second: int = player.hand[1].instance_id
	assert(not combat.discard_cards_for_turn(1, [first, second]).valid)
	var weapon: CardInstance = AoeSystemTest.give(combat, 1, "crossbow")
	assert(combat.equip_weapon(1, weapon.instance_id).valid)
	var foreign: CardInstance = AoeSystemTest.give(combat, 2, "heal")
	assert(combat.end_turn(1).valid)
	assert(combat.turn_manager.get_required_discards() == 4)
	var before: Array[CardInstance] = player.hand.duplicate()
	var discard_before: int = combat.game_state.deck.get_discard_count()
	assert(not combat.discard_cards_for_turn(1, []).valid)
	assert(not combat.discard_cards_for_turn(2, [first, second]).valid)
	assert(not combat.discard_cards_for_turn(1, [first, first]).valid)
	assert(not combat.discard_cards_for_turn(1, [first, 999999]).valid)
	assert(not combat.discard_cards_for_turn(1, [first, foreign.instance_id]).valid)
	assert(not combat.discard_cards_for_turn(1, [first, weapon.instance_id]).valid)
	var too_many: Array[int] = []
	for index: int in range(5):
		too_many.append(player.hand[index].instance_id)
	assert(not combat.discard_cards_for_turn(1, too_many).valid)
	assert(player.hand == before and combat.game_state.deck.get_discard_count() == discard_before)
	combat.turn_manager.set_phase_wait(TurnManager.Phase.DISCARD, "Fixture hold")
	assert(not combat.discard_cards_for_turn(1, [first, second]).valid)
	combat.turn_manager.set_phase_wait(TurnManager.Phase.DISCARD, "")
	var events: Dictionary = {"count": 0}
	var during_discard: Callable = func(names: PackedStringArray) -> void:
		events["count"] += 1
		assert(names.size() == 2)
		assert(not combat.discard_cards_for_turn(1, [first, second]).valid)
		combat.turn_manager.advance_phase()
		assert(combat.turn_manager.current_phase == TurnManager.Phase.DISCARD)
		assert(not combat.end_turn(1).valid)
	combat.game_state.zone_manager.cards_discarded.connect(during_discard)
	assert(combat.discard_cards_for_turn(1, [first, second]).valid)
	assert(player.get_hand_count() == 6 and combat.turn_manager.get_required_discards() == 2)
	assert(not combat.discard_cards_for_turn(1, [first, player.hand[0].instance_id]).valid)
	assert(player.get_hand_count() == 6)
	assert(combat.discard_cards_for_turn(1, [player.hand[0].instance_id, player.hand[1].instance_id]).valid)
	combat.game_state.zone_manager.cards_discarded.disconnect(during_discard)
	assert(events["count"] == 2 and player.get_hand_count() == 4)
	assert(combat.turn_manager.get_current_player().player_id == 2)
	assert(combat.game_state.deck.get_discard_count() == discard_before + 4)
	assert(not combat.discard_cards_for_turn(1, [first, second]).valid)
	assert(combat.game_state.validate_state())
	print("[PASS] Atomic selected batches, partial/final progression, duplicates/foreign/equipment/stale/over-discard and reentry guards")


static func _test_dying_and_limits() -> void:
	var combat: CombatController = setup(6)
	var first: int = combat.game_state.get_player(1).hand[0].instance_id
	var second: int = combat.game_state.get_player(1).hand[1].instance_id
	assert(combat.end_turn(1).valid)
	assert(combat.executor.resolver.deal_damage(2, 4))
	assert(not combat.discard_cards_for_turn(1, [first, second]).valid)
	assert(combat.game_state.get_player(1).get_hand_count() == 6)
	var heal: CardInstance = AoeSystemTest.give(combat, 3, "heal")
	assert(combat.rescue_player(3, 2, heal.instance_id).valid)
	assert(combat.discard_cards_for_turn(1, [first, second]).valid)
	assert(combat.game_state.validate_state())
	combat = setup(6)
	combat.executor.validator.rule_engine.add_modifier(RuleModifier.new("hand_limit", "set", 3, RuleModifier.Source.CHARACTER_SKILL, "fixture_limit", 1))
	assert(combat.end_turn(1).valid)
	assert(combat.turn_manager.get_required_discards() == 3)
	var selected: Array[int] = []
	for card: CardInstance in combat.game_state.get_player(1).hand:
		if selected.size() < 3:
			selected.append(card.instance_id)
	assert(combat.discard_cards_for_turn(1, selected).valid)
	assert(combat.game_state.get_player(1).get_hand_count() == 3 and combat.game_state.validate_state())
	print("[PASS] Dying priority and RuleEngine hand limits apply to batch discard without changed rules")
