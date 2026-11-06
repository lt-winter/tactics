
class_name Deck
extends RefCounted

var draw_pile: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []
var shuffle_count: int = 0

var rng := RandomNumberGenerator.new()


func _init(cards: Array[CardInstance]) -> void:
	draw_pile.assign(cards)
	rng.randomize()


func shuffle() -> void:
	shuffle_count += 1
	for i in range(draw_pile.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp := draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = temp


func recycle_discard_pile() -> void:
	if not draw_pile.is_empty():
		return

	if discard_pile.is_empty():
		return

	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle()


func get_draw_count() -> int:
	return draw_pile.size()


func get_discard_count() -> int:
	return discard_pile.size()
