extends Node2D

var children = []

var floater = 0.0
var up = true
var floatAmp = 10.0
var placement = Vector2(0.0, 0.0)
var seed = ""
var spacer = 0
var atlas = AtlasTexture.new()
var _controller: GameController
const NAME_MAX_LEN := 6


func _ready():
	_controller = get_tree().get_first_node_in_group("game_controller")
	self.position = Vector2(-64.0 + (32 * placement.x), -80.0 + (32 * placement.y))
	for child in self.get_children():
		children.append(child)
		if(child.name == "Sprite2D"):
			match seed:
				"pumpkin":
					spacer = 0
				"chili":
					spacer = 1
				"rose":
					spacer = 2
				"strawberry":
					spacer = 3
				"sunflower":
					spacer = 4
			atlas.atlas = load("res://art/plants-Sheet.png")
			atlas.region = Rect2(160.0 + (spacer * 32), 0.0, 32.0, 32.0)
			child.texture = atlas

func _process(delta):
	children[0].position = Vector2(children[0].position.x, children[0].position.y + (sin(floater) * delta * floatAmp))
	floater += 0.1 if up else -0.1
	if(floater > 360):
		up = false
	if(floater < 0):
		up = true
	atlas.region = Rect2(160.0 + (spacer * 32), 0.0, 32.0, 32.0)
	var st = _controller.state
	var cell = st.get_cell(placement)
	var sell: int = _controller.get_sell_price(placement)
	var line2: String = "G:%d $%d" % [cell.remaining_grow, sell]
	var harvestable: bool = cell.remaining_grow <= 0
	var is_telegraph: bool = st.has_pest_telegraph() and st.next_pest_target == placement
	if harvestable:
		line2 += "\nHarvest!"
	var line3: String = ""
	if cell.has_pest:
		# Rose shows P:0/3 (counter never increases); other crops show progress
		line3 = "P:%d/3" % cell.pest_rounds
	elif is_telegraph:
		line3 = "!!"
	var def = _controller.registry.get_def(cell.def_id)
	var name_str: String = (def.display_name if def else cell.def_id).substr(0, NAME_MAX_LEN)
	children[1].text = "%s\n%s" % [name_str, line2] if line3.is_empty() else "%s\n%s\n%s" % [name_str, line2, line3]
