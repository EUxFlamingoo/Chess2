extends Node2D

const GAME_MANAGER = preload("res://Scenes/Managers/game_manager.tscn")
const MOVE_MANAGER = preload("res://Scenes/Managers/move_manager.tscn")
const NETWORK_MANAGER = preload("res://Scenes/Managers/network_manager.tscn")
const TURN_MANAGER = preload("res://Scenes/Managers/turn_manager.tscn")
const UNIT_MANAGER = preload("res://Scenes/Managers/unit_manager.tscn")

@onready var start_game: Button = $CanvasLayer/VBoxContainer/StartGame
@onready var options: Button = $CanvasLayer/VBoxContainer/Options
@onready var quit: Button = $CanvasLayer/VBoxContainer/Quit


func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/GameStart.tscn")

func _on_options_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	pass # Replace with function body.

func _ready() -> void:
	BoardManager.selecting_ok = false
