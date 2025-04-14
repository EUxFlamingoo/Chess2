extends Node2D

const TILE_SIZE = 64  # Size of each tile in pixels
const adjust_hight = TILE_SIZE / 1.03 # increase to adjust height on tile
const BOARD_SIZE = 8  # 8x8 chessboard

#region pieces

const WHITE_PAWN = preload("res://Scenes/Pieces/white_pawn.tscn")
const WHITE_BISHOP = preload("res://Scenes/Pieces/white_bishop.tscn")
const WHITE_KING = preload("res://Scenes/Pieces/white_king.tscn")
const WHITE_KNIGHT = preload("res://Scenes/Pieces/white_knight.tscn")
const WHITE_QUEEN = preload("res://Scenes/Pieces/white_queen.tscn")
const WHITE_ROOK = preload("res://Scenes/Pieces/white_rook.tscn")

const BLACK_PAWN = preload("res://Scenes/Pieces/black_pawn.tscn")
const BLACK_BISHOP = preload("res://Scenes/Pieces/black_bishop.tscn")
const BLACK_KING = preload("res://Scenes/Pieces/black_king.tscn")
const BLACK_KNIGHT = preload("res://Scenes/Pieces/black_knight.tscn")
const BLACK_QUEEN = preload("res://Scenes/Pieces/black_queen.tscn")
const BLACK_ROOK = preload("res://Scenes/Pieces/black_rook.tscn")

const PIECE_MOVE = preload("res://Scenes/piece_move.tscn")

@onready var white_2: Button = $white2
@onready var white_3: Button = $white3
@onready var white_4: Button = $white4
@onready var white_5: Button = $white5
@onready var black_2: Button = $black2
@onready var black_3: Button = $black3
@onready var black_4: Button = $black4
@onready var black_5: Button = $black5





@onready var end_turn: Button = $end_turn

#endregion

const LIGHT_COLOR = Color(0.4, 0.3, 0.2)  # Light tile color (e.g., beige)
const DARK_COLOR = Color(0.3, 0.2, 0.1)   # Dark tile color (e.g., brown)

#region var

var is_white = true  # Set to false for black pawns
var board_state = []  # 2D array to track the state of the board
var move_highlights = []  # List to track move highlight nodes
var selected_piece = null  # The currently selected piece
var selected_piece_position = null  # The grid position of the selected piece
var is_white_turn = true  # True for white's turn, false for black's turn
var moves_this_turn = 0  # Tracks the number of moves made in the current turn
var max_moves_per_turn = 1  # Maximum moves allowed per turn (default is 1)
var chess_mode = true     # Hide skip turn button
var en_passant = null
var en_passant_capture_white = false
var en_passant_capture_black = false
var promotion_pawn = null  # Stores the pawn to be promoted
var promotion_position = null  # Stores the position of the pawn to be promoted
var is_promotion_in_progress = false  # Tracks if a pawn promotion is in progress

#endregion

#region ready

func initialize_board_state():
	# Initialize the board state with null values (empty tiles)
	board_state = []
	for y in range(BOARD_SIZE):
		var row = []
		for x in range(BOARD_SIZE):
			row.append(null)  # null means the tile is empty
		board_state.append(row)

func _ready():
	if chess_mode == true:
		end_turn.visible = false
	
	initialize_board_state()
	# Place pieces and update the board state
	create_chessboard()
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

#endregion

#region place_pieces

func create_chessboard():
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			# Create a tile (ColorRect for visual representation)
			var tile = ColorRect.new()
			tile.color = LIGHT_COLOR if (x + y) % 2 == 0 else DARK_COLOR  # Alternate colors
			tile.size = Vector2(TILE_SIZE, TILE_SIZE)
			tile.position = Vector2(x * TILE_SIZE, -y * TILE_SIZE)
			add_child(tile)

func place_white_pawns():
	for x in range(BOARD_SIZE):
		var pawn = WHITE_PAWN.instantiate()
		pawn.name = "WhitePawn_" + str(x) + "_1"  # Set a unique name
		pawn.position = get_centered_position(x, 1)  # Row 1 for white pawns
		add_child(pawn)
		board_state[1][x] = pawn  # Update the board state

