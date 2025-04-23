extends Node

var is_white_turn = true
var moves_this_turn = 0

func initialize():
	is_white_turn = true
	moves_this_turn = Rules.max_moves_per_turn - 1


func end_turn():
	moves_this_turn = 0
	is_white_turn = not is_white_turn
	print("Turn switched. It's now ", "White's" if is_white_turn else "Black's", " turn.")
	if Rules.enemy_logic_on and (is_white_turn != Rules.player_is_white):
		# Check for checkmate before making an AI move
		if Rules.is_checkmate(is_white_turn):
			GameManager.end_game("Checkmate, Restart?")
			return
		EnemyLogic.make_defensive_move()
	# Send board state to client if host
	if NetworkManager.is_host:
		print("sending boardstate")
		NetworkManager.send_full_board_state()

func check_turn_end():
	if Rules.is_promotion_in_progress:
		print("Turn cannot end because a promotion is in progress.")
		return
	if moves_this_turn >= Rules.max_moves_per_turn:
		end_turn()
		return
	if Rules.check_fifty_move_rule():
		get_tree().get_root().get_node("Main").end_game("Draw by Fifty-move rule")
		return
	if Rules.is_checkmate(is_white_turn) or Rules.is_checkmate(!is_white_turn):
		print("checkmate")
		GameManager.end_game("checkmate")
		return
