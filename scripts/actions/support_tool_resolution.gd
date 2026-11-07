class_name SupportToolResolution
extends RefCounted

var _state: GameState
var _turns: TurnManager
var _resolver: EffectResolver
var _pending: Dictionary = {}
var _executing: bool = false


func _init(state: GameState, turns: TurnManager, resolver: EffectResolver) -> void:
	_state = state
	_turns = turns
	_resolver = resolver


static func _whole_number(value: Variant, minimum: int) -> bool:
	if not (value is int or value is float):
		return false
	var number: float = float(value)
	return is_finite(number) and number >= minimum and number == floor(number) and number <= 2147483647.0


static func valid_effect(effect: Dictionary) -> bool:
	var parameters: Variant = effect.get("parameters")
	if not parameters is Dictionary:
		return false
	match effect.get("effect_id"):
		"draw_cards":
			if not _whole_number(parameters.get("count"), 1) or not _whole_number(parameters.get("discard_count", 0), 0):
				return false
			var discard_zones: Variant = parameters.get("discard_zones", ["hand"])
			if not discard_zones is Array or discard_zones.is_empty():
				return false
			var seen_zones: Dictionary = {}
			for zone: Variant in discard_zones:
				if not zone is String or zone not in ["hand", "equipment"] or seen_zones.has(zone):
					return false
				seen_zones[zone] = true
			return true
		"heal_all_players":
			return _whole_number(parameters.get("amount"), 1) and float(parameters["amount"]) == 1.0
	return false


static func get_effect(definition: CardDefinition) -> Dictionary:
	if not definition.is_tool() or definition.effects.size() != 1:
		return {}
	var effect: Dictionary = definition.effects[0]
	return effect.duplicate(true) if valid_effect(effect) else {}


func has_pending() -> bool:
	if not _executing and not _pending.is_empty():
		var actor: Player = _state.get_player(int(_pending["actor_id"]))
		if _state.match_over or actor == null or actor.is_eliminated():
			_pending.clear()
	return _executing or not _pending.is_empty()


func get_pending() -> Dictionary:
	has_pending()
	return _pending.duplicate(true)


func clear() -> void:
	_pending.clear()


func execute(actor_id: int, card: CardInstance, effect: Dictionary) -> ActionResult:
	if has_pending() or not valid_effect(effect) or _state.zone_manager.is_transfer_in_progress():
		return ActionResult.failure("Không thể thực thi công cụ hỗ trợ lúc này.")
	_executing = true
	var parameters: Dictionary = effect["parameters"]
	if effect["effect_id"] == "draw_cards":
		# Reserve the played card in hand under the busy guard until drawing ends;
		# it must not be recycled into its own draw effect.
		_resolver.draw_cards(actor_id, int(parameters["count"]))
		var discard_count: int = int(parameters.get("discard_count", 0))
		if discard_count > 0:
			_pending = {
				"actor_id": actor_id,
				"card_id": card.instance_id,
				"card_name": card.definition.display_name,
				"discard_count": discard_count,
				"discard_zones": parameters.get("discard_zones", ["hand"])
			}
	else:
		_resolver.heal_all_players(int(parameters["amount"]), actor_id)
	var paid: bool = _state.discard_card(actor_id, card.instance_id)
	_executing = false
	if not paid:
		clear()
		return ActionResult.failure("Không thể chuyển công cụ hỗ trợ vào chồng bỏ.")
	return ActionResult.success()


func discard_selected(actor_id: int, card_ids: Array[int]) -> ActionResult:
	var dying_reason: String = _turns.get_dying_block_reason()
	if not dying_reason.is_empty():
		return ActionResult.failure(dying_reason)
	if _executing or _state.match_over or not has_pending() or _pending.is_empty():
		return ActionResult.failure("Không có lựa chọn bỏ bài hỗ trợ đang chờ.")
	if actor_id != int(_pending["actor_id"]) or card_ids.size() != int(_pending["discard_count"]):
		return ActionResult.failure("Phải chọn đúng người và đủ số lá cần bỏ.")
	var actor: Player = _state.get_player(actor_id)
	var seen: Dictionary = {}
	var moves: Array[Dictionary] = []
	var discard_zones: Array = _pending.get("discard_zones", ["hand"])
	for card_id: int in card_ids:
		if seen.has(card_id):
			return ActionResult.failure("Không thể chọn trùng lá bài.")
		seen[card_id] = true
		var owned: bool = false
		var source_zone: String = ""
		for zone: String in discard_zones:
			for card: CardInstance in actor.get_zone(zone):
				if card.instance_id == card_id:
					owned = true
					source_zone = zone
					break
			if owned:
				break
		if not owned:
			return ActionResult.failure("Lá đã chọn không còn trong vùng được phép bỏ.")
		moves.append({"card_id": card_id, "from_zone": source_zone, "from_player_id": actor_id, "to_zone": "discard", "to_player_id": 0})
	_executing = true
	var moved: bool = _state.zone_manager.transfer_cards(moves)
	_executing = false
	if not moved:
		return ActionResult.failure("Không thể bỏ các lá đã chọn; lựa chọn vẫn đang chờ.")
	clear()
	return ActionResult.success()
