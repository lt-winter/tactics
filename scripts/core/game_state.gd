
class_name GameState
extends RefCounted

signal match_finished(winner_id: int)
signal damage_applied(source_id: int, target_id: int, amount: int)
signal healing_applied(source_id: int, target_id: int, amount: int)
signal player_eliminated(player_id: int, killer_id: int)
signal kill_reward_drawn(killer_id: int, victim_id: int, count: int)

var _lethal_sources: Dictionary = {}


func record_damage(source_id: int, target_id: int, amount: int) -> void:
	var target: Player = get_player(target_id)
	if target != null and target.is_dying():
		_lethal_sources[target_id] = source_id
	damage_applied.emit(source_id, target_id, amount)


func get_lethal_source(target_id: int) -> int:
	return int(_lethal_sources.get(target_id, 0))


func clear_lethal_source(target_id: int) -> void:
	_lethal_sources.erase(target_id)

var players: Array[Player] = []
var deck: Deck
var zone_manager: CardZoneManager
var opening_hands_dealt: bool = false
var match_over: bool = false
var winner_id: int = 0


func update_match_result() -> void:
	if match_over:
		return
	var survivors: Array[Player] = []
	for player: Player in players:
		# DYING still occupies a seat and retains the right to be rescued.
		if player.is_dying() or (not player.is_eliminated() and player.hp <= 0):
			return
		if not player.is_eliminated():
			survivors.append(player)
	if survivors.size() == 1 and survivors[0].is_alive():
		winner_id = survivors[0].player_id
		match_over = true
		match_finished.emit(winner_id)


func deal_initial_hands(count: int, order: Array[int]) -> ActionResult:
	if match_over or opening_hands_dealt or count < 1 or order.size() != players.size() or players.is_empty():
		return ActionResult.failure("Không thể chia lại bài đầu hoặc cấu hình không hợp lệ.")
	var seen: Dictionary = {}
	for player_id: int in order:
		var player: Player = get_player(player_id)
		if player == null or seen.has(player_id) or not player.is_alive():
			return ActionResult.failure("Thứ tự chia bài không hợp lệ.")
		if not player.hand.is_empty() or not player.equipment.is_empty() or not player.judgment.is_empty():
			return ActionResult.failure("Chỉ chia bài đầu trên bàn mới.")
		seen[player_id] = true
	if deck.get_discard_count() > 0 or deck.get_draw_count() < count * order.size():
		return ActionResult.failure("Bộ bài không đủ để chia %d lá cho mỗi người." % count)
	if not zone_manager.validate_integrity():
		return ActionResult.failure("Bộ bài không bảo toàn trước khi chia.")
	for round_index: int in range(count):
		for player_id: int in order:
			var drawn: CardInstance = draw_card(player_id)
			assert(drawn != null)
	opening_hands_dealt = true
	return ActionResult.success()


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
	if match_over or get_player(player_id) == null:
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
	if match_over:
		return false
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
	if match_over:
		return false
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
		if player.hp > player.max_hp or (player.life_state == Player.LifeState.ALIVE and player.hp <= 0) or (player.is_dying() and player.hp > 0):
			push_error(
				"HP không hợp lệ của Player %d"
				% player.player_id
			)
			return false

	return true
