
class_name ActionResult
extends RefCounted

var valid: bool
var reason: String


func _init(
	is_valid: bool,
	error_reason: String = ""
) -> void:
	valid = is_valid
	reason = error_reason


static func success() -> ActionResult:
	return ActionResult.new(true)


static func failure(message: String) -> ActionResult:
	return ActionResult.new(false, message)
