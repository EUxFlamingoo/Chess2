extends Node

@onready var end_turn_button: Button = $end_turn_button  # Renamed from `end_turn`


var is_white_turn = true
var moves_this_turn = 0

func initialize():
	is_white_turn = true
	moves_this_turn = 0

func start_turn():
	print("Starting turn for ", "White" if is_white_turn else "Black")


func end_turn():
	moves_this_turn = 0
	is_white_turn = not is_white_turn
	GameManager.end_turn()
	print("Turn switched. It's now ", "White's" if is_white_turn else "Black's", " turn.")

func check_turn_end():
	if Rules.is_promotion_in_progress:
		print("Turn cannot end because a promotion is in progress.")
		return
	if moves_this_turn >= Rules.max_moves_per_turn:
		if !is_white_turn:
			Rules.en_passant_capture_white = false
		elif is_white_turn:
			Rules.en_passant_capture_black = false
		moves_this_turn = 0
		is_white_turn = not is_white_turn
		print("Turn switched. It's now ", "White's" if is_white_turn else "Black's", " turn.")
		return
	if Rules.check_fifty_move_rule():
		GameManager.end_game("Draw by Fifty-move rule")
		return
	is_white_turn = not is_white_turn
	print("Starting turn for ", "White" if is_white_turn else "Black")

func _on_end_turn_button_pressed() -> void:
		# Reset en_passant variables
	if TurnManager.is_white_turn:
		Rules.en_passant_capture_white = false
	else:
		Rules.en_passant_capture_black = false
	# Reset the move counter and switch turns
	TurnManager.moves_this_turn = 0
	TurnManager.is_white_turn = not TurnManager.is_white_turn

	# Clear any selected piece and move highlights
	MoveManager.deselect_piece()
	print("Turn switched. It's now ", "White's" if TurnManager.is_white_turn else "Black's", " turn.")
