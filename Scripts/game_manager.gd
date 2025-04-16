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
	game_finish.visible = true
	# Add logic to display the result and stop the game


func _on_game_finish_pressed() -> void:
	get_tree().reload_current_scene()
