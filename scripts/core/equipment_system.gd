class_name EquipmentSystem
extends RefCounted

var game_state: GameState
var rule_engine: RuleEngine
var _sources: Dictionary = {}


func _init(state: GameState, rules: RuleEngine) -> void:
	game_state = state
	rule_engine = rules
	game_state.zone_manager.equipment_changed.connect(_sync_modifiers)
	_sync_modifiers()


func get_weapon(player_id: int) -> CardInstance:
	var player: Player = game_state.get_player(player_id)
	if player == null:
		return null
	for card: CardInstance in player.equipment:
		if card.definition.is_equipment() and card.definition.equipment_slot == "weapon":
			return card
	return null


func commit_equip(player_id: int, card_id: int) -> ActionResult:
	var moves: Array[Dictionary] = []
	var old_weapon: CardInstance = get_weapon(player_id)
	if old_weapon != null:
		moves.append({"card_id": old_weapon.instance_id, "from_zone": "equipment", "from_player_id": player_id, "to_zone": "discard", "to_player_id": 0})
	moves.append({"card_id": card_id, "from_zone": "hand", "from_player_id": player_id, "to_zone": "equipment", "to_player_id": player_id})
	if not game_state.zone_manager.transfer_cards(moves):
		return ActionResult.failure("Không thể trang bị vũ khí; bài và trang bị cũ được giữ nguyên.")
	return ActionResult.success()


func _sync_modifiers() -> void:
	var current: Dictionary = {}
	for player: Player in game_state.players:
		var weapon: CardInstance = get_weapon(player.player_id)
		if weapon != null:
			var source_key: String = "equipment:%d:%d" % [player.player_id, weapon.instance_id]
			current[source_key] = {"owner": player.player_id, "card": weapon}
	for source_key: String in _sources:
		if not current.has(source_key):
			rule_engine.remove_modifier(source_key)
	for source_key: String in current:
		if _sources.has(source_key):
			continue
		var owner_id: int = current[source_key]["owner"]
		var weapon: CardInstance = current[source_key]["card"]
		rule_engine.add_modifier(RuleModifier.new("attack_range", "set", weapon.definition.attack_range, RuleModifier.Source.CARD_EFFECT, source_key, owner_id))
		if weapon.definition.has_effect("remove_attack_limit"):
			rule_engine.add_modifier(RuleModifier.new("attack_limit_per_turn", "remove_limit", 0, RuleModifier.Source.CARD_EFFECT, source_key, owner_id))
	_sources = current
