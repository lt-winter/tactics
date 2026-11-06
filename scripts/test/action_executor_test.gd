
class_name ActionExecutorTest
extends RefCounted


static func run_all() -> void:
	var card_db: CardDatabase = CardDatabase.new()
	assert(card_db.load_from_file("res://data/cards.json"))

	var deck_db: DeckDatabase = DeckDatabase.new(card_db)
	assert(
		deck_db.load_from_file(
			"res://data/decks/standard.json"
		)
	)

	var cards: Array[CardInstance] = deck_db.create_instances()

	var player_a: Player = Player.new(1, "Player A", 4)
	var player_b: Player = Player.new(2, "Player B", 4)

	var players: Array[Player] = [player_a, player_b]

	var game: GameState = GameState.new(cards, players)
	var turns: TurnManager = TurnManager.new(game)
	var rules: RuleEngine = RuleEngine.new()

	assert(
		rules.load_base_rules(
			"res://data/rules/base_rules.json"
		)
	)

	var executor: ActionExecutor = ActionExecutor.new(
		game,
		turns,
		rules
	)

	var attack_cards: Array[CardInstance] = []
	var dodge_card: CardInstance = null

	for card in cards:
		if card.definition.has_effect("deal_attack"):
			attack_cards.append(card)

		if card.definition.has_effect("block_attack"):
			if dodge_card == null:
				dodge_card = card

	assert(attack_cards.size() >= 2)
	assert(dodge_card != null)

	# Chuẩn bị bài cho hai người chơi
	for card in attack_cards:
		assert(
			game.zone_manager.transfer_card(
				card.instance_id,
				"draw",
				0,
				"hand",
				1
			)
		)

	assert(
		game.zone_manager.transfer_card(
			dodge_card.instance_id,
			"draw",
			0,
			"hand",
			2
		)
	)

	assert(game.validate_state())

	turns.start_game()
	turns.advance_phase()
	turns.advance_phase()
	turns.advance_phase()

	assert(turns.current_phase == TurnManager.Phase.PLAY)

	print("=== ACTION EXECUTOR TEST ===")

	# Test 1: Bị chặn do không phải lượt
	var result: ActionResult = executor.use_attack(
		2,
		1,
		dodge_card.instance_id
	)

	assert(not result.valid)
	print("[PASS] Chặn hành động không hợp lệ")

	# Test 2: Player A sử dụng Tấn công
	var first_attack: CardInstance = attack_cards[0]

	result = executor.use_attack(
		1,
		2,
		first_attack.instance_id
	)

	assert(result.valid)
	assert(executor.has_pending_attack())
	assert(executor.attacks_used == 1)
	assert(player_b.hp == 4)
	assert(game.validate_state())

	print("[PASS] Tấn công tạo trạng thái chờ")

	# Test 3: Không cho Tấn công chồng lên nhau
	result = executor.use_attack(
		1,
		2,
		attack_cards[1].instance_id
	)

	assert(not result.valid)
	print("[PASS] Chặn Tấn công khi đang chờ phản ứng")

	# Test 4: Player B dùng Né tránh
	result = executor.respond_to_attack(
		2,
		dodge_card.instance_id
	)

	assert(result.valid)
	assert(not executor.has_pending_attack())
	assert(player_b.hp == 4)
	assert(game.validate_state())

	print("[PASS] Né tránh thành công")

	# Test 5: Giới hạn một lần Tấn công
	result = executor.use_attack(
		1,
		2,
		attack_cards[1].instance_id
	)

	assert(not result.valid)
	print("[PASS] Giới hạn Tấn công được ghi nhận")

	# Test 6: Thêm kỹ năng Liên kích
	var combo: RuleModifier = RuleModifier.new(
		"attack_limit_per_turn",
		"remove_limit",
		0,
		RuleModifier.Source.CHARACTER_SKILL,
		"combo_attack",
		1
	)

	rules.add_modifier(combo)

	result = executor.use_attack(
		1,
		2,
		attack_cards[1].instance_id
	)

	assert(result.valid)
	assert(executor.has_pending_attack())

	print("[PASS] Liên kích cho phép Tấn công tiếp")

	# Test 7: Player B không Né tránh
	result = executor.respond_to_attack(2)

	assert(result.valid)
	assert(not executor.has_pending_attack())
	assert(player_b.hp == 3)
	assert(game.validate_state())

	print("[PASS] Gây sát thương thành công")

	# Test 8: Hồi máu
	var healed: bool = executor.resolver.restore_hp(2, 1)

	assert(healed)
	assert(player_b.hp == 4)
	assert(game.validate_state())

	print("[PASS] Hồi máu không vượt HP tối đa")

	# Test 9: Không hồi máu khi đầy HP
	healed = executor.resolver.restore_hp(2, 1)

	assert(not healed)
	assert(player_b.hp == 4)

	print("[PASS] Chặn hồi máu khi đầy HP")

	_test_tool_actions()
	_test_heal_card()
	_test_equipment()
	print("=== ALL ACTION EXECUTOR TESTS PASSED ===")


