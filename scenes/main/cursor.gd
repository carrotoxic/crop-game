extends AnimatedSprite2D

const CELL_SIZE := 88
const GRID_GAP := 4
const NAME_MAX_LEN := 6

var _controller: GameController
var _selected_crop_id: String = ""
var _cached_forbidden_set: Dictionary = {}  # set of Vector2i (forbidden cells); O(1) lookup per cell
var currPos = Vector2i(0, 0)
var mode = 0

func _ready() -> void:
	_controller = get_tree().get_first_node_in_group("game_controller")
	if not _controller:
		return

func set_selected_crop(crop_id: String) -> void:
	_selected_crop_id = crop_id

func _index_for(pos: Vector2i) -> int:
	return pos.y * _controller.state.size.x + pos.x

func _process(delta):
	if Input.is_action_just_pressed("move_forward") and currPos.y > 0 and mode == 1:
		currPos.y -= 1
	elif Input.is_action_just_pressed("move_backward") and currPos.y < 4 and mode == 1:
		currPos.y += 1
	elif Input.is_action_just_pressed("move_left") and currPos.x > 0:
		currPos.x -= 1
	elif Input.is_action_just_pressed("move_right") and currPos.x < 4:
		currPos.x += 1
	if Input.is_action_just_pressed("exit") and mode == 1:
		mode = 0
		currPos.x = 0
		currPos.y = 0
	elif Input.is_action_just_pressed("select"):
		if mode == 1:
			var cell = _controller.state.get_cell(currPos)
			if cell and cell.remaining_grow <= 0:
				_controller.harvest(currPos)
				var check = get_parent().get_node("Pointers").get_children()
				for c in check:
					print(str(c.position.x) + ", " + str(c.position.y))
					print(str(currPos.x*32) + ", " + str(currPos.y*32))
					if c.position.x == -64.0 + currPos.x*32 and (c.position.y  < -64 +(currPos.y*32) - 11.0 and c.position.y > -64 + (currPos.y*32) - 21.0):
						print("work")
						c.free()
						break
				
				return
			if not _selected_crop_id.is_empty() and cell == null:
				_controller.plant(currPos, _selected_crop_id)
		elif mode == 0:
			mode = 1
			match currPos.x:
				0:
					_selected_crop_id = "pumpkin"
				1:
					_selected_crop_id = "chili"
				2:
					_selected_crop_id = "rose"
				3:
					_selected_crop_id = "strawberry"
				4:
					_selected_crop_id = "sunflower"
			currPos.x = 0
			currPos.y = 0
			Global.last_crop = -1
	if mode == 0:
		Global.last_crop = currPos.x
	var baseY = -64 if mode == 1 else 160
	self.position = Vector2(-64.0 + (32.0 * currPos.x), baseY + (32.0 * currPos.y))
