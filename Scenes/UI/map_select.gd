extends Node2D

const MAP_1 = preload("res://Scenes/maps/map1.tscn") # Add this line

@onready var map_1_button: Button = $CanvasLayer/MapsBox/Map1Button
@onready var home_1_button: Button = $CanvasLayer/MapsBox/Home1Button



func _on_map_1_button_pressed() -> void:
	GameManager.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/maps/BattleMaps/map1.tscn")






func _on_home_1_button_pressed() -> void:
	GameManager.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/maps/HomeMaps/home1.tscn")
