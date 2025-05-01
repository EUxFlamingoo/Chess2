extends Node

var enemy_logic_on = false
const chess_mode = true     # Modify

const max_moves_per_turn = 1   # Modify

const fifty_move_rule_enabled = true  # Modify

#region var

# At the top of the file
var is_promotion_in_progress = false

# Tracks the number of moves since the last pawn move or capture
var move_counter = 0

var player_is_white = true

var en_passant = null
var en_passant_capture_white = false
var en_passant_capture_black = false
#endregion



func are_squares_safe_and_empty(_king_pos: Vector2, square1: Vector2, square2: Vector2) -> bool:
	# Check if the squares are empty
	if BoardManager.is_tile_occupied(int(square1.x), int(square1.y)) or BoardManager.is_tile_occupied(int(square2.x), int(square2.y)):
		return false
	# Check if the king's position is safe (you can implement this logic later)
	# For now, assume it is safe
	return true

func check_fifty_move_rule() -> bool:
	if not fifty_move_rule_enabled:
		return false
	if move_counter >= 50:
		print("Fifty-move rule triggered. Game is a draw.")
		return true
	return false

func is_checkmate(is_white: bool) -> bool:
	var king_in_check = MoveManager.is_king_in_check(is_white)
	var all_moves = MoveManager.get_all_valid_moves(is_white)
	return king_in_check and all_moves.size() == 0

func is_stalemate(is_white: bool) -> bool:
	var king_in_check = MoveManager.is_king_in_check(is_white)
	var all_moves = MoveManager.get_all_valid_moves(is_white)
	return not king_in_check and all_moves.size() == 0
