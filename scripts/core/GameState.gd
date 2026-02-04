class_name GameState
extends RefCounted

var money: int = 0
var stage_index: int = 0
var turn_in_stage: int = 1
var global_turn: int = 1
var grid: Array = []  # grid[y][x] = CropInstance or null
var next_pest_target: Vector2i = Vector2i(-1, -1)  # (-1,-1) = none
var forbidden_cells_per_crop: Dictionary = {}  # crop_id -> Array of Vector2i (cells where that crop was planted; can't re-plant there until another crop is planted)
var stage_requirements: Array[int] = [10, 25, 45, 70]
var size: Vector2i = Vector2i(5, 5)
var rng: RandomNumberGenerator

func _init(config: GameConfig = null) -> void:
	if config:
		stage_requirements = config.stage_requirements.duplicate()
		size = config.board_size
		rng = RandomNumberGenerator.new()
		rng.seed = config.seed_value
	else:
		rng = RandomNumberGenerator.new()
		rng.seed = 12345
	_init_grid()

func _init_grid() -> void:
	grid.clear()
	for y in size.y:
		var row: Array = []
		for x in size.x:
			row.append(null)
		grid.append(row)

func get_cell(pos: Vector2i):
	if not GridRules.in_bounds(size, pos):
		return null
	return grid[pos.y][pos.x]

func set_cell(pos: Vector2i, crop: CropInstance) -> void:
	if GridRules.in_bounds(size, pos):
		grid[pos.y][pos.x] = crop

func clear_cell(pos: Vector2i) -> void:
	if GridRules.in_bounds(size, pos):
		grid[pos.y][pos.x] = null

func has_pest_telegraph() -> bool:
	return next_pest_target.x >= 0 and next_pest_target.y >= 0

func get_forbidden_cells_for_crop(crop_id: String) -> Array[Vector2i]:
	var arr = forbidden_cells_per_crop.get(crop_id, []) as Array
	var out: Array[Vector2i] = []
	for c in arr:
		out.append(c as Vector2i)
	return out

func is_cell_forbidden_for_crop(cell: Vector2i, crop_id: String) -> bool:
	var arr = forbidden_cells_per_crop.get(crop_id, [])
	for c in arr:
		if c == cell:
			return true
	return false

func add_forbidden(cell: Vector2i, crop_id: String) -> void:
	if not forbidden_cells_per_crop.has(crop_id):
		forbidden_cells_per_crop[crop_id] = []
	forbidden_cells_per_crop[crop_id].append(cell)

func remove_forbidden_for_cell(cell: Vector2i) -> void:
	for crop_id in forbidden_cells_per_crop:
		var arr: Array = forbidden_cells_per_crop[crop_id]
		var i: int = arr.size() - 1
		while i >= 0:
			if arr[i] == cell:
				arr.remove_at(i)
			i -= 1
