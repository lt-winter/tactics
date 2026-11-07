
class_name CardInstance
extends RefCounted

enum Suit {
	HEARTS = 0,
	DIAMONDS = 1,
	CLUBS = 2,
	SPADES = 3
}

const SUIT_NAMES := {
	Suit.SPADES: "spades",
	Suit.HEARTS: "hearts",
	Suit.DIAMONDS: "diamonds",
	Suit.CLUBS: "clubs"
}

const SUIT_SYMBOLS := {
	Suit.SPADES: "♠",
	Suit.HEARTS: "♥",
	Suit.DIAMONDS: "♦",
	Suit.CLUBS: "♣"
}

const RANK_NAMES := {
	1: "A",
	11: "J",
	12: "Q",
	13: "K"
}

var instance_id: int
var definition: CardDefinition
var suit: Suit
var rank: int


func _init(
	new_id: int,
	card_definition: CardDefinition,
	card_suit: Suit,
	card_rank: int
) -> void:
	assert(card_definition != null)
	assert(card_rank >= 1 and card_rank <= 13)
	assert(card_suit >= Suit.HEARTS)
	assert(card_suit <= Suit.SPADES)

	instance_id = new_id
	definition = card_definition
	suit = card_suit
	rank = card_rank


func get_rank_text() -> String:
	return RANK_NAMES.get(rank, str(rank))


func get_display_name() -> String:
	return "%s %s%s" % [
		definition.display_name,
		get_rank_text(),
		SUIT_SYMBOLS[suit]
	]


func get_suit_name() -> String:
	return SUIT_NAMES[suit]


func is_red() -> bool:
	return suit == Suit.HEARTS or suit == Suit.DIAMONDS


func is_black() -> bool:
	return not is_red()

#

static func is_valid_suit_name(suit_name: String) -> bool:
	return SUIT_NAMES.values().has(suit_name)


static func suit_from_name(suit_name: String) -> Suit:
	match suit_name:
		"spades":
			return Suit.SPADES
		"hearts":
			return Suit.HEARTS
		"diamonds":
			return Suit.DIAMONDS
		"clubs":
			return Suit.CLUBS
		_:
			push_error("Chất bài không hợp lệ: " + suit_name)
			return Suit.SPADES
