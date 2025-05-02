extends Node2D


@onready var player_2: Button = $CanvasLayer/player_2
@onready var player_1: Button = $CanvasLayer/player_1
@onready var play_white: Button = $CanvasLayer/play_white
@onready var play_black: Button = $CanvasLayer/play_black
@onready var online_button: Button = $CanvasLayer/online_button
@onready var offline_button: Button = $CanvasLayer/offline_button
@onready var host_button: Button = $CanvasLayer/host_button
@onready var join_button: Button = $CanvasLayer/join_button

const MAP_1 = preload("res://Scenes/maps/map1.tscn") # Add this line

func _on_player_1_pressed():
	Rules.enemy_logic_on = true
	player_1.visible = false
	player_2.visible = false
	play_white.visible = true
	play_black.visible = true

func _on_player_2_pressed():
	player_1.visible = false
	player_2.visible = false
	online_button.visible = true
	offline_button.visible = true

func _on_play_white_pressed():
	Rules.player_is_white = true
	play_white.visible = false
	play_black.visible = false
	TurnManager.initialize()
	BoardManager.initialize()
	# Instance and add map_1
	var map_instance = MAP_1.instantiate()
	add_child(map_instance)
	TurnManager.is_white_turn = true

func _on_play_black_pressed():
	Rules.player_is_white = false
	play_white.visible = false
	play_black.visible = false
	TurnManager.initialize()
	BoardManager.initialize()
	# Instance and add map_1
	var map_instance = MAP_1.instantiate()
	add_child(map_instance)
	TurnManager.is_white_turn = true
	# If it's the AI's turn (white), make the AI move immediately
	if Rules.enemy_logic_on and TurnManager.is_white_turn != Rules.player_is_white:
		EnemyLogic.make_defensive_move()


func _on_online_button_pressed() -> void:
	online_button.visible = false
	offline_button.visible = false
	join_button.visible = true
	host_button.visible = true
	GameManager.online_enabled = true

func _on_offline_button_pressed() -> void:
	online_button.visible = false
	offline_button.visible = false
	Rules.enemy_logic_on = false
	TurnManager.initialize()
	BoardManager.initialize()
	# Instance and add map_1
	var map_instance = MAP_1.instantiate()
	add_child(map_instance)


func _on_host_button_pressed() -> void:
	NetworkManager.host_game()
	join_button.visible = false
	host_button.visible = false
	TurnManager.initialize()

func _on_join_button_pressed() -> void:
	NetworkManager.join_game()
	join_button.visible = false
	host_button.visible = false
