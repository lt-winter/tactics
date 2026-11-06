
class_name TurnManager
extends RefCounted

enum Phase {
	START,
	JUDGMENT,
	DRAW,
	PLAY,
	DISCARD,
	END
}

var game_state: GameState

var current_player_index: int = 0
var current_phase: Phase = Phase.START
var turn_number: int = 1

var draw_count_per_turn: int = 2


func _init(state: GameState) -> void:
	game_state = state


func get_current_player() -> Player:
	if game_state.players.is_empty():
		return null

	return game_state.players[current_player_index]


func start_game() -> void:
	current_player_index = 0
	current_phase = Phase.START
	turn_number = 1

	print("Bắt đầu trận đấu")
	print_turn_info()


func advance_phase() -> void:
	match current_phase:
		Phase.START:
			current_phase = Phase.JUDGMENT

		Phase.JUDGMENT:
			current_phase = Phase.DRAW

		Phase.DRAW:
			_execute_draw_phase()
			current_phase = Phase.PLAY

		Phase.PLAY:
			current_phase = Phase.DISCARD

		Phase.DISCARD:
			current_phase = Phase.END

		Phase.END:
			_next_player()

	print_turn_info()


func _execute_draw_phase() -> void:
	var player: Player = get_current_player()

	if player == null:
		return

	for i in range(draw_count_per_turn):
		var card: CardInstance = game_state.draw_card(
			player.player_id
		)

		if card == null:
			break


func _next_player() -> void:
	if game_state.players.is_empty():
		return

	current_player_index = (
		current_player_index + 1
	) % game_state.players.size()

	turn_number += 1
	current_phase = Phase.START


func print_turn_info() -> void:
	var player: Player = get_current_player()

	if player == null:
		return

	print(
		"Turn %d | Player: %s | Phase: %s"
		% [
			turn_number,
			player.display_name,
			Phase.keys()[current_phase]
		]
	)
