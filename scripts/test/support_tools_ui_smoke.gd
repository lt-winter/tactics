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
	_fixture()
	var draw: CardInstance = AoeSystemTest.give(_ui.combat, 1, "draw_2")
	var exchange: CardInstance = AoeSystemTest.give(_ui.combat, 1, "exchange")
	var saloon: CardInstance = AoeSystemTest.give(_ui.combat, 1, "saloon")
	var heal: CardInstance = AoeSystemTest.give(_ui.combat, 1, "heal")
	_ui._refresh()
	assert(not (_ui.find_child("Card%d" % saloon.instance_id, true, false) as Button).disabled)
	var events_before: Array[String] = _ui._events.duplicate()
	await _click("Card%d" % draw.instance_id)
	assert(_ui.selected_target_id == 0 and not (_ui.find_child("ActionConfirm", true, false) as Button).disabled)
	assert(_ui._events == events_before)
	await _click("ActionCancel")
	assert(_ui._events == events_before and _ui.game_state.get_player(1).get_hand_count() == 4)
	await _double_click("Card%d" % draw.instance_id)
	assert(_ui.game_state.get_player(1).get_hand_count() == 5)
	assert(_ui.game_state.deck.discard_pile.count(draw) == 1 and not _ui.is_choice_visible())
	assert(_ui.combat.executor.resolver.deal_damage(1, 2))
	assert(_ui.combat.executor.resolver.deal_damage(2, 1))
	_ui._refresh()
	await _click("Card%d" % saloon.instance_id)
	await _click("ActionConfirm")
	assert(_ui.game_state.get_player(1).hp == 3 and _ui.game_state.get_player(2).hp == 4)
	assert(not _ui.is_choice_visible() and _ui.game_state.deck.discard_pile.count(saloon) == 1)
	var hand_before: int = _ui.game_state.get_player(1).get_hand_count()
	await _double_click("Card%d" % exchange.instance_id)
	assert(_ui._choice_kind == "support" and _ui._choice_confirm.disabled)
	await process_frame
	await process_frame
	assert(_ui._inline_choice_host.is_visible_in_tree() and not _ui._choice_overlay.visible)
	assert(not _ui._hand_column.visible)
	assert(_ui._choice_confirm.get_global_rect().end.y <= _ui._choice_scroll.get_global_rect().position.y)
	assert(_ui._inline_choice_host.get_global_rect().end.y <= root.size.y)
	assert(_ui.game_state.get_player(1).get_hand_count() == hand_before + 2)
	assert((_ui.find_child("EndTurn", true, false) as Button).disabled)
	assert(_ui._choice_title.text.contains(exchange.definition.display_name))
	assert(_ui.find_child("SupportDiscardCard%d" % exchange.instance_id, true, false) == null)
	var first: CardInstance = _ui.game_state.get_player(1).hand[0]
	var second: CardInstance = _ui.game_state.get_player(1).hand[1]
	events_before = _ui._events.duplicate()
	await _double_click("SupportDiscardCard%d" % first.instance_id)
	assert(_ui.combat.has_pending_support() and _ui._support_selected_ids == [first.instance_id])
	assert(not (_ui.find_child("SupportDiscardCard%d" % first.instance_id, true, false) as Button).disabled)
	assert(_ui._choice_confirm.disabled and _ui._events == events_before)
	await _click("ChoiceCancel")
	assert(_ui._support_selected_ids.is_empty() and _ui.combat.has_pending_support())
	assert(_ui.game_state.get_player(1).get_hand_count() == hand_before + 2 and _ui._events == events_before)
	# Dying supersedes the committed Exchange without cancelling or repeating draws.
	assert(_ui.combat.executor.resolver.deal_damage(2, 4))
	_ui._refresh()
	assert(_ui._choice_kind == "dying" and _ui.combat.has_pending_support())
	assert(_ui._inline_choice_host.visible and not _ui._choice_overlay.visible)
	var rescuers: OptionButton = _ui.find_child("DyingRescuer", true, false) as OptionButton
	for index: int in range(rescuers.item_count):
		if rescuers.get_item_id(index) == 1:
			rescuers.select(index)
			rescuers.item_selected.emit(index)
			break
	await _double_click("RescueCard%d" % heal.instance_id)
	assert(_ui._choice_kind == "support" and not _ui.combat.has_pending_dying())
	assert(_ui.game_state.get_player(1).get_hand_count() == hand_before + 1)
	# The old selected card may have been the rescue card; query fresh choices.
	first = _ui.game_state.get_player(1).hand[0]
	second = _ui.game_state.get_player(1).hand[1]
	events_before = _ui._events.duplicate()
	await _click("SupportDiscardCard%d" % first.instance_id)
	assert(_ui._choice_confirm.disabled and _ui._events == events_before)
	await _double_click("SupportDiscardCard%d" % second.instance_id)
	assert(not _ui.combat.has_pending_support() and not _ui.is_choice_visible())
	assert(_ui.game_state.get_player(1).get_hand_count() == hand_before - 1)
	assert(_ui.game_state.deck.discard_pile.count(first) == 1 and _ui.game_state.deck.discard_pile.count(second) == 1)
	assert(_ui.game_state.deck.discard_pile.count(exchange) == 1)
	assert(_ui.combat.turn_manager.current_phase == TurnManager.Phase.PLAY and _ui.combat.executor.attacks_used == 0)
	assert(_ui.game_state.validate_state())
	# Equipment is a distinct face-up section and is discarded through the same API.
	_fixture()
	var weapon: CardInstance = AoeSystemTest.give(_ui.combat, 1, "crossbow")
	assert(_ui.combat.equip_weapon(1, weapon.instance_id).valid)
	exchange = AoeSystemTest.give(_ui.combat, 1, "exchange")
	_ui._refresh()
	await _double_click("Card%d" % exchange.instance_id)
	assert(_ui.find_child("SupportZone_hand", true, false) != null)
	var equipment_section: Node = _ui.find_child("SupportZone_equipment", true, false)
	assert(equipment_section != null)
	var equipped_button: Button = equipment_section.find_child("SupportDiscardCard%d" % weapon.instance_id, true, false) as Button
	assert(equipped_button != null and not equipped_button.disabled)
	assert(str(equipped_button.get_meta("choice_zone")) == "equipment")
	first = _ui.game_state.get_player(1).hand[0]
	await _click(equipped_button.name)
	await _click("SupportDiscardCard%d" % first.instance_id)
	await _click("ChoiceConfirm")
	assert(not _ui.combat.has_pending_support() and _ui.combat.get_weapon(1) == null)
	assert(_ui.game_state.deck.discard_pile.count(weapon) == 1)
	assert(_ui._events.back().contains(weapon.definition.display_name))
	assert(_ui.game_state.validate_state())
	_ui.queue_free()
	await process_frame
	print("=== SUPPORT TOOLS UI SMOKE PASSED ===")
	quit()


func _fixture() -> void:
	# Separate fixture deck includes Support Tool definitions; standard.json is untouched.
	_ui.combat = AoeSystemTest.setup()
	_ui.game_state = _ui.combat.game_state
	_ui.game_state.zone_manager.cards_discarded.connect(_ui._on_cards_discarded)
	_ui.game_state.match_finished.connect(_ui._on_match_finished)
	_ui.selected_hand_card_id = 0
	_ui.selected_target_id = 0
	_ui.displayed_player_id = 0
	_ui._choice_kind = ""
	_ui._hide_choice()
	_ui._events.clear()
	_ui._refresh()


func _double_click(node_name: String) -> void:
	await _click(node_name)
	await _click(node_name, true)


func _click(node_name: String, double_click: bool = false) -> void:
	var button: Button = _ui.find_child(node_name, true, false) as Button
	assert(button != null and not button.disabled, node_name)
	await process_frame
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
