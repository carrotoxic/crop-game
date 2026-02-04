class_name StageClearPopup
extends PopupPanel

@onready var title_label: Label = $Margin/VBox/Title
@onready var continue_btn: Button = $Margin/VBox/Continue

var _controller: GameController
var _closing_by_continue: bool = false

func _ready() -> void:
	_controller = get_tree().get_first_node_in_group("game_controller")
	continue_btn.pressed.connect(_on_continue)
	popup_hide.connect(_on_popup_hide)
	hide()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey:
		get_viewport().set_input_as_handled()

func show_stage_cleared(stage_index_0based: int) -> void:
	_closing_by_continue = false
	var n: int = stage_index_0based + 1
	title_label.text = "Stage %d Clear!" % n
	exclusive = true
	popup_centered()

func _on_popup_hide() -> void:
	if not _closing_by_continue and _controller and _controller.stage_clear_showing:
		popup_centered()

func _on_continue() -> void:
	_closing_by_continue = true
	if _controller:
		_controller.continue_to_next_stage()
	hide()
