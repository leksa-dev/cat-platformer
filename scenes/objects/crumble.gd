extends StaticBody2D
# Crumbling ledge (eroded slope, rotten stand bench): shakes once the cat stands on it, drops away after `delay` s,
# grows back after `respawn` s. Top-left at the node; a plain box, or `texture` (drawn at 1/3, its width wins) lying
# `surface` px above the walkable top.

@export var width_tiles := 2.0
@export var texture: Texture2D
@export var surface := 0.0
@export var delay := 0.5
@export var respawn := 3.0

var _t := -1.0  # time since the cat stepped on it; -1 = untouched
var _shape: CollisionShape2D
var _x0 := 0.0


func _ready() -> void:
	_x0 = position.x
	if texture:
		width_tiles = texture.get_width() / 48.0
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2.ONE / 3
		sprite.position.y = -surface
		add_child(sprite)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width_tiles * 16.0, 6)
	_shape = CollisionShape2D.new()
	_shape.shape = rect
	_shape.position = rect.size / 2
	_shape.one_way_collision = true
	add_child(_shape)


func _physics_process(delta: float) -> void:
	if _t < 0:
		var cat := get_tree().get_first_node_in_group("player") as CharacterBody2D
		var local := cat.global_position - global_position if cat else Vector2.INF
		if cat and cat.is_on_floor() and absf(local.y) < 2 and local.x > -4 and local.x < width_tiles * 16.0 + 4:
			_t = 0.0
		return
	_t += delta
	var gone := _t >= delay and _t < delay + respawn
	_shape.set_deferred("disabled", gone)
	visible = not gone
	position.x = _x0 + (sin(_t * 60.0) if _t < delay else 0.0)  # shake before it drops
	if _t >= delay + respawn:
		_t = -1.0


func _draw() -> void:
	if texture:
		return
	var w := width_tiles * 16.0
	draw_rect(Rect2(0, 0, w, 6), Color(0.55, 0.4, 0.25))
	for x in range(4, int(w), 6):
		draw_line(Vector2(x, 1), Vector2(x - 2, 5), Color(0.35, 0.25, 0.15))  # cracks
