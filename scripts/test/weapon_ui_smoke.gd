extends SceneTree

var _ui: PlayablePrototype


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/dev/playable_prototype.tscn")
	_ui = scene.instantiate() as PlayablePrototype
	root.add_child(_ui)
	await process_frame
	(_ui.find_child("CreateMatch", true, false) as Button).pressed.emit()
	_fixture("pistol")
	var card: CardInstance = AoeSystemTest.give(_ui.combat, 1, "attack")
	_ui._refresh()
	var events_before: Array[String] = _ui._events.duplicate()
	await _click("Card%d" % card.instance_id)
	await _click("Seat4")
	await _click("Seat2")
	assert(_ui.selected_target_id == 2 and _ui._attack_targets.is_empty())
	assert(not _ui.is_choice_visible() and _ui._events == events_before)
	await _click("Seat4")
	await _click("ActionConfirm")
	assert(_ui._choice_kind == "attack_targets" and not _ui._picking_extra_target)
	assert(_ui.game_state.get_player(1).hand.has(card) and _ui.combat.executor.attacks_used == 0)
	assert(_ui._events == events_before and _ui.find_child("ExtraTarget2", true, false) == null)
	await _click("ChoiceConfirm")
	assert(_ui._picking_extra_target and _ui._choice_confirm.disabled)
	assert(_ui.find_child("ExtraTarget4", true, false) == null)
	await _click("ExtraTarget2")
	assert(_ui._events == events_before and not _ui.combat.has_pending_response())
	await _click("ChoiceConfirm")
	assert(_ui._choice_kind == "response" and _ui._choice_target_id == 2)
	assert(_ui._inline_choice_host.visible and not _ui._choice_overlay.visible)
	await _click("ChoiceCancel")
	assert(_ui._choice_kind == "response" and _ui._choice_target_id == 4)
	await _click("ChoiceCancel")
	assert(not _ui.is_choice_visible() and _ui.combat.executor.attacks_used == 1)
	assert(_ui.game_state.deck.discard_pile.count(card) == 1)
	await _test_target_drafts()
	_fixture("butchers_knife")
	var first: CardInstance = AoeSystemTest.give(_ui.combat, 2, "heal")
	var second: CardInstance = AoeSystemTest.give(_ui.combat, 2, "dodge")
	WeaponSystemTest.attack(_ui.combat)
	_ui._refresh()
	assert(_ui._choice_kind == "weapon" and _ui._choice_confirm.disabled)
	assert(_ui._choice_overlay.visible and not _ui._inline_choice_host.visible)
	var hidden: Button = _ui.find_child("WeaponCard%d" % first.instance_id, true, false) as Button
	assert(hidden.text.contains("BÀI ÚP") and hidden.tooltip_text.is_empty())
	events_before = _ui._events.duplicate()
	await _click(hidden.name)
	assert(_ui._choice_confirm.disabled and _ui._events == events_before)
	await _click("WeaponCard%d" % second.instance_id)
	await _click("ChoiceConfirm")
	assert(_ui.game_state.get_player(2).hp == 4 and _ui.game_state.get_player(2).hand.is_empty())
	assert(not _ui.is_choice_visible())
	_fixture("slingshot")
	var cost: CardInstance = AoeSystemTest.give(_ui.combat, 1, "dodge")
	WeaponSystemTest.attack(_ui.combat)
	_ui._refresh()
	assert(_ui._choice_kind == "weapon")
	await process_frame
	await process_frame
	assert(_ui._inline_choice_host.visible and not _ui._choice_overlay.visible)
	assert(_ui._inline_choice_host.get_global_rect().end.y <= root.size.y)
	assert(_ui._weapon_target_prompt and _ui.find_child("WeaponTarget3", true, false) == null)
	assert(_ui.game_state.get_player(1).hand.has(cost))
	await _click("ChoiceConfirm")
	assert(not _ui._weapon_target_prompt)
	assert(_ui.find_child("WeaponTarget1", true, false) == null and _ui.find_child("WeaponTarget2", true, false) == null)
	assert(_ui.find_child("WeaponTarget3", true, false) != null)
	await _double_click("WeaponCard%d" % cost.instance_id)
	assert(_ui._choice_confirm.disabled and _ui._weapon_cards == [cost.instance_id])
	assert(_ui.game_state.get_player(1).hand.has(cost))
	await _double_click("WeaponCard%d" % cost.instance_id)
	assert(_ui._weapon_cards.is_empty())
	await _click("WeaponCard%d" % cost.instance_id)
	await _click("WeaponTarget3")
	await _click("ChoiceConfirm")
	assert(_ui.game_state.get_player(3).hp == 3 and not _ui.combat.has_pending_response())
	assert(_ui.game_state.deck.discard_pile.count(cost) == 1 and not _ui.is_choice_visible())
	_fixture("slingshot")
	cost = AoeSystemTest.give(_ui.combat, 1, "dodge")
	WeaponSystemTest.attack(_ui.combat)
	_ui._refresh()
	assert(_ui._weapon_target_prompt)
	await _click("ChoiceCancel")
	assert(_ui.game_state.get_player(1).hand.has(cost) and not _ui.is_choice_visible())
	assert(_ui.game_state.get_player(3).hp == 4)
	_fixture("rifle")
	var equipment: CardInstance = AoeSystemTest.give(_ui.combat, 2, "crossbow")
	assert(_ui.game_state.zone_manager.transfer_card(equipment.instance_id, "hand", 2, "equipment", 2))
	assert(_ui.combat.executor.resolver.deal_damage(2, 3))
	WeaponSystemTest.attack(_ui.combat)
	_ui._refresh()
	assert(_ui._choice_kind == "dying" and _ui.combat.get_pending_weapon().is_empty())
	var heal: CardInstance = AoeSystemTest.give(_ui.combat, 1, "heal")
	assert(_ui.combat.rescue_player(1, 2, heal.instance_id).valid)
	_ui._refresh()
	assert(_ui._choice_kind == "weapon")
	var face: Button = _ui.find_child("WeaponCard%d" % equipment.instance_id, true, false) as Button
	assert(face != null and not face.text.contains("BÀI ÚP"))
	await _click(face.name)
	await _click("ChoiceConfirm")
	assert(_ui.combat.get_weapon(2) == null and _ui.game_state.get_player(2).hp == 1)
	assert(_ui.game_state.validate_state() and not _ui.is_choice_visible())
	_ui.queue_free()
	await process_frame
	print("=== WEAPON UI SMOKE PASSED ===")
	quit()


