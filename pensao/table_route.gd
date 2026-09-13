extends RefCounted
## Table top: x +/-1.25, z -0.45..1.05; add 0.55 m for the actor's body.
const BLOCKED := AABB(Vector3(-1.8, -1, -1.0), Vector3(3.6, 3, 2.6))
const CORNERS := [Vector3(-1.86, 0, -1.06), Vector3(1.86, 0, -1.06), Vector3(1.86, 0, 1.66), Vector3(-1.86, 0, 1.66)]

static func clear_segment(a: Vector3, b: Vector3) -> bool:
	return BLOCKED.intersects_segment(a, b) == null

static func walkable_segment(a: Vector3, b: Vector3, obstacles: Array[Vector3]) -> bool:
	if not clear_segment(a, b): return false
	for obstacle in obstacles:
		var nearest := Geometry3D.get_closest_point_to_segment(obstacle, a, b)
		if nearest.distance_to(obstacle) < 0.9: return false
	return true

static func path(start: Vector3, target: Vector3, obstacles: Array[Vector3] = []) -> Array[Vector3]:
	if BLOCKED.has_point(start) or BLOCKED.has_point(target):
		return []
	if walkable_segment(start, target, obstacles):
		return [target]
	# Include passing points around people when the cached route is blocked.
	var nodes: Array[Vector3] = [start, target]
	nodes.append_array(CORNERS)
	for obstacle in obstacles:
		for i in range(8):
			var point := obstacle + Vector3(cos(i*TAU/8), 0, sin(i*TAU/8))*1.08
			if absf(point.x) <= 4.8 and point.z >= -3.4 and point.z <= 3.4 and not BLOCKED.has_point(point):
				nodes.append(point)
	var costs: Array[float] = []
	costs.resize(nodes.size())
	costs.fill(INF)
	costs[0] = 0.0
	var previous: Array[int] = []
	previous.resize(nodes.size())
	previous.fill(-1)
	var visited: Array[int] = []
	for iteration in range(nodes.size()):
		var current := -1
		for i in range(nodes.size()):
			if i not in visited and (current == -1 or costs[i] < costs[current]):
				current = i
		if current == -1 or costs[current] == INF:
			break
		if current == 1:
			var result: Array[Vector3] = []
			while current != 0:
				result.push_front(nodes[current])
				current = previous[current]
			return result
		visited.append(current)
		for i in range(nodes.size()):
			if i in visited or not walkable_segment(nodes[current], nodes[i], obstacles):
				continue
			var cost := costs[current] + nodes[current].distance_to(nodes[i])
			if cost < costs[i]:
				costs[i] = cost
				previous[i] = current
	return []
