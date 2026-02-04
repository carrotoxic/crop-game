@tool
class_name GameConfig
extends Resource

@export var stage_requirements: Array[int] = [10, 25, 45, 70, 100]
@export var initial_money: int = 15
@export var board_size: Vector2i = Vector2i(8, 8)
@export var turns_per_stage: int = 10
@export var pest_start_turn: int = 3
@export var pest_destroy_rounds: int = 3
@export var seed_value: int = 12345
