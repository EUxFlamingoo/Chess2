extends Node

# set units, start positions and define Moves

const WHITE_PAWN = preload("res://Scenes/Pieces/white_pawn.tscn")
const BLACK_PAWN = preload("res://Scenes/Pieces/black_pawn.tscn")
const WHITE_KNIGHT = preload("res://Scenes/Pieces/white_knight.tscn")
const BLACK_KNIGHT = preload("res://Scenes/Pieces/black_knight.tscn")
const WHITE_BISHOP = preload("res://Scenes/Pieces/white_bishop.tscn")
const BLACK_BISHOP = preload("res://Scenes/Pieces/black_bishop.tscn")
const WHITE_ROOK = preload("res://Scenes/Pieces/white_rook.tscn")
const BLACK_ROOK = preload("res://Scenes/Pieces/black_rook.tscn")
const WHITE_QUEEN = preload("res://Scenes/Pieces/white_queen.tscn")
const BLACK_QUEEN = preload("res://Scenes/Pieces/black_queen.tscn")
const WHITE_KING = preload("res://Scenes/Pieces/white_king.tscn")
const BLACK_KING = preload("res://Scenes/Pieces/black_king.tscn")


var white_king_pos = Vector2(4, BoardManager.First_Rank)
var black_king_pos = Vector2(4, BoardManager.Last_Rank)

#func initialize():
#	place_pieces()

func place_starting_pieces():
	place_white_pawns()
	place_black_pawns()
	place_white_knights()
	place_black_knights()
	place_white_bishops()
	place_black_bishops()
	place_white_rooks()
	place_black_rooks()
	place_white_queen()
	place_white_king()
	place_black_queen()
	place_black_king()


# Helper function to place a piece
func place_piece(piece_scene: PackedScene, board_x: int, board_y: int, name_prefix: String = ""):
	var piece = piece_scene.instantiate()
	if name_prefix != "":
		piece.name = name_prefix + "_" + str(board_x) + "_" + str(board_y)  # Set a unique name
	piece.position = BoardManager.get_centered_position(board_x, board_y)  # Use Global for positioning
	BoardManager.add_child(piece)  # Add the piece to the board
	BoardManager.board_state[board_y][board_x] = piece  # Update the board state

#region place_pieces

# Place white pawns
func place_white_pawns():
	for x in range(BoardManager.BOARD_WIDTH):  # Use BOARD_WIDTH for the number of columns
		place_piece(WHITE_PAWN, x, 1, "WhitePawn")

# Place black pawns
func place_black_pawns():
	for x in range(BoardManager.BOARD_WIDTH):  # Use BOARD_WIDTH for the number of columns
		place_piece(BLACK_PAWN, x, BoardManager.Last_Rank - 1, "BlackPawn")

# Place white knights
func place_white_knights():
	for x in [1, 6]:
		place_piece(WHITE_KNIGHT, x, BoardManager.First_Rank, "WhiteKnight")

# Place black knights
func place_black_knights():
	for x in [1, 6]:
		place_piece(BLACK_KNIGHT, x, BoardManager.Last_Rank, "BlackKnight")

# Place white bishops
func place_white_bishops():
	for x in [2, 5]:
		place_piece(WHITE_BISHOP, x, BoardManager.First_Rank, "WhiteBishop")

# Place black bishops
func place_black_bishops():
	for x in [2, 5]:
		place_piece(BLACK_BISHOP, x, BoardManager.Last_Rank, "BlackBishop")

# Place white rooks
func place_white_rooks():
	for x in [0, 7]:  # Place rooks at (0, 0) and (7, 0)
		place_piece(WHITE_ROOK, x, BoardManager.First_Rank, "WhiteRook")

# Place black rooks
func place_black_rooks():
	for x in [BoardManager.First_Rank, 7]:
		place_piece(BLACK_ROOK, x, BoardManager.Last_Rank, "BlackRook")

# Place the white queen
func place_white_queen():
	place_piece(WHITE_QUEEN, 3, BoardManager.First_Rank, "WhiteQueen")

# Place the black queen
func place_black_queen():
	place_piece(BLACK_QUEEN, 3, BoardManager.Last_Rank, "BlackQueen")

# Place the white king
func place_white_king():
	place_piece(WHITE_KING, 4, BoardManager.First_Rank, "WhiteKing")

# Place the black king
func place_black_king():
	place_piece(BLACK_KING, 4, BoardManager.Last_Rank, "BlackKing")
