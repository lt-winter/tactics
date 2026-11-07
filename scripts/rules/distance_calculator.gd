
class_name DistanceCalculator
extends RefCounted


static func calculate(
	players: Array[Player],
	from_player_id: int,
	to_player_id: int,
	seat_order: Array[int] = []
) -> int:
	var seated_players: Array[Player] = []

	var ordered_players: Array[Player] = players
	if not seat_order.is_empty():
		ordered_players = []
		for player_id: int in seat_order:
			for candidate: Player in players:
				if candidate.player_id == player_id:
					ordered_players.append(candidate)
	for player: Player in ordered_players:
		if not player.is_eliminated():
			seated_players.append(player)

	var from_index: int = -1
	var to_index: int = -1

	for i: int in range(seated_players.size()):
		var player: Player = seated_players[i]

		if player.player_id == from_player_id:
			from_index = i

		if player.player_id == to_player_id:
			to_index = i

	if from_index == -1 or to_index == -1:
		return -1

	if from_index == to_index:
		return 0

	var count: int = seated_players.size()
	var direct_distance: int = abs(from_index - to_index)

	return mini(
		direct_distance,
		count - direct_distance
	)
