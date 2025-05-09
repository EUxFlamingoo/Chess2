extends Node

var is_white_turn = true
var moves_this_turn_white = 0
var moves_this_turn_black = 0
var post_move_attack_pending = false

var max_moves_per_turn_white = 1
var max_moves_per_turn_black = 1

signal turn_ended(is_white_turn)

func initialize():
	is_white_turn = true
	moves_this_turn_white = 0
	moves_this_turn_black = 0

func update_max_moves_per_turn():
	# Get the map node to access its exported variables
	var map_node = GameManager.current_map
	var max_moves_per_turn = map_node.MAX_MOVES_PER_TURN
	var moves_per_turn_mode = map_node.MOVES_PER_TURN_MODE

	if moves_per_turn_mode == "flat":
		set_max_moves_per_turn(max_moves_per_turn, max_moves_per_turn)
	elif moves_per_turn_mode == "piece_count":
		# Count pieces for each side
		var white_count = 0
		var black_count = 0
		for y in range(BoardManager.BOARD_HEIGHT):
			for x in range(BoardManager.BOARD_WIDTH):
				var piece = BoardManager.board_state[y][x]
				if piece != null:
					if "is_white" in piece:
						if piece.is_white:
							white_count += 1
							print("[TurnManager] Counting WHITE piece:", piece.name, "at", x, y)
						else:
							black_count += 1
							print("[TurnManager] Counting BLACK piece:", piece.name, "at", x, y)
					elif piece.name.begins_with("White"):
						white_count += 1
						print("[TurnManager] Counting WHITE piece:", piece.name, "at", x, y)
					elif piece.name.begins_with("Black"):
						black_count += 1
						print("[TurnManager] Counting BLACK piece:", piece.name, "at", x, y)
		set_max_moves_per_turn(white_count, black_count)

# Call update_max_moves_per_turn() at the start of each turn or after board changes if using "piece_count" mode.

func end_turn():
	if is_white_turn:
		moves_this_turn_white = 0
	else:
		moves_this_turn_black = 0
	is_white_turn = not is_white_turn
	reset_all_piece_moves()
	print("Turn switched. It's now ", "White's" if is_white_turn else "Black's", " turn.")
	# Notify the client of the new turn
	if multiplayer.is_server():
		rpc("sync_turn", is_white_turn)
	if Rules.enemy_logic_on and (is_white_turn != Rules.player_is_white):
		EnemyLogic.make_defensive_move()
	if GameManager.online_enabled and multiplayer.get_unique_id() == 1:
		var state = NetworkManager.get_board_state_as_array()
		for peer_id in multiplayer.get_peers():
			if peer_id != multiplayer.get_unique_id():
				NetworkManager.rpc_id(peer_id, "receive_full_board_state", state, TurnManager.is_white_turn)
	# REMOVE THIS LINE TO PREVENT INFINITE RECURSION:
	# check_turn_end()
	print("checking for win conditions")
	emit_signal("turn_ended", is_white_turn)
	post_move_attack_pending = false
	update_max_moves_per_turn()

@rpc("any_peer")
func sync_turn(new_is_white_turn: bool):
	is_white_turn = new_is_white_turn

func get_moves_this_turn() -> int:
	return moves_this_turn_white if is_white_turn else moves_this_turn_black

func set_moves_this_turn(value: int) -> void:
	if is_white_turn:
		moves_this_turn_white = value
	else:
		moves_this_turn_black = value

func increment_moves_this_turn(amount: int = 1) -> void:
	if is_white_turn:
		moves_this_turn_white += amount
	else:
		moves_this_turn_black += amount

func get_max_moves_this_turn() -> int:
	return max_moves_per_turn_white if is_white_turn else max_moves_per_turn_black

func set_max_moves_per_turn(white: int, black: int) -> void:
	max_moves_per_turn_white = white
	max_moves_per_turn_black = black

func check_turn_end():
	if Rules.is_promotion_in_progress:
		print("Turn cannot end because a promotion is in progress.")
		return
	if post_move_attack_pending:
		print("Turn cannot end: post-move attack is pending.")
		return
	if get_moves_this_turn() >= get_max_moves_this_turn():
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

func reset_all_piece_moves():
	for y in range(BoardManager.BOARD_HEIGHT):
		for x in range(BoardManager.BOARD_WIDTH):
			var piece = BoardManager.board_state[y][x]
			if piece != null and piece.has_method("reset_moves_this_turn"):
				piece.reset_moves_this_turn()
