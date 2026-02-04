class_name GameOverPopup
extends PopupPanel

@onready var title_label: Label = $Margin/VBox/Title
@onready var reason_label: Label = $Margin/VBox/Reason
@onready var restart_btn: Button = $Margin/VBox/Restart

var _controller: GameController
var _closing_by_restart: bool = false

func _ready() -> void:
	_controller = get_tree().get_first_node_in_group("game_controller")
	restart_btn.pressed.connect(_on_restart)
	popup_hide.connect(_on_popup_hide)
	hide()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey:
		get_viewport().set_input_as_handled()

func show_result(won: bool, reason: String) -> void:
	_closing_by_restart = false
	title_label.text = "You Win!" if won else "Game Over"
	reason_label.text = reason
	exclusive = true
	popup_centered()

func _on_popup_hide() -> void:
	if not _closing_by_restart and _controller and _controller.game_ended:
		popup_centered()

func _on_restart() -> void:
	_closing_by_restart = true
	if _controller:
		_controller.restart()
	hide()
