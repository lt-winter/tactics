extends SceneTree

var _ui: PlayablePrototype


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/dev/playable_prototype.tscn")
	_ui = scene.instantiate() as PlayablePrototype
	root.add_child(_ui)
	await process_frame
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		_ui.get_window().size = resolution
		for count: int in range(2, 7):
			_ui._new_table(count)
			for frame: int in range(4):
				await process_frame
			var board: Control = _ui.find_child("BotTable", true, false) as Control
			for index: int in range(_ui._seats.size()):
				var seat: PlayerFrame = _ui._seats[index] as PlayerFrame
				_check_cells(seat)
				assert(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(seat.get_global_rect()), "resolution=%s count=%d seat=%d rect=%s window=%s canvas=%s ui=%s page=%s board=%s sidebar=%s" % [resolution, count, index + 1, seat.get_global_rect(), root.size, root.content_scale_size, _ui.size, _ui._game_page.size, board.size, (_ui.find_child("MatchSidebar", true, false) as Control).size])
				if index > 0:
					assert(board.get_global_rect().encloses(seat.get_global_rect()))
				assert(not seat.get_slot_text("weapon").contains("Tầm"))
				for slot: String in CardDefinition.EQUIPMENT_SLOTS:
					assert(not seat.is_slot_occupied(slot))
					assert(is_zero_approx((seat.find_child(slot + "Cell", true, false) as Control).modulate.a))
			for first: int in range(1, _ui._seats.size()):
				for second: int in range(first + 1, _ui._seats.size()):
					assert(not _ui._seats[first].get_global_rect().intersects(_ui._seats[second].get_global_rect()))
		_ui._new_table(4)
		_ui.combat = AoeSystemTest.setup()
		_ui.game_state = _ui.combat.game_state
		_ui._connect_game_events()
		_ui.displayed_player_id = 0
		for owner: int in [1, 2]:
			var weapon: CardInstance = AoeSystemTest.give(_ui.combat, owner, "rifle")
			weapon.rank = 7
			weapon.suit = CardInstance.Suit.HEARTS
			if owner == 1:
				assert(_ui.combat.equip_weapon(owner, weapon.instance_id).valid)
			else:
				assert(_ui.game_state.zone_manager.transfer_card(weapon.instance_id, "hand", owner, "equipment", owner))
			ArmorSystemTest.equip(_ui.combat, owner, "helmet")
			AccessorySystemTest.equip(_ui.combat, owner, "scope")
			var mustang: CardInstance = AccessorySystemTest.equip(_ui.combat, owner, "mustang")
			mustang.rank = 11
			mustang.suit = CardInstance.Suit.CLUBS
		_ui._refresh()
		for frame: int in range(3):
			await process_frame
		var own: PlayerFrame = _ui._seats[0] as PlayerFrame
		var opponent: PlayerFrame = _ui._seats[1] as PlayerFrame
		for seat: PlayerFrame in [own, opponent]:
			_check_cells(seat)
			assert(seat.get_slot_text("weapon").contains("7♥ Tầm 5"))
			assert((seat.find_child("weaponRank", true, false) as Label).get_theme_color("font_color") == Color("f28b7b"))
			assert((seat.find_child("defensive_accessoryRank", true, false) as Label).text == "J♣")
			assert((seat.find_child("defensive_accessoryRank", true, false) as Label).get_theme_color("font_color") == PlayerFrame.INK)
			for slot: String in CardDefinition.EQUIPMENT_SLOTS:
				var card: CardInstance = _ui.combat.executor.equipment_system.get_equipment(1 if seat == own else 2, slot)
				assert(seat.get_slot_text(slot).contains(card.get_rank_text() + CardInstance.SUIT_SYMBOLS[card.suit]))
				var cell: Control = seat.find_child(slot + "Cell", true, false) as Control
				assert(cell.get_tooltip().contains(card.get_display_name()) and cell.get_tooltip().contains(card.definition.description))
				for other_slot: String in CardDefinition.EQUIPMENT_SLOTS:
					if slot != other_slot:
						var other: CardInstance = _ui.combat.executor.equipment_system.get_equipment(1 if seat == own else 2, other_slot)
						assert(not cell.get_tooltip().contains(other.definition.display_name))
				await _hover(cell.get_global_rect().get_center())
				assert(root.gui_get_hovered_control() == cell)
			assert(seat.get_tooltip().is_empty())
			for info_name: String in ["PlayerName", "PortraitArea", "HealthCell", "Health", "LifeState", "HandCount"]:
				assert((seat.find_child(info_name, true, false) as Control).get_tooltip().is_empty())
		var positions: Dictionary = {}
		for slot: String in CardDefinition.EQUIPMENT_SLOTS:
			positions[slot] = (own.find_child(slot + "Cell", true, false) as Control).get_global_rect()
		await _capture("player-frame-%d.png" % resolution.x)
		var equipped: CardInstance = _ui.combat.get_weapon(1)
		assert(_ui.game_state.discard_card(1, equipped.instance_id, "equipment"))
		_ui._refresh()
		assert(not own.get_slot_text("weapon").contains("7♥") and not own.get_slot_text("weapon").contains("Tầm"))
		assert(not own.is_slot_occupied("weapon"))
		for slot: String in ["defensive_accessory", "offensive_accessory", "armor"]:
			var card: CardInstance = _ui.combat.executor.equipment_system.get_equipment(1, slot)
			assert(_ui.game_state.discard_card(1, card.instance_id, "equipment"))
			_ui._refresh()
			await process_frame
			await process_frame
			var removed_cell: Control = own.find_child(slot + "Cell", true, false) as Control
			assert(removed_cell.visible and is_zero_approx(removed_cell.modulate.a))
			assert(removed_cell.get_tooltip().is_empty())
			assert(own.get_slot_text(slot).is_empty())
			for fixed_slot: String in CardDefinition.EQUIPMENT_SLOTS:
				assert((own.find_child(fixed_slot + "Cell", true, false) as Control).get_global_rect() == positions[fixed_slot])
			if slot == "defensive_accessory":
				var single: Control = own.find_child("offensive_accessoryCell", true, false) as Control
				var row: Control = own.find_child("AccessoryRow", true, false) as Control
				assert(row.visible and own.is_slot_occupied("offensive_accessory"))
				assert(single.size.x < row.size.x * 0.6)
		assert(is_zero_approx((own.find_child("AccessoryRow", true, false) as Control).modulate.a))
		AccessorySystemTest.equip(_ui.combat, 1, "scope")
		var attack: CardInstance = AoeSystemTest.give(_ui.combat, 1, "attack")
		_ui._refresh()
		_ui._select_hand_card(attack.instance_id)
		await process_frame
		var own_accessory: Control = own.find_child("offensive_accessoryCell", true, false) as Control
		await _hover(own_accessory.get_global_rect().get_center())
		assert(own.disabled and root.gui_get_hovered_control() == own_accessory)
		assert(not own_accessory.get_tooltip().is_empty())
		var armor_cell: Control = opponent.find_child("armorCell", true, false) as Control
		await _hover(armor_cell.get_global_rect().get_center())
		for down: bool in [true, false]:
			var click: InputEventMouseButton = InputEventMouseButton.new()
			click.position = armor_cell.get_global_rect().get_center()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = down
			root.push_input(click)
			await process_frame
		assert(_ui.selected_target_id == 2)
		_ui.selected_target_id = 0
		_ui._refresh()
		var name: Label = opponent.find_child("PlayerName", true, false) as Label
		var point: Vector2 = name.get_global_rect().get_center()
		for down: bool in [true, false]:
			var event: InputEventMouseButton = InputEventMouseButton.new()
			event.position = point
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = down
			root.push_input(event)
			await process_frame
		assert(_ui.selected_target_id == 2)
		assert(_ui.combat.executor.resolver.deal_damage(3, 5))
		_ui._refresh()
		var dying: PlayerFrame = _ui._seats[2] as PlayerFrame
		assert((dying.find_child("Health", true, false) as Label).text == "♥ -1/4")
		assert(dying.get_display_text().contains("Hấp hối"))
		assert(_ui.game_state.validate_state())
	_ui.queue_free()
	await process_frame
	print("=== PLAYER FRAME UI SMOKE PASSED ===")
	quit()


