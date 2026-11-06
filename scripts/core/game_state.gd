
class_name GameState
extends RefCounted

var players: Array[Player] = []
var deck: Deck
var zone_manager: CardZoneManager


func _init(
	cards: Array[CardInstance],
	game_players: Array[Player]
) -> void:
	players.assign(game_players)

	deck = Deck.new(cards)
	deck.shuffle()

	zone_manager = CardZoneManager.new(
		deck,
		players
	)


func get_player(player_id: int) -> Player:
	for player in players:
		if player.player_id == player_id:
			return player

	return null


func draw_card(player_id: int) -> CardInstance:
	if get_player(player_id) == null:
		return null

	if deck.draw_pile.is_empty():
		deck.recycle_discard_pile()

	if deck.draw_pile.is_empty():
		return null

	var card: CardInstance = deck.draw_pile.back()

	var success := zone_manager.transfer_card(
		card.instance_id,
		"draw",
		0,
		"hand",
		player_id
	)

	if not success:
		return null

	return card


func discard_card(
	player_id: int,
	card_id: int,
	from_zone: String = "hand"
) -> bool:
	return zone_manager.transfer_card(
		card_id,
		from_zone,
		player_id,
		"discard",
		0
	)


func transfer_player_card(
	card_id: int,
	from_player_id: int,
	from_zone: String,
	to_player_id: int,
	to_zone: String
) -> bool:
	return zone_manager.transfer_card(
		card_id,
		from_zone,
		from_player_id,
		to_zone,
		to_player_id
	)


func validate_state() -> bool:
	if not zone_manager.validate_integrity():
		return false

	for player in players:
		if player.hp < 0 or player.hp > player.max_hp:
			push_error(
				"HP không hợp lệ của Player %d"
				% player.player_id
			)
			return false

	return true
