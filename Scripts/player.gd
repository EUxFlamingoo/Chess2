extends Control

func _enter_tree():
	set_multiplayer_authority(name.to_int())

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
