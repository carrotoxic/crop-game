class_name GameController
extends Node

signal state_changed(state: GameState)
signal cell_changed(pos: Vector2i, cell_data)
signal pest_telegraphed(pos: Vector2i)
signal stage_changed(stage_index: int)
signal stage_cleared(stage_index: int)
signal game_over(won: bool, reason: String)

var state: GameState
var config: GameConfig
var registry: CropRegistry
var game_ended: bool = false
var stage_clear_showing: bool = false

var plant_pointer = preload("res://scenes/main/plant_pointer.tscn")
var pest = preload("res://scenes/main/pests.tscn")
var blocked = preload("res://scenes/main/blocker.tscn")

func _ready() -> void:
	add_to_group("game_controller")
	config = load("res://data/config/game_config.tres") as GameConfig
	if not config:
		config = GameConfig.new()
	registry = CropRegistry.new()
	state = GameState.new(config)
	state.money = config.initial_money
	state_changed.emit(state)

func can_plant(cell: Vector2i, crop_id: String) -> bool:
	if game_ended or stage_clear_showing:
		return false
	var def := registry.get_def(crop_id)
	if not def or state.get_cell(cell) != null:
		return false
	if state.is_cell_forbidden_for_crop(cell, crop_id):
		print("failed")
		return false
	return state.money >= def.cost

func plant(cell: Vector2i, crop_id: String) -> bool:
	if game_ended or stage_clear_showing:
		return false
	if not can_plant(cell, crop_id):
		return false
	var def := registry.get_def(crop_id)
	state.money -= def.cost
	var inst := CropInstance.new(crop_id, def.grow_time)
	# Pumpkin: GT-1 if no crops within 1 grid
	if def.type_enum == CropDef.Type.PUMPKIN:
		var neighbors := GridRules.cells_in_chebyshev(state.size, cell, def.pumpkin_isolation_radius)
		var isolated := true
		for p in neighbors:
			if state.get_cell(p) != null:
				isolated = false
				break
		if isolated:
			inst.remaining_grow = maxi(1, def.grow_time - 2)
	# Chili: remove pests in orthogonal range 2 (cannot remove pest from rose)
	if def.type_enum == CropDef.Type.CHILI:
		var in_range: Array[Vector2i] = GridRules.cells_orthogonal(state.size, cell, def.chili_clean_radius)
		in_range.append(cell)
		for p in in_range:
			var c = state.get_cell(p)
			if not c or not c.has_pest:
				continue
			if String(c.def_id) == "rose":
				continue  # Rose pest cannot be removed by any means
			c.has_pest = false
			set_pests_visual()
			c.pest_rounds = 0
	# Clear this cell from every crop's forbidden list (planting something else here frees it for other crops)
	state.remove_forbidden_for_cell(cell)
	state.set_cell(cell, inst)
	state.add_forbidden(cell, crop_id)
	cell_changed.emit(cell, inst)
	state_changed.emit(state)
	var temp = plant_pointer.instantiate()
	temp.placement = cell
	temp.seed = crop_id
	get_parent().get_node("Node2D").get_node("Pointers").add_child(temp)
	return true

func harvest(cell: Vector2i) -> bool:
	if game_ended or stage_clear_showing:
		return false
	var c = state.get_cell(cell)
	if not c or c.remaining_grow > 0:
		return false
	var price: int = _harvest_price(cell, c)
	state.money += price
	state.clear_cell(cell)
	cell_changed.emit(cell, null)
	state_changed.emit(state)
	var check = get_parent().get_node("Node2D").get_node("Pointers").get_children()
	for child in check:
		if child.placement.x == cell.x and child.placement.y == cell.y:
			child.free()
			break;
	return true

func update_plantable():
	var st := state
	var block = _get_cells_with_block(st)
	var check = $"../Node2D/Blocked"
	var children = check.get_children()
	for child in children:
			child.free()
	if(block.size() > 0):
		for c in block:
			var temp = blocked.instantiate()
			temp.position = Vector2(-64.0 + 32 * c.x, -64.0 + 32 * c.y)
			check.add_child(temp)

func set_pests_visual():
	var st := state
	var infected = _get_cells_with_pests(st)
	var check = $"../Node2D/PestsHome"
	var children = check.get_children()
	for child in children:
			child.free()
	if(infected.size() > 0):
		for c in infected:
			var temp = pest.instantiate()
			temp.position = Vector2(-64.0 + 32 * c.x, -64.0 + 32 * c.y)
			check.add_child(temp)
			
func visual_harvest_change(pos):
	var check = get_parent().get_node("Node2D").get_node("Pointers").get_children()
	for child in check:
		if child.placement.x == pos.x and child.placement.y == pos.y:
			child.spacer -= 5
			child.self_modulate.a = 1.0
			break;