func _test_target_drafts() -> void:
	_fixture("pistol")
	var card: CardInstance = AoeSystemTest.give(_ui.combat, 1, "attack")
	_ui._refresh()
	var before: Array[String] = _ui._events.duplicate()
	await _click("Card%d" % card.instance_id)
	await _click("Seat4")
	await _click("ActionConfirm")
	await _click("CancelTargetDraft")
	assert(not _ui.is_choice_visible() and _ui._events == before)
	assert(_ui.game_state.get_player(1).hand.has(card) and _ui.combat.executor.attacks_used == 0)
	await _click("Card%d" % card.instance_id)
	await _click("Seat4")
	await _click("ActionConfirm")
	await _click("ChoiceCancel")
	assert(_ui._choice_kind == "response" and _ui._choice_target_id == 4)
	await _click("ChoiceCancel")
	assert(not _ui.is_choice_visible() and _ui.game_state.deck.discard_pile.count(card) == 1)
	# A stale target draft must fail engine validation without paying or counting.
	_fixture("pistol")
	card = AoeSystemTest.give(_ui.combat, 1, "attack")
	_ui._refresh()
	await _click("Card%d" % card.instance_id)
	await _click("Seat4")
	await _click("ActionConfirm")
	await _click("ChoiceConfirm")
	await _click("ExtraTarget2")
	var pistol: CardInstance = _ui.combat.get_weapon(1)
	assert(_ui.game_state.discard_card(1, pistol.instance_id, "equipment"))
	before = _ui._events.duplicate()
	await _click("ChoiceConfirm")
	assert(_ui.game_state.get_player(1).hand.has(card) and _ui.combat.executor.attacks_used == 0)
	assert(not _ui.combat.has_pending_response() and _ui._events == before)
	assert(_ui.game_state.validate_state())
	# When no additional legal seat exists, do not ask an empty question.
	_fixture("pistol")
	for player_id: int in [3, 4]:
		assert(_ui.combat.executor.resolver.deal_damage(player_id, 4))
		assert(_ui.combat.finalize_dying().valid)
	card = AoeSystemTest.give(_ui.combat, 1, "attack")
	_ui._refresh()
	await _click("Card%d" % card.instance_id)
	await _click("Seat2")
	await _click("ActionConfirm")
	assert(_ui._choice_kind == "response" and _ui._choice_target_id == 2)
	assert(_ui.game_state.deck.discard_pile.count(card) == 1)


func _fixture(weapon_id: String) -> void:
	_ui.combat = WeaponSystemTest.setup(weapon_id)
	_ui.game_state = _ui.combat.game_state
	_ui.game_state.zone_manager.cards_discarded.connect(_ui._on_cards_discarded)
	_ui.game_state.match_finished.connect(_ui._on_match_finished)
	_ui.displayed_player_id = 0
	_ui.selected_hand_card_id = 0
	_ui.selected_target_id = 0
	_ui._choice_kind = ""
	_ui._hide_choice()
	_ui._events.clear()
	_ui._refresh()


func _double_click(node_name: String) -> void:
	await _click(node_name)
	await _click(node_name, true)


func _click(node_name: String, double_click: bool = false) -> void:
	await process_frame
	var button: Button = _ui.find_child(node_name, true, false) as Button
	assert(button != null and not button.disabled and button.is_visible_in_tree(), node_name)
	var ancestor: Node = button.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			(ancestor as ScrollContainer).ensure_control_visible(button)
			await process_frame
			break
		ancestor = ancestor.get_parent()
	var point: Vector2 = button.get_global_rect().get_center()
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.double_click = double_click and down
		root.push_input(event)
		await process_frame
