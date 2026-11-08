extends SceneTree

var _ui: PlayablePrototype


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/dev/playable_prototype.tscn")
	_ui = scene.instantiate() as PlayablePrototype
	root.add_child(_ui)
	await process_frame
	_ui._new_table(4)
	_ui.combat = AoeSystemTest.setup()
	_ui.game_state = _ui.combat.game_state
	_ui._connect_game_events()
	_ui.displayed_player_id = 0
	_ui.selected_hand_card_id = 0
	_ui.selected_target_id = 0
	_ui._hide_choice()
	var scope: CardInstance = AoeSystemTest.give(_ui.combat, 1, "scope")
	var mustang: CardInstance = AoeSystemTest.give(_ui.combat, 1, "mustang")
	_ui._refresh()
	await _click("Card%d" % scope.instance_id)
	await _click("ActionConfirm")
	assert(_ui.combat.get_accessory(1, "offensive_accessory") == scope)
	await _click("Card%d" % mustang.instance_id)
	await _click("ActionConfirm")
	assert(_ui.combat.get_accessory(1, "defensive_accessory") == mustang)
	var own_seat: Button = _ui.find_child("Seat1", true, false) as Button
	assert((own_seat as PlayerFrame).get_slot_text("offensive_accessory").contains(scope.definition.display_name))
	assert((own_seat as PlayerFrame).get_slot_text("defensive_accessory").contains(mustang.definition.display_name))
	var replacement: CardInstance = AoeSystemTest.give(_ui.combat, 1, "scope")
	_ui._refresh()
	await _click("Card%d" % replacement.instance_id)
	await _click("ActionConfirm")
	assert(_ui.game_state.deck.discard_pile.count(scope) == 1)
	var enemy_scope: CardInstance = AccessorySystemTest.equip(_ui.combat, 2, "scope")
	AccessorySystemTest.equip(_ui.combat, 2, "mustang")
	ArmorSystemTest.equip(_ui.combat, 2, "helmet")
	var weapon: CardInstance = AoeSystemTest.give(_ui.combat, 2, "rifle")
	assert(_ui.game_state.zone_manager.transfer_card(weapon.instance_id, "hand", 2, "equipment", 2))
	var attack: CardInstance = AoeSystemTest.give(_ui.combat, 1, "attack")
	AccessorySystemTest.equip(_ui.combat, 3, "mustang")
	_ui._refresh()
	await _click("Card%d" % attack.instance_id)
	var target: Button = _ui.find_child("Seat3", true, false) as Button
	assert((target as PlayerFrame).get_display_text().contains("Cách 2") and target.disabled)
	var opponent: Button = _ui.find_child("Seat2", true, false) as Button
	assert((opponent as PlayerFrame).get_display_text().contains(enemy_scope.definition.display_name))
	assert(not opponent.disabled and (opponent as PlayerFrame).get_display_text().contains("Cách 1"))
	await process_frame
	assert((_ui.find_child("BotTable", true, false) as Control).get_global_rect().encloses(opponent.get_global_rect()))
	await _click("Seat2")
	await _click("ActionConfirm")
	assert(_ui.combat.has_pending_response())
	assert(_ui.game_state.validate_state())
	_ui.queue_free()
	await process_frame
	print("=== ACCESSORY UI SMOKE PASSED ===")
	quit()


func _click(node_name: String) -> void:
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
		root.push_input(event)
		await process_frame