static func _test_equipment() -> void:
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file("res://data/cards.json"))
	var ids: Array[String] = ["crossbow", "butchers_knife", "slingshot", "pistol", "rifle", "crossbow", "attack", "attack", "attack", "discard", "steal"]
	var cards: Array[CardInstance] = []
	for index: int in range(ids.size()):
		cards.append(CardInstance.new(index + 1, database.get_definition(ids[index]), CardInstance.Suit.SPADES, 1))
	var players: Array[Player] = []
	for player_id: int in range(1, 13):
		players.append(Player.new(player_id, "Seat %d" % player_id, 4))
	var state: GameState = GameState.new(cards, players)
	var turns: TurnManager = TurnManager.new(state)
	turns.draw_count_per_turn = 0
	var rules: RuleEngine = RuleEngine.new()
	assert(rules.load_base_rules("res://data/rules/base_rules.json"))
	var combat: CombatController = CombatController.new(state, turns, rules)
	var discarded_names: Array[String] = []
	state.zone_manager.cards_discarded.connect(func(names: PackedStringArray) -> void:
		discarded_names.append(", ".join(names))
	)
	for card: CardInstance in cards:
		assert(state.zone_manager.transfer_card(card.instance_id, "draw", 0, "hand", 2 if card.instance_id == 6 else 1))
	assert(not combat.equip_weapon(1, 1).valid)
	assert(combat.start_game().valid)
	assert(not combat.equip_weapon(2, 6).valid)
	assert(not combat.equip_weapon(1, 7).valid)
	assert(not combat.equip_weapon(1, 9999).valid)
	var hand_count: int = players[0].get_hand_count()
	assert(combat.equip_weapon(1, 1).valid)
	assert(combat.get_weapon(1).instance_id == 1)
	assert(players[0].get_hand_count() == hand_count - 1 and state.deck.get_discard_count() == 0)
	assert(not combat.use_attack(1, 3, 7).valid)
	assert(combat.use_attack(1, 2, 7).valid)
	assert(not combat.equip_weapon(1, 5).valid)
	assert(not combat.executor.equip_weapon(1, 5).valid)
	assert(combat.respond_to_attack(2).valid)
	assert(combat.use_attack(1, 2, 8).valid)
	assert(combat.respond_to_attack(2).valid)
	assert(combat.executor.attacks_used == 2)
	assert(combat.equip_weapon(1, 5).valid)
	assert(combat.get_weapon(1).instance_id == 5 and combat.get_attack_range(1)["value"] == 5)
	assert(state.deck.discard_pile.has(cards[0]) and state.deck.get_discard_count() == 3)
	assert(discarded_names == ["Tấn công", "Tấn công", "Nỏ thần"])
	assert(combat.executor.attacks_used == 2)
	assert(not rules.get_rule("attack_limit_per_turn", {}, RuleContext.new(1))["unlimited"])
	assert(not combat.use_attack(1, 2, 9).valid)
	# Independent range boundary check on a 12-seat fixture, not the 4-seat UI.
	combat.executor.reset_turn_counters()
	assert(not combat.use_attack(1, 7, 9).valid)
	assert(combat.use_attack(1, 6, 9).valid)
	assert(combat.respond_to_attack(6).valid)
	assert(combat.equip_weapon(1, 2).valid)
	assert(combat.get_attack_range(1)["value"] == 2)
	rules.add_modifier(RuleModifier.new("attack_range", "set", 7, RuleModifier.Source.CHARACTER_SKILL, "equipment_test_skill", 1))
	assert(combat.equip_weapon(1, 3).valid)
	assert(combat.get_attack_range(1)["value"] == 7)
	rules.remove_modifier("equipment_test_skill")
	assert(combat.get_attack_range(1)["value"] == 3)
	assert(combat.executor.attacks_used == 1)
	assert(state.zone_manager.transfer_card(6, "hand", 2, "equipment", 2))
	assert(rules.get_rule("attack_limit_per_turn", {}, RuleContext.new(2))["unlimited"])
	assert(not rules.get_rule("attack_limit_per_turn", {}, RuleContext.new(1))["unlimited"])
	assert(not state.zone_manager.transfer_card(4, "hand", 1, "equipment", 2))
	assert(combat.use_tool(1, 2, 10, 6, "equipment").valid)
	assert(combat.get_weapon(2) == null)
	assert(not rules.get_rule("attack_limit_per_turn", {}, RuleContext.new(2))["unlimited"])
	assert(state.zone_manager.transfer_card(6, "discard", 0, "equipment", 2))
	assert(combat.use_tool(1, 2, 11, 6, "equipment").valid)
	assert(combat.get_weapon(2) == null and players[0].hand.has(cards[5]))
	assert(combat.get_weapon(1).instance_id == 3)
	assert(not rules.get_rule("attack_limit_per_turn", {}, RuleContext.new(2))["unlimited"])
	assert(combat.equip_weapon(1, 6).valid)
	assert(rules.get_rule("attack_limit_per_turn", {}, RuleContext.new(1))["unlimited"])
	var before_discard: Array[CardInstance] = state.deck.discard_pile.duplicate()
	var before_log_count: int = discarded_names.size()
	var invalid_batch: Array[Dictionary] = [
		{"card_id": 6, "from_zone": "equipment", "from_player_id": 1, "to_zone": "discard", "to_player_id": 0},
		{"card_id": 99999, "from_zone": "hand", "from_player_id": 1, "to_zone": "equipment", "to_player_id": 1}
	]
	assert(not state.zone_manager.transfer_cards(invalid_batch))
	assert(discarded_names.size() == before_log_count)
	assert(state.deck.discard_pile == before_discard and combat.get_weapon(1).instance_id == 6)
	assert(rules.get_rule("attack_limit_per_turn", {}, RuleContext.new(1))["unlimited"])
	turns.set_phase_wait(TurnManager.Phase.PLAY, "Unresolved effect")
	assert(not combat.equip_weapon(1, 4).valid)
	turns.set_phase_wait(TurnManager.Phase.PLAY, "")
	assert(combat.executor.resolver.deal_damage(2, 2))
	assert(combat.has_pending_dying())
	assert(not combat.equip_weapon(1, 4).valid)
	assert(not combat.executor.equip_weapon(1, 4).valid)
	assert(combat.finalize_dying().valid)
	assert(turns.end_play(1).valid)
	assert(not combat.equip_weapon(1, 4).valid)
	assert(state.validate_state())
	print("[PASS] Weapon equip/replace, free equip, range 1..5, Crossbow count, skill precedence, Huy/Cuop detach, atomic slot/failed batch and window guards")


