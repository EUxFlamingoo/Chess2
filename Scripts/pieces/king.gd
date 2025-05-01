extends Sprite2D

const castling_enabled = true # Modify

var is_white: bool





func get_moves(x: int, y: int) -> Array:
	return get_king_moves(x, y, is_white)

func get_king_moves(x: int, y: int, is_white_piece: bool) -> Array:
	var moves = []
	var directions = [
		Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
	]
	# Generate all potential moves for the king
	for direction in directions:
		var target_x = x + direction.x
		var target_y = y + direction.y
		if BoardManager.is_within_board(target_x, target_y):
			if not BoardManager.is_tile_occupied(target_x, target_y) or BoardManager.is_tile_occupied_by_opponent(target_x, target_y, is_white_piece):
				# Only allow move if the target square is NOT attacked
				if not MoveManager.is_square_attacked(Vector2(target_x, target_y), not is_white_piece):
					# Prevent king from capturing a covered enemy piece
					if BoardManager.is_tile_occupied_by_opponent(target_x, target_y, is_white_piece):
						if EnemyLogic.is_covered(Vector2(target_x, target_y), not is_white_piece):
							continue # Skip this move, as the enemy piece is protected
					moves.append(Vector2(target_x, target_y))
	# Add castling moves
	moves += get_king_castling_moves(x, y, is_white_piece)
	return moves

func get_king_castling_moves(x: int, y: int, is_white_piece: bool) -> Array:
	var moves = []
	if is_white_piece:
		if x == 4 and y == 0:  # White king starting position
			if can_castle(true, true):  # White kingside castling
				moves.append(Vector2(6, 0))
			if can_castle(true, false):  # White queenside castling
				moves.append(Vector2(2, 0))
	else:
		if x == 4 and y == 7:  # Black king starting position
			if can_castle(false, true):  # Black kingside castling
				moves.append(Vector2(6, 7))
			if can_castle(false, false):  # Black queenside castling
				moves.append(Vector2(2, 7))
	return moves

func locate_king(is_white_turn: bool) -> Vector2:
	return UnitManager.white_king_pos if is_white_turn else UnitManager.black_king_pos

#region castling

func can_castle(is_white_piece: bool, kingside: bool) -> bool:
	if not castling_enabled:
		return false
	if is_white_piece:
		if UnitManager.white_king_moved:
			return false
		if kingside:
			if UnitManager.white_rook_kingside_moved:
				return false
			if not Rules.are_squares_safe_and_empty(Vector2(4, 0), Vector2(5, 0), Vector2(6, 0)):
				return false
		else:
			if UnitManager.white_rook_queenside_moved:
				return false
			if not Rules.are_squares_safe_and_empty(Vector2(4, 0), Vector2(3, 0), Vector2(2, 0)):
				return false
	else:
		if UnitManager.black_king_moved:
			return false
		if kingside:
			if UnitManager.black_rook_kingside_moved:
				return false
			if not Rules.are_squares_safe_and_empty(Vector2(4, 7), Vector2(5, 7), Vector2(6, 7)):
				return false
		else:
			if UnitManager.black_rook_queenside_moved:
				return false
			if not Rules.are_squares_safe_and_empty(Vector2(4, 7), Vector2(3, 7), Vector2(2, 7)):
				return false
	return true

func handle_castling(piece, from_position: Vector2, to_position: Vector2):
	# Only handle castling for king-like pieces at their starting row and file
	if not piece.has_method("get_moves"):
		return

	var is_white = piece.is_white

	if is_white:
		if from_position == Vector2(4, 0) and to_position == Vector2(6, 0):  # White kingside
			var rook = BoardManager.board_state[0][7]
			if rook and rook.has_method("move_rook"):
				rook.move_rook(Vector2(7, 0), Vector2(5, 0))
		elif from_position == Vector2(4, 0) and to_position == Vector2(2, 0):  # White queenside
			var rook = BoardManager.board_state[0][0]
			if rook and rook.has_method("move_rook"):
				rook.move_rook(Vector2(0, 0), Vector2(3, 0))
	else:
		if from_position == Vector2(4, 7) and to_position == Vector2(6, 7):  # Black kingside
			var rook = BoardManager.board_state[7][7]
			if rook and rook.has_method("move_rook"):
				rook.move_rook(Vector2(7, 7), Vector2(5, 7))
		elif from_position == Vector2(4, 7) and to_position == Vector2(2, 7):  # Black queenside
			var rook = BoardManager.board_state[7][0]
			if rook and rook.has_method("move_rook"):
				rook.move_rook(Vector2(0, 7), Vector2(3, 7))

#endregion
