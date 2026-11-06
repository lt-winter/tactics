class_name MatchSetupMenu
extends Control

signal start_requested(player_count: int)
signal cancel_requested()

var _count: SpinBox
var _cancel: Button
var _message: Label


func _ready() -> void:
	name = "MatchSetupMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color("151916")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.x = 440.0
	center.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	var title: Label = Label.new()
	title.text = "TACTICS / VÁN MỚI"
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	var info: Label = Label.new()
	info.text = "Chọn 2–6 người chơi.\nP1 là bạn; P2…Pn điều khiển thủ công."
	column.add_child(info)
	_count = SpinBox.new()
	_count.name = "MatchPlayerCount"
	_count.min_value = 2
	_count.max_value = 6
	_count.step = 1
	_count.value = 4
	_count.prefix = "Số người: "
	column.add_child(_count)
	var start: Button = Button.new()
	start.name = "CreateMatch"
	start.text = "Tạo ván"
	start.pressed.connect(_request_start)
	column.add_child(start)
	_cancel = Button.new()
	_cancel.name = "CancelMatchSetup"
	_cancel.text = "Trở lại ván hiện tại"
	_cancel.pressed.connect(func() -> void: cancel_requested.emit())
	column.add_child(_cancel)
	_message = Label.new()
	_message.name = "MatchSetupMessage"
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_message)


func open(player_count: int, can_cancel: bool) -> void:
	_count.value = clampi(player_count, 2, 6)
	_cancel.visible = can_cancel
	_message.text = ""
	show()


func show_error(message: String) -> void:
	_message.text = message


func _request_start() -> void:
	_count.apply()
	start_requested.emit(int(_count.value))
