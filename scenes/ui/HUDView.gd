extends PanelContainer

@onready var stage_label: Label = $Margin/VBox/StageTurn
@onready var money_label: Label = $Margin/VBox/Money
@onready var requirement_label: Label = $Margin/VBox/Requirement
@onready var requirement_bar: ProgressBar = $Margin/VBox/ReqBar
@onready var telegraph_label: Label = $Margin/VBox/Telegraph
@onready var end_turn_btn: Button = $Margin/VBox/EndTurn

var _controller: GameController

func _ready() -> void:
	add_theme_stylebox_override("panel", GameTheme.style_hud_panel())
	stage_label.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
	money_label.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
	requirement_label.add_theme_color_override("font_color", GameTheme.TEXT_MUTED)
	telegraph_label.add_theme_color_override("font_color", GameTheme.PEST_WARN)
	requirement_bar.add_theme_stylebox_override("background", GameTheme.make_stylebox_flat(GameTheme.PROGRESS_BG, GameTheme.CARD_BORDER, 4))
	requirement_bar.add_theme_stylebox_override("fill", GameTheme.make_stylebox_flat(GameTheme.PROGRESS_FILL, GameTheme.PROGRESS_FILL, 4))
	end_turn_btn.add_theme_stylebox_override("normal", GameTheme.make_stylebox_flat(GameTheme.PROGRESS_FILL, GameTheme.SOIL_BORDER, 4))
	end_turn_btn.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
	_controller = get_tree().get_first_node_in_group("game_controller")
	if _controller:
		_controller.state_changed.connect(_on_state_changed)
		_controller.pest_telegraphed.connect(_on_pest_telegraphed)
		end_turn_btn.pressed.connect(_on_end_turn)
		_refresh(_controller.state)

func _on_end_turn() -> void:
	if _controller:
		_controller.end_turn()

func _on_state_changed(_state: GameState) -> void:
	_refresh(_state)

func _on_pest_telegraphed(pos: Vector2i) -> void:
	if pos.x >= 0 and pos.y >= 0:
		telegraph_label.text = "Pest next: (%d, %d)" % [pos.x, pos.y]
	else:
		telegraph_label.text = ""

func _refresh(state: GameState) -> void:
	if not state:
		return
	var controller := get_tree().get_first_node_in_group("game_controller") as GameController
	end_turn_btn.disabled = controller != null and (controller.game_ended or controller.stage_clear_showing)
	stage_label.text = "Stage %d | Turn %d/10 (Global %d)" % [state.stage_index + 1, state.turn_in_stage, state.global_turn]
	money_label.text = "Money: %d" % state.money
	var req := state.stage_requirements[state.stage_index] if state.stage_index < state.stage_requirements.size() else 0
	requirement_label.text = "Requirement: %d" % req
	requirement_bar.max_value = req
	requirement_bar.value = state.money
	if not state.has_pest_telegraph():
		telegraph_label.text = ""
