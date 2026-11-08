extends SceneTree

var _menu: MainMenu


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main_menu.tscn")
	_menu = scene.instantiate() as MainMenu
	root.add_child(_menu)
	current_scene = _menu
	await process_frame
	await process_frame
	await process_frame
	assert(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/main_menu.tscn")
	assert((_menu.find_child("Play", true, false) as Button).is_visible_in_tree())
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH))
	for visit: int in range(2):
		await _click("CardCatalog")
		var entries: VBoxContainer = _menu.find_child("CatalogEntries", true, false) as VBoxContainer
		assert(entries != null and entries.get_child_count() == database.definitions.size() + 1)
		assert(not (_menu.find_child("Play", true, false) as Button).is_visible_in_tree())
		for card_id: String in database.definitions:
			var item: Control = entries.get_node("CatalogCard_" + card_id) as Control
			var description: Label = item.find_child("Description", true, false) as Label
			assert(description.text == database.get_definition(card_id).description)
			assert(item.size.x <= root.size.x - 240.0)
		var scroll: ScrollContainer = _menu.find_child("CatalogScroll", true, false) as ScrollContainer
		scroll.scroll_vertical = 10000
		await process_frame
		# Navigation remains available while the catalog is scrolled to its end.
		assert((_menu.find_child("CatalogBack", true, false) as Button).get_global_rect().position.y < scroll.get_global_rect().position.y)
		await _click("CatalogBack")
		assert(_menu._catalog == null)
	await _click("Play")
	await process_frame
	assert(current_scene is PlayablePrototype)
	var prototype: PlayablePrototype = current_scene as PlayablePrototype
	assert(prototype.game_state == null and prototype._setup_menu.visible)
	(prototype.find_child("CreateMatch", true, false) as Button).pressed.emit()
	assert(prototype.game_state.players.size() == 4 and prototype.game_state.validate_state())
	prototype.queue_free()
	await process_frame
	print("=== MAIN MENU AND CATALOG UI SMOKE PASSED ===")
	quit()


func _click(node_name: String) -> void:
	await process_frame
	var button: Button = _menu.find_child(node_name, true, false) as Button
	assert(button != null and button.is_visible_in_tree() and not button.disabled, node_name)
	var point: Vector2 = button.get_global_rect().get_center()
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
		await process_frame
