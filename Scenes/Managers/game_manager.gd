extends Node

@onready var input_blocker: Control = $CanvasLayer/input_blocker
@onready var game_finish: Button = $CanvasLayer/game_finish

# GameContext.gd (autoload this script)
var current_map = null

var online_enabled = false


func end_game(result_text: String):
	game_finish.text = result_text
	game_finish.visible = true
	input_blocker.visible = true

func reset_game_state():
	TurnManager.is_white_turn = true
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
	BoardManager.delete_all_tiles()
	BoardManager.clear_custom_highlights()
	BoardManager.remove_all_pieces()

func _on_game_finish_pressed():
	game_finish.visible = false
	input_blocker.visible = false
	# Show the main menu buttons
	reset_game_state()
	BoardManager.remove_all_pieces()
	get_tree().change_scene_to_file("res://Scenes/UI/GameStart.tscn")
