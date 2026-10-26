extends Area2D
# Half coconut lying around (reward spots): heals when the cat needs it.

@export var heal := 2

var _t := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	$Sprite.position.y = -8 + sin(_t * 3.0)  # gentle bob so it reads as a pickup


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.hp < body.max_hp:
		body.heal(heal)
		queue_free()
