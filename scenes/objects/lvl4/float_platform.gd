@tool
extends StaticBody2D
# Floating grass block (art from the Kopiec sheet, drawn at 1/3): the node is the top-centre of the walkable grass;
# `surface` is how far the grass tufts stick up above it. The top is one-way, so the cat can jump up through it; below it the
# body of the block (`body_depth` px, 0 = none, a core `body_inset` px in from each end) is solid, so the cat can slide down
# its sides and wall-jump off it; the overhanging ends stay open, so it can still jump up past the edge onto a platform above.

@export var texture: Texture2D:
	set(value):
		texture = value
		_build()
@export var surface := 4.0:
	set(value):
		surface = value
		_build()
@export var ledge_width := 0.0:  # no texture: an invisible ledge this wide (cornices, gables on a backdrop building)
	set(value):
		ledge_width = value
		_build()
@export var body_depth := -1.0:  # -1 = the sprite's height below the walkable top, minus a little; 0 = a bare one-way ledge
	set(value):
		body_depth = value
		_build()
@export var body_inset := 8.0
@export var gap_x := INF   # x (local, px) of a climbable pole running through the block: the body leaves a gap there
@export var count := 1:  # the block repeated side by side, for longer platforms (footbridge deck, long ledges)
	set(value):
		count = maxi(value, 1)
		_build()


func _ready() -> void:
	_build()


func _build() -> void:
	if not is_inside_tree() or (texture == null and ledge_width <= 0):
		return
	for c in get_children():
		c.free()
	var piece := texture.get_width() / 3.0 if texture else ledge_width
	var w := piece * count
	for i in count if texture else 0:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2.ONE / 3
		sprite.position = Vector2(-w / 2 + i * piece, -surface)
		add_child(sprite)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w - 4, 6)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0, 3)
	shape.one_way_collision = true
	add_child(shape)
	var depth := body_depth
	if depth < 0:
		depth = maxf(texture.get_height() / 3.0 - surface - 8.0, 0.0) if texture else 0.0
	if depth > 0:
		var x0 := -w / 2 + 2 + body_inset
		var x1 := w / 2 - 2 - body_inset
		var spans := [[x0, x1]]
		if gap_x != INF and gap_x > x0 - 9 and gap_x < x1 + 9:   # a pole by the edge needs the gap too
			spans = [[x0, gap_x - 9], [gap_x + 9, x1]]
		for span in spans:
			if span[1] - span[0] < 4.0:
				continue
			var body := RectangleShape2D.new()
			body.size = Vector2(span[1] - span[0], depth)
			var side := CollisionShape2D.new()
			side.shape = body
			side.position = Vector2((span[0] + span[1]) / 2, 6 + depth / 2)   # right under the one-way top
			add_child(side)