func _check_cells(seat: PlayerFrame) -> void:
	var portrait: Control = seat.find_child("PortraitArea", true, false) as Control
	var health: Control = seat.find_child("HealthCell", true, false) as Control
	assert(portrait.get_global_rect().encloses(health.get_global_rect()))
	assert(is_equal_approx(health.get_global_rect().end.x, portrait.get_global_rect().end.x))
	assert(is_equal_approx(health.get_global_rect().end.y, portrait.get_global_rect().end.y))
	var previous: Control = portrait
	for node_name: String in ["weaponCell", "armorCell", "AccessoryRow", "specialCell"]:
		var cell: Control = seat.find_child(node_name, true, false) as Control
		assert(seat.get_global_rect().encloses(cell.get_global_rect()))
		assert(cell.get_global_rect().position.y >= previous.get_global_rect().end.y)
		previous = cell
	var offense: Control = seat.find_child("offensive_accessoryCell", true, false) as Control
	var defense: Control = seat.find_child("defensive_accessoryCell", true, false) as Control
	if offense.visible and defense.visible:
		assert(is_equal_approx(offense.get_global_rect().position.y, defense.get_global_rect().position.y))
		assert(defense.get_global_rect().position.x >= offense.get_global_rect().end.x)
	assert(is_zero_approx((seat.find_child("specialCell", true, false) as Control).modulate.a))
	assert(seat.get_slot_text("special").is_empty())
	assert("special" not in CardDefinition.EQUIPMENT_SLOTS)
	for node: Node in seat.find_children("*", "Control", true, false):
		var tooltip_cell: bool = false
		for slot: String in CardDefinition.EQUIPMENT_SLOTS:
			tooltip_cell = tooltip_cell or (seat.is_slot_occupied(slot) and node == seat.find_child(slot + "Cell", true, false))
		assert((node as Control).mouse_filter == (Control.MOUSE_FILTER_PASS if tooltip_cell else Control.MOUSE_FILTER_IGNORE))


func _hover(point: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion)
	await process_frame
	await process_frame


func _capture(filename: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"):
		return
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://" + filename) == OK)
	var cell: Control = _ui._seats[1].find_child("armorCell", true, false) as Control
	await _hover(cell.get_global_rect().get_center())
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://" + filename.trim_suffix(".png") + "-tooltip.png") == OK)
	await _hover(Vector2.ONE)
