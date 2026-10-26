extends Area2D
# Flag: touching it makes this the respawn point for the rest of the level (until the level changes).


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Sprite.frame = 1 if Game.checkpoint == global_position else 0


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and Game.checkpoint != global_position:
		Game.checkpoint = global_position
		Game.sfx("menu_select", 0.0)
		$Sprite.frame = 1
