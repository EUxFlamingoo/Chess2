extends Node


@onready var reload_button: Button = $reload_button
@onready var undo_button: Button = $undo_button
@onready var game_finish: Button = $game_finish


func start_game():
	BoardManager.setup_board()
	UnitManager.place_starting_pieces()
	TurnManager.initialize()
	TurnManager.start_turn()

func end_game(result: String):
	print(result)
	if Rules.is_checkmate(TurnManager.is_white_turn):
		GameManager.end_game("Checkmate! " + ("Black" if TurnManager.is_white_turn else "White") + " wins.")
	if Rules.is_stalemate(TurnManager.is_white_turn):
		GameManager.end_game("Stalemate! The game is a draw.")
	game_finish.visible = true
	
