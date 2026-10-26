extends Area2D
# Invisible tip: the first time the cat walks past, the HUD shows `text` in the dialog box for a few seconds.

@export_multiline var text := ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Game.hint.emit(text)
		queue_free()  # once per level load
