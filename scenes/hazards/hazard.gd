extends Node2D
# Something that hurts the cat on touch (cactus, sea rock, shark, fish). Subclasses move it in _move(delta).

@export var damage := 1
@export var hit_size := Vector2(10, 10)  # hit rect centred at hit_offset
@export var hit_offset := Vector2(0, -5)

var active := true


func _physics_process(delta: float) -> void:
	_move(delta)
	if active:
		hit_cat()


func _move(_delta: float) -> void:
	pass


func hit_cat() -> bool:
	var shape := RectangleShape2D.new()
	shape.size = hit_size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position + hit_offset)
	query.collision_mask = 1
	for result in get_world_2d().direct_space_state.intersect_shape(query):
		if result.collider.is_in_group("player"):
			result.collider.take_damage(damage, global_position)
			return true
	return false
