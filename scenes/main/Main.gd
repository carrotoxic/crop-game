extends Node

func _ready() -> void:
	var controller := $GameController as GameController
	var game_over_popup: GameOverPopup = $GameOverPopup as GameOverPopup
	var stage_clear_popup: StageClearPopup = $StageClearPopup as StageClearPopup
	var end_turn_btn: Button = $UI/HBoxRoot/VBoxRoot/EndTurnRow/EndTurn as Button
	if controller and game_over_popup:
		controller.game_over.connect(game_over_popup.show_result)
	if controller and stage_clear_popup:
		controller.stage_cleared.connect(stage_clear_popup.show_stage_cleared)
	if controller and end_turn_btn:
		end_turn_btn.add_theme_stylebox_override("normal", GameTheme.make_stylebox_flat(GameTheme.PROGRESS_FILL, GameTheme.SOIL_BORDER, 4))
		end_turn_btn.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
		end_turn_btn.pressed.connect(controller.end_turn)
		controller.state_changed.connect(_on_state_changed.bind(end_turn_btn, controller))
		_update_end_turn(end_turn_btn, controller)

func _on_state_changed(_state: GameState, end_turn_btn: Button, controller: GameController) -> void:
	_update_end_turn(end_turn_btn, controller)

func _update_end_turn(btn: Button, controller: GameController) -> void:
	btn.disabled = true
	btn.disabled = false
	btn.disabled = controller.game_ended or controller.stage_clear_showing
