extends Node2D

# get_valid_moves needs to be updated when units are added
const PIECE_MOVE = preload("res://Scenes/misc/piece_move.tscn")

var move_highlights = []  # List to track move highlight nodes

#region move/deselect_piece

func move_piece(piece, from_position: Vector2, to_position: Vector2):
	# Handle special moves
	Rules.handle_castling(piece, from_position, to_position)
	UnitManager.handle_double_forward_move(piece, from_position, to_position)
	Rules.handle_en_passant(from_position, to_position)
	# Capture opponent piece if present
	handle_capture(to_position)
	# Update the board state
	update_board_state(piece, from_position, to_position)
	# Handle pawn promotion
	Rules.handle_promotion(piece, to_position)
	# Track movement for castling rules
	track_piece_movement(piece, from_position)
	# Update king position if the piece is a king
	if piece.name.find("King") != -1:
		if piece.name.begins_with("White"):
			UnitManager.white_king_pos = to_position
		else:
			UnitManager.black_king_pos = to_position
	TurnManager.check_turn_end()

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
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		# Client: send move to host, do not validate locally
		NetworkManager.rpc_id(1, "remote_move", BoardManager.selected_piece_position, Vector2(x, y))
		BoardManager.can_select_piece = false
		BoardManager.deselect_piece()
		return
	# Host or offline: validate and apply move locally
	var moves = get_valid_moves(BoardManager.selected_piece, BoardManager.selected_piece_position.x, BoardManager.selected_piece_position.y)
	if Vector2(x, y) in moves:
		move_piece(BoardManager.selected_piece, BoardManager.selected_piece_position, Vector2(x, y))
		TurnManager.moves_this_turn += 1
		TurnManager.check_turn_end()
		# --- SEND BOARD UPDATE TO CLIENTS ---
		if GameManager.online_enabled and multiplayer.get_unique_id() == 1:
			var state = NetworkManager.get_board_state_as_array()
			for peer_id in multiplayer.get_peers():
				if peer_id != multiplayer.get_unique_id():
					NetworkManager.rpc_id(peer_id, "receive_full_board_state", state, TurnManager.is_white_turn)
	else:
		print("Invalid move")
	BoardManager.deselect_piece()

#endregion

#region highlite_tile

func highlight_possible_moves(moves: Array):
	print("Highlighting moves: ", moves)
	clear_move_highlights()
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

#region tile_validation

func get_valid_moves(piece, x: int, y: int, ignore_check_filter := false) -> Array:
	var moves = []
	var is_white = piece.name.begins_with("White")
	if piece.name.find("Rook") != -1:
		moves = UnitManager.get_rook_moves(x, y, is_white)
	elif piece.name.find("Bishop") != -1:
		moves = UnitManager.get_bishop_moves(x, y, is_white)
	elif piece.name.find("Queen") != -1:
		moves = UnitManager.get_queen_moves(x, y, is_white)
	elif piece.name.find("King") != -1:
		moves = UnitManager.get_king_moves(x, y, is_white)
	elif piece.name.find("Knight") != -1:
		moves = UnitManager.get_knight_moves(x, y, is_white)
	elif piece.name.find("Pawn") != -1:
		moves = UnitManager.get_pawn_moves(x, y, is_white)
	# --- Filter moves if the king is in check and this is NOT the king ---
	if not ignore_check_filter and piece.name.find("King") == -1:
		if MoveManager.is_king_in_check(is_white):
			var filtered_moves = []
			for move in moves:
				var original_piece = simulate_move(Vector2(x, y), move)
				if not is_king_in_check(is_white):
					filtered_moves.append(move)
				revert_move(Vector2(x, y), move, original_piece)
			moves = filtered_moves
	return moves

