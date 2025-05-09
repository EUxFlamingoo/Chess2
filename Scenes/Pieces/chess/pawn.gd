extends Node2D

@export var template_name := "WhitePawn"
var is_white: bool
var abilities: Array = []
var ATTACK_RANGE := []
var RANGE_ATTACK_INTERRUPTED := true

func get_moves(x: int, y: int) -> Array:
	var moves = []
	var direction = 1 if is_white else -1

	if "jump" in abilities:
		# Forward move (can jump over anything, but can't land on obstacles or friendly pieces)
		var forward_y = y + direction
		if BoardManager.is_within_board(x, forward_y):
			if not BoardManager.is_tile_obstacle(x, forward_y) and not BoardManager.is_tile_occupied_by_friendly(x, forward_y, is_white):
				moves.append(Vector2(x, forward_y))
		# Double move from starting row (can jump over anything, but can't land on obstacles or friendly pieces)
		var starting_row = BoardManager.First_Rank + 1 if is_white else BoardManager.Last_Rank - 1
		var double_forward_y = y + 2 * direction
		if y == starting_row and BoardManager.is_within_board(x, double_forward_y):
			if not BoardManager.is_tile_obstacle(x, double_forward_y) and not BoardManager.is_tile_occupied_by_friendly(x, double_forward_y, is_white):
				moves.append(Vector2(x, double_forward_y))
		# Captures (can only capture enemy pieces, not obstacles or friendlies)
		for dx in [-1, 1]:
			var tx = x + dx
			var ty = y + direction
			if BoardManager.is_within_board(tx, ty):
				if BoardManager.is_tile_occupied_by_opponent(tx, ty, is_white):
					moves.append(Vector2(tx, ty))
				# Only add en_passant if this pawn can capture en_passant
				if (is_white and Rules.en_passant_capture_white and Rules.en_passant == Vector2(tx, ty)) \
				or (not is_white and Rules.en_passant_capture_black and Rules.en_passant == Vector2(tx, ty)):
					moves.append(Vector2(tx, ty))
	else:
		# Forward move
		if BoardManager.is_within_board(x, y + direction) and (not BoardManager.is_tile_occupied(x, y + direction) || !BoardManager.is_tile_obstacle(x, y + direction)):
			moves.append(Vector2(x, y + direction))
		# Double move from starting row
		var starting_row = BoardManager.First_Rank + 1 if is_white else BoardManager.Last_Rank - 1
		if y == starting_row and (not BoardManager.is_tile_occupied(x, y + direction) and not BoardManager.is_tile_occupied(x, y + 2 * direction) || !BoardManager.is_tile_obstacle(x, y + 2 * direction)):
			moves.append(Vector2(x, y + 2 * direction))
		# Captures
		for dx in [-1, 1]:
			var tx = x + dx
			var ty = y + direction
			if BoardManager.is_within_board(tx, ty):
				if BoardManager.is_tile_occupied_by_opponent(tx, ty, is_white):
					moves.append(Vector2(tx, ty))
				# Only add en_passant if this pawn can capture en_passant
				if (is_white and Rules.en_passant_capture_white and Rules.en_passant == Vector2(tx, ty)) \
				or (not is_white and Rules.en_passant_capture_black and Rules.en_passant == Vector2(tx, ty)):
					moves.append(Vector2(tx, ty))
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
		var starting_row = BoardManager.First_Rank + 1 if piece != null and piece.name.begins_with("White") else BoardManager.Last_Rank - 1
		# Check if the move is a double forward move from the starting row
		if abs(to_position.y - from_position.y) == 2 and from_position.y == starting_row:
			Rules.en_passant = Vector2(to_position.x, int((to_position.y + from_position.y) / 2))  # Set en passant target square (ensure integer)
			if piece.name.begins_with("White"):
				Rules.en_passant_capture_white = true
				Rules.en_passant_capture_black = false
			else:
				Rules.en_passant_capture_black = true
				Rules.en_passant_capture_white = false


func handle_promotion(pawn, target_position: Vector2):
	UnitManager.handle_promotion(pawn, target_position)

func get_promotion_options() -> Array:
	# Return a list of piece names or types this pawn can promote to
	return ["Queen", "Rook", "Bishop", "Knight"]

func get_attack_range(x: int, y: int, _is_white_override: bool = self.is_white) -> Array:
	return MoveUtils.get_range_attack_tiles(self, x, y)


var moves_made_this_turn := 0 
@export var MOVES_PER_TURN := 1
func can_move_this_turn() -> bool:
	# Get the global max moves per turn from the map
	var map_node = GameManager.current_map
	var global_max = map_node.MAX_MOVES_PER_TURN
	var allowed_moves = min(MOVES_PER_TURN, global_max)
	return moves_made_this_turn < allowed_moves

func reset_moves_this_turn():
	moves_made_this_turn = 0

func increment_moves_this_turn():
	moves_made_this_turn += 1