func end_turn() -> void:
	if game_ended or stage_clear_showing:
		return
	var cfg := config
	var st := state
	# Step 1: apply telegraphed pest; cells in 1 range of Rose are protected; Chili immune; only apply if cell doesn't already have pest
	if st.global_turn >= cfg.pest_start_turn and st.has_pest_telegraph():
		var target: Vector2i = st.next_pest_target
		var protected_set: Dictionary = _get_cells_protected_by_rose(st)
		if not protected_set.has(target):
			var c = st.get_cell(target)
			if c and c.def_id != "chili" and c.remaining_grow > 0 and not c.has_pest:
				c.has_pest = true
				c.pest_rounds = 0
		st.next_pest_target = Vector2i(-1, -1)

	# Step 2: pest rounds + destroy (Rose can be destroyed by pest like others; pest on Rose cannot be removed)
	for y in st.size.y:
		for x in st.size.x:
			var p: Vector2i = Vector2i(x, y)
			var c = st.get_cell(p)
			if c and c.has_pest:
				c.pest_rounds += 1
				if c.pest_rounds >= cfg.pest_destroy_rounds:
					st.clear_cell(p)
					cell_changed.emit(p, null)
					var check = get_parent().get_node("Node2D").get_node("Pointers").get_children()
					for child in check:
						if child.placement.x == p.x and child.placement.y == p.y:
							child.free()
							break;
					c.has_pest = false

	# Step 3: growth tick (pest blocks growth)
	for y in st.size.y:
		for x in st.size.x:
			var pos: Vector2i = Vector2i(x, y)
			var c = st.get_cell(pos)
			if c and not c.has_pest and c.remaining_grow > 0:
				c.remaining_grow -= 1
				if c.remaining_grow <= 0:
					visual_harvest_change(pos)

	# Step 4: no auto-harvest; player harvests by clicking harvestable cells

	# Step 5: stage end check before incrementing (so display stays 10/10 when showing popup)
	if st.turn_in_stage == 10:
		if st.money >= st.stage_requirements[st.stage_index]:
			if st.stage_index == 4:
				game_ended = true
				state_changed.emit(state)
				game_over.emit(true, "You are the Master Gardener")
				return
			stage_clear_showing = true
			state_changed.emit(state)
			stage_cleared.emit(st.stage_index)
			return
		else:
			game_ended = true
			state_changed.emit(state)
			game_over.emit(false, "Stage requirement not met by turn 10.")
			return

	# Step 6: advance turn counters
	st.global_turn += 1
	st.turn_in_stage += 1

	# Step 7: next pest telegraph; cells protected by Rose (range 1) cannot be targeted; Chili and harvestable not targeted
	if st.global_turn + 1 >= cfg.pest_start_turn:
		var protected_set: Dictionary = _get_cells_protected_by_rose(st)
		var candidates: Array[Vector2i] = []
		for y in st.size.y:
			for x in st.size.x:
				var p: Vector2i = Vector2i(x, y)
				if protected_set.has(p):
					continue
				var c = st.get_cell(p)
				if not c or c.def_id == "chili" or c.remaining_grow <= 0 or c.has_pest:
					continue
				candidates.append(p)
		if candidates.size() > 0:
			st.next_pest_target = candidates[st.rng.randi() % candidates.size()]
			pest_telegraphed.emit(st.next_pest_target)
		else:
			st.next_pest_target = Vector2i(-1, -1)
	
	set_pests_visual()

	state_changed.emit(state)

func continue_to_next_stage() -> void:
	stage_clear_showing = false
	state.stage_index += 1
	state.turn_in_stage = 1
	stage_changed.emit(state.stage_index)
	state_changed.emit(state)

func _get_cells_protected_by_rose(st: GameState) -> Dictionary:
	var protected: Dictionary = {}
	for y in st.size.y:
		for x in st.size.x:
			var p: Vector2i = Vector2i(x, y)
			var c = st.get_cell(p)
			if c and c.def_id == "rose":
				for q in GridRules.cells_in_chebyshev(st.size, p, 1):
					protected[q] = true
	return protected

func _get_cells_with_pests(st: GameState):
	var infected = []
	for y in st.size.y:
		for x in st.size.x:
			var p: Vector2i = Vector2i(x, y)
			var c = st.get_cell(p)
			if c != null and c.has_pest:
				infected.append(Vector2(x, y))
	return infected
	
func _get_cells_with_block(st: GameState):
	var block = []
	for y in st.size.y:
		for x in st.size.x:
			var p: Vector2i = Vector2i(x, y)
			var c = st.get_cell(p)
			if st.is_cell_forbidden_for_crop(p, Global.last_crop):
				block.append(Vector2(x, y))
	return block

func get_sell_price(pos: Vector2i) -> int:
	var c = state.get_cell(pos)
	if not c:
		return 0
	return _harvest_price(pos, c)

func _harvest_price(pos: Vector2i, crop: CropInstance) -> int:
	var def := registry.get_def(crop.def_id)
	if not def:
		return 0
	var price := def.base_price
	if crop.def_id == "strawberry":
		var comp := GridRules.connected_component_4dir(state.grid, state.size, pos, "strawberry")
		price += comp.size() - 1
	if crop.def_id == "sunflower":
		var diag: Array[Vector2i] = GridRules.diag_rays_from(state.size, pos)
		for i in range(diag.size()):
			var p: Vector2i = diag[i]
			if state.get_cell(p) != null:
				price += 1
	return price

func restart() -> void:
	game_ended = false
	stage_clear_showing = false
	state = GameState.new(config)
	state.money = config.initial_money
	state_changed.emit(state)
	stage_changed.emit(0)
	for y in state.size.y:
		for x in state.size.x:
			cell_changed.emit(Vector2i(x, y), null)
	# Set initial pest telegraph for turn 3 if any crops
	if state.global_turn + 2 >= config.pest_start_turn:
		var candidates: Array[Vector2i] = []
		for yy in state.size.y:
			for xx in state.size.x:
				var p: Vector2i = Vector2i(xx, yy)
				if state.get_cell(p) != null:
					candidates.append(p)
		if candidates.size() > 0:
			state.next_pest_target = candidates[state.rng.randi() % candidates.size()]
			pest_telegraphed.emit(state.next_pest_target)
	var check = $"../Node2D/PestsHome"
	var check2 = $"../Node2D/Pointers"
	var children = check.get_children()
	for child in children:
			child.free()
	children = check2.get_children()
	for child in children:
		child.free()
	state_changed.emit(state)
