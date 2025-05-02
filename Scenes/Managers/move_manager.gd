extends Node2D

# get_valid_moves needs to be updated when units are added
const PIECE_MOVE = preload("res://Scenes/misc/piece_move.tscn")

const en_passant_enabled = true

var move_highlights = []  # List to track move highlight nodes

#region move/deselect_piece

func move_piece(piece, from_position: Vector2, to_position: Vector2):
	# Handle special moves
	if piece.has_method("handle_castling"):
		piece.handle_castling(piece, from_position, to_position)
	# Updated: Call handle_double_forward_move on the piece if it has the method, otherwise fallback
	if piece.has_method("handle_double_forward_move"):
		piece.handle_double_forward_move(piece, from_position, to_position)
	if Rules.en_passant_enabled == true:
		if piece.has_method("handle_en_passant") && en_passant_enabled == true:
			piece.handle_en_passant(from_position, to_position)
	# Capture opponent piece if present
	handle_capture(to_position)
	# Update the board state
	update_board_state(piece, from_position, to_position)
	# Handle pawn promotion
	if piece.has_method("handle_promotion"):
		piece.handle_promotion(piece, to_position)
	UnitManager.check_custom_promotion(piece, to_position)
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
		EndConditions.move_counter = 0
	elif BoardManager.is_tile_occupied(int(from_position.x), int(from_position.y)):  # Reset counter if a piece is captured
		EndConditions.move_counter = 0
	else:
		EndConditions.move_counter += 1  # Increment counter for other moves
	if piece.name.find("King") != -1:
		if piece.name.begins_with("White"): UnitManager.white_king_moved = true
		else: UnitManager.black_king_moved = true
	elif piece.name.find("Rook") != -1:
		if piece.name.begins_with("White"):
			if from_position == Vector2(0, 0): UnitManager.white_rook_queenside_moved = true
			elif from_position == Vector2(7, 0): UnitManager.white_rook_kingside_moved = true
		else:
			if from_position == Vector2(0, 7): UnitManager.black_rook_queenside_moved = true
			elif from_position == Vector2(7, 7): UnitManager.black_rook_kingside_moved = true

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
	if BoardManager.selected_piece:
		var is_white = BoardManager.selected_piece.is_white
		# Filter out moves that land on a friendly piece
		moves = moves.filter(func(move):
			if BoardManager.is_tile_occupied(move.x, move.y):
				var target_piece = BoardManager.board_state[move.y][move.x]
				print("At ", move, " piece: ", target_piece, " is_white: ", target_piece.is_white)
				return target_piece.is_white != is_white
			return true
		)
	for move in moves:
		var highlight = PIECE_MOVE.instantiate()
		highlight.position = Vector2(move.x * BoardManager.TILE_SIZE + BoardManager.TILE_SIZE / 2.0, -move.y * BoardManager.TILE_SIZE + BoardManager.TILE_SIZE / 2.0)
		add_child(highlight)
		move_highlights.append(highlight)  # Track the highlight

# New function for highlighting attack range with a texture
func highlight_range_attack_tiles(tiles: Array, texture: Texture2D):
	for tile in tiles:
		var highlight = Sprite2D.new()
		highlight.texture = texture
		highlight.position = BoardManager.get_centered_position(tile.x, tile.y)
		highlight.z_index = 100  # Ensure it's above the board
		add_child(highlight)
		move_highlights.append(highlight)

func clear_move_highlights():
	for highlight in move_highlights:
		if highlight:
			highlight.queue_free()
	move_highlights.clear()  # Clear the list

#endregion

#region tile_validation

func get_valid_moves(piece, x: int, y: int, ignore_check_filter := false) -> Array:
	if piece == null or !piece.has_method("get_moves") or ("is_obstacle" in piece and piece.is_obstacle):
		return []
	var moves = []
	# For king, pass ignore_check_filter as ignore_attack_check
	if piece.name.find("King") != -1:
		moves = piece.get_moves(x, y, ignore_check_filter)
	else:
		moves = piece.get_moves(x, y)
	# Only filter for check if not ignoring and not a king
	if not ignore_check_filter and piece.name.find("King") == -1:
		# ... filter moves that leave king in check ...
		if MoveManager.is_king_in_check(piece.is_white):
			var filtered_moves = []
			for move in moves:
				var original_piece = simulate_move(Vector2(x, y), move)
				if not is_king_in_check(piece.is_white):
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
				if !piece.has_method("get_moves"):
					continue
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
					var moves = []
					if piece.name.find("Pawn") != -1:
						var direction = -1 if by_white else 1
						for dx in [-1, 1]:
							var attack_x = x + dx
							var attack_y = y + direction
							if BoardManager.is_within_board(attack_x, attack_y):
								moves.append(Vector2(attack_x, attack_y))
					elif piece.name.find("Bishop") != -1:
						moves = piece.get_bishop_attacks(x, y, by_white)
					elif piece.name.find("Rook") != -1:
						moves = piece.get_rook_attacks(x, y, by_white)
					elif piece.name.find("Queen") != -1:
						moves = piece.get_bishop_attacks(x, y, by_white)
						moves += piece.get_rook_attacks(x, y, by_white)
					elif piece.name.find("Knight") != -1:
						moves = piece.get_moves(x, y)
					elif piece.name.find("King") != -1:
						for dx in [-1, 0, 1]:
							for dy in [-1, 0, 1]:
								if dx == 0 and dy == 0:
									continue
								var kx = x + dx
								var ky = y + dy
								if BoardManager.is_within_board(kx, ky):
									moves.append(Vector2(kx, ky))
					else:
						moves = get_valid_moves(piece, x, y, true)
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
					# IMPORTANT: pass ignore_check_filter = true to avoid recursion!
					var moves = get_valid_moves(piece, x, y, true)
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
