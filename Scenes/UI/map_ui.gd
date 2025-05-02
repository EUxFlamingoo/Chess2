extends Node2D


@onready var undo_button: Button = $CanvasLayer/undo_button
@onready var end_turn_button: Button = $CanvasLayer/end_turn_button
@onready var input_blocker: Control = $CanvasLayer/input_blocker
@onready var reload_button: Button = $CanvasLayer/reload_button



func _on_end_turn_button_pressed() -> void:
	# Reset en_passant variables
	if TurnManager.is_white_turn:
		Rules.en_passant_capture_white = false
	else:
		Rules.en_passant_capture_black = false
	BoardManager.deselect_piece()
	TurnManager.end_turn()
	GameManager.update_turn_label()

func _on_reload_button_pressed() -> void:
	input_blocker.visible = false
	# Show the main menu buttons
	GameManager.reset_game_state()
	BoardManager.remove_all_pieces()
	get_tree().change_scene_to_file("res://Scenes/UI/GameStart.tscn")
