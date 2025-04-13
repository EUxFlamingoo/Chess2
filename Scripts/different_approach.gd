extends Node2D

const TILE_SIZE = 64  # Size of each tile in pixels
const adjust_hight = TILE_SIZE / 1.03 # increase to adjust height on tile
const BOARD_SIZE = 8  # 8x8 chessboard

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

const LIGHT_COLOR = Color(0.4, 0.3, 0.2)  # Light tile color (e.g., beige)
const DARK_COLOR = Color(0.3, 0.2, 0.1)   # Dark tile color (e.g., brown)

func _ready():
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


#region place_pieces

func create_chessboard():
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			var tile = ColorRect.new()
			tile.color = LIGHT_COLOR if (row + col) % 2 == 0 else DARK_COLOR  # Alternate colors
			tile.size = Vector2(TILE_SIZE, TILE_SIZE)
			tile.position = Vector2(col * TILE_SIZE, -row * TILE_SIZE)
			add_child(tile)

func place_white_pawns():
	for col in range(BOARD_SIZE):
		var pawn = WHITE_PAWN.instantiate()
		pawn.position = get_centered_position(col, 1)  # Row 1 for white pawns
		add_child(pawn)

func place_black_pawns():
	for col in range(BOARD_SIZE):
		var pawn = BLACK_PAWN.instantiate()
		pawn.position = get_centered_position(col, 6)
		add_child(pawn)

func place_white_knights():
	# Place white knights at columns 1 and 6 on row 0
	var knight_positions = [1, 6]
	for col in knight_positions:
		var knight = WHITE_KNIGHT.instantiate()
		knight.position = get_centered_position(col, 0)  # Row 0 for white knights
		add_child(knight)

func place_black_knights():
	# Place black knights at columns 1 and 6 on row 0
	var knight_positions = [1, 6]
	for col in knight_positions:
		var knight = BLACK_KNIGHT.instantiate()
		knight.position = get_centered_position(col, 7)  # Row 0 for black knights
		add_child(knight)

func place_black_bishops():
	# Place black knights at columns 1 and 6 on row 0
	var bishop_positions = [2, 5]
	for col in bishop_positions:
		var bishop = BLACK_BISHOP.instantiate()
		bishop.position = get_centered_position(col, 7)  # Row 0 for black bishops
		add_child(bishop)

func place_black_rooks():
	# Place black knights at columns 1 and 6 on row 0
	var rook_positions = [0, 7]
	for col in rook_positions:
		var rook = BLACK_ROOK.instantiate()
		rook.position = get_centered_position(col, 7)  # Row 0 for black rooks
		add_child(rook)

func place_white_bishops():
	# Place white bishops at columns 2 and 5 on row 0
	var bishop_positions = [2, 5]
	for col in bishop_positions:
		var bishop = WHITE_BISHOP.instantiate()
		bishop.position = get_centered_position(col, 0)  # Row 0 for white bishops
		add_child(bishop)

func place_white_rooks():
	# Place white rooks at columns 0 and 7 on row 0
	var rook_positions = [0, 7]
	for col in rook_positions:
		var rook = WHITE_ROOK.instantiate()
		rook.position = get_centered_position(col, 0)  # Row 0 for white rooks
		add_child(rook)

func place_white_queen():
	# Place the white queen at column 3 on row 0
	var queen = WHITE_QUEEN.instantiate()
	queen.position = get_centered_position(3, 0)  # Row 0, column 3 for white queen
	add_child(queen)

func place_white_king():
	# Place the white king at column 4 on row 0
	var king = WHITE_KING.instantiate()
	king.position = get_centered_position(4, 0)  # Row 0, column 4 for white king
	add_child(king)

func place_black_queen():
	# Place the black queen at column 3 on row 7
	var queen = BLACK_QUEEN.instantiate()
	queen.position = get_centered_position(3, 7)  # Row 7, column 3 for black queen
	add_child(queen)

func place_black_king():
	# Place the black king at column 4 on row 7
	var king = BLACK_KING.instantiate()
	king.position = get_centered_position(4, 7)  # Row 7, column 4 for black king
	add_child(king)


#endregion

func get_centered_position(col: int, row: int) -> Vector2:
	# Returns the centered position for a piece on the given column and row
	return Vector2(col * TILE_SIZE + (TILE_SIZE / 2), -row * TILE_SIZE + (TILE_SIZE / 2) - (TILE_SIZE - adjust_hight))
