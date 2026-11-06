
class_name CardZoneManager
extends RefCounted

signal equipment_changed()
signal cards_discarded(card_names: PackedStringArray)

const DRAW := "draw"
const DISCARD := "discard"
const HAND := "hand"
const EQUIPMENT := "equipment"
const JUDGMENT := "judgment"

var deck: Deck
var players: Dictionary = {}
var original_ids: Dictionary = {}
var _committing: bool = false


func _init(
	game_deck: Deck,
	game_players: Array[Player]
) -> void:
	deck = game_deck

	for player in game_players:
		assert(not players.has(player.player_id))
		players[player.player_id] = player

	for card in deck.draw_pile:
		assert(not original_ids.has(card.instance_id))
		original_ids[card.instance_id] = true


func _is_valid_zone(
	zone_name: String,
	player_id: int
) -> bool:
	if zone_name == DRAW or zone_name == DISCARD:
		return player_id == 0

	if not players.has(player_id):
		return false

	return zone_name in [HAND, EQUIPMENT, JUDGMENT]


func _get_zone(
	zone_name: String,
	player_id: int
) -> Array[CardInstance]:
	if zone_name == DRAW:
		return deck.draw_pile

	if zone_name == DISCARD:
		return deck.discard_pile

	var player: Player = players[player_id]

	match zone_name:
		HAND:
			return player.hand
		EQUIPMENT:
			return player.equipment
		JUDGMENT:
			return player.judgment

	return []


func transfer_card(
	card_id: int,
	from_zone: String,
	from_player_id: int,
	to_zone: String,
	to_player_id: int
) -> bool:
	var moves: Array[Dictionary] = [{"card_id": card_id, "from_zone": from_zone, "from_player_id": from_player_id, "to_zone": to_zone, "to_player_id": to_player_id}]
	return transfer_cards(moves)


func transfer_cards(moves: Array[Dictionary]) -> bool:
	if _committing or moves.is_empty():
		return false
	var originals: Dictionary = {}
	var shadows: Dictionary = {}
	var equipment_touched: bool = false
	for move: Dictionary in moves:
		if not (move.get("card_id") is int and move.get("from_zone") is String and move.get("to_zone") is String and move.get("from_player_id") is int and move.get("to_player_id") is int):
			return false
		var card_id: int = move["card_id"]
		var from_zone: String = move["from_zone"]
		var to_zone: String = move["to_zone"]
		var from_owner: int = move["from_player_id"]
		var to_owner: int = move["to_player_id"]
		if not _is_valid_zone(from_zone, from_owner) or not _is_valid_zone(to_zone, to_owner):
			return false
		var source_key: String = "%s:%d" % [from_zone, from_owner]
		var destination_key: String = "%s:%d" % [to_zone, to_owner]
		if source_key == destination_key or not original_ids.has(card_id):
			return false
		if not originals.has(source_key):
			originals[source_key] = _get_zone(from_zone, from_owner)
			shadows[source_key] = _get_zone(from_zone, from_owner).duplicate()
		if not originals.has(destination_key):
			originals[destination_key] = _get_zone(to_zone, to_owner)
			shadows[destination_key] = _get_zone(to_zone, to_owner).duplicate()
		var source: Array[CardInstance] = shadows[source_key]
		var destination: Array[CardInstance] = shadows[destination_key]
		var found: CardInstance = null
		for card: CardInstance in source:
			if card.instance_id == card_id:
				found = card
				break
		if found == null:
			return false
		for card: CardInstance in destination:
			if card.instance_id == card_id:
				return false
			if to_zone == EQUIPMENT and found.definition.has_equipment_slot() and card.definition.has_equipment_slot() and found.definition.equipment_slot == card.definition.equipment_slot:
				return false
		source.erase(found)
		destination.append(found)
		equipment_touched = equipment_touched or from_zone == EQUIPMENT or to_zone == EQUIPMENT
	# Publish only after every move succeeds in the shadow state.
	var discarded_names: PackedStringArray = []
	if shadows.has("discard:0"):
		var previous_discard: Array[CardInstance] = originals["discard:0"]
		var next_discard: Array[CardInstance] = shadows["discard:0"]
		for card: CardInstance in next_discard:
			if not previous_discard.has(card):
				discarded_names.append(card.definition.display_name)
	_committing = true
	for key: String in originals:
		var zone: Array[CardInstance] = originals[key]
		zone.assign(shadows[key])
	if equipment_touched:
		equipment_changed.emit()
	if not discarded_names.is_empty():
		cards_discarded.emit(discarded_names)
	_committing = false
	return true


func validate_integrity() -> bool:
	var current_ids: Dictionary = {}

	var zones: Array[Array] = [
		deck.draw_pile,
		deck.discard_pile
	]

	for player in players.values():
		zones.append(player.hand)
		zones.append(player.equipment)
		zones.append(player.judgment)

	for zone in zones:
		for card in zone:
			if card == null:
				push_error("Phát hiện lá bài null.")
				return false

			var id: int = card.instance_id

			if current_ids.has(id):
				push_error("Trùng instance_id: %d" % id)
				return false

			if not original_ids.has(id):
				push_error("Lá bài không thuộc bộ bài gốc: %d" % id)
				return false

			current_ids[id] = true

	if current_ids.size() != original_ids.size():
		push_error("Số lượng bài không được bảo toàn.")
		return false

	return true
