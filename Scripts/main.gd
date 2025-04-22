extends Node2D

const GAME_MANAGER = preload("res://Scenes/game_manager.tscn")
const MOVE_MANAGER = preload("res://Scenes/move_manager.tscn")
const PIECE_MOVE = preload("res://Scenes/piece_move.tscn")
const TURN_MANAGER = preload("res://Scenes/turn_manager.tscn")
const UNIT_MANAGER = preload("res://Scenes/unit_manager.tscn")

@onready var player_2: Button = $player_2
@onready var player_1: Button = $player_1
@onready var play_white: Button = $play_white
@onready var play_black: Button = $play_black

func _ready():
	BoardManager.initialize()

func _on_player_1_pressed():
	Rules.enemy_logic_on = true
	player_1.visible = false
	player_2.visible = false
	play_white.visible = true
	play_black.visible = true

func _on_player_2_pressed():
	Rules.enemy_logic_on = false
	player_1.visible = false
	player_2.visible = false
	GameManager.start_game()
	TurnManager.is_white_turn = true
	TurnManager.start_turn() # Only called here

func _on_play_white_pressed():
	Rules.player_is_white = true
	play_white.visible = false
	play_black.visible = false
	GameManager.start_game()
	TurnManager.is_white_turn = true
	TurnManager.start_turn()

func _on_play_black_pressed():
	Rules.player_is_white = false
	play_white.visible = false
	play_black.visible = false
	GameManager.start_game()
	TurnManager.is_white_turn = true
	TurnManager.start_turn()
	# If it's the AI's turn (white), make the AI move immediately
	if Rules.enemy_logic_on and TurnManager.is_white_turn != Rules.player_is_white:
		EnemyLogic.make_defensive_move()
