
class_name CardZoneManager
extends RefCounted

const DRAW := "draw"
const DISCARD := "discard"
const HAND := "hand"
const EQUIPMENT := "equipment"
const JUDGMENT := "judgment"

var deck: Deck
var players: Dictionary = {}
var original_ids: Dictionary = {}


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
	if not _is_valid_zone(from_zone, from_player_id):
		return false

	if not _is_valid_zone(to_zone, to_player_id):
		return false

	if from_zone == to_zone:
		if from_player_id == to_player_id:
			return false

	var source := _get_zone(from_zone, from_player_id)
	var destination := _get_zone(to_zone, to_player_id)

	var found_card: CardInstance = null

	for card in source:
		if card.instance_id == card_id:
			found_card = card
			break

	if found_card == null:
		return false

	if not original_ids.has(card_id):
		return false

	for card in destination:
		if card.instance_id == card_id:
			return false

	source.erase(found_card)
	destination.append(found_card)

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
