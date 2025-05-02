extends Node

var enemy_logic_on = false

const max_moves_per_turn = 1   # Modify

var is_promotion_in_progress = false

var player_is_white = true

const en_passant_enabled = false
var en_passant = null
var en_passant_capture_white = false
var en_passant_capture_black = false


func are_squares_safe_and_empty(_king_pos: Vector2, square1: Vector2, square2: Vector2) -> bool:
	# Check if the squares are empty
	if BoardManager.is_tile_occupied(int(square1.x), int(square1.y)) or BoardManager.is_tile_occupied(int(square2.x), int(square2.y)):
		return false
	# Check if the king's position is safe (you can implement this logic later)
	# For now, assume it is safe
	return true
