extends Node2D

# get_valid_moves needs to be updated when units are added

const PIECE_MOVE = preload("res://Scenes/piece_move.tscn")

var move_highlights = []  # List to track move highlight nodes

#region move/deselect_piece

func move_piece(piece, from_position: Vector2, to_position: Vector2):
	# Handle special moves
	Rules.handle_castling(piece, from_position, to_position)
	Rules.handle_en_passant(from_position, to_position)
	# Capture opponent piece if present
	handle_capture(to_position)
	# Update the board state
	update_board_state(piece, from_position, to_position)
	# Handle pawn promotion
	Rules.handle_promotion(piece, to_position)
	# Track movement for castling rules
	track_piece_movement(piece, from_position)

func handle_capture(to_position: Vector2):
	if BoardManager.is_tile_occupied(int(to_position.x), int(to_position.y)):
		var captured_piece = BoardManager.board_state[to_position.y][to_position.x]
		if captured_piece:
			captured_piece.queue_free()

func update_board_state(piece, from_position: Vector2, to_position: Vector2):
	BoardManager.board_state[from_position.y][from_position.x] = null  # Clear the old position
	BoardManager.board_state[to_position.y][to_position.x] = piece  # Set the new position
	piece.position = BoardManager.get_centered_position(int(to_position.x), int(to_position.y))

func track_piece_movement(piece, from_position: Vector2):
	if piece.name.find("Pawn") != -1:  # Reset counter if a pawn is moved
		Rules.move_counter = 0
	elif BoardManager.is_tile_occupied(int(from_position.x), int(from_position.y)):  # Reset counter if a piece is captured
		Rules.move_counter = 0
	else:
		Rules.move_counter += 1  # Increment counter for other moves
	if piece.name.find("King") != -1:
		if piece.name.begins_with("White"): Rules.white_king_moved = true
		else: Rules.black_king_moved = true
	elif piece.name.find("Rook") != -1:
		if piece.name.begins_with("White"):
			if from_position == Vector2(0, 0): Rules.white_rook_queenside_moved = true
			elif from_position == Vector2(7, 0): Rules.white_rook_kingside_moved = true
		else:
			if from_position == Vector2(0, 7): Rules.black_rook_queenside_moved = true
			elif from_position == Vector2(7, 7): Rules.black_rook_kingside_moved = true

func move_selected_piece(x: int, y: int):
	# Get the valid moves for the selected piece
	var moves = get_valid_moves(BoardManager.selected_piece, BoardManager.selected_piece_position.x, BoardManager.selected_piece_position.y)
	print("Valid moves are: ", moves)
	
	# Highlight only valid moves
	highlight_possible_moves(moves)

	# Check if the target position is in the list of valid moves
	if Vector2(x, y) in moves:
		move_piece(BoardManager.selected_piece, BoardManager.selected_piece_position, Vector2(x, y))
		TurnManager.moves_this_turn += 1  # Increment the move counter
		TurnManager.check_turn_end()  # Check if the turn should end
	else:
		print("Invalid move")
	BoardManager.deselect_piece()

#endregion

#region highlite_tile

func highlight_possible_moves(moves: Array):
	# Clear existing highlights
	clear_move_highlights()
	# Add new highlights for valid moves
	for move in moves:
		var highlight = PIECE_MOVE.instantiate()
		highlight.position = Vector2(move.x * BoardManager.TILE_SIZE + BoardManager.TILE_SIZE / 2.0, -move.y * BoardManager.TILE_SIZE + BoardManager.TILE_SIZE / 2.0)
		add_child(highlight)
		move_highlights.append(highlight)  # Track the highlight

func clear_move_highlights():
	for highlight in move_highlights:
		if highlight:
			highlight.queue_free()
	move_highlights.clear()  # Clear the list

#endregion

func get_valid_moves(piece, x: int, y: int) -> Array:
	var moves = []
	if piece.name.find("Rook") != -1:
		moves = UnitManager.get_rook_moves(x, y, piece.name.begins_with("White"))
	elif piece.name.find("Bishop") != -1:
		moves = UnitManager.get_bishop_moves(x, y, piece.name.begins_with("White"))
	elif piece.name.find("Queen") != -1:
		moves = UnitManager.get_queen_moves(x, y, piece.name.begins_with("White"))
	elif piece.name.find("King") != -1:
		moves = UnitManager.get_king_moves(x, y, piece.name.begins_with("White"))
	elif piece.name.find("Knight") != -1:
		moves = UnitManager.get_knight_moves(x, y, piece.name.begins_with("White"))
	elif piece.name.find("Pawn") != -1:
		moves = UnitManager.get_pawn_moves(x, y, piece.name.begins_with("White"))

	# Filter moves if the king is in check
	var is_white = piece.name.begins_with("White")
	var king_pos = Rules.get_king_position(is_white)
	if Rules.is_in_check(king_pos, is_white):
		print("King is in check. Filtering moves for ", piece.name, " at (", x, ", ", y, ")")
		moves = moves.filter(func(move):
			var resolves_check = Rules.does_move_resolve_check(piece, Vector2(x, y), move, is_white)
			print("Move ", move, " resolves check? ", resolves_check)
			return resolves_check
		)

	print("Valid moves for ", piece.name, " at (", x, ", ", y, "): ", moves)
	return moves
