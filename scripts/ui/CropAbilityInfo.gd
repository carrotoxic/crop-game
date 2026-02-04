class_name CropAbilityInfo
extends RefCounted

const GRID_CENTER := Vector2i(2, 2)

static func get_ability_text(crop_id: String) -> String:
	match crop_id:
		"pumpkin":
			return "Pumpkin:\nCost: 3  Sells: 5  Grows: 5\nIf no crops within 1 tile when planted: grows 1 turn faster."
		"chili":
			return "Chili:\nCost: 2  Sells: 2  Grows: 6\nImmune to pests. On plant: removes pests from crops in horizontal and vertical lines, range 2."
		"rose":
			return "Rose:\nCost: 4  Sells: 15  Grows: 6\nPlants in the 8 cells around it cannot be infested by pest. Rose can get pest and can be destroyed by pest (3 rounds). Pest on Rose cannot be removed (e.g. by Chili)."
		"strawberry":
			return "Strawberry:\nCost: 3  Sells: 5  Grows: 5\nSell price +1 for each connected Strawberry (N/E/S/W)."
		"sunflower":
			return "Sunflower:\nCost: 4  Sells: 7  Grows: 5\nSell price +2 for each plant on its 4 diagonal lines."
	return ""

static func get_effect_cells(crop_id: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var c := GRID_CENTER
	match crop_id:
		"pumpkin":
			out.append(c)
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx != 0 or dy != 0:
						out.append(Vector2i(c.x + dx, c.y + dy))
		"chili":
			out.append(c)
			for step in range(1, 3):
				out.append(Vector2i(c.x, c.y - step))
				out.append(Vector2i(c.x + step, c.y))
				out.append(Vector2i(c.x, c.y + step))
				out.append(Vector2i(c.x - step, c.y))
		"rose":
			out.append(c)
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx != 0 or dy != 0:
						out.append(Vector2i(c.x + dx, c.y + dy))
		"strawberry":
			out.append(c)
			out.append(Vector2i(c.x, c.y - 1))
			out.append(Vector2i(c.x + 1, c.y))
			out.append(Vector2i(c.x, c.y + 1))
			out.append(Vector2i(c.x - 1, c.y))
		"sunflower":
			out.append(c)
			for i in range(1, 3):
				for sx in [-1, 1]:
					for sy in [-1, 1]:
						var p := Vector2i(c.x + sx * i, c.y + sy * i)
						if p.x >= 0 and p.x < 5 and p.y >= 0 and p.y < 5:
							out.append(p)
	return out

static func is_center_cell(crop_id: String, local: Vector2i) -> bool:
	return local == GRID_CENTER
