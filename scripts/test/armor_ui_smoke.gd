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
	_fixture()
	var armor: CardInstance = AoeSystemTest.give(_ui.combat, 1, "black_shield")
	_ui._refresh()
	assert(not (_ui.find_child("Card%d" % armor.instance_id, true, false) as Button).disabled)
	await _click("Card%d" % armor.instance_id)
	await _click("ActionConfirm")
	assert(_ui.combat.get_defense(1) == armor and _ui._last_played_card_id == armor.instance_id)
	assert((_ui.find_child("Seat1", true, false) as PlayerFrame).get_display_text().contains(armor.definition.display_name))
	var helmet: CardInstance = AoeSystemTest.give(_ui.combat, 1, "helmet")
	_ui._refresh()
	await _click("Card%d" % helmet.instance_id)
	await _click("ActionConfirm")
	assert(_ui.combat.get_defense(1) == helmet and _ui.game_state.deck.discard_pile.count(armor) == 1)
	var enemy_helmet: CardInstance = ArmorSystemTest.equip(_ui.combat, 2, "helmet")
	_ui._refresh()
	await process_frame
	await process_frame
	var enemy_seat: Button = _ui.find_child("Seat2", true, false) as Button
	assert((enemy_seat as PlayerFrame).get_display_text().contains(enemy_helmet.definition.display_name))
	assert((_ui.find_child("BotTable", true, false) as Control).get_global_rect().encloses(enemy_seat.get_global_rect()))
	_fixture("barrel")
	var dodge: CardInstance = AoeSystemTest.give(_ui.combat, 2, "dodge")
	await _declare_attack()
	assert(_ui._choice_kind == "armor" and not _ui.combat.has_pending_response())
	assert(_ui._inline_choice_host.visible and not _ui._choice_overlay.visible)
	assert((_ui.find_child("UnavailableCard%d" % dodge.instance_id, true, false) as Button).disabled)
	var judgment: CardInstance = _ui.game_state.deck.draw_pile.back()
	judgment.suit = CardInstance.Suit.HEARTS
	var before: int = _ui.game_state.deck.get_draw_count()
	await _click("ChoiceConfirm")
	assert(_ui.game_state.deck.get_draw_count() == before - 1)
	assert(not _ui.is_choice_visible() and _ui.game_state.get_player(2).hp == 4)
	assert(_ui.game_state.get_player(2).hand.has(dodge))
	var logged: bool = false
	for entry: String in _ui._events:
		if entry.contains("phán xét") and entry.contains("♥") and entry.contains("Né thành công"):
			logged = true
	assert(logged and _ui.game_state.validate_state())
	_fixture("barrel")
	await _declare_attack()
	await _click("ChoiceCancel")
	assert(_ui._choice_kind == "response")
	await _click("ChoiceCancel")
	assert(_ui.game_state.get_player(2).hp == 3 and not _ui.is_choice_visible())
	_fixture("chainmail", true)
	armor = _ui.combat.get_defense(2)
	await _declare_attack()
	assert(_ui._choice_kind == "response")
	await _click("ChoiceCancel")
	assert(_ui._choice_kind == "armor" and not _ui.combat.has_pending_dying())
	assert(_ui.game_state.get_player(2).hp == 1)
	await _click("ChoiceConfirm")
	assert(_ui.game_state.get_player(2).hp == 1 and _ui.combat.get_defense(2) == null)
	assert(_ui.game_state.deck.discard_pile.count(armor) == 1 and not _ui.is_choice_visible())
	_fixture("chainmail", true)
	var rifle: CardInstance = AoeSystemTest.give(_ui.combat, 1, "rifle")
	assert(_ui.combat.equip_weapon(1, rifle.instance_id).valid)
	await _declare_attack()
	await _click("ChoiceCancel")
	assert(_ui._choice_kind == "armor")
	await _click("ChoiceCancel")
	assert(_ui._choice_kind == "dying" and _ui.combat.get_pending_weapon().is_empty())
	var heal: CardInstance = AoeSystemTest.give(_ui.combat, 3, "heal")
	assert(_ui.combat.rescue_player(3, 2, heal.instance_id).valid)
	_ui._refresh()
	assert(_ui._choice_kind == "weapon")
	armor = _ui.combat.get_defense(2)
	await _click("WeaponCard%d" % armor.instance_id)
	await _click("ChoiceConfirm")
	assert(_ui.combat.get_defense(2) == null and _ui.game_state.get_player(2).hp == 1)
	assert(not _ui.is_choice_visible() and _ui.game_state.validate_state())
	_ui.queue_free()
	await process_frame
	print("=== ARMOR UI SMOKE PASSED ===")
	quit()


func _fixture(armor_id: String = "", low_hp: bool = false) -> void:
	_ui.combat = AoeSystemTest.setup()
	_ui.game_state = _ui.combat.game_state
	_ui._connect_game_events()
	_ui.combat.executor.damage_pipeline.armor_effects.effect_resolved.connect(_ui._on_armor_effect)
	if low_hp:
		assert(_ui.combat.executor.resolver.deal_damage(2, 3))
	if not armor_id.is_empty():
		ArmorSystemTest.equip(_ui.combat, 2, armor_id)
	_ui.displayed_player_id = 0
	_ui.selected_hand_card_id = 0
	_ui.selected_target_id = 0
	_ui._choice_kind = ""
	_ui._hide_choice()
	_ui._events.clear()
	_ui._refresh()


func _declare_attack() -> void:
	var card: CardInstance = AoeSystemTest.give(_ui.combat, 1, "attack")
	_ui._refresh()
	await _click("Card%d" % card.instance_id)
	await _click("Seat2")
	await _click("ActionConfirm")


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
