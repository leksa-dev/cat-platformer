extends SceneTree
# Level layout audit (headless): collects every walkable surface (ground tiles, floating blocks, pillars, crumbling
# ledges) and climbable poles, floods outward from the spawn with the cat's jump reach and writes surfaces, poles and
# pickups with a `reach` flag to the given JSON. Usage: godot --headless --script tools/audit_level.gd -- <level index> <out.json>
# Reach is an estimate: up <= 36 px, sideways gap <= ~50 px (less when jumping up), drops widen it; no wall-jumps.

const STEP_UP := 36.0
var tsz_ := 16.0
var surfaces := []   # {x0, x1, y, kind, name}
var poles := []      # {x, y0, y1, name}
var solid := {}
var org := Vector2.ZERO
var pillar_h := {}  # surface index -> pillar height


func gap(a0: float, a1: float, b0: float, b1: float) -> float:
	return maxf(0.0, maxf(b0 - a1, a0 - b1))


func can_jump(a: Dictionary, b: Dictionary) -> bool:
	var dy: float = a.y - b.y  # > 0: b is higher
	var g := gap(a.x0 - 4, a.x1 + 4, b.x0, b.x1)
	if dy > STEP_UP:
		return false
	if dy >= 0:
		return g <= 52.0 - dy * 0.5
	return g <= 52.0 + minf(-dy, 160.0) * 0.45


