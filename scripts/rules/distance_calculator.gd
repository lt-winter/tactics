
class_name DistanceCalculator
extends RefCounted


static func calculate(
	players: Array[Player],
	from_player_id: int,
	to_player_id: int
) -> int:
	var alive_players: Array[Player] = []

	for player in players:
		if player.is_alive():
			alive_players.append(player)

	var from_index: int = -1
	var to_index: int = -1

	for i in range(alive_players.size()):
		var player: Player = alive_players[i]

		if player.player_id == from_player_id:
			from_index = i

		if player.player_id == to_player_id:
			to_index = i

	if from_index == -1 or to_index == -1:
		return -1

	if from_index == to_index:
		return 0

	var count: int = alive_players.size()
	var direct_distance: int = abs(from_index - to_index)

	return mini(
		direct_distance,
		count - direct_distance
	)
