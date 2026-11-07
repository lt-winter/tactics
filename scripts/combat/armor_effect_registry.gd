class_name ArmorEffectRegistry
extends RefCounted

signal effect_resolved(owner_id: int, effect_id: String, details: Dictionary)

const HOOKS: Dictionary = {
	"negate_attack_by_color": "attack_targeted",
	"judgment_dodge": "before_response",
	"cap_incoming_damage": "damage_reduction",
	"prevent_lethal_damage": "before_damage_commit"
}

var _state: GameState
var _equipment: EquipmentSystem
var _handlers: Dictionary = {}
var _instances: Dictionary = {}
var _revisions: Dictionary = {}
var _serial: int = 0


func _init(state: GameState, equipment: EquipmentSystem = null) -> void:
	_state = state
	_equipment = equipment
	_handlers = {
		"negate_attack_by_color": _negate_attack_by_color,
		"judgment_dodge": _judgment_dodge,
		"cap_incoming_damage": _cap_incoming_damage,
		"prevent_lethal_damage": _prevent_lethal_damage
	}
	_state.zone_manager.equipment_changed.connect(_sync_equipment)
	_sync_equipment()


static func valid_effect(effect: Dictionary) -> bool:
	var parameters: Variant = effect.get("parameters")
	if not parameters is Dictionary or not HOOKS.has(effect.get("effect_id")):
		return false
	if not parameters.get("optional") is bool:
		return false
	match effect["effect_id"]:
		"negate_attack_by_color":
			var colors: Variant = parameters.get("colors")
			if not colors is Array or colors.is_empty():
				return false
			for color: Variant in colors:
				if color not in ["black", "red"]:
					return false
			return parameters.get("trigger") == "on_attack_targeted" and parameters.get("optional") == false
		"judgment_dodge":
			return parameters.get("success_suit") == "hearts" and parameters.get("trigger") == "before_attack_response" and parameters.get("optional") == true
		"cap_incoming_damage":
			var threshold: Variant = parameters.get("threshold")
			var maximum: Variant = parameters.get("max_damage")
			return (threshold is int or threshold is float) and (maximum is int or maximum is float) and threshold == 1 and maximum == 1 and parameters.get("trigger") == "before_damage" and parameters.get("optional") == false
		"prevent_lethal_damage":
			var cost: Variant = parameters.get("cost")
			return cost is Dictionary and cost.get("type") == "discard_self_equipment" and parameters.get("prevent_damage") == "all" and parameters.get("trigger") == "before_damage" and parameters.get("optional") == true
	return false


static func supports(definition: CardDefinition) -> bool:
	return definition.is_equipment() and definition.equipment_slot == "armor" and definition.effects.size() == 1 and valid_effect(definition.effects[0])


func get_armor(owner_id: int) -> CardInstance:
	if _equipment != null:
		return _equipment.get_defense(owner_id)
	var player: Player = _state.get_player(owner_id)
	if player != null:
		for card: CardInstance in player.equipment:
			if card.definition.equipment_slot == "armor":
				return card
	return null


func _sync_equipment() -> void:
	for player: Player in _state.players:
		var armor: CardInstance = get_armor(player.player_id)
		var instance_id: int = 0 if armor == null else armor.instance_id
		if int(_instances.get(player.player_id, 0)) != instance_id:
			_revisions[player.player_id] = int(_revisions.get(player.player_id, 0)) + 1
		_instances[player.player_id] = instance_id


func next_decision_id() -> int:
	_serial += 1
	return _serial


func is_current(view: Dictionary) -> bool:
	var owner_id: int = int(view.get("actor_id", 0))
	var armor: CardInstance = get_armor(owner_id)
	return armor != null and armor.instance_id == int(view.get("armor_id", 0)) and int(_revisions.get(owner_id, 0)) == int(view.get("armor_revision", -1))


func query(owner_id: int, hook: String, payload: Dictionary = {}) -> Dictionary:
	var owner: Player = _state.get_player(owner_id)
	var armor: CardInstance = get_armor(owner_id)
	if owner == null or not owner.is_alive() or armor == null or not supports(armor.definition):
		return {}
	var effect: Dictionary = armor.definition.effects[0]
	var effect_id: String = effect["effect_id"]
	if HOOKS[effect_id] != hook:
		return {}
	if hook in ["damage_reduction", "before_damage_commit"]:
		var context: Variant = payload.get("context")
		if not context is DamageContext or context.target_id != owner_id:
			return {}
	var handler: Callable = _handlers[effect_id]
	if not bool(handler.call(effect["parameters"], payload)):
		return {}
	return {"actor_id": owner_id, "target_id": owner_id, "armor_id": armor.instance_id, "armor_revision": int(_revisions.get(owner_id, 0)), "armor_name": armor.definition.display_name, "effect_id": effect_id, "parameters": effect["parameters"].duplicate(true)}


func _negate_attack_by_color(parameters: Dictionary, payload: Dictionary) -> bool:
	return parameters["colors"].has(payload.get("attack_color", ""))


func _judgment_dodge(_parameters: Dictionary, _payload: Dictionary) -> bool:
	return true


func _cap_incoming_damage(parameters: Dictionary, payload: Dictionary) -> bool:
	var context: DamageContext = payload["context"]
	if context.cancelled or context.final_damage <= int(parameters["threshold"]):
		return false
	context.final_damage = mini(context.final_damage, int(parameters["max_damage"]))
	return true


func _prevent_lethal_damage(_parameters: Dictionary, payload: Dictionary) -> bool:
	var context: DamageContext = payload["context"]
	var target: Player = _state.get_player(context.target_id)
	return not context.cancelled and context.final_damage > 0 and context.final_damage >= target.hp


func judge(view: Dictionary) -> Dictionary:
	if _state.match_over or _state.zone_manager.is_transfer_in_progress() or not is_current(view) or view.get("effect_id") != "judgment_dodge":
		return {}
	if _state.deck.draw_pile.is_empty():
		_state.deck.recycle_discard_pile()
	if _state.deck.draw_pile.is_empty():
		return {}
	var card: CardInstance = _state.deck.draw_pile.back()
	var result: Dictionary = {"card_id": card.instance_id, "card_name": card.definition.display_name, "suit": card.get_suit_name(), "rank": card.get_rank_text(), "success": card.get_suit_name() == view["parameters"]["success_suit"]}
	if not _state.zone_manager.transfer_card(card.instance_id, "draw", 0, "discard", 0):
		return {}
	effect_resolved.emit(int(view["actor_id"]), "judgment_dodge", result.duplicate(true))
	return result
