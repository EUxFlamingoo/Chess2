extends Node

@onready var reload_button: Button = $reload_button
@onready var undo_button: Button = $undo_button
@onready var end_turn_button: Button = $end_turn_button  # Renamed from `end_turn`
@onready var game_finish: Button = $game_finish
@onready var input_blocker: Control = $input_blocker
@onready var player_2: Button = $player_2
@onready var player_1: Button = $player_1
@onready var play_white: Button = $play_white
@onready var play_black: Button = $play_black
@onready var online_button: Button = $online_button
@onready var offline_button: Button = $offline_button
@onready var host_button: Button = $host_button
@onready var join_button: Button = $join_button
@onready var turn_label: Label = $turn_label

var online_enabled = false

func _on_end_turn_button_pressed() -> void:
	# Reset en_passant variables
	if TurnManager.is_white_turn:
		Rules.en_passant_capture_white = false
	else:
		Rules.en_passant_capture_black = false
	MoveManager.deselect_piece()
	TurnManager.end_turn()
	update_turn_label()

func end_game(result_text: String):
	game_finish.text = result_text
	game_finish.visible = true
	input_blocker.visible = true

func _on_game_finish_pressed():
	game_finish.visible = false
	input_blocker.visible = false
	# Show the main menu buttons
	player_1.visible = true
	player_2.visible = true
	play_white.visible = false
	play_black.visible = false
	reset_game_state()
	BoardManager.remove_all_pieces()

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
	UnitManager.place_starting_pieces()
	TurnManager.initialize()
	TurnManager.is_white_turn = true

func _on_play_black_pressed():
	Rules.player_is_white = false
	play_white.visible = false
	play_black.visible = false
	UnitManager.place_starting_pieces()
	TurnManager.initialize()
	TurnManager.is_white_turn = true
	# If it's the AI's turn (white), make the AI move immediately
	if Rules.enemy_logic_on and TurnManager.is_white_turn != Rules.player_is_white:
		EnemyLogic.make_defensive_move()

func reset_game_state():
	TurnManager.is_white_turn = true
	TurnManager.moves_this_turn = 0
	if TurnManager.has_method("deselect_piece"):
		TurnManager.deselect_piece()
	# Reset castling rights if you track them
	UnitManager.white_king_moved = false
	UnitManager.black_king_moved = false
	UnitManager.white_rook_queenside_moved = false
	UnitManager.white_rook_kingside_moved = false
	UnitManager.black_rook_queenside_moved = false
	UnitManager.black_rook_kingside_moved = false
	# Reset king positions
	UnitManager.white_king_pos = Vector2(4, BoardManager.First_Rank)
	UnitManager.black_king_pos = Vector2(4, BoardManager.Last_Rank)


func _on_reload_button_pressed() -> void:
	game_finish.visible = false
	input_blocker.visible = false
	# Show the main menu buttons
	player_1.visible = true
	player_2.visible = true
	play_white.visible = false
	play_black.visible = false
	reset_game_state()
	BoardManager.remove_all_pieces()

func _on_online_button_pressed() -> void:
	online_button.visible = false
	offline_button.visible = false
	join_button.visible = true
	host_button.visible = true
	online_enabled = true

func _on_offline_button_pressed() -> void:
	online_button.visible = false
	offline_button.visible = false
	Rules.enemy_logic_on = false
	UnitManager.place_starting_pieces()
	TurnManager.initialize()

func _on_host_button_pressed() -> void:
	NetworkManager.host_game()
	join_button.visible = false
	host_button.visible = false
	UnitManager.place_starting_pieces()
	TurnManager.initialize()

func _on_join_button_pressed() -> void:
	NetworkManager.join_game()
	join_button.visible = false
	host_button.visible = false

func update_turn_label():
	if TurnManager.is_white_turn == true:
		turn_label.text = "White's turn"
	else:
		turn_label.text = "Black's turn"