#endregion


#region unit_specific_moves

#region pawn

func get_pawn_moves(x: int, y: int, is_white_piece: bool) -> Array:
	# Initialize an empty array to store all valid moves for the piece
	var moves = []
	var direction = 1 if is_white_piece else -1  # -White- pawn-s move up (-1), black pawns move down (+1)
	# Frward mve
	if BoardManager.is_within_board(x, y + direction):
		if not BoardManager.is_tile_occupied(x, y + direction):
			moves.append(Vector2(x, y + direction))
	# Double forward move (only if on starting row)
	var starting_row = BoardManager.First_Rank + 1 if is_white_piece else BoardManager.Last_Rank - 1
	if y == starting_row:
		if not BoardManager.is_tile_occupied(x, y + direction) and not BoardManager.is_tile_occupied(x, y + 2 * direction):
			moves.append(Vector2(x, y + 2 * direction))
	# Capture moves (diagonally forward)
	for dx in [-1, 1]:  # Check both left and right diagonals
		var target_x = x + dx
		var target_y = y + direction
		if BoardManager.is_within_board(target_x, target_y):
			if BoardManager.is_tile_occupied_by_opponent(target_x, target_y, is_white_piece):
				moves.append(Vector2(target_x, target_y))
			elif Rules.en_passant == Vector2(target_x, target_y) && Rules.en_passant_enabled == true:
				moves.append(Rules.en_passant)

	return moves

func handle_en_passant(from_position: Vector2, to_position: Vector2) -> void:
	var captured_piece = null
	# Check for en passant capture for black pawns
	if Rules.en_passant_capture_black and from_position.y == BoardManager.Last_Rank - 3 and abs(to_position.x - from_position.x) == 1:
		var captured_piece_position = Vector2(to_position.x, to_position.y - 1)
		if BoardManager.is_tile_occupied(int(captured_piece_position.x), int(captured_piece_position.y)):
			captured_piece = BoardManager.board_state[int(captured_piece_position.y)][int(captured_piece_position.x)]
			if captured_piece:
				captured_piece.queue_free()
				BoardManager.board_state[int(captured_piece_position.y)][int(captured_piece_position.x)] = null
				Rules.en_passant_capture_black = false
	# Check for en passant capture for white pawns
	elif Rules.en_passant_capture_white and from_position.y == BoardManager.First_Rank + 3 and abs(to_position.x - from_position.x) == 1:
		var captured_piece_position = Vector2(to_position.x, to_position.y + 1)
		if BoardManager.is_tile_occupied(int(captured_piece_position.x), int(captured_piece_position.y)):
			captured_piece = BoardManager.board_state[int(captured_piece_position.y)][int(captured_piece_position.x)]
			if captured_piece:
				captured_piece.queue_free()
				BoardManager.board_state[int(captured_piece_position.y)][int(captured_piece_position.x)] = null
				Rules.en_passant_capture_white = false

func handle_double_forward_move(piece, from_position: Vector2, to_position: Vector2) -> void:
	# Check if the piece is a pawn
	if piece.name.find("Pawn") != -1:
		var starting_row = BoardManager.First_Rank + 1 if piece.name.begins_with("White") else BoardManager.Last_Rank - 1
		# Check if the move is a double forward move from the starting row
		if abs(to_position.y - from_position.y) == 2 and from_position.y == starting_row:
			Rules.en_passant = Vector2(to_position.x, (to_position.y + from_position.y) / 2)  # Set en passant target square
			if piece.name.begins_with("White"):
				Rules.en_passant_capture_white = true
			else:
				Rules.en_passant_capture_black = true

#endregion


func get_linear_moves(x: int, y: int, is_white_piece: bool, directions: Array) -> Array:
	var moves = []
	for direction in directions:
		var pos = Vector2(x, y) + direction
		while BoardManager.is_within_board(pos.x, pos.y):  # Ensure position is within bounds
			if not BoardManager.is_tile_occupied(pos.x, pos.y):
				moves.append(pos)
			elif BoardManager.is_tile_occupied_by_opponent(pos.x, pos.y, is_white_piece):
				moves.append(pos)
				break  # Stop further moves in this direction
			else:
				break  # Stop further moves in this direction
			pos += direction  # Move to the next position in the direction
	return moves

