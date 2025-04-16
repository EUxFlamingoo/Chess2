extends Node2D

# select_piece needto be updated when new unit is added

const TILE_SIZE = 64  # Modify
const BOARD_WIDTH = 8  # Modify
const BOARD_HEIGHT = 8  # Modify
const First_Rank = 0  # Modify with caution
const Last_Rank = BOARD_HEIGHT - 1 # Modify with caution
const Fist_File = 0  # Modify with caution
const Last_File = BOARD_WIDTH - 1  # Modify with caution
const adjust_height = TILE_SIZE / 1.01  # Modify
const LIGHT_COLOR = Color(0.4, 0.3, 0.2)  # Modify
const DARK_COLOR = Color(0.3, 0.2, 0.1)  # Modify

var board_state = []
var selected_piece = null
var selected_piece_position = null


#region create/initialize_board

func initialize():
	board_state = []
	for y in range(BOARD_HEIGHT):  # Use BOARD_HEIGHT for the number of rows
		var row = []
		for x in range(BOARD_WIDTH):  # Use BOARD_WIDTH for the number of columns
			row.append(null)
		board_state.append(row)
	setup_board()

func setup_board():
	create_chessboard()

func initialize_board_state():
	# Initialize the board state with null values (empty tiles)
	board_state = []
	for y in range(BOARD_HEIGHT):  # Use BOARD_HEIGHT for the number of rows
		var row = []
		for x in range(BOARD_WIDTH):  # Use BOARD_WIDTH for the number of columns
			row.append(null)  # null means the tile is empty
		board_state.append(row)

func create_chessboard():
	for y in range(BOARD_HEIGHT):  # Use BOARD_HEIGHT for the number of rows
		for x in range(BOARD_WIDTH):  # Use BOARD_WIDTH for the number of columns
			var tile = ColorRect.new()
			tile.color = LIGHT_COLOR if (x + y) % 2 == 0 else DARK_COLOR
			tile.size = Vector2(TILE_SIZE, TILE_SIZE)
			tile.position = Vector2(x * TILE_SIZE, -y * TILE_SIZE)
			add_child(tile)


#endregion

#region input/grid

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
					MoveManager.move_selected_piece(x, y)

func get_centered_position(x: int, y: int) -> Vector2:
	# Returns the centered position for a piece on the given x and y
	return Vector2(x * TILE_SIZE + (TILE_SIZE / 2.0), -y * TILE_SIZE + (TILE_SIZE / 2.0) - (TILE_SIZE - adjust_height))

func get_grid_coordinates(mouse_pos: Vector2) -> Vector2:
	var snapped_x = floor(mouse_pos.x / TILE_SIZE) * TILE_SIZE
	var snapped_y = floor(mouse_pos.y / TILE_SIZE) * TILE_SIZE
	var x = int(snapped_x / TILE_SIZE)
	var y = int(-snapped_y / TILE_SIZE)  # Negative because y-axis is flipped
	if is_within_board(x, y):  # Ensure the coordinates are valid
		return Vector2(x, y)
	return Vector2(-1, -1)  # Return an invalid position if out of bounds

func is_within_board(x: int, y: int) -> bool:
	# Check if the coordinates are within the board bounds
	return x >= 0 and x < BOARD_WIDTH and y >= 0 and y < BOARD_HEIGHT

#endregion

#region select/deselect_unit

func select_piece(x: int, y: int):
	if is_within_board(x, y) and is_tile_occupied(x, y):
		var piece = board_state[y][x]
		var is_white_piece = piece.name.begins_with("White")
		if is_white_piece == TurnManager.is_white_turn:
			selected_piece = piece
			selected_piece_position = Vector2(x, y)
			var moves = []
			if piece.name.find("Pawn") != -1:
				moves = UnitManager.get_pawn_moves(x, y, is_white_piece)
			elif piece.name.find("Rook") != -1:
				moves = UnitManager.get_rook_moves(x, y, is_white_piece)
			elif piece.name.find("Bishop") != -1:
				moves = UnitManager.get_bishop_moves(x, y, is_white_piece)
			elif piece.name.find("Queen") != -1:
				moves = UnitManager.get_queen_moves(x, y, is_white_piece)
			elif piece.name.find("King") != -1:
				moves = UnitManager.get_king_moves(x, y, is_white_piece)
			elif piece.name.find("Knight") != -1:
				moves = UnitManager.get_knight_moves(x, y, is_white_piece)
			MoveManager.highlight_possible_moves(moves)

func deselect_piece():
	BoardManager.selected_piece = null
	BoardManager.selected_piece_position = null
	MoveManager.clear_move_highlights()

#endregion

#region tile_occupience

func is_tile_occupied(x: int, y: int) -> bool:
	# Ensure the coordinates are within the board bounds
	if not is_within_board(x, y):
		return false  # Return false if the tile is out of bounds
	return board_state[y][x] != null

func is_tile_occupied_by_opponent(x: int, y: int, is_white_piece: bool) -> bool:
	if not is_tile_occupied(x, y):
		return false
	var piece = BoardManager.board_state[y][x]
	return (is_white_piece and piece.name.begins_with("Black")) or (not is_white_piece and piece.name.begins_with("White"))


#endregion
