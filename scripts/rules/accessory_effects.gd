class_name AccessoryEffects
extends RefCounted

const SLOTS: Array[String] = ["offensive_accessory", "defensive_accessory"]


static func valid_effect(effect: Dictionary, slot: String) -> bool:
	var effect_id: Variant = effect.get("effect_id")
	if slot not in SLOTS or not effect_id is String or effect_id != "modify_distance":
		return false
	var parameters: Variant = effect.get("parameters")
	if not parameters is Dictionary:
		return false
	var amount: Variant = parameters.get("amount")
	if not (amount is int or amount is float) or not is_finite(float(amount)):
		return false
	var direction: Variant = parameters.get("direction")
	if not direction is String:
		return false
	var outgoing: bool = slot == "offensive_accessory"
	return direction == ("outgoing" if outgoing else "incoming") and float(amount) == (-1.0 if outgoing else 1.0)


static func supports(definition: CardDefinition) -> bool:
	return definition != null and definition.is_equipment() and definition.subcategory == "accessory" and definition.effects.size() == 1 and valid_effect(definition.effects[0], definition.equipment_slot)


static func modifier(player: Player, direction: String) -> int:
	# Read the live zone; no cached or repeatedly registered modifier can linger.
	if direction not in ["outgoing", "incoming"]:
		return 0
	var slot: String = "offensive_accessory" if direction == "outgoing" else "defensive_accessory"
	for card: CardInstance in player.equipment:
		if card.definition.equipment_slot == slot and supports(card.definition):
			return int(card.definition.effects[0]["parameters"]["amount"])
	return 0