func place_black_pawns():
	for x in range(BOARD_SIZE):
		var pawn = BLACK_PAWN.instantiate()
		pawn.name = "BlackPawn_" + str(x) + "_6"  # Set a unique name (e.g., BlackPawn_0_6 for column 0, row 6)
		pawn.position = get_centered_position(x, 6)  # Row 6 for black pawns
		add_child(pawn)
		board_state[6][x] = pawn  # Update the board state

func place_white_knights():
	# Place white knights at columns 1 and 6 on row 0
	var knight_positions = [1, 6]
	for x in knight_positions:
		var knight = WHITE_KNIGHT.instantiate()
		knight.name = "WhiteKnight_" + str(x) + "_0"  # Set a unique name
		knight.position = get_centered_position(x, 0)  # Row 0 for white knights
		add_child(knight)
		board_state[0][x] = knight  # Update the board state

func place_black_knights():
	# Place black knights at columns 1 and 6 on row 7
	var knight_positions = [1, 6]
	for x in knight_positions:
		var knight = BLACK_KNIGHT.instantiate()
		knight.name = "BlackKnight_" + str(x) + "_7"  # Set a unique name
		knight.position = get_centered_position(x, 7)  # Row 7 for black knights
		add_child(knight)
		board_state[7][x] = knight  # Update the board state

func place_black_bishops():
	# Place black bishops at columns 2 and 5 on row 7
	var bishop_positions = [2, 5]
	for x in bishop_positions:
		var bishop = BLACK_BISHOP.instantiate()
		bishop.name = "BlackBishop_" + str(x) + "_7"  # Set a unique name
		bishop.position = get_centered_position(x, 7)  # Row 7 for black bishops
		add_child(bishop)
		board_state[7][x] = bishop  # Update the board state

func place_black_rooks():
	# Place black rooks at columns 0 and 7 on row 7
	var rook_positions = [0, 7]
	for x in rook_positions:
		var rook = BLACK_ROOK.instantiate()
		rook.name = "BlackRook_" + str(x) + "_7"  # Set a unique name
		rook.position = get_centered_position(x, 7)  # Row 7 for black rooks
		add_child(rook)
		board_state[7][x] = rook  # Update the board state

func place_white_bishops():
	# Place white bishops at columns 2 and 5 on row 0
	var bishop_positions = [2, 5]
	for x in bishop_positions:
		var bishop = WHITE_BISHOP.instantiate()
		bishop.name = "WhiteBishop_" + str(x) + "_0"  # Set a unique name
		bishop.position = get_centered_position(x, 0)  # Row 0 for white bishops
		add_child(bishop)
		board_state[0][x] = bishop  # Update the board state

func place_white_rooks():
	# Place white rooks at columns 0 and 7 on row 0
	var rook_positions = [0, 7]
	for x in rook_positions:
		var rook = WHITE_ROOK.instantiate()
		rook.name = "WhiteRook_" + str(x) + "_0"  # Set a unique name
		rook.position = get_centered_position(x, 0)  # Row 0 for white rooks
		add_child(rook)
		board_state[0][x] = rook  # Update the board state

func place_white_queen():
	# Place the white queen at column 3 on row 0
	var queen = WHITE_QUEEN.instantiate()
	queen.position = get_centered_position(3, 0)  # Row 0, column 3 for white queen
	add_child(queen)
	board_state[0][3] = queen  # Update the board state

func place_white_king():
	# Place the white king at column 4 on row 0
	var king = WHITE_KING.instantiate()
	king.position = get_centered_position(4, 0)  # Row 0, column 4 for white king
	add_child(king)
	board_state[0][4] = king  # Update the board state

func place_black_queen():
	# Place the black queen at column 3 on row 7
	var queen = BLACK_QUEEN.instantiate()
	queen.position = get_centered_position(3, 7)  # Row 7, column 3 for black queen
	add_child(queen)
	board_state[7][3] = queen  # Update the board state

