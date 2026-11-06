extends SceneTree

var _ui: PlayablePrototype


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/dev/playable_prototype.tscn")
	_ui = scene.instantiate() as PlayablePrototype
	root.add_child(_ui)
	await process_frame
	assert(_ui.game_state == null)
	_press("CreateMatch")
	await process_frame
	assert(_ui.game_state.players.size() == 4)
	assert(_ui.combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
	for player: Player in _ui.game_state.players:
		assert(player.get_hand_count() == (6 if player.player_id == 1 else 4))
	var phase_label: Label = _ui.find_child("PhaseLabel", true, false) as Label
	assert(phase_label.text.contains("Giai đoạn sử dụng bài"))
	assert(not phase_label.text.contains("PLAY"))
	await process_frame
	var human_seat: Button = _ui.find_child("Seat1", true, false) as Button
	var bot_one_seat: Button = _ui.find_child("Seat2", true, false) as Button
	var bot_two_seat: Button = _ui.find_child("Seat3", true, false) as Button
	var bot_three_seat: Button = _ui.find_child("Seat4", true, false) as Button
	assert(bot_three_seat.get_global_rect().get_center().x < bot_two_seat.get_global_rect().get_center().x)
	assert(bot_one_seat.get_global_rect().get_center().x > bot_two_seat.get_global_rect().get_center().x)
	var human_panel: Control = _ui.find_child("HumanInfoPanel", true, false) as Control
	var bot_table: Control = _ui.find_child("BotTable", true, false) as Control
	assert(human_panel.is_ancestor_of(human_seat) and not bot_table.is_ancestor_of(human_seat))
	assert(bot_table.is_ancestor_of(bot_one_seat) and bot_table.is_ancestor_of(bot_three_seat))
	assert(human_panel.get_global_rect().position.y >= bot_table.get_global_rect().end.y)
	assert(bot_two_seat.get_global_rect().get_center().y < bot_one_seat.get_global_rect().get_center().y)
	assert(human_seat.get_global_rect().get_center().y > bot_three_seat.get_global_rect().get_center().y)
	assert(_ui.find_child("DebugActor", true, false) == null)
	assert(_ui.find_child("HumanDraw", true, false) == null)
	var log_panel: Control = _ui.find_child("EventLogPanel", true, false) as Control
	assert(log_panel.get_global_rect().end.y < bot_two_seat.get_global_rect().position.y)
	assert(human_seat.text.contains("♥♥♥♥") and not human_seat.text.contains("HP "))
	var visible_card: CardInstance = null
	for card: CardInstance in _ui.game_state.get_player(1).hand:
		if _ui._can_select_card(1, card):
			visible_card = card
			break
	while visible_card == null:
		var drawn: CardInstance = _ui.game_state.draw_card(1)
		assert(drawn != null)
		_ui._refresh()
		if _ui._can_select_card(1, drawn):
			visible_card = drawn
	var compact_card: Button = _ui.find_child("Card%d" % visible_card.instance_id, true, false) as Button
	assert(compact_card.size.y > compact_card.size.x)
	assert((compact_card.find_child("CardTitle", true, false) as Label).text == visible_card.definition.display_name.to_upper())
	assert(compact_card.custom_minimum_size == Vector2(88.0, 120.0))
	assert((compact_card.find_child("RankTop", true, false) as Label).text == visible_card.get_rank_text() + CardInstance.SUIT_SYMBOLS[visible_card.suit])
	assert(compact_card.find_children("*", "Label", true, false).size() == 2)
	assert(compact_card.tooltip_text == visible_card.definition.description)
	assert(_ui._card_usage(visible_card) == visible_card.definition.description)
	var events_before_selection: Array[String] = _ui._events.duplicate()
	await _click("Card%d" % visible_card.instance_id)
	assert(_ui.selected_human_card_id == visible_card.instance_id)
	var initial_log: RichTextLabel = _ui.find_child("EventLog", true, false) as RichTextLabel
	assert(not initial_log.text.contains("\n\n"))
	assert(_ui._events == events_before_selection)
	assert((_ui.find_child("Card%d" % visible_card.instance_id, true, false) as Button).position.y == 0.0)
	var deck_panel: Control = _ui.find_child("DeckInfoPanel", true, false) as Control
	assert(deck_panel.get_global_rect().position.y > human_seat.get_global_rect().end.y)
	var deck_label: Label = _ui.find_child("DeckInfoLabel", true, false) as Label
	assert(deck_label.text.contains("Chồng rút: %d" % _ui.game_state.deck.get_draw_count()))
	assert(deck_label.text.contains("Xào: 1 lần"))
	await _click("Seat2")
	assert(_ui.selected_target_id == 2)
	for expected: int in [2, 3, 4, 1]:
		_finish_current_turn()
		assert(_ui.combat.turn_manager.get_current_player().player_id == expected)
		assert(_ui.game_state.get_player(expected).get_hand_count() == 6)
		assert(_ui.displayed_player_id == expected)
		assert(human_panel.is_ancestor_of(human_seat) and human_seat.name == "Seat1")
		for card: CardInstance in _ui.game_state.get_player(expected).hand:
			assert(_ui.find_child("Card%d" % card.instance_id, true, false) != null)
		for player: Player in _ui.game_state.players:
			if player.player_id != expected:
				for card: CardInstance in player.hand:
					assert(_ui.find_child("Card%d" % card.instance_id, true, false) == null)
	_press("NewTable")
	_draw_all_for_human()
	var full_count: int = _ui.game_state.get_player(1).get_hand_count()
	var unsupported: CardInstance = _first_card(1, "restore_hp")
	assert(unsupported != null)
	_press("Card%d" % unsupported.instance_id)
	_press("Seat2")
	_press("ActionConfirm")
	assert(not _ui.combat.has_pending_response())
	assert(_ui.game_state.get_player(1).get_hand_count() == full_count)
	assert(_ui._feedback.text.contains("Chưa thể sử dụng"))
	_press("ActionCancel")
	_select_human_attack()
	_press("Seat3")
	assert((_ui.find_child("Seat3", true, false) as Button).disabled)
	assert(_ui.selected_target_id == 0)
	_press("ActionConfirm")
	assert(not _ui.combat.has_pending_response())
	assert(_ui.game_state.get_player(1).get_hand_count() == full_count)
	_test_lethal_and_rescue()
	_test_bot_attack_and_human_dodge()
	_press("NewTable")
	_draw_all_for_human()
	_make_target_dying()
	_press("ChoiceCancel")
	assert(_ui.game_state.get_player(2).is_eliminated())
	assert(not _ui.combat.has_pending_dying())
	_finish_current_turn()
	assert(_ui.combat.turn_manager.get_current_player().player_id == 3)
	assert(_ui.game_state.validate_state())
	_test_bot_dodge()
	_test_heal_and_cancel()
	_test_weapon_equip()
	_test_target_filtering()
	_test_selection_presentation()
	_test_dying_modal_priority()
	_test_negative_hp_rescue_cards()
	await _test_hidden_tools()
	_test_winner_ui()
	await _test_disabled_cards_and_seats()
	_ui.queue_free()
	await process_frame
	print("=== PLAYABLE PROTOTYPE UI SMOKE PASSED ===")
	quit()


func _press(node_name: String) -> void:
	var button: Button = _ui.find_child(node_name, true, false) as Button
	assert(button != null, node_name)
	button.pressed.emit()
	if node_name == "NewTable":
		(_ui.find_child("CreateMatch", true, false) as Button).pressed.emit()


func _click(node_name: String) -> void:
	var button: Button = _ui.find_child(node_name, true, false) as Button
	assert(button != null)
	await process_frame
	var ancestor: Node = button.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			(ancestor as ScrollContainer).ensure_control_visible(button)
			await process_frame
			break
		ancestor = ancestor.get_parent()
	var position_on_screen: Vector2 = button.get_global_rect().get_center()
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = position_on_screen
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
		await process_frame


func _first_card(player_id: int, effect_id: String) -> CardInstance:
	for card: CardInstance in _ui.game_state.get_player(player_id).hand:
		if card.definition.has_effect(effect_id):
			return card
	return null


func _draw_all_for_human() -> void:
	# Independent UI fixture: collect the opening Bot hands via the transfer API.
	for player_id: int in range(2, 5):
		var cards: Array[CardInstance] = _ui.game_state.get_player(player_id).hand.duplicate()
		for card: CardInstance in cards:
			assert(_ui.game_state.transfer_player_card(card.instance_id, player_id, "hand", 1, "hand"))
	while _ui.game_state.deck.get_draw_count() > 0:
		assert(_ui.game_state.draw_card(1) != null)
	_ui._refresh()
	assert(_ui.game_state.validate_state())


func _select_human_attack() -> void:
	var attack: CardInstance = _first_card(1, "deal_attack")
	assert(attack != null)
	_press("Card%d" % attack.instance_id)


func _make_target_dying() -> void:
	for hit: int in range(4):
		_select_human_attack()
		_press("Seat2")
		_press("ActionConfirm")
		assert(_ui.combat.has_pending_response())
		var phase_before: TurnManager.Phase = _ui.combat.turn_manager.current_phase
		_press("EndTurn")
		assert(_ui.combat.turn_manager.current_phase == phase_before)
		assert((_ui.find_child("CardChoiceOverlay", true, false) as Control).visible)
		_press("ChoiceCancel")
		assert(not _ui.combat.has_pending_response())
		assert(_ui.game_state.get_player(2).hp == 3 - hit)
		if hit < 3:
			for step: int in range(4):
				_finish_current_turn()
	assert(_ui.combat.has_pending_dying())
	assert(_ui.game_state.get_player(2).is_dying())
	assert(_ui._choice_kind == "dying")
	assert((_ui.find_child("CardChoiceOverlay", true, false) as Control).visible)
	assert(_ui.game_state.validate_state())


func _test_lethal_and_rescue() -> void:
	_make_target_dying()
	var phase_before: TurnManager.Phase = _ui.combat.turn_manager.current_phase
	var hand_before: int = _ui.game_state.get_player(1).get_hand_count()
	_press("EndTurn")
	assert((_ui.find_child("ActionConfirm", true, false) as Button).disabled)
	assert(_ui.combat.turn_manager.current_phase == phase_before)
	assert(_ui.game_state.get_player(1).get_hand_count() == hand_before)
	var rescue_card: CardInstance = _give_rescue_card(1)
	_ui._rescue(1)
	assert((_ui.find_child("ChoiceConfirm", true, false) as Button).disabled)
	_press("RescueCard%d" % rescue_card.instance_id)
	_press("ChoiceConfirm")
	assert(not _ui.combat.has_pending_dying())
	assert(_ui.game_state.get_player(2).is_alive())
	assert(_ui.game_state.get_player(2).hp == 1)


func _select_bot_card(effect_id: String) -> void:
	var card: CardInstance = _first_card(_ui.displayed_player_id, effect_id)
	assert(card != null)
	_press("Card%d" % card.instance_id)

func _test_bot_attack_and_human_dodge() -> void:
	_press("NewTable")
	_draw_all_for_human()
	var attack: CardInstance = _first_card(1, "deal_attack")
	var dodge: CardInstance = _first_card(1, "block_attack")
	assert(attack != null and dodge != null)
	assert(_ui.game_state.transfer_player_card(attack.instance_id, 1, "hand", 2, "hand"))
	var remaining: Array[CardInstance] = _ui.game_state.get_player(1).hand.duplicate()
	for card: CardInstance in remaining:
		if card != dodge:
			assert(_ui.game_state.transfer_player_card(card.instance_id, 1, "hand", 3, "hand"))
	_ui._refresh()
	_press("EndTurn")
	assert(_ui.combat.turn_manager.get_current_player().player_id == 2)
	_select_bot_card("deal_attack")
	assert((_ui.find_child("Seat2", true, false) as Button).disabled)
	assert((_ui.find_child("Seat4", true, false) as Button).disabled)
	_press("Seat1")
	_press("ActionConfirm")
	assert(_ui.combat.has_pending_response())
	_press("DodgeCard%d" % dodge.instance_id)
	assert(_ui.combat.has_pending_response())
	assert(_ui.game_state.get_player(1).hp == 4)
	_press("ChoiceConfirm")
	assert(not _ui.combat.has_pending_response())
	assert(_ui.game_state.get_player(1).hp == 4)
	assert(_ui.game_state.validate_state())


func _test_bot_dodge() -> void:
	_press("NewTable")
	_draw_all_for_human()
	# Fixture setup uses the existing transfer API; no HP/phase/window mutation.
	var dodge: CardInstance = _first_card(1, "block_attack")
	assert(dodge != null)
	assert(_ui.game_state.transfer_player_card(dodge.instance_id, 1, "hand", 2, "hand"))
	_ui._refresh()
	_select_human_attack()
	_press("Seat2")
	_press("ActionConfirm")
	assert(_ui.combat.has_pending_response())
	var hand_before: int = _ui.game_state.get_player(2).get_hand_count()
	_press("DodgeCard%d" % dodge.instance_id)
	assert(_ui.game_state.get_player(2).get_hand_count() == hand_before)
	assert(_ui.combat.has_pending_response())
	_press("ChoiceConfirm")
	assert(not _ui.combat.has_pending_response())
	assert(_ui.game_state.get_player(2).hp == 4)
	assert(_ui.game_state.validate_state())


func _finish_current_turn() -> void:
	var actor_id: int = _ui.combat.turn_manager.get_current_player().player_id
	_press("EndTurn")
	var discard_budget: int = _ui.game_state.get_player(actor_id).get_hand_count() + 1
	for step: int in range(discard_budget):
		if _ui.combat.turn_manager.current_phase != TurnManager.Phase.DISCARD:
			assert(_ui.combat.turn_manager.current_phase == TurnManager.Phase.PLAY)
			return
		var player: Player = _ui.game_state.get_player(actor_id)
		assert((_ui.find_child("PhaseLabel", true, false) as Label).text.contains("Giai đoạn bỏ bài"))
		var chosen: CardInstance = player.hand[0]
		for card: CardInstance in player.hand:
			if not card.definition.has_effect("deal_attack"):
				chosen = card
				break
		_press("Card%d" % chosen.instance_id)
		_press("ActionConfirm")
	assert(false, "UI turn/discard did not finish within budget")


func _test_heal_and_cancel() -> void:
	_press("NewTable")
	_draw_all_for_human()
	var heal: CardInstance = _first_card(1, "restore_hp")
	assert(heal != null)
	assert(_ui.combat.executor.resolver.deal_damage(1, 1))
	_ui._refresh()
	var hand_count: int = _ui.game_state.get_player(1).get_hand_count()
	_press("Card%d" % heal.instance_id)
	_press("Seat2")
	_press("ActionCancel")
	assert(_ui.selected_hand_card_id == 0 and _ui.selected_target_id == 0)
	assert(_ui.game_state.get_player(1).get_hand_count() == hand_count)
	assert(_ui.game_state.get_player(1).hp == 3)
	_press("Card%d" % heal.instance_id)
	_press("ActionConfirm")
	assert(_ui.game_state.get_player(1).hp == 4)
	assert(_ui.game_state.get_player(1).get_hand_count() == hand_count - 1)
	# Prepare Bot healing through the same engine API; the displayed hand is actionable.
	var bot_heal: CardInstance = _first_card(1, "restore_hp")
	assert(_ui.game_state.transfer_player_card(bot_heal.instance_id, 1, "hand", 2, "hand"))
	var remaining: Array[CardInstance] = _ui.game_state.get_player(1).hand.duplicate()
	for card: CardInstance in remaining:
		assert(_ui.game_state.transfer_player_card(card.instance_id, 1, "hand", 3, "hand"))
	_ui._refresh()
	_press("EndTurn")
	assert(_ui.displayed_player_id == 2)
	assert(_ui.combat.executor.resolver.deal_damage(2, 1))
	_ui._refresh()
	_press("Card%d" % bot_heal.instance_id)
	assert(_ui.game_state.get_player(2).hp == 3)
	_press("ActionConfirm")
	assert(_ui.game_state.get_player(2).hp == 4)
	assert(_ui.game_state.validate_state())


func _test_dying_modal_priority() -> void:
	_press("NewTable")
	_draw_all_for_human()
	_select_human_attack()
	_press("Seat2")
	_press("ActionConfirm")
	assert(_ui._choice_kind == "response")
	assert(_ui.combat.executor.damage_pipeline.process_damage(1, 3, 4))
	_ui._refresh()
	assert(_ui._choice_kind == "dying" and _ui._choice_target_id == 3)
	assert((_ui.find_child("ActionConfirm", true, false) as Button).disabled)
	assert((_ui.find_child("EndTurn", true, false) as Button).disabled)
	assert(not _ui.combat.respond_to_attack(2).valid)
	var rescue_card: CardInstance = _first_card(1, "restore_hp")
	assert(rescue_card != null)
	_press("RescueCard%d" % rescue_card.instance_id)
	_press("ChoiceConfirm")
	assert(_ui.game_state.get_player(3).is_alive())
	assert(_ui._choice_kind == "response")
	# Dying again replaces the response picker, and choosing no rescue eliminates.
	assert(_ui.combat.executor.resolver.deal_damage(2, 10))
	_ui._refresh()
	assert(_ui._choice_kind == "dying" and _ui._choice_target_id == 2)
	_press("ChoiceCancel")
	assert(_ui.game_state.get_player(2).is_eliminated())
	assert(not _ui.combat.has_pending_response() and not _ui.combat.has_pending_dying())
	assert(not (_ui.find_child("CardChoiceOverlay", true, false) as Control).visible)
	assert(_ui.game_state.validate_state())


func _test_weapon_equip() -> void:
	_press("NewTable")
	_draw_all_for_human()
	var crossbow: CardInstance = _first_card(1, "remove_attack_limit")
	var rifle: CardInstance = _first_card(1, "discard_equipment_on_hit")
	assert(crossbow != null and rifle != null)
	var hand_before: int = _ui.game_state.get_player(1).get_hand_count()
	_press("Card%d" % crossbow.instance_id)
	_press("ActionCancel")
	assert(_ui.combat.get_weapon(1) == null)
	assert(_ui.game_state.get_player(1).get_hand_count() == hand_before)
	_press("Card%d" % crossbow.instance_id)
	_press("ActionConfirm")
	assert(_ui.combat.get_weapon(1) == crossbow)
	assert(_ui.game_state.get_player(1).get_hand_count() == hand_before - 1)
	assert((_ui.find_child("Seat1", true, false) as Button).text.contains("Nỏ thần · Tầm 1"))
	_select_human_attack()
	_press("Seat2")
	_press("ActionConfirm")
	_press("ChoiceCancel")
	_select_human_attack()
	_press("Seat2")
	_press("ActionConfirm")
	assert(_ui.combat.has_pending_response())
	_press("ChoiceCancel")
	assert(_ui.combat.executor.attacks_used == 2)
	_press("Card%d" % rifle.instance_id)
	_press("ActionConfirm")
	assert(_ui.combat.get_weapon(1) == rifle)
	assert(_ui.game_state.deck.discard_pile.has(crossbow))
	assert((_ui.find_child("Seat1", true, false) as Button).text.contains("Súng trường · Tầm 5"))
	assert((_ui.find_child("EventLog", true, false) as RichTextLabel).text.contains("chưa được triển khai"))
	assert((_ui.find_child("EventLog", true, false) as RichTextLabel).text.contains("Vào chồng bài bỏ: Nỏ thần"))
	assert((_ui.find_child("EventLog", true, false) as RichTextLabel).text.contains("Vào chồng bài bỏ: Tấn công"))
	_select_human_attack()
	_press("Seat2")
	_press("ActionConfirm")
	assert(not _ui.combat.has_pending_response())
	assert(_ui.game_state.validate_state())


func _test_target_filtering() -> void:
	_press("NewTable")
	_draw_all_for_human()
	var victim: CardInstance = _first_card(1, "block_attack")
	assert(_ui.game_state.transfer_player_card(victim.instance_id, 1, "hand", 2, "hand"))
	var other_victim: CardInstance = _first_card(1, "block_attack")
	assert(_ui.game_state.transfer_player_card(other_victim.instance_id, 1, "hand", 3, "hand"))
	_ui._refresh()
	_select_human_attack()
	assert((_ui.find_child("Seat1", true, false) as Button).disabled)
	assert((_ui.find_child("Seat3", true, false) as Button).disabled)
	assert(not (_ui.find_child("Seat2", true, false) as Button).disabled)
	assert(not (_ui.find_child("Seat4", true, false) as Button).disabled)
	assert((_ui.find_child("ActionConfirm", true, false) as Button).disabled)
	_press("Seat3")
	assert(_ui.selected_target_id == 0)
	_press("Seat2")
	assert(_ui.selected_target_id == 2)
	var steal: CardInstance = _first_card(1, "steal_card")
	_press("Card%d" % steal.instance_id)
	assert(_ui.selected_target_id == 2)
	assert((_ui.find_child("Seat4", true, false) as Button).disabled)
	assert((_ui.find_child("Seat3", true, false) as Button).disabled)
	var discard: CardInstance = _first_card(1, "discard")
	_press("Card%d" % discard.instance_id)
	assert(not (_ui.find_child("Seat3", true, false) as Button).disabled)
	_press("Seat3")
	assert(_ui.selected_target_id == 3)
	_press("Card%d" % steal.instance_id)
	assert(_ui.selected_target_id == 0)
	assert((_ui.find_child("ActionConfirm", true, false) as Button).disabled)
	_press("ActionCancel")
	assert(not (_ui.find_child("Seat4", true, false) as Button).disabled)
	var rifle: CardInstance = _first_card(1, "discard_equipment_on_hit")
	_press("Card%d" % rifle.instance_id)
	_press("ActionConfirm")
	_select_human_attack()
	assert(not (_ui.find_child("Seat3", true, false) as Button).disabled)
	_press("Seat3")
	var crossbow: CardInstance = _first_card(1, "remove_attack_limit")
	_press("Card%d" % crossbow.instance_id)
	_press("ActionConfirm")
	_select_human_attack()
	assert((_ui.find_child("Seat3", true, false) as Button).disabled and _ui.selected_target_id == 0)
	assert(_ui.game_state.validate_state())


func _test_selection_presentation() -> void:
	_press("NewTable")
	_draw_all_for_human()
	var victim: CardInstance = _first_card(1, "block_attack")
	assert(_ui.game_state.transfer_player_card(victim.instance_id, 1, "hand", 2, "hand"))
	_ui._refresh()
	var attack: CardInstance = _first_card(1, "deal_attack")
	var other: CardInstance = _first_card(1, "discard")
	var events_before: Array[String] = _ui._events.duplicate()
	var hand_before: int = _ui.game_state.get_player(1).get_hand_count()
	_press("Card%d" % attack.instance_id)
	_press("Seat2")
	var raised: Button = _ui.find_child("Card%d" % attack.instance_id, true, false) as Button
	var dimmed: Button = _ui.find_child("Card%d" % other.instance_id, true, false) as Button
	assert(raised.position.y == 0.0 and raised.modulate == Color.WHITE)
	assert(dimmed.position.y == 12.0 and dimmed.modulate.r < 1.0 and not dimmed.disabled)
	_press("Card%d" % other.instance_id)
	raised = _ui.find_child("Card%d" % other.instance_id, true, false) as Button
	dimmed = _ui.find_child("Card%d" % attack.instance_id, true, false) as Button
	assert(raised.position.y == 0.0 and dimmed.position.y == 12.0)
	assert(_ui._events == events_before)
	_press("ActionCancel")
	var reset: Button = _ui.find_child("Card%d" % attack.instance_id, true, false) as Button
	assert(reset.position.y == 12.0 and reset.modulate == Color.WHITE)
	assert(_ui._events == events_before)
	assert(_ui.game_state.get_player(1).get_hand_count() == hand_before)
	_press("Card%d" % attack.instance_id)
	_press("Seat2")
	_press("ActionConfirm")
	assert(_ui._events.size() > events_before.size() and _ui.combat.has_pending_response())
	_press("ChoiceCancel")


func _give_rescue_card(player_id: int) -> CardInstance:
	for zone: String in ["draw", "discard"]:
		var cards: Array[CardInstance] = _ui.game_state.deck.draw_pile if zone == "draw" else _ui.game_state.deck.discard_pile
		for card: CardInstance in cards:
			if card.definition.has_effect("restore_hp"):
				assert(_ui.game_state.zone_manager.transfer_card(card.instance_id, zone, 0, "hand", player_id))
				return card
	var existing: CardInstance = _first_card(player_id, "restore_hp")
	assert(existing != null)
	return existing


func _choose_rescuer(player_id: int) -> void:
	var options: OptionButton = _ui.find_child("DyingRescuer", true, false) as OptionButton
	for index: int in range(options.item_count):
		if options.get_item_id(index) == player_id:
			options.select(index)
			options.item_selected.emit(index)
			return
	assert(false, "Missing rescue participant")


func _test_negative_hp_rescue_cards() -> void:
	_press("NewTable")
	_draw_all_for_human()
	var self_heal: CardInstance = _first_card(1, "restore_hp")
	assert(_ui.game_state.transfer_player_card(self_heal.instance_id, 1, "hand", 2, "hand"))
	assert(_ui.combat.executor.resolver.deal_damage(2, 5))
	_ui._refresh()
	assert(_ui.game_state.get_player(2).hp == -1)
	_choose_rescuer(4)
	assert((_ui.find_child("ChoiceConfirm", true, false) as Button).disabled)
	_choose_rescuer(2)
	_press("RescueCard%d" % self_heal.instance_id)
	assert(_ui.game_state.get_player(2).hp == -1)
	_press("ChoiceConfirm")
	assert(_ui.game_state.get_player(2).hp == 0 and _ui.game_state.get_player(2).is_dying())
	assert(_ui._choice_kind == "dying")
	assert((_ui.find_child("EndTurn", true, false) as Button).disabled)
	_choose_rescuer(1)
	var other_heal: CardInstance = _first_card(1, "restore_hp")
	var hand_before: int = _ui.game_state.get_player(1).get_hand_count()
	_press("RescueCard%d" % other_heal.instance_id)
	_press("ChoiceConfirm")
	assert(_ui.game_state.get_player(2).hp == 1 and _ui.game_state.get_player(2).is_alive())
	assert(_ui.game_state.get_player(1).get_hand_count() == hand_before - 1)
	assert(not _ui.combat.has_pending_dying())
	assert(_ui.game_state.validate_state())


func _test_hidden_tools() -> void:
	for effect_id: String in ["discard", "steal_card"]:
		_press("NewTable")
		_draw_all_for_human()
		var tool: CardInstance = _first_card(1, effect_id)
		var victim: CardInstance = _first_card(1, "deal_attack")
		assert(tool != null and victim != null)
		assert(_ui.game_state.transfer_player_card(victim.instance_id, 1, "hand", 2, "hand"))
		var equipment: CardInstance = _first_card(1, "remove_attack_limit")
		assert(equipment != null)
		assert(_ui.game_state.transfer_player_card(equipment.instance_id, 1, "hand", 2, "equipment"))
		var judgment: CardInstance = _first_card(1, "block_attack")
		assert(judgment != null)
		assert(_ui.game_state.transfer_player_card(judgment.instance_id, 1, "hand", 2, "judgment"))
		_ui._refresh()
		_press("Card%d" % tool.instance_id)
		_press("Seat2")
		var hand_before: int = _ui.game_state.get_player(1).get_hand_count()
		var events_before: Array[String] = _ui._events.duplicate()
		_press("ActionConfirm")
		assert((_ui.find_child("ChoiceConfirm", true, false) as Button).disabled)
		var back: Button = _ui.find_child("HiddenCard0", true, false) as Button
		assert(back != null and back.text.contains("BÀI ÚP"))
		assert(not back.text.contains(victim.definition.display_name))
		assert(back.tooltip_text.is_empty())
		var face_up: Button = _ui.find_child("EquipmentCard%d" % equipment.instance_id, true, false) as Button
		assert(face_up != null and (face_up.find_child("CardTitle", true, false) as Label).text == equipment.definition.display_name.to_upper())
		for zone: String in ["hand", "equipment", "judgment"]:
			assert(_ui.find_child("ToolZone_" + zone, true, false) != null)
		assert((_ui.find_child("ToolZone_hand", true, false) as Node).is_ancestor_of(back))
		assert((_ui.find_child("ToolZone_equipment", true, false) as Node).is_ancestor_of(face_up))
		assert(not face_up.text.contains("BÀI ÚP"))
		assert(face_up.tooltip_text == equipment.definition.description)
		_press("ChoiceCancel")
		assert(_ui._events == events_before)
		assert(_ui.game_state.get_player(1).get_hand_count() == hand_before)
		_press("ActionConfirm")
		await process_frame
		await _click("HiddenCard0")
		assert((_ui.find_child("HiddenCard0", true, false) as Button).position.y == 0.0)
		assert((_ui.find_child("EquipmentCard%d" % equipment.instance_id, true, false) as Button).modulate.r < 1.0)
		assert(_ui._events == events_before)
		assert(_ui.game_state.get_player(2).get_hand_count() == 1)
		await _click("ChoiceConfirm")
		assert(_ui.game_state.get_player(2).hand.is_empty())
		assert(_ui.game_state.get_player(1).get_hand_count() == hand_before - (0 if effect_id == "steal_card" else 1))
		var next_tool: CardInstance = _first_card(1, effect_id)
		assert(next_tool != null)
		_press("Card%d" % next_tool.instance_id)
		_press("ActionConfirm")
		var judgment_back: Button = null
		for node: Node in _ui.find_child("ToolZone_judgment", true, false).find_children("*", "Button", true, false):
			judgment_back = node as Button
		assert(judgment_back != null and judgment_back.text.contains("BÀI ÚP"))
		judgment_back.pressed.emit()
		assert(_ui._choice_zone == "judgment" and _ui._choice_selected_card_id == judgment.instance_id)
		_press("EquipmentCard%d" % equipment.instance_id)
		assert(_ui._choice_zone == "equipment" and not judgment_back.button_pressed)
		assert(_ui.combat.get_weapon(2) == equipment)
		_press("ChoiceConfirm")
		assert(_ui.combat.get_weapon(2) == null)
		assert(not _ui.combat.executor.validator.rule_engine.get_rule("attack_limit_per_turn", {}, RuleContext.new(2))["unlimited"])
		assert(_ui.game_state.validate_state())


func _test_winner_ui() -> void:
	_press("NewTable")
	for player_id: int in [2, 3, 4]:
		assert(_ui.combat.executor.resolver.deal_damage(player_id, 4))
		_ui._refresh()
		assert(not _ui.game_state.match_over)
		_press("ChoiceCancel")
	assert(_ui.game_state.match_over and _ui.game_state.winner_id == 1)
	assert((_ui.find_child("PhaseLabel", true, false) as Label).text.contains("P1 thắng cuộc"))
	assert((_ui.find_child("EventLog", true, false) as RichTextLabel).text.contains("P1 thắng cuộc"))
	assert((_ui.find_child("EndTurn", true, false) as Button).disabled)
	assert(_ui.find_child("HumanDraw", true, false) == null)
	assert(not (_ui.find_child("CardChoiceOverlay", true, false) as Control).visible)
	var before_hand: int = _ui.game_state.get_player(1).get_hand_count()
	assert(_ui.game_state.draw_card(1) == null)
	assert(_ui.game_state.get_player(1).get_hand_count() == before_hand)
	_press("NewTable")
	assert(not _ui.game_state.match_over and _ui.game_state.winner_id == 0)
	assert(not (_ui.find_child("EndTurn", true, false) as Button).disabled)


func _test_disabled_cards_and_seats() -> void:
	_press("NewTable")
	_draw_all_for_human()
	var dodge: CardInstance = _first_card(1, "block_attack")
	var heal: CardInstance = _first_card(1, "restore_hp")
	assert(dodge != null and heal != null)
	var dodge_button: Button = _ui.find_child("Card%d" % dodge.instance_id, true, false) as Button
	assert(dodge_button.disabled)
	assert((_ui.find_child("Card%d" % heal.instance_id, true, false) as Button).disabled)
	var before_hand: int = _ui.game_state.get_player(1).get_hand_count()
	await _click("Card%d" % dodge.instance_id)
	assert(_ui.selected_hand_card_id == 0)
	assert(_ui.game_state.get_player(1).get_hand_count() == before_hand)
	assert(_ui.combat.executor.resolver.deal_damage(1, 1))
	_ui._refresh()
	assert(not (_ui.find_child("Card%d" % heal.instance_id, true, false) as Button).disabled)
	assert((_ui.find_child("Seat1", true, false) as Button).text.contains("♥♥♥♡"))
	_press("EndTurn")
	assert(_ui.combat.turn_manager.current_phase == TurnManager.Phase.DISCARD)
	assert(not (_ui.find_child("Card%d" % dodge.instance_id, true, false) as Button).disabled)
	await _click("Card%d" % dodge.instance_id)
	assert(_ui.selected_hand_card_id == dodge.instance_id)
	_press("ActionCancel")
	assert(_ui.game_state.get_player(1).get_hand_count() == before_hand)
	_press("Seat2")
	assert(_ui.combat.executor.resolver.deal_damage(2, 5))
	_ui._refresh()
	assert(_ui._health_text(_ui.game_state.get_player(2)) == "♡♡♡♡ · -1")
	assert(_ui._choice_kind == "dying")
	_press("ChoiceCancel")
	var eliminated_seat: Button = _ui.find_child("Seat2", true, false) as Button
	assert(eliminated_seat.disabled and eliminated_seat.text.contains("Đã loại"))
	assert(_ui.selected_target_id == 0)
	await _click("Seat2")
	assert(_ui.selected_target_id == 0)
	_ui._select_target(2)
	assert(_ui.selected_target_id == 0)
	assert(_ui.game_state.validate_state())