static func _test_heal_card() -> void:
	var database: CardDatabase = CardDatabase.new()
	assert(database.load_from_file("res://data/cards.json"))
	var decks: DeckDatabase = DeckDatabase.new(database)
	assert(decks.load_from_file("res://data/decks/standard.json"))
	var cards: Array[CardInstance] = decks.create_instances()
	var players: Array[Player] = [Player.new(1, "A", 4), Player.new(2, "B", 4)]
	var state: GameState = GameState.new(cards, players)
	var turns: TurnManager = TurnManager.new(state)
	turns.draw_count_per_turn = 0
	var rules: RuleEngine = RuleEngine.new()
	assert(rules.load_base_rules("res://data/rules/base_rules.json"))
	var combat: CombatController = CombatController.new(state, turns, rules)
	var heals: Array[CardInstance] = []
	var attacks: Array[CardInstance] = []
	for card: CardInstance in cards:
		if card.definition.has_effect("restore_hp"):
			heals.append(card)
			assert(state.zone_manager.transfer_card(card.instance_id, "draw", 0, "hand", 1))
		elif card.definition.has_effect("deal_attack"):
			attacks.append(card)
	assert(heals.size() >= 3 and attacks.size() >= 2)
	assert(not combat.use_heal(1, heals[0].instance_id).valid)
	assert(combat.start_game().valid)
	assert(not combat.use_heal(1, heals[0].instance_id).valid)
	assert(combat.executor.resolver.deal_damage(1, 2))
	assert(not combat.use_heal(2, heals[0].instance_id).valid)
	assert(not combat.use_heal(999, heals[0].instance_id).valid)
	assert(not combat.use_heal(1, 999999).valid)
	assert(state.zone_manager.transfer_card(attacks[0].instance_id, "draw", 0, "hand", 1))
	assert(not combat.use_heal(1, attacks[0].instance_id).valid)
	turns.set_phase_wait(TurnManager.Phase.PLAY, "Unresolved effect")
	assert(not combat.use_heal(1, heals[0].instance_id).valid)
	turns.set_phase_wait(TurnManager.Phase.PLAY, "")
	assert(combat.use_attack(1, 2, attacks[0].instance_id).valid)
	assert(not combat.use_heal(1, heals[0].instance_id).valid)
	assert(combat.respond_to_attack(2).valid)
	assert(state.deck.get_discard_count() == 1)
	assert(combat.use_heal(1, heals[0].instance_id).valid)
	assert(players[0].hp == 3 and state.deck.get_discard_count() == 2)
	assert(not combat.use_heal(1, heals[0].instance_id).valid)
	# Read amount from JSON and clamp to max HP, consuming the card once.
	heals[1].definition = CardDefinition.new({"id": "large_heal", "name": "Heal", "category": "basic", "subcategory": "recovery", "description": "", "effects": [{"effect_id": "restore_hp", "parameters": {"amount": 2}}]})
	assert(combat.use_heal(1, heals[1].instance_id).valid)
	assert(players[0].hp == 4)
	assert(not combat.use_heal(1, heals[2].instance_id).valid)
	assert(combat.executor.resolver.deal_damage(1, 1))
	for amount: Variant in [0, -1, 0.5, "1", true, null]:
		heals[2].definition = CardDefinition.new({"id": "bad_heal", "name": "Heal", "category": "basic", "subcategory": "recovery", "description": "", "effects": [{"effect_id": "restore_hp", "parameters": {"amount": amount}}]})
		assert(not combat.use_heal(1, heals[2].instance_id).valid)
	assert(players[0].hp == 3 and state.deck.get_discard_count() == 3)
	heals[2].definition = database.get_definition("heal")
	assert(combat.end_turn(1).valid)
	assert(turns.current_phase == TurnManager.Phase.DISCARD)
	assert(not combat.use_heal(1, heals[2].instance_id).valid)
	# Pending dying takes priority, even for a wounded living actor.
	assert(combat.executor.resolver.deal_damage(2, 3))
	assert(combat.executor.dying_manager.begin_dying(2).valid)
	assert(not combat.use_heal(1, heals[2].instance_id).valid)
	assert(state.validate_state())
	print("[PASS] Heal card: ownership, turn/phase, windows/holds, amount, payment, cap and rejection without cost")