func place_black_king():
	# Place the black king at column 4 on row 7
	var king = BLACK_KING.instantiate()
	king.position = get_centered_position(4, 7)  # Row 7, column 4 for black king
	add_child(king)
	board_state[7][4] = king  # Update the board state

#endregion

#region board/mouse_settings


func get_centered_position(x: int, y: int) -> Vector2:
	# Returns the centered position for a piece on the given x and y
	return Vector2(x * TILE_SIZE + (TILE_SIZE / 2.0), -y * TILE_SIZE + (TILE_SIZE / 2.0) - (TILE_SIZE - adjust_hight))

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			var grid_coordinates = get_grid_coordinates(mouse_pos)
			var x = grid_coordinates.x
			var y = grid_coordinates.y

			if is_within_board(x, y):
				if selected_piece == null:
					select_piece(x, y)
				else:
					move_selected_piece(x, y)

func get_grid_coordinates(mouse_pos: Vector2) -> Vector2:
	var snapped_x = floor(mouse_pos.x / TILE_SIZE) * TILE_SIZE
	var snapped_y = floor(mouse_pos.y / TILE_SIZE) * TILE_SIZE
	var x = int(snapped_x / TILE_SIZE)
	var y = int(-snapped_y / TILE_SIZE)  # Negative because y-axis is flipped
	if is_within_board(x, y):  # Ensure the coordinates are valid
		return Vector2(x, y)
	return Vector2(-1, -1)  # Return an invalid position if out of bounds

func select_piece(x: int, y: int):
	if is_within_board(x, y) and is_tile_occupied(x, y):  # Ensure the tile is valid and occupied
		var piece = board_state[y][x]
		var is_white_piece = piece.name.begins_with("White")
		if is_white_piece == is_white_turn:  # Only allow selecting pieces of the current turn's color
			selected_piece = piece
			selected_piece_position = Vector2(x, y)
			var moves = get_pawn_moves(x, y, is_white_piece)
			print("Possible moves for pawn at (", x, ", ", y, "): ", moves)
			highlight_possible_moves(moves)
		else:
			print("It's not your turn!")

func move_selected_piece(x: int, y: int):
	var moves = get_pawn_moves(selected_piece_position.x, selected_piece_position.y, selected_piece.name.begins_with("White"))
	if Vector2(x, y) in moves:
		move_piece(selected_piece, selected_piece_position, Vector2(x, y))
		moves_this_turn += 1  # Increment the move counter
		check_turn_end()  # Check if the turn should end
	else:
		print("Invalid move")
	deselect_piece()

func deselect_piece():
	selected_piece = null
	selected_piece_position = null
	clear_move_highlights()

func is_tile_occupied(x: int, y: int) -> bool:
	# Ensure the coordinates are within the board bounds
	if not is_within_board(x, y):
		return false  # Return false if the tile is out of bounds
	return board_state[y][x] != null

func is_within_board(x: int, y: int) -> bool:
	return x >= 0 and x < BOARD_SIZE and y >= 0 and y < BOARD_SIZE


#endregion

#region general_move_settings

func move_piece(piece, from_position: Vector2, to_position: Vector2):
	var captured_piece = null

	# Handle en passant capture
	handle_en_passant(from_position, to_position)

	# Check if the target tile is occupied by an opponent
	if is_tile_occupied(int(to_position.x), int(to_position.y)):
		captured_piece = board_state[to_position.y][to_position.x]
		if captured_piece:
			# Remove the captured piece from the scene tree
			captured_piece.queue_free()

	# Handle double forward move by a pawn
	handle_double_forward_move(piece, from_position, to_position)

	# Update the board state
	board_state[from_position.y][from_position.x] = null  # Clear the old position
	board_state[to_position.y][to_position.x] = piece  # Set the new position
	
	# Update the piece's position
	piece.position = get_centered_position(int(to_position.x), int(to_position.y))
	print("Moved piece from (", from_position, ") to (", to_position, ")")

	# Check for pawn promotion
	if piece.name.find("Pawn") != -1:
		handle_pawn_promotion(piece, to_position)

