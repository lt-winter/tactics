extends SceneTree

var _ui: PlayablePrototype


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/dev/playable_prototype.tscn")
	_ui = scene.instantiate() as PlayablePrototype
	root.add_child(_ui)
	await process_frame
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	for count: int in range(2, 7):
		_ui._new_table(count)
		_ui.combat = SupportToolsTest._small("exchange", 16, count)
		_ui.game_state = _ui.combat.game_state
		_ui.game_state.zone_manager.cards_discarded.connect(_ui._on_cards_discarded)
		_ui.game_state.match_finished.connect(_ui._on_match_finished)
		for card: CardInstance in _ui.game_state.deck.draw_pile:
			if card.instance_id == 2:
				card.definition = database.get_definition("crossbow")
		assert(_ui.game_state.zone_manager.transfer_card(2, "draw", 0, "hand", 1))
		assert(_ui.game_state.zone_manager.transfer_card(3, "draw", 0, "hand", 1))
		assert(_ui.combat.equip_weapon(1, 2).valid)
		_ui._refresh()
		assert((_ui.find_child("DeckInfoLabel", true, false) as Label).text.contains("Xào lại: 0 lần"))
		assert(_ui.combat.use_support_tool(1, 1).valid)
		_ui._refresh()
		for frame: int in range(3):
			await process_frame
		assert(_ui._inline_choice_host.is_visible_in_tree() and not _ui._choice_overlay.visible)
		assert(not _ui._hand_column.visible)
		assert(_ui._inline_choice_host.get_global_rect().end.y <= 720.0)
		assert(_ui._choice_confirm.get_global_rect().end.y <= _ui._choice_scroll.get_global_rect().position.y)
		var notice: Control = _ui.find_child("TableNotice", true, false) as Control
		assert(notice.get_global_rect().end.y <= _ui._inline_choice_host.get_global_rect().position.y)
		assert(not _ui.combat.end_turn(1).valid)
		await _click("SupportDiscardCard2")
		await _click("SupportDiscardCard3")
		await _click("ChoiceConfirm")
		assert(not _ui.is_choice_visible() and _ui._hand_column.visible)
		assert(_ui.combat.get_weapon(1) == null and _ui.game_state.validate_state())
		while _ui.game_state.deck.get_draw_count() > 0:
			assert(_ui.game_state.draw_card(1) != null)
		assert(_ui.game_state.draw_card(1) != null)
		_ui._refresh()
		assert(_ui.game_state.deck.reshuffle_count == 1)
		assert((_ui.find_child("DeckInfoLabel", true, false) as Label).text.contains("Xào lại: 1 lần"))
		assert(_ui.game_state.validate_state())
	_ui.queue_free()
	await process_frame
	print("=== INLINE CHOICES AND RESHUFFLE UI SMOKE PASSED ===")
	quit()


func _click(node_name: String) -> void:
	await process_frame
	var button: Button = _ui.find_child(node_name, true, false) as Button
	assert(button != null and button.is_visible_in_tree() and not button.disabled, node_name)
	if _ui._choice_scroll.is_ancestor_of(button):
		_ui._choice_scroll.ensure_control_visible(button)
	await process_frame
	var point: Vector2 = button.get_global_rect().get_center()
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
		await process_frame
