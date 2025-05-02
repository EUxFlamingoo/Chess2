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
	# Notify the client of the new turn
	if multiplayer.is_server():
		rpc("sync_turn", is_white_turn)
	if Rules.enemy_logic_on and (is_white_turn != Rules.player_is_white):
		# Check for checkmate before making an AI move
		EnemyLogic.make_defensive_move()
	GameManager.update_turn_label()
	if GameManager.online_enabled and multiplayer.get_unique_id() == 1:
		var state = NetworkManager.get_board_state_as_array()
		for peer_id in multiplayer.get_peers():
			if peer_id != multiplayer.get_unique_id():
				NetworkManager.rpc_id(peer_id, "receive_full_board_state", state, TurnManager.is_white_turn)
	check_turn_end()
	print("checking for win conditions")

@rpc("any_peer")
func sync_turn(new_is_white_turn: bool):
	is_white_turn = new_is_white_turn

func check_turn_end():
	if Rules.is_promotion_in_progress:
		print("Turn cannot end because a promotion is in progress.")
		return
	if moves_this_turn >= Rules.max_moves_per_turn:
		end_turn()
		return
	if EndConditions.check_fifty_move_rule() && EndConditions.fifty_move_rule_enabled == true:
		print("Draw by Fifty-move rule")
		GameManager.end_game("Draw by Fifty-move rule")
		return
	if EndConditions.is_checkmate(is_white_turn) or EndConditions.is_checkmate(!is_white_turn) && EndConditions.checkmate_enabled == true:
		print("checkmate")
		GameManager.end_game("checkmate")
		return
	if EndConditions.end_piece_capture() && EndConditions.end_piece_capture_enabled == true:
		print("Capture Win")
		GameManager.end_game("Capture Win")
		return
