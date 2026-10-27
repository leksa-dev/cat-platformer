extends Node2D
# Beach bar = pharmacy: the cat walks up to the counter, has a drink and gets its HP back.
# At the counter the jump button orders another drink, as many as you like (a secret: no hint mentions it).


func _ready() -> void:
	$Counter.body_entered.connect(_on_counter)
	$Counter.body_exited.connect(func(body): if "at_bar" in body: body.at_bar = false)


func _on_counter(body: Node2D) -> void:
	if "at_bar" in body:
		body.at_bar = true
	if body.has_method("drink") and body.hp < body.max_hp:
		body.drink()