func get_rook_moves(x: int, y: int, is_white_piece: bool) -> Array:
	var moves = []
	var directions = [
		Vector2(1, 0),  # Right
		Vector2(-1, 0), # Left
		Vector2(0, 1),  # Down
		Vector2(0, -1)  # Up
	]

	for direction in directions:
		var pos = Vector2(x, y) + direction
		while BoardManager.is_within_board(pos.x, pos.y):
			if not BoardManager.is_tile_occupied(pos.x, pos.y):
				moves.append(pos)
			elif BoardManager.is_tile_occupied_by_opponent(pos.x, pos.y, is_white_piece):
				moves.append(pos)
				break  # Stop further moves in this direction
			else:
				break  # Stop further moves in this direction
			pos += direction  # Move to the next position in the direction

	return moves

func get_bishop_moves(x: int, y: int, is_white_piece: bool) -> Array:
	var moves = []
	var directions = [
		Vector2(1, 1),   # Diagonal up-right
		Vector2(-1, 1),  # Diagonal up-left
		Vector2(1, -1),  # Diagonal down-right
		Vector2(-1, -1)  # Diagonal down-left
	]

	for direction in directions:
		var pos = Vector2(x, y) + direction
		while BoardManager.is_within_board(pos.x, pos.y):
			if not BoardManager.is_tile_occupied(pos.x, pos.y):
				moves.append(pos)
			elif BoardManager.is_tile_occupied_by_opponent(pos.x, pos.y, is_white_piece):
				moves.append(pos)
				break  # Stop further moves in this direction
			else:
				break  # Stop further moves in this direction
			pos += direction  # Move to the next position in the direction

	return moves

func get_queen_moves(x: int, y: int, is_white_piece: bool) -> Array:
	# Combine rook-like and bishop-like moves
	var moves = []
	moves += get_rook_moves(x, y, is_white_piece)
	moves += get_bishop_moves(x, y, is_white_piece)
	return moves

func move_rook(from_position: Vector2, to_position: Vector2):
	var rook = BoardManager.board_state[from_position.y][from_position.x]
	BoardManager.board_state[from_position.y][from_position.x] = null  # Clear the old position
	BoardManager.board_state[to_position.y][to_position.x] = rook  # Set the new position
	rook.position = BoardManager.get_centered_position(int(to_position.x), int(to_position.y))

func get_king_moves(x: int, y: int, is_white_piece: bool) -> Array:
	print("Entering get_king_moves for king at (", x, ", ", y, ")")
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
					moves.append(Vector2(target_x, target_y))

	# Add castling moves (you may want to add additional checks for castling safety)
	moves += get_king_castling_moves(x, y, is_white_piece)

	print("Exiting get_king_moves for king at (", x, ", ", y, ")")
	return moves

func get_king_castling_moves(x: int, y: int, is_white_piece: bool) -> Array:
	var moves = []
	if is_white_piece:
		if x == 4 and y == 0:  # Ensure the king is in the correct starting position
			if Rules.can_castle(true, true):  # White kingside castling
				moves.append(Vector2(6, 0))
			if Rules.can_castle(true, false):  # White queenside castling
				moves.append(Vector2(2, 0))
	else:
		if x == 4 and y == 7:  # Ensure the king is in the correct starting position
			if Rules.can_castle(false, true):  # Black kingside castling
				moves.append(Vector2(6, 7))
			if Rules.can_castle(false, false):  # Black queenside castling
				moves.append(Vector2(2, 7))
	return moves

func get_knight_moves(x: int, y: int, is_white_piece: bool) -> Array:
	var moves = []
	var directions = [
		Vector2(2, 1),   # Two right, one up
		Vector2(2, -1),  # Two right, one down
		Vector2(-2, 1),  # Two left, one up
		Vector2(-2, -1), # Two left, one down
		Vector2(1, 2),   # One right, two up
		Vector2(1, -2),  # One right, two down
		Vector2(-1, 2),  # One left, two up
		Vector2(-1, -2)  # One left, two down
	]
	for direction in directions:
		var target_x = x + direction.x
		var target_y = y + direction.y
		if BoardManager.is_within_board(target_x, target_y):
			if not BoardManager.is_tile_occupied(target_x, target_y) or BoardManager.is_tile_occupied_by_opponent(target_x, target_y, is_white_piece):
				moves.append(Vector2(target_x, target_y))
	return moves

func locate_king(is_white_turn: bool) -> Vector2:
	return white_king_pos if is_white_turn else black_king_pos




#endregion
