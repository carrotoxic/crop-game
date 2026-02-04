class_name GridRules
extends RefCounted

static func in_bounds(size: Vector2i, pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < size.x and pos.y < size.y

static func chebyshev_dist(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))

static func cells_in_chebyshev(size: Vector2i, pos: Vector2i, radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx == 0 and dy == 0:
				continue
			var p: Vector2i = Vector2i(pos.x + dx, pos.y + dy)
			if in_bounds(size, p) and chebyshev_dist(pos, p) <= radius:
				out.append(p)
	return out

static func four_neighbors(size: Vector2i, pos: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var p: Vector2i = pos + d
		if in_bounds(size, p):
			out.append(p)
	return out

# Cells on horizontal and vertical (orthogonal) rays from pos, up to range_dist steps each way.
static func cells_orthogonal(size: Vector2i, pos: Vector2i, range_dist: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for d in dirs:
		for step in range(1, range_dist + 1):
			var p: Vector2i = Vector2i(pos.x + d.x * step, pos.y + d.y * step)
			if not in_bounds(size, p):
				break
			out.append(p)
	return out

static func diag_rays_from(size: Vector2i, pos: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for step in [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
		var p: Vector2i = pos + step
		while in_bounds(size, p):
			out.append(p)
			p += step
	return out

static func connected_component_4dir(grid: Array, size: Vector2i, start: Vector2i, def_id: String) -> Array[Vector2i]:
	var visited: Array[Vector2i] = []
	var stack: Array[Vector2i] = [start]
	var seen: Dictionary = {}
	seen[Vector2i(start.x, start.y)] = true
	while stack.size() > 0:
		var cur: Vector2i = stack.pop_back()
		visited.append(cur)
		for n in four_neighbors(size, cur):
			if seen.get(Vector2i(n.x, n.y), false):
				continue
			var cell = cell_at(grid, size, n)
			if cell and cell.get("def_id") == def_id:
				seen[Vector2i(n.x, n.y)] = true
				stack.append(n)
	return visited

static func cell_at(grid: Array, size: Vector2i, pos: Vector2i):
	if not in_bounds(size, pos):
		return null
	return grid[pos.y][pos.x]