func get_all_valid_moves(is_white_turn: bool) -> Array:
	var all_moves = []
	for y in range(BoardManager.BOARD_HEIGHT):
		for x in range(BoardManager.BOARD_WIDTH):
			if BoardManager.is_tile_occupied(x, y):
				var piece = BoardManager.board_state[y][x]
				if piece.name.begins_with("White") == is_white_turn:
					var moves = get_valid_moves(piece, x, y)
					if moves.size() > 0:
						all_moves.append({
							"piece": piece,
							"position": Vector2(x, y),
							"moves": moves
						})
	return all_moves

# Returns true if the given position is attacked by the opponent
func is_square_attacked(pos: Vector2, by_white: bool) -> bool:
	for y in range(BoardManager.BOARD_HEIGHT):
		for x in range(BoardManager.BOARD_WIDTH):
			if BoardManager.is_tile_occupied(x, y):
				var piece = BoardManager.board_state[y][x]
				if piece.name.begins_with("White") == by_white:
					# Skip opponent king to avoid recursion
					if piece.name.find("King") != -1:
						continue
					var moves = get_valid_moves(piece, x, y, true) # <--- pass true here!
					if pos in moves:
						return true
	return false

# Returns true if the king of the given color is in check
func is_king_in_check(is_white: bool) -> bool:
	var king_pos = UnitManager.white_king_pos if is_white else UnitManager.black_king_pos
	return is_square_attacked(king_pos, not is_white)

# Returns all pieces attacking the given position
func get_attackers(pos: Vector2, by_white: bool) -> Array:
	var attackers = []
	for y in range(BoardManager.BOARD_HEIGHT):
		for x in range(BoardManager.BOARD_WIDTH):
			if BoardManager.is_tile_occupied(x, y):
				var piece = BoardManager.board_state[y][x]
				if piece.name.begins_with("White") == by_white:
					var moves = []
					if piece.name.find("Pawn") != -1:
						# Pawns attack diagonally
						var direction = -1 if by_white else 1
						for dx in [-1, 1]:
							var attack_x = x + dx
							var attack_y = y + direction
							if BoardManager.is_within_board(attack_x, attack_y):
								moves.append(Vector2(attack_x, attack_y))
					elif piece.name.find("Bishop") != -1:
						moves = UnitManager.get_bishop_attacks(x, y, by_white)
					elif piece.name.find("Rook") != -1:
						moves = UnitManager.get_rook_attacks(x, y, by_white)
					elif piece.name.find("Queen") != -1:
						moves = UnitManager.get_bishop_attacks(x, y, by_white)
						moves += UnitManager.get_rook_attacks(x, y, by_white)
					else:
						moves = get_valid_moves(piece, x, y, true)
					if pos in moves:
						attackers.append({"piece": piece, "position": Vector2(x, y)})
	return attackers

# Simulates moving a piece from one position to another.
func simulate_move(from_position: Vector2, to_position: Vector2) -> Variant:
	var piece = BoardManager.board_state[from_position.y][from_position.x]
	var captured_piece = BoardManager.board_state[to_position.y][to_position.x]
	# Move the piece
	BoardManager.board_state[to_position.y][to_position.x] = piece
	BoardManager.board_state[from_position.y][from_position.x] = null
	# If the king moves, update its tracked position
	if piece != null and piece.name.find("King") != -1:
		if piece.name.begins_with("White"):
			UnitManager.white_king_pos = to_position
		else:
			UnitManager.black_king_pos = to_position
	return captured_piece

# Reverts a simulated move.
func revert_move(from_position: Vector2, to_position: Vector2, captured_piece: Variant) -> void:
	var piece = BoardManager.board_state[to_position.y][to_position.x]
	BoardManager.board_state[from_position.y][from_position.x] = piece
	BoardManager.board_state[to_position.y][to_position.x] = captured_piece
	# If the king moves, restore its tracked position
	if piece != null and piece.name.find("King") != -1:
		if piece.name.begins_with("White"):
			UnitManager.white_king_pos = from_position
		else:
			UnitManager.black_king_pos = from_position

#endregion
