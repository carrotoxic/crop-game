extends Control

const CELL_SIZE := 88
const GRID_GAP := 4
const NAME_MAX_LEN := 6

var _controller: GameController
var _buttons: Array[Button] = []
var _selected_crop_id: String = ""
var _cached_forbidden_set: Dictionary = {}  # set of Vector2i (forbidden cells); O(1) lookup per cell

func _ready() -> void:
	add_to_group("grid_view")
	_controller = get_tree().get_first_node_in_group("game_controller")
	if not _controller:
		return
	_controller.state_changed.connect(_on_state_changed)
	_controller.cell_changed.connect(_on_cell_changed)
	_controller.pest_telegraphed.connect(_on_pest_telegraphed)
	_build_grid()
	_refresh_all_cells()

func set_selected_crop(crop_id: String) -> void:
	_selected_crop_id = crop_id
	_refresh_all_cells()

func _build_grid() -> void:
	var state = _controller.state
	if not state:
		return
	var container := GridContainer.new()
	container.columns = state.size.x
	container.add_theme_constant_override("h_separation", GRID_GAP)
	container.add_theme_constant_override("v_separation", GRID_GAP)
	add_child(container)
	var soil_style := GameTheme.style_grid_cell()
	for y in state.size.y:
		for x in state.size.x:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			btn.add_theme_font_size_override("font_size", 12)
			btn.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
			btn.add_theme_color_override("font_disabled_color", GameTheme.TEXT_DARK)
			btn.add_theme_stylebox_override("normal", soil_style)
			btn.add_theme_stylebox_override("disabled", soil_style)
			btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			btn.clip_text = true
			btn.set_meta("pos", Vector2i(x, y))
			btn.pressed.connect(_on_cell_pressed.bind(Vector2i(x, y)))
			container.add_child(btn)
			_buttons.append(btn)
	var total: int = state.size.x * CELL_SIZE + (state.size.x - 1) * GRID_GAP
	var totaly: int = state.size.y * CELL_SIZE + (state.size.y - 1) * GRID_GAP
	custom_minimum_size = Vector2(total, totaly)

func _index_for(pos: Vector2i) -> int:
	return pos.y * _controller.state.size.x + pos.x

func _on_cell_pressed(pos: Vector2i) -> void:
	var cell = _controller.state.get_cell(pos)
	if cell and cell.remaining_grow <= 0:
		_controller.harvest(pos)
		return
	if not _selected_crop_id.is_empty() and cell == null:
		_controller.plant(pos, _selected_crop_id)

func _on_state_changed(_state: GameState) -> void:
	_refresh_all_cells()

func _on_cell_changed(pos: Vector2i, _cell_data) -> void:
	_refresh_cell(pos)

func _on_pest_telegraphed(_pos: Vector2i) -> void:
	_refresh_all_cells()

func _update_forbidden_cache() -> void:
	_cached_forbidden_set.clear()
	var state := _controller.state
	if not state or _selected_crop_id.is_empty():
		return
	for pos in state.get_forbidden_cells_for_crop(_selected_crop_id):
		_cached_forbidden_set[pos] = true

func _refresh_all_cells() -> void:
	var state = _controller.state
	if not state:
		return
	_update_forbidden_cache()
	for y in state.size.y:
		for x in state.size.x:
			_refresh_cell(Vector2i(x, y))

func _refresh_cell(pos: Vector2i) -> void:
	var idx := _index_for(pos)
	if idx < 0 or idx >= _buttons.size():
		return
	var btn: Button = _buttons[idx]
	var state = _controller.state
	var cell = state.get_cell(pos)
	var block_input: bool = _controller.game_ended or _controller.stage_clear_showing
	var is_telegraph: bool = state.has_pest_telegraph() and state.next_pest_target == pos
	if cell:
		var harvestable: bool = cell.remaining_grow <= 0
		if harvestable:
			btn.add_theme_stylebox_override("normal", GameTheme.style_grid_cell_harvestable())
			btn.add_theme_stylebox_override("disabled", GameTheme.style_grid_cell_harvestable())
			btn.disabled = block_input
		else:
			btn.add_theme_stylebox_override("normal", GameTheme.style_grid_cell())
			btn.add_theme_stylebox_override("disabled", GameTheme.style_grid_cell())
			btn.disabled = true
		var def = _controller.registry.get_def(cell.def_id)
		var name_str: String = (def.display_name if def else cell.def_id).substr(0, NAME_MAX_LEN)
		var sell: int = _controller.get_sell_price(pos)
		var line2: String = "G:%d $%d" % [cell.remaining_grow, sell]
		if harvestable:
			line2 += "\nHarvest!"
		var line3: String = ""
		if cell.has_pest:
			# Rose shows P:0/3 (counter never increases); other crops show progress
			line3 = "P:%d/3" % cell.pest_rounds
		elif is_telegraph:
			line3 = "!!"
		btn.text = "%s\n%s" % [name_str, line2] if line3.is_empty() else "%s\n%s\n%s" % [name_str, line2, line3]
	else:
		btn.text = "!!" if is_telegraph else ""
		btn.disabled = block_input
		var def = _controller.registry.get_def(_selected_crop_id) if not _selected_crop_id.is_empty() else null
		var can_afford: bool = def != null and state.money >= def.cost
		var is_forbidden: bool = _cached_forbidden_set.has(pos)
		var non_plantable: bool = not _selected_crop_id.is_empty() and can_afford and is_forbidden
		if non_plantable:
			btn.add_theme_stylebox_override("normal", GameTheme.style_grid_cell_non_plantable())
			btn.add_theme_stylebox_override("disabled", GameTheme.style_grid_cell_non_plantable())
		else:
			btn.add_theme_stylebox_override("normal", GameTheme.style_grid_cell())
			btn.add_theme_stylebox_override("disabled", GameTheme.style_grid_cell())
