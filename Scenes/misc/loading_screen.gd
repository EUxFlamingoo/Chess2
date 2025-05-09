extends Node2D

const MAP_1 = preload("res://Scenes/maps/BattleMaps/map1.tscn")

func _ready():
	load_map_1()

func load_map_1():
	get_tree().change_scene_to_packed(MAP_1)
