extends Node

func _ready() -> void:
	var controller := $GameController as GameController
	var game_over_popup: GameOverPopup = $GameOverPopup as GameOverPopup
	var stage_clear_popup: StageClearPopup = $StageClearPopup as StageClearPopup
	if controller and game_over_popup:
		controller.game_over.connect(game_over_popup.show_result)
	if controller and stage_clear_popup:
		controller.stage_cleared.connect(stage_clear_popup.show_stage_cleared)
