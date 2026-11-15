extends "res://scenes/enemies/boar/boar.gd"
# Swan on the Wisła quays (placeholder art: the duck sheet whitened): guards its patch, hisses (the boar's wind-up) and charges
# with its wings out. Same AI as the boar; only the frames differ.


func _ready() -> void:
	super._ready()
	# duck.png layout: float 0-3, swim 4-9, walk 10-15, peck 16-19, hurt 20-22, death 23-26
	anims = {"idle": [0, 1, 2, 3], "run": [10, 11, 12, 13, 14, 15], "attack": [16, 17, 18, 19], "hurt": [20, 21, 22], "death": [23, 24, 25, 26]}
	play("run")
