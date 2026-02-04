extends Node2D

var children = []

var floater = 0.0
var up = true
var floatAmp = 10.0
var placement = Vector2(0.0, 0.0)
var seed = ""
var spacer = 0
var atlas = AtlasTexture.new()


func _ready():
	self.self_modulate.a = 0.75
	for child in self.get_children():
		children.append(child)
		self.position = Vector2(-64.0 + (32 * placement.x), -80.0 + (32 * placement.y))
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
	self.position = Vector2(self.position.x, self.position.y + (sin(floater) * delta * floatAmp))
	floater += 0.1 if up else -0.1
	if(floater > 360):
		up = false
	if(floater < 0):
		up = true
	atlas.region = Rect2(160.0 + (spacer * 32), 0.0, 32.0, 32.0)
	