func is_tile_occupied_by_opponent(x: int, y: int, is_white_piece: bool) -> bool:
	if not is_tile_occupied(x, y):
		return false
	var piece = board_state[y][x]
	return (is_white_piece and piece.name.begins_with("Black")) or (not is_white_piece and piece.name.begins_with("White"))

func highlight_possible_moves(moves: Array):
	# Clear existing highlights
	clear_move_highlights()

	# Add new highlights
	for move in moves:
		var highlight = PIECE_MOVE.instantiate()
		highlight.position = Vector2(move.x * TILE_SIZE + TILE_SIZE / 2.0, -move.y * TILE_SIZE + TILE_SIZE / 2.0)
		add_child(highlight)
		move_highlights.append(highlight)  # Track the highlight

func clear_move_highlights():
	for highlight in move_highlights:
		if highlight:
			highlight.queue_free()
	move_highlights.clear()  # Clear the list


#endregion

#region piece_moves

func get_pawn_moves(x: int, y: int, is_white_piece: bool) -> Array:
	var moves = []
	var direction = 1 if is_white_piece else -1  # White pawns move up (-1), black pawns move down (+1)
	# Forward move
	if is_within_board(x, y + direction):
		if not is_tile_occupied(x, y + direction):
			moves.append(Vector2(x, y + direction))
	# Double forward move (only if on starting row)
	var starting_row = 1 if is_white_piece else 6
	if y == starting_row:
		if not is_tile_occupied(x, y + direction) and not is_tile_occupied(x, y + 2 * direction):
			moves.append(Vector2(x, y + 2 * direction))
		else:
			print("Double forward move blocked")
	# Capture moves (diagonally forward)
	for dx in [-1, 1]:  # Check both left and right diagonals
		var target_x = x + dx
		var target_y = y + direction
		if is_within_board(target_x, target_y):
			if is_tile_occupied_by_opponent(target_x, target_y, is_white_piece):
				print("Capture move to: (", target_x, ", ", target_y, ") is valid")
				moves.append(Vector2(target_x, target_y))
			elif is_tile_occupied_by_opponent(target_x + 1 * direction, target_y + 1 * direction, is_white_piece) && \
			((y == 4) || (y == 3)) && en_passant == Vector2(target_x, target_y):
				moves.append(en_passant)
	return moves

func handle_en_passant(from_position: Vector2, to_position: Vector2) -> void:
	var captured_piece = null
	# Check for en passant capture for black pawns
	if en_passant_capture_black and from_position.y == 4 and abs(to_position.x - from_position.x) == 1:
		var captured_piece_position = Vector2(to_position.x, to_position.y - 1)
		if is_tile_occupied(int(captured_piece_position.x), int(captured_piece_position.y)):
			captured_piece = board_state[int(captured_piece_position.y)][int(captured_piece_position.x)]
			if captured_piece:
				captured_piece.queue_free()
				board_state[int(captured_piece_position.y)][int(captured_piece_position.x)] = null
				en_passant_capture_black = false
				print("en_passant_capture_black = false")
	# Check for en passant capture for white pawns
	elif en_passant_capture_white and from_position.y == 3 and abs(to_position.x - from_position.x) == 1:
		var captured_piece_position = Vector2(to_position.x, to_position.y + 1)
		if is_tile_occupied(int(captured_piece_position.x), int(captured_piece_position.y)):
			captured_piece = board_state[int(captured_piece_position.y)][int(captured_piece_position.x)]
			if captured_piece:
				captured_piece.queue_free()
				board_state[int(captured_piece_position.y)][int(captured_piece_position.x)] = null
				en_passant_capture_white = false
				print("en_passant_capture_white = false")

func handle_double_forward_move(piece, from_position: Vector2, to_position: Vector2) -> void:
	# Check if the piece is a pawn
	if piece.name.find("Pawn") != -1:
		var starting_row = 1 if piece.name.begins_with("White") else 6
		# Check if the move is a double forward move from the starting row
		if abs(to_position.y - from_position.y) == 2 and from_position.y == starting_row:
			en_passant = Vector2(to_position.x, (to_position.y + from_position.y) / 2)  # Set en passant target square
			if piece.name.begins_with("White"):
				en_passant_capture_white = true
				print("en_passant_capture_white = true")
			else:
				en_passant_capture_black = true
				print("en_passant_capture_black = true")