static func _test_tool_actions() -> void:
	for effect_id: String in ["discard", "steal_card"]:
		for zone: String in ["hand", "equipment", "judgment"]:
			var database: CardDatabase = CardDatabase.new()
			assert(database.load_from_file("res://data/cards.json"))
			var decks: DeckDatabase = DeckDatabase.new(database)
			assert(decks.load_from_file("res://data/decks/standard.json"))
			var cards: Array[CardInstance] = decks.create_instances()
			var tool: CardInstance = null
			var victim: CardInstance = null
			var attack: CardInstance = null
			for card: CardInstance in cards:
				if card.definition.has_effect(effect_id) and tool == null:
					tool = card
				if card.definition.has_effect("deal_attack"):
					if victim == null:
						victim = card
					elif attack == null:
						attack = card
			assert(tool != null and victim != null and attack != null)
			var players: Array[Player] = [Player.new(1, "A", 4), Player.new(2, "B", 4), Player.new(3, "C", 4), Player.new(4, "D", 4)]
			var state: GameState = GameState.new(cards, players)
			var turns: TurnManager = TurnManager.new(state)
			turns.draw_count_per_turn = 0
			var rules: RuleEngine = RuleEngine.new()
			assert(rules.load_base_rules("res://data/rules/base_rules.json"))
			var combat: CombatController = CombatController.new(state, turns, rules)
			assert(state.zone_manager.transfer_card(tool.instance_id, "draw", 0, "hand", 1))
			assert(state.zone_manager.transfer_card(victim.instance_id, "draw", 0, zone, 2))
			assert(not combat.use_tool(1, 2, tool.instance_id, victim.instance_id, zone).valid)
			assert(combat.start_game().valid)
			assert(not combat.use_tool(2, 1, tool.instance_id, victim.instance_id, zone).valid)
			assert(not combat.use_tool(1, 1, tool.instance_id, victim.instance_id, zone).valid)
			assert(not combat.use_tool(1, 2, tool.instance_id, 99999, zone).valid)
			assert(not combat.use_tool(1, 2, tool.instance_id, victim.instance_id, "draw").valid)
			assert(state.deck.get_discard_count() == 0 and players[0].get_hand_count() == 1)
			assert(state.transfer_player_card(victim.instance_id, 2, zone, 3, zone))
			assert(not combat.use_tool(1, 2, tool.instance_id, victim.instance_id, zone).valid)
			if effect_id == "steal_card":
				assert(not combat.use_tool(1, 3, tool.instance_id, victim.instance_id, zone).valid)
			assert(state.transfer_player_card(victim.instance_id, 3, zone, 2, zone))
			assert(state.zone_manager.transfer_card(attack.instance_id, "draw", 0, "hand", 1))
			assert(combat.use_attack(1, 2, attack.instance_id).valid)
			assert(not combat.use_tool(1, 2, tool.instance_id, victim.instance_id, zone).valid)
			assert(combat.respond_to_attack(2).valid)
			assert(combat.use_tool(1, 2, tool.instance_id, victim.instance_id, zone).valid)
			assert(players[1].get_zone(zone).is_empty())
			assert(players[0].get_hand_count() == (1 if effect_id == "steal_card" else 0))
			assert(state.deck.get_discard_count() == (2 if effect_id == "steal_card" else 3))
			assert(not combat.use_tool(1, 2, tool.instance_id, victim.instance_id, zone).valid)
			assert(state.validate_state())
	print("[PASS] Hủy/Cướp: zones, range, ownership, windows, payment and stale choices")
