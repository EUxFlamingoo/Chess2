extends Node2D

const GAME_MANAGER = preload("res://Scenes/Managers/game_manager.tscn")
const MOVE_MANAGER = preload("res://Scenes/Managers/move_manager.tscn")
const NETWORK_MANAGER = preload("res://Scenes/Managers/network_manager.tscn")
const TURN_MANAGER = preload("res://Scenes/Managers/turn_manager.tscn")
const UNIT_MANAGER = preload("res://Scenes/Managers/unit_manager.tscn")
const PIECE_MOVE = preload("res://Scenes/misc/piece_move.tscn")

func _ready():
	BoardManager.initialize()
	GameManager.update_turn_label()
