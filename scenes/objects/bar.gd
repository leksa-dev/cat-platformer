extends Node2D
# Beach bar = pharmacy: the cat walks up to the counter, has a drink and gets its HP back.


func _ready() -> void:
	$Counter.body_entered.connect(_on_counter)


func _on_counter(body: Node2D) -> void:
	if body.has_method("drink") and body.hp < body.max_hp:
		body.drink()