#endregion

#region turn_settings

func check_turn_end():
	if is_promotion_in_progress:
		print("Turn cannot end because a promotion is in progress.")
		return  # Do not end the turn if a promotion is in progress

	if moves_this_turn >= max_moves_per_turn:
		# Reset en passant variables
		if !is_white_turn:
			en_passant_capture_white = false
			print("en passant white false")
		elif is_white_turn:
			en_passant_capture_black = false
			print("en passant black false")

		# Reset the move counter and switch turns
		moves_this_turn = 0
		is_white_turn = not is_white_turn
		print("Turn switched. It's now ", "White's" if is_white_turn else "Black's", " turn.")

func set_turn_rules(max_moves: int):
	max_moves_per_turn = max_moves
	print("Turn rules updated: ", max_moves_per_turn, " moves per turn.")

func _on_end_turn_pressed() -> void:
	# Reset en_passant variables
	if is_white_turn:
		en_passant_capture_white = false
	else:
		en_passant_capture_black = false

	# Reset the move counter and switch turns
	moves_this_turn = 0
	is_white_turn = not is_white_turn
	
	# Clear any selected piece and move highlights
	deselect_piece()

	print("Turn switched. It's now ", "White's" if is_white_turn else "Black's", " turn.")

#endregion


func handle_pawn_promotion(pawn, target_position: Vector2) -> void:
	# Check if the pawn has reached the last rank
	if pawn.name.begins_with("White") and target_position.y == 7:
		print("White pawn reached the last rank at position: ", target_position)
		promotion_pawn = pawn
		promotion_position = target_position
		is_promotion_in_progress = true  # Set promotion in progress
		white_2.visible = true
		white_3.visible = true
		white_4.visible = true
		white_5.visible = true
	elif pawn.name.begins_with("Black") and target_position.y == 0:
		print("Black pawn reached the last rank at position: ", target_position)
		promotion_pawn = pawn
		promotion_position = target_position
		is_promotion_in_progress = true  # Set promotion in progress
		black_2.visible = true
		black_3.visible = true
		black_4.visible = true
		black_5.visible = true

func _on_white_5_pressed():
	promote_pawn("Queen", WHITE_QUEEN)

func _on_white_4_pressed():
	promote_pawn("Rook", WHITE_ROOK)

func _on_white_3_pressed():
	promote_pawn("Bishop", WHITE_BISHOP)

func _on_white_2_pressed():
	print("Button pressed")
	promote_pawn("Knight", WHITE_KNIGHT)

func _on_black_5_pressed():
	promote_pawn("Queen", BLACK_QUEEN)

func _on_black_4_pressed():
	promote_pawn("Rook", BLACK_ROOK)

func _on_black_3_pressed():
	promote_pawn("Bishop", BLACK_BISHOP)

func _on_black_2_pressed():
	promote_pawn("Knight", BLACK_KNIGHT)

func promote_pawn(piece_name: String, piece_scene: PackedScene):
	if promotion_pawn == null or promotion_position == null:
		print("No pawn to promote!")
		return

	# Remove the pawn from the board and scene tree
	board_state[int(promotion_position.y)][int(promotion_position.x)] = null
	promotion_pawn.queue_free()

	# Instantiate the new piece and place it on the board
	var new_piece = piece_scene.instantiate()
	new_piece.name = promotion_pawn.name.replace("Pawn", piece_name)
	new_piece.position = get_centered_position(int(promotion_position.x), int(promotion_position.y))
	add_child(new_piece)
	board_state[int(promotion_position.y)][int(promotion_position.x)] = new_piece

	# Hide the promotion controls
	white_2.visible = false
	white_3.visible = false
	white_4.visible = false
	white_5.visible = false
	black_2.visible = false
	black_3.visible = false
	black_4.visible = false
	black_5.visible = false
	# Reset promotion variables
	promotion_pawn = null
	promotion_position = null
	is_promotion_in_progress = false  # Reset promotion in progress
	check_turn_end()
