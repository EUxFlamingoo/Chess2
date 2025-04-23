extends Node2D

const GAME_MANAGER = preload("res://Scenes/game_manager.tscn")
const MOVE_MANAGER = preload("res://Scenes/move_manager.tscn")
const PIECE_MOVE = preload("res://Scenes/piece_move.tscn")
const TURN_MANAGER = preload("res://Scenes/turn_manager.tscn")
const UNIT_MANAGER = preload("res://Scenes/unit_manager.tscn")

func _ready():
	BoardManager.initialize()