# The cat wall-jumps without limit (every kick is a full jump), so a plain wall is climbable at any height: ground
# runs that touch sideways are joined when the taller one is a solid wall down to the lower, and pillars can be
# climbed from a surface within reach of their side.
func wall_climb(a: Dictionary, bi: int) -> bool:
	var b: Dictionary = surfaces[bi]
	if a.y <= b.y:
		return false
	if b.kind == "pillar":
		return gap(a.x0 - 4, a.x1 + 4, b.x0, b.x1) <= 26.0 and a.y - b.y <= pillar_h.get(bi, 0.0) + 8.0
	if a.kind == "ground" and b.kind == "ground" and (absf(a.x1 - b.x0) < 0.5 or absf(b.x1 - a.x0) < 0.5):
		var col_b := int(roundf(((b.x0 if absf(a.x1 - b.x0) < 0.5 else b.x1 - tsz_) - org.x) / tsz_))
		var col_a := col_b - 1 if absf(a.x1 - b.x0) < 0.5 else col_b + 1
		var r0 := int(roundf((b.y - org.y) / tsz_))
		var r1 := int(roundf((a.y - org.y) / tsz_))
		for r in range(r0, r1):
			if not solid.has(Vector2i(col_b, r)) or solid.has(Vector2i(col_a, r)):
				return false
		return true
	return false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var G = root.get_node("Game")
	G.level_index = int(args[0])
	change_scene_to_file("res://scenes/level/level_%02d.tscn" % (int(args[0]) + 1))
	for i in 10:
		await physics_frame
	var lvl = current_scene
	var ground = lvl.find_child("Ground")
	for c in ground.get_used_cells():
		var td = ground.get_cell_tile_data(c)
		if td and td.get_collision_polygons_count(0) > 0:
			solid[c] = true
	var tsz := 16.0
	var o: Vector2 = ground.to_global(ground.map_to_local(Vector2i.ZERO)) - Vector2(8, 8)
	org = o
	var cells := solid.keys()
	cells.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
	var run = null
	for c in cells:
		if solid.has(c + Vector2i(0, -1)):
			continue
		var x0: float = o.x + c.x * tsz
		var y: float = o.y + c.y * tsz
		if run and run.y == y and absf(run.x1 - x0) < 0.5:
			run.x1 = x0 + tsz
		else:
			run = {"x0": x0, "x1": x0 + tsz, "y": y, "kind": "ground", "name": "ground"}
			surfaces.append(run)
	for n in lvl.level_objects():
		var sc: String = n.get_script().resource_path if n.get_script() else ""
		if n is Area2D and n.collision_layer & 2:
			var sh = n.get_node_or_null("Shape")
			if sh and sh.shape is RectangleShape2D:
				var gp: Vector2 = sh.global_position
				poles.append({"x": gp.x, "y0": gp.y - sh.shape.size.y / 2, "y1": gp.y + sh.shape.size.y / 2, "name": str(n.name)})
		elif sc.ends_with("float_platform.gd"):
			var piece: float = n.texture.get_width() / 3.0 if n.texture else n.ledge_width
			var w: float = piece * n.count
			surfaces.append({"x0": n.global_position.x - w / 2 + 2, "x1": n.global_position.x + w / 2 - 2, "y": n.global_position.y, "kind": "block", "name": str(n.name)})
		elif sc.ends_with("pillar.gd"):
			var w: float = n.width_tiles * 16.0 if n.width_tiles > 0 else n.texture.get_width() / 3.0
			pillar_h[surfaces.size()] = n.height_tiles * 16.0
			surfaces.append({"x0": n.global_position.x - w / 2 + 1, "x1": n.global_position.x + w / 2 - 1, "y": n.global_position.y, "kind": "pillar", "name": str(n.name)})
		elif sc.ends_with("crumble.gd"):
			var w: float = n.texture.get_width() / 3.0 if n.texture else n.width_tiles * 16.0
			surfaces.append({"x0": n.global_position.x, "x1": n.global_position.x + w, "y": n.global_position.y, "kind": "crumble", "name": str(n.name)})
	# flood from the spawn
	var spawn: Vector2 = lvl.find_child("Spawn").global_position
	var start := -1
	var best := 1e9
	for i in surfaces.size():
		var s = surfaces[i]
		if spawn.x >= s.x0 - 2 and spawn.x <= s.x1 + 2 and s.y >= spawn.y - 4 and s.y - spawn.y < best:
			best = s.y - spawn.y
			start = i
	var ns := surfaces.size()
	var seen_s := {}
	var seen_p := {}
	var queue := [["s", start]]
	seen_s[start] = true
	while not queue.is_empty():
		var cur = queue.pop_front()
		if cur[0] == "s":
			var a = surfaces[cur[1]]
			for j in ns:
				if not seen_s.has(j) and (can_jump(a, surfaces[j]) or wall_climb(a, j)):
					seen_s[j] = true; queue.append(["s", j])
			for k in poles.size():  # grab a pole standing at it
				var p = poles[k]
				if not seen_p.has(k) and p.x >= a.x0 - 8 and p.x <= a.x1 + 8 and a.y >= p.y0 - 2 and a.y <= p.y1 + 6:
					seen_p[k] = true; queue.append(["p", k])
		else:
			var p = poles[cur[1]]
			for j in ns:  # off a pole: sideways jump or hop up/over its top
				var s = surfaces[j]
				if not seen_s.has(j) and s.y >= p.y0 - STEP_UP and s.y <= p.y1 + 4 and gap(p.x, p.x, s.x0, s.x1) <= 44.0:
					seen_s[j] = true; queue.append(["s", j])
			for k in poles.size():
				var q = poles[k]
				if not seen_p.has(k) and absf(q.x - p.x) <= 44.0 and q.y1 >= p.y0 and q.y0 <= p.y1:
					seen_p[k] = true; queue.append(["p", k])
	var out := {"surfaces": [], "poles": [], "pickups": [], "start": start}
	for i in ns:
		var s: Dictionary = surfaces[i].duplicate()
		s["reach"] = seen_s.has(i)
		out.surfaces.append(s)
	for k in poles.size():
		var p: Dictionary = poles[k].duplicate()
		p["reach"] = seen_p.has(k)
		out.poles.append(p)
	for n in lvl.level_objects():
		var nm := str(n.name)
		if nm.begins_with("Coin") or nm.begins_with("Diamond") or nm.begins_with("Life"):
			var pp: Vector2 = n.global_position
			var ok := false
			for i in ns:
				var s = surfaces[i]
				if seen_s.has(i) and pp.x >= s.x0 - 16 and pp.x <= s.x1 + 16 and pp.y <= s.y + 6 and s.y - pp.y <= 46:
					ok = true
			for k in poles.size():
				var p = poles[k]
				if seen_p.has(k) and absf(pp.x - p.x) <= 22 and pp.y >= p.y0 - 40 and pp.y <= p.y1:
					ok = true
			out.pickups.append({"name": nm, "x": pp.x, "y": pp.y, "reach": ok})
	var f := FileAccess.open(args[1], FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	quit()
