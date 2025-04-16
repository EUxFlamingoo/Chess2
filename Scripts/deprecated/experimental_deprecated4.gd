extends Sprite2D

#region const
# Constants for board size and cell width
const BOARD_SIZE = 8
const CELL_WIDTH = 18

# Preload texture holder scene
const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")

# Preload textures for black pieces
const BLACK_BISHOP = preload("res://Assets/black_bishop.png")
const BLACK_KING = preload("res://Assets/black_king.png")
const BLACK_KNIGHT = preload("res://Assets/black_knight.png")
const BLACK_PAWN = preload("res://Assets/black_pawn.png")
const BLACK_QUEEN = preload("res://Assets/black_queen.png")
const BLACK_ROOK = preload("res://Assets/black_rook.png")

# Preload textures for white pieces
const WHITE_BISHOP = preload("res://Assets/white_bishop.png")
const WHITE_KING = preload("res://Assets/white_king.png")
const WHITE_KNIGHT = preload("res://Assets/white_knight.png")
const WHITE_PAWN = preload("res://Assets/white_pawn.png")
const WHITE_QUEEN = preload("res://Assets/white_queen.png")
const WHITE_ROOK = preload("res://Assets/white_rook.png")

# Preload textures for turn indicators
const TURN_WHITE = preload("res://Assets/turn-white.png")
const TURN_BLACK = preload("res://Assets/turn-black.png")

# Preload texture for piece movement indicator
const PIECE_MOVE = preload("res://Assets/Piece_move.png")

# Piece values for evaluation
const PIECE_VALUES = {
	1: 10,    # White Pawn
	2: 30,    # White Knight
	3: 30,    # White Bishop
	4: 50,    # White Rook
	5: 90,    # White Queen
	6: 900,   # White King (never scored)
}

# Mapping of chess notation to board indices
const CHESS_NOTATION_TO_INDEX = {
	"A1": Vector2(0, 0), "B1": Vector2(0, 1), "C1": Vector2(0, 2), "D1": Vector2(0, 3),
	"E1": Vector2(0, 4), "F1": Vector2(0, 5), "G1": Vector2(0, 6), "H1": Vector2(0, 7),
	"A2": Vector2(1, 0), "B2": Vector2(1, 1), "C2": Vector2(1, 2), "D2": Vector2(1, 3),
	"E2": Vector2(1, 4), "F2": Vector2(1, 5), "G2": Vector2(1, 6), "H2": Vector2(1, 7),
	"A3": Vector2(2, 0), "B3": Vector2(2, 1), "C3": Vector2(2, 2), "D3": Vector2(2, 3),
	"E3": Vector2(2, 4), "F3": Vector2(2, 5), "G3": Vector2(2, 6), "H3": Vector2(2, 7),
	"A4": Vector2(3, 0), "B4": Vector2(3, 1), "C4": Vector2(3, 2), "D4": Vector2(3, 3),
	"E4": Vector2(3, 4), "F4": Vector2(3, 5), "G4": Vector2(3, 6), "H4": Vector2(3, 7),
	"A5": Vector2(4, 0), "B5": Vector2(4, 1), "C5": Vector2(4, 2), "D5": Vector2(4, 3),
	"E5": Vector2(4, 4), "F5": Vector2(4, 5), "G5": Vector2(4, 6), "H5": Vector2(4, 7),
	"A6": Vector2(5, 0), "B6": Vector2(5, 1), "C6": Vector2(5, 2), "D6": Vector2(5, 3),
	"E6": Vector2(5, 4), "F6": Vector2(5, 5), "G6": Vector2(5, 6), "H6": Vector2(5, 7),
	"A7": Vector2(6, 0), "B7": Vector2(6, 1), "C7": Vector2(6, 2), "D7": Vector2(6, 3),
	"E7": Vector2(6, 4), "F7": Vector2(6, 5), "G7": Vector2(6, 6), "H7": Vector2(6, 7),
	"A8": Vector2(7, 0), "B8": Vector2(7, 1), "C8": Vector2(7, 2), "D8": Vector2(7, 3),
	"E8": Vector2(7, 4), "F8": Vector2(7, 5), "G8": Vector2(7, 6), "H8": Vector2(7, 7)
}

# Mapping of piece values to descriptive names
const PIECE_MAPPING = {
	-6: "BLACK_KING",
	-5: "BLACK_QUEEN",
	-4: "BLACK_ROOK",
	-3: "BLACK_BISHOP",
	-2: "BLACK_KNIGHT",
	-1: "BLACK_PAWN",
	0: "EMPTY_FIELD",
	6: "WHITE_KING",
	5: "WHITE_QUEEN",
	4: "WHITE_ROOK",
	3: "WHITE_BISHOP",
	2: "WHITE_KNIGHT",
	1: "WHITE_PAWN"
}

# Invert PIECE_MAPPING for reverse lookups
var INVERTED_PIECE_MAPPING = {}
func _init():
	INVERTED_PIECE_MAPPING = invert_dictionary(PIECE_MAPPING)

# Direction vectors for sliding pieces
const ROOK_DIRECTIONS = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
const BISHOP_DIRECTIONS = [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
const QUEEN_DIRECTIONS = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
const KING_DIRECTIONS = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
const KNIGHT_DIRECTIONS = [Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(1, -2),
	Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)]

#endregion

#region var
# Onready variables for accessing nodes
@onready var pieces = $Pieces
@onready var dots = $Dots
@onready var turn = $Turn
@onready var white_pieces = $"../CanvasLayer/white_pieces"
@onready var black_pieces = $"../CanvasLayer/black_pieces"
@onready var player_2: Button = $"../player_2"
@onready var player_1: Button = $"../player_1"
@onready var game_finish: Button = $"../game_finish"

# Board representation and game state variables
var board : Array
var white : bool = true
var state : bool = false
var moves = []
var selected_piece : Vector2

var promotion_square = null

# Castling rights
var white_king = false
var black_king = false
var white_rook_left = false
var white_rook_right = false
var black_rook_left = false
var black_rook_right = false

var en_passant = null

# King positions
var white_king_pos = Vector2(0, 4)
var black_king_pos = Vector2(7, 4)

var fifty_move_rule = 0

# Threefold repetition tracking
var unique_board_moves : Array = []
var amount_of_same : Array = []

# AI settings
var ai_enabled := true #TODO AI 1
#endregion

#region ready/input/board

# Function to handle player 2 button press
func _on_player_2_pressed() -> void:
	player_2.visible = false
	player_1.visible = false
	ai_enabled = false

# Function to handle player 1 button press
func _on_player_1_pressed() -> void:
	player_2.visible = false
	player_1.visible = false
	ai_enabled = true

# Function called when the node is ready
func _ready() -> void:
	randomize() #Seed Game for opening move and random moves
	# Initialize the board with starting positions
	board = Array([
		[4, 2, 3, 5, 6, 3, 2, 4],
		[1, 1, 1, 1, 1, 1, 1, 1],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[-1, -1, -1, -1, -1, -1, -1, -1],
		[-4, -2, -3, -5, -6, -3, -2, -4]
	])
	
	display_board()
	
	# Connect button signals for white and black pieces
	var white_buttons = get_tree().get_nodes_in_group("white_pieces")
	var black_buttons = get_tree().get_nodes_in_group("black_pieces")
	
	for button in white_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
		
	for button in black_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
	
# Function to handle input events
func _input(event):
	if event is InputEventMouseButton && event.pressed && promotion_square == null:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out(): return
			var var1 = snapped(get_global_mouse_position().x, 0) / CELL_WIDTH
			var var2 = abs(snapped(get_global_mouse_position().y, 0)) / CELL_WIDTH
			if !state && (white && board[var2][var1] > 0 || !white && board[var2][var1] < 0):
				selected_piece = Vector2(var2, var1)
				show_options()
				state = true
			elif state: set_move(var2, var1)
			
# Function to check if the mouse is out of the board
func is_mouse_out():
	if get_rect().has_point(to_local(get_global_mouse_position())): return false
	return true

# Function to display the board with pieces
func display_board():
	@warning_ignore("integer_division")
	for child in pieces.get_children():
		child.queue_free()
	
	# Map piece values to textures
	var piece_textures = {
		-6: BLACK_KING,
		-5: BLACK_QUEEN,
		-4: BLACK_ROOK,
		-3: BLACK_BISHOP,
		-2: BLACK_KNIGHT,
		-1: BLACK_PAWN,
		0: null,
		6: WHITE_KING,
		5: WHITE_QUEEN,
		4: WHITE_ROOK,
		3: WHITE_BISHOP,
		2: WHITE_KNIGHT,
		1: WHITE_PAWN
	}
	
	# Instantiate texture holders for each piece
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			@warning_ignore("integer_division")
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2), -i * CELL_WIDTH - (CELL_WIDTH / 2))
			holder.texture = piece_textures.get(board[i][j], null)
			
	# Update turn indicator
	if white: turn.texture = TURN_WHITE
	else: turn.texture = TURN_BLACK
#endregion

#region set_moves/dots
# Function to show available moves for the selected piece
func show_options():
	moves = get_moves(selected_piece)
	if moves == []:
		state = false
		return
	show_dots()
	
# Function to display dots for available moves
func show_dots():
	for i in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		@warning_ignore("integer_division")
		holder.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH / 2), -i.x * CELL_WIDTH - (CELL_WIDTH / 2))

# Function to delete move dots
func delete_dots():
	for child in dots.get_children():
		child.queue_free()

# Function to set a move for the selected piece
func set_move(var2, var1):
	var just_now = false
	for i in moves:
		if i.x == var2 && i.y == var1:
			fifty_move_rule += 1
			if get_position_state(Vector2(var2, var1)) == "enemy": fifty_move_rule = 0
			match board[selected_piece.x][selected_piece.y]:
				1:
					fifty_move_rule = 0
					if i.x == 7: promote(i)
					if i.x == 3 && selected_piece.x == 1:
						en_passant = i
						just_now = true
					elif en_passant != null:
						if en_passant.y == i.y && selected_piece.y != i.y && en_passant.x == selected_piece.x:
							board[en_passant.x][en_passant.y] = 0
				-1:
					fifty_move_rule = 0
					if ai_enabled == false:
						if i.x == 0: promote(i)
					if ai_enabled == true:
						if i.x == 0:
							ai_promote(i) #TODO AI 3
							return
					if i.x == 4 && selected_piece.x == 6:
						en_passant = i
						just_now = true
					elif en_passant != null:
						if en_passant.y == i.y && selected_piece.y != i.y && en_passant.x == selected_piece.x:
							board[en_passant.x][en_passant.y] = 0
				4:
					if selected_piece.x == 0 && selected_piece.y == 0: white_rook_left = true
					elif selected_piece.x == 0 && selected_piece.y == 7: white_rook_right = true
				-4:
					if selected_piece.x == 7 && selected_piece.y == 0: black_rook_left = true
					elif selected_piece.x == 7 && selected_piece.y == 7: black_rook_right = true
				6:
					if selected_piece.x == 0 && selected_piece.y == 4:
						white_king = true
						if i.y == 2:
							white_rook_left = true
							white_rook_right = true
							board[0][0] = 0
							board[0][3] = 4
						elif i.y == 6:
							white_rook_left = true
							white_rook_right = true
							board[0][7] = 0
							board[0][5] = 4
					white_king_pos = i
				-6:
					if selected_piece.x == 7 && selected_piece.y == 4:
						black_king = true
						if i.y == 2:
							black_rook_left = true
							black_rook_right = true
							board[7][0] = 0
							board[7][3] = -4
						elif i.y == 6:
							black_rook_left = true
							black_rook_right = true
							board[7][7] = 0
							board[7][5] = -4
					black_king_pos = i
			if !just_now: en_passant = null
			board[var2][var1] = board[selected_piece.x][selected_piece.y]
			board[selected_piece.x][selected_piece.y] = 0
			white = !white
			threefold_position(board)
			display_board()
			if !white and ai_enabled: #TODO AI 2
				await get_tree().create_timer(0.3).timeout
				ai_move() #FIXME change ai
			break
	delete_dots()
	state = false
	
	# Check for stalemate or checkmate
	if (selected_piece.x != var2 || selected_piece.y != var1) && (white && board[var2][var1] > 0 || !white && board[var2][var1] < 0):
		selected_piece = Vector2(var2, var1)
		show_options()
		state = true
	elif is_stalemate():
		if white && is_in_check(white_king_pos) || !white && is_in_check(black_king_pos):
			print("CHECKMATE")
			white = true
			game_finish.text = "Checkmate"
			game_finish.visible = true
			
		else:
			print("DRAW")
			white = true
			game_finish.text = "Draw"
			game_finish.visible = true
		
	# Check for draw conditions
	if fifty_move_rule == 50:
		print("DRAW")
		white = true
		game_finish.text = "Draw"
		game_finish.visible = true
	elif insuficient_material():
		print("DRAW")
		white = true
		game_finish.text = "Draw"
		game_finish.visible = true

#endregion

#region get_moves
# Function to get available moves for a selected piece
func get_moves(selected : Vector2):
	var _moves = []
	match abs(board[selected.x][selected.y]):
		1: _moves = get_pawn_moves(selected)
		2: _moves = get_knight_moves(selected)
		3: _moves = get_bishop_moves(selected)
		4: _moves = get_rook_moves(selected)
		5: _moves = get_queen_moves(selected)
		6: _moves = get_king_moves(selected)
		
	return _moves

# Function to get moves for sliding pieces (rook, bishop, queen)
func get_sliding_piece_moves(piece_position : Vector2, directions : Array, piece_value : int):
	var _moves = []
	for i in directions:
		var pos = piece_position
		pos += i
		while is_valid_position(pos):
			var position_state = get_position_state(pos)
			if position_state == "empty":
				board[pos.x][pos.y] = piece_value
				board[piece_position.x][piece_position.y] = 0
				if white && !is_in_check(white_king_pos) || !white && !is_in_check(black_king_pos): _moves.append(pos)
				board[pos.x][pos.y] = 0
				board[piece_position.x][piece_position.y] = piece_value
			elif position_state == "enemy":
				var t = board[pos.x][pos.y]
				board[pos.x][pos.y] = piece_value
				board[piece_position.x][piece_position.y] = 0
				if white && !is_in_check(white_king_pos) || !white && !is_in_check(black_king_pos): _moves.append(pos)
				board[pos.x][pos.y] = t
				board[piece_position.x][piece_position.y] = piece_value
				break
			else: break
			pos += i
	return _moves

# Function to get rook moves
func get_rook_moves(piece_position : Vector2):
	return get_sliding_piece_moves(piece_position, ROOK_DIRECTIONS, 4 if white else -4)

# Function to get bishop moves
func get_bishop_moves(piece_position : Vector2):
	return get_sliding_piece_moves(piece_position, BISHOP_DIRECTIONS, 3 if white else -3)

# Function to get queen moves
func get_queen_moves(piece_position : Vector2):
	return get_sliding_piece_moves(piece_position, QUEEN_DIRECTIONS, 5 if white else -5)

# Function to get king moves
func get_king_moves(piece_position : Vector2):
	var _moves = []
	
	# Temporarily remove the king from the board to check for checks
	if white:
		board[white_king_pos.x][white_king_pos.y] = 0
	else:
		board[black_king_pos.x][black_king_pos.y] = 0
	
	# Check all possible king moves
	for i in KING_DIRECTIONS:
		var pos = piece_position + i
		if is_valid_position(pos):
			if !is_in_check(pos):
				var position_state = get_position_state(pos)
				if position_state == "empty": _moves.append(pos)
				elif position_state == "enemy":
					_moves.append(pos)
				
	# Check for castling moves
	if white && !white_king:
		if !white_rook_left && is_empty(Vector2(0, 1)) && is_empty(Vector2(0, 2)) && !is_in_check(Vector2(0, 2)) && is_empty(Vector2(0, 3)) && !is_in_check(Vector2(0, 3)) && !is_in_check(Vector2(0, 4)):
			_moves.append(Vector2(0, 2))
		if !white_rook_right && !is_in_check(Vector2(0, 4)) && is_empty(Vector2(0, 5)) && !is_in_check(Vector2(0, 5)) && is_empty(Vector2(0, 6)) && !is_in_check(Vector2(0, 6)):
			_moves.append(Vector2(0, 6))
	elif !white && !black_king:
		if !black_rook_left && is_empty(Vector2(7, 1)) && is_empty(Vector2(7, 2)) && !is_in_check(Vector2(7, 2)) && is_empty(Vector2(7, 3)) && !is_in_check(Vector2(7, 3)) && !is_in_check(Vector2(7, 4)):
			_moves.append(Vector2(7, 2))
		if !black_rook_right && !is_in_check(Vector2(7, 4)) && is_empty(Vector2(7, 5)) && !is_in_check(Vector2(7, 5)) && is_empty(Vector2(7, 6)) && !is_in_check(Vector2(7, 6)):
			_moves.append(Vector2(7, 6))
			
	# Restore the king's position on the board
	if white:
		board[white_king_pos.x][white_king_pos.y] = 6
	else:
		board[black_king_pos.x][black_king_pos.y] = -6
	
	return _moves
	
# Function to get knight moves
func get_knight_moves(piece_position : Vector2):
	var _moves = []
	
	for i in KNIGHT_DIRECTIONS:
		var pos = piece_position + i
		if is_valid_position(pos):
			var position_state = get_position_state(pos)
			if position_state == "empty":
				board[pos.x][pos.y] = 2 if white else -2
				board[piece_position.x][piece_position.y] = 0
				if white && !is_in_check(white_king_pos) || !white && !is_in_check(black_king_pos): _moves.append(pos)
				board[pos.x][pos.y] = 0
				board[piece_position.x][piece_position.y] = 2 if white else -2
			elif position_state == "enemy":
				var t = board[pos.x][pos.y]
				board[pos.x][pos.y] = 2 if white else -2
				board[piece_position.x][piece_position.y] = 0
				if white && !is_in_check(white_king_pos) || !white && !is_in_check(black_king_pos): _moves.append(pos)
				board[pos.x][pos.y] = t
				board[piece_position.x][piece_position.y] = 2 if white else -2
	
	return _moves

# Function to get pawn moves
func get_pawn_moves(piece_position : Vector2):
	var _moves = []
	var direction
	var is_first_move = false
	
	# Determine pawn direction based on color
	if white: direction = Vector2(1, 0)
	else: direction = Vector2(-1, 0)
	
	# Check if it's the pawn's first move
	if white && piece_position.x == 1 || !white && piece_position.x == 6: is_first_move = true
	
	# Check for en passant move
	if en_passant != null && (white && piece_position.x == 4 || !white && piece_position.x == 3) && abs(en_passant.y - piece_position.y) == 1:
		@warning_ignore("confusable_local_declaration")
		var pos = en_passant + direction
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		board[en_passant.x][en_passant.y] = 0
		if white && !is_in_check(white_king_pos) || !white && !is_in_check(black_king_pos): _moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = 1 if white else -1
		board[en_passant.x][en_passant.y] = -1 if white else 1
	
	# Check for standard pawn move
	var pos = piece_position + direction
	if is_empty(pos):
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		if white && !is_in_check(white_king_pos) || !white && !is_in_check(black_king_pos): _moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = 1 if white else -1
	
	# Check for pawn capture moves
	pos = piece_position + Vector2(direction.x, 1)
	if is_valid_position(pos):
		if is_enemy(pos):
			var t = board[pos.x][pos.y]
			board[pos.x][pos.y] = 1 if white else -1
			board[piece_position.x][piece_position.y] = 0
			if white && !is_in_check(white_king_pos) || !white && !is_in_check(black_king_pos): _moves.append(pos)
			board[pos.x][pos.y] = t
			board[piece_position.x][piece_position.y] = 1 if white else -1
	pos = piece_position + Vector2(direction.x, -1)
	if is_valid_position(pos):
		if is_enemy(pos):
			var t = board[pos.x][pos.y]
			board[pos.x][pos.y] = 1 if white else -1
			board[piece_position.x][piece_position.y] = 0
			if white && !is_in_check(white_king_pos) || !white && !is_in_check(black_king_pos): _moves.append(pos)
			board[pos.x][pos.y] = t
			board[piece_position.x][piece_position.y] = 1 if white else -1
		
	# Check for double move on first move
	pos = piece_position + direction * 2
	if is_first_move && is_empty(pos) && is_empty(piece_position + direction):
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		if white && !is_in_check(white_king_pos) || !white && !is_in_check(black_king_pos): _moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = 1 if white else -1
	
	return _moves
#endregion

#region features

# Function to check if a position is valid on the board
func is_valid_position(pos : Vector2):
	if pos.x >= 0 && pos.x < BOARD_SIZE && pos.y >= 0 && pos.y < BOARD_SIZE: return true
	return false
	
# Function to get the state of a position (empty, enemy, ally)
func get_position_state(pos : Vector2):
	var piece = board[pos.x][pos.y]
	if piece == 0:
		return "empty"
	elif white && piece < 0 or !white && piece > 0:
		return "enemy"
	else:
		return "ally"
	
# Function to check if a position on the board is empty
func is_empty(pos: Vector2) -> bool:
	return board[pos.x][pos.y] == 0

# Function to check if a position on the board contains an enemy piece
func is_enemy(pos: Vector2) -> bool:
	var piece = board[pos.x][pos.y]
	return (white and piece < 0) or (!white and piece > 0)

# Function to handle pawn promotion
func promote(_var : Vector2):
	promotion_square = _var
	white_pieces.visible = white
	black_pieces.visible = !white

# Function to handle AI pawn promotion
func ai_promote(pos : Vector2):
	board[selected_piece.x][selected_piece.y] = 0
	board[pos.x][pos.y] = 5 if white else -5
	promotion_square = null
	display_board()
	white = true

# Function to handle button press for promotion
func _on_button_pressed(button):
	var num_char = int(button.name.substr(0, 1))
	board[promotion_square.x][promotion_square.y] = -num_char if white else num_char
	white_pieces.visible = false
	black_pieces.visible = false
	promotion_square = null
	display_board()
	if ai_enabled == true:
		ai_move() #FIXME change ai 3

# Function to handle game finish button press
func _on_game_finish_pressed() -> void:
	get_tree().reload_current_scene()

#endregion

#region is_in_check/etc.
# Function to check if a king is in check
func is_in_check(king_pos: Vector2):
	if is_attacked_by_pawn(king_pos) or is_attacked_by_knight(king_pos) or is_attacked_by_sliding_pieces(king_pos):
		return true
	return false

# Function to check if a king is attacked by a pawn
func is_attacked_by_pawn(king_pos: Vector2):
	var pawn_direction = 1 if white else -1
	var pawn_attacks = [
		king_pos + Vector2(pawn_direction, 1),
		king_pos + Vector2(pawn_direction, -1)
	]
	for i in pawn_attacks:
		if is_valid_position(i):
			if white && board[i.x][i.y] == -1 || !white && board[i.x][i.y] == 1:
				return true
	return false

# Function to check if a king is attacked by a knight
func is_attacked_by_knight(king_pos: Vector2):
	for i in KNIGHT_DIRECTIONS:
		var pos = king_pos + i
		if is_valid_position(pos):
			if white && board[pos.x][pos.y] == -2 || !white && board[pos.x][pos.y] == 2:
				return true
	return false

# Function to check if a king is attacked by sliding pieces (rook, bishop, queen)
func is_attacked_by_sliding_pieces(king_pos: Vector2):
	for i in QUEEN_DIRECTIONS:
		var pos = king_pos + i
		while is_valid_position(pos):
			if !is_empty(pos):
				var piece = board[pos.x][pos.y]
				if (i.x == 0 || i.y == 0) && (white && piece in [-4, -5] || !white && piece in [4, 5]):
					return true
				elif (i.x != 0 && i.y != 0) && (white && piece in [-3, -5] || !white && piece in [3, 5]):
					return true
				break
			pos += i
	return false

# Function to check for stalemate
func is_stalemate():
	if white:
		for i in BOARD_SIZE:
			for j in BOARD_SIZE:
				if board[i][j] > 0:
					if get_moves(Vector2(i, j)) != []: return false
				
	else:
		for i in BOARD_SIZE:
			for j in BOARD_SIZE:
				if board[i][j] < 0:
					if get_moves(Vector2(i, j)) != []: return false
	return true

# Function to check for insufficient material for checkmate
func insuficient_material():
	var white_piece = 0
	var black_piece = 0
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			match board[i][j]:
				2, 3:
					if white_piece == 0: white_piece += 1
					else: return false
				-2, -3:
					if black_piece == 0: black_piece += 1
					else: return false
				6, -6, 0: pass
				_: #4 -4 1 -1 -5 5
					return false
	return true

# Function to track threefold repetition for draw
func threefold_position(var1 : Array):
	for i in unique_board_moves.size():
		if var1 == unique_board_moves[i]:
			amount_of_same[i] += 1
			if amount_of_same[i] >= 3: print("DRAW")
			return
	unique_board_moves.append(var1.duplicate(true))
	amount_of_same.append(1)
#endregion

#region AI_sets

# Function to make an AI move
func ai_move():
	if promotion_square != null: return
	evaluate_board_advantage()
	respond_to_opening()

# Function to make a random AI move
func make_random_move():   #random piece, random legal move
	if promotion_square != null: return
	var all_moves: Array = []
	var all_pieces: Array = []
	
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var piece = board[x][y]
			if piece < 0:
				var pos = Vector2(x, y)
				var piece_moves = get_moves(pos)
				if piece_moves.size() > 0:
					all_moves.append(piece_moves)
					all_pieces.append(pos)
	
	if all_pieces.size() == 0:
		return
	
	var idx = randi() % all_pieces.size()
	selected_piece = all_pieces[idx]
	moves = get_moves(selected_piece)
	var move_idx = randi() % moves.size()
	var move = moves[move_idx]
	
	set_move(move.x, move.y)
	print("Random move")

# Function to make a greedy AI move (capture highest value piece)
func make_greed_move():
	var best_choice = -INF
	var best_from = null
	var best_to = null

	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var piece = board[i][j]
			if piece < 0:
				var from = Vector2(i, j)
				var legal_moves = get_moves(from)
				for move in legal_moves:
					var captured = board[move.x][move.y]
					var value = 0
					if captured > 0:
						value = PIECE_VALUES[captured]
					if value > best_choice:
						best_choice = value
						best_from = from
						best_to = move
	if best_choice > 0:
		if best_from != null and best_to != null:
			selected_piece = best_from
			moves = get_moves(best_from)
			set_move(best_to.x, best_to.y)
		print("Greed move")
	else: make_random_move()

#endregion

#region value_system

# Function to evaluate board advantage
func evaluate_board_advantage():
	var value = 0
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var piece = board[x][y]
			match piece:
				1: value += 10   # white pawn
				2: value += 30   # white knight
				3: value += 30   # white bishop
				4: value += 50   # white rook
				5: value += 90   # white queen
				6: value += 900  # white king
				-1: value -= 10  # black pawn
				-2: value -= 30  # black knight
				-3: value -= 30  # black bishop
				-4: value -= 50  # black rook
				-5: value -= 90  # black queen
				-6: value -= 900 # black king
	print(value)
	return value

# Function to get all enemy moves
func get_all_enemy_moves(input_board: Array, is_white_turn: bool) -> Dictionary:
	var enemy_moves: Dictionary = {}

	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var piece = input_board[x][y]
			if is_white_turn and piece < 0 or not is_white_turn and piece > 0:
				var pos = Vector2(x, y)
				var piece_moves = get_piece_moves(pos, input_board, not is_white_turn)
				enemy_moves[pos] = piece_moves

	return enemy_moves

# Function to get the value of a position
func get_position_value(pos: Vector2, input_board: Array) -> int:
	var piece = input_board[pos.x][pos.y]
	if piece == 0:
		return 0
	elif piece > 0:
		return PIECE_VALUES[piece]
	else:
		return -PIECE_VALUES[-piece]

# Function to get the value of a piece
func get_piece_value(piece: int) -> int:
	if piece == 0:
		return 0
	elif piece > 0:
		return PIECE_VALUES[piece]
	else:
		return -PIECE_VALUES[-piece]

# Function to get moves for a piece
func get_piece_moves(pos: Vector2, input_board: Array, is_white: bool) -> Array:
	# backup original state
	var original_white = white
	white = is_white
	
	var result = []
	match abs(input_board[pos.x][pos.y]):
		1: result = get_pawn_moves(pos)
		2: result = get_knight_moves(pos)
		3: result = get_bishop_moves(pos)
		4: result = get_rook_moves(pos)
		5: result = get_queen_moves(pos)
		6: result = get_king_moves(pos)

	# restore state
	white = original_white
	return result
#endregion

#region tactics

# Function to execute the AI's response to the opening move
func respond_to_opening():
	# Define the shared opening move for both defenses
	var opening_move = [
		["A2", "WHITE_PAWN"], ["B2", "WHITE_PAWN"],   ["C2", "WHITE_PAWN"],
		["D2", "WHITE_PAWN"], ["E2", "EMPTY_FIELD"],  ["F2", "WHITE_PAWN"],
		["H2", "WHITE_PAWN"], ["B1", "WHITE_KNIGHT"], ["G1", "WHITE_KNIGHT"],
		["E4", "WHITE_PAWN"],
	]

	# Check if the opening move matches
	if check_positions(convert_scenario(opening_move)):
		 #Randomly choose between openings
		print("AI chooses French Defense")
		print("Converted scenario:", convert_scenario(opening_move))
		french_defense()
	else: french_defense()

# Function to check if a piece is at a specific location
func piece_loaction(pos: Vector2, piece_id: int) -> bool:
	if not is_valid_position(pos):
		return false
	return board[pos.x][pos.y] == piece_id

# Helper function to check multiple piece locations
func check_positions(positions: Array) -> bool:
	for pos in positions:
		# Ensure pos[0] is a Vector2 and pos[1] is an integer
		if typeof(pos[0]) != TYPE_VECTOR2 or typeof(pos[1]) != TYPE_INT:
			print("Invalid position format:", pos)
			return false
		if not piece_loaction(pos[0], pos[1]):
			return false
	return true

# Helper function to convert chess notation to Vector2 and descriptive names to integers
func convert_scenario(scenario):
	var result = []
	for entry in scenario:
		# Convert chess notation to Vector2 and descriptive names to integers
		var position = CHESS_NOTATION_TO_INDEX[entry[0]]  # Convert "A2" to Vector2
		var piece_value = INVERTED_PIECE_MAPPING[entry[1]]  # Convert "WHITE_PAWN" to 1
		result.append([position, piece_value])
	return result

# Function to execute the French Defense opening
func french_defense():
	# Define scenarios for the French Defense using chess notation and descriptive names
	var scenario_1 = [
		["A2", "WHITE_PAWN"], ["B2", "WHITE_PAWN"], ["C2", "WHITE_PAWN"],
		["D2", "WHITE_PAWN"], ["E2", "EMPTY_FIELD"], ["F2", "WHITE_PAWN"],
		["H2", "WHITE_PAWN"], ["B1", "WHITE_KNIGHT"], ["G1", "WHITE_KNIGHT"],
		["E4", "WHITE_PAWN"]
	]

	var scenario_2 = [
		["A2", "WHITE_PAWN"], ["B2", "WHITE_PAWN"], ["C2", "WHITE_PAWN"],
		["D2", "EMPTY_FIELD"], ["D4", "WHITE_PAWN"], ["F2", "WHITE_PAWN"],
		["H2", "WHITE_PAWN"], ["B1", "WHITE_KNIGHT"], ["G1", "WHITE_KNIGHT"],
		["E4", "WHITE_PAWN"]
	]

	var scenario_3 = [
		["A2", "WHITE_PAWN"], ["B2", "WHITE_PAWN"], ["C2", "WHITE_PAWN"],
		["E5", "WHITE_PAWN"], ["D4", "WHITE_PAWN"], ["F2", "WHITE_PAWN"],
		["H2", "WHITE_PAWN"], ["B1", "WHITE_KNIGHT"], ["G1", "WHITE_KNIGHT"],
		["E4", "EMPTY_FIELD"]
	]

	# Execute moves for each scenario
	if check_positions(convert_scenario(scenario_1)):
		board[CHESS_NOTATION_TO_INDEX["E7"].x][CHESS_NOTATION_TO_INDEX["E7"].y] = INVERTED_PIECE_MAPPING["EMPTY_FIELD"]
		board[CHESS_NOTATION_TO_INDEX["E6"].x][CHESS_NOTATION_TO_INDEX["E6"].y] = INVERTED_PIECE_MAPPING["BLACK_PAWN"]
		display_board()
		print("French Defense 1")
	elif check_positions(convert_scenario(scenario_2)):
		board[CHESS_NOTATION_TO_INDEX["D7"].x][CHESS_NOTATION_TO_INDEX["D7"].y] = INVERTED_PIECE_MAPPING["EMPTY_FIELD"]
		board[CHESS_NOTATION_TO_INDEX["D5"].x][CHESS_NOTATION_TO_INDEX["D5"].y] = INVERTED_PIECE_MAPPING["BLACK_PAWN"]
		display_board()
		print("French Defense 2")
	elif check_positions(convert_scenario(scenario_3)):
		board[CHESS_NOTATION_TO_INDEX["C7"].x][CHESS_NOTATION_TO_INDEX["C7"].y] = INVERTED_PIECE_MAPPING["EMPTY_FIELD"]
		board[CHESS_NOTATION_TO_INDEX["C5"].x][CHESS_NOTATION_TO_INDEX["C5"].y] = INVERTED_PIECE_MAPPING["BLACK_PAWN"]
		display_board()
		print("French Defense 3")
	else:
		make_greed_move()

	# Ensure the turn is set to white if it was black
	if not white:
		white = true

# Function to execute the Queen's Gambit Declined opening
func queens_gambit_declined():
	# Define scenarios for the Queen's Gambit Declined
	var scenario_1 = [
		[Vector2(1, 0), 1], [Vector2(1, 1), 1], [Vector2(1, 2), 1],
		[Vector2(3, 3), 1], [Vector2(1, 4), 1], [Vector2(1, 5), 1],
		[Vector2(1, 6), 1], [Vector2(1, 7), 1]
	]

	var scenario_2 = [
		[Vector2(1, 0), 1], [Vector2(1, 1), 1], [Vector2(3, 2), 1],
		[Vector2(3, 3), 1], [Vector2(1, 4), 1], [Vector2(1, 5), 1],
		[Vector2(1, 6), 1], [Vector2(1, 7), 1], [Vector2(0, 1), 2]
	]

	var scenario_3 = [
		[Vector2(1, 0), 1], [Vector2(1, 1), 1], [Vector2(3, 2), 1],
		[Vector2(3, 3), 1], [Vector2(1, 4), 1], [Vector2(1, 5), 1],
		[Vector2(1, 6), 1], [Vector2(1, 7), 1], [Vector2(2, 2), 2],
		[Vector2(0, 2), 3]
	]

	var scenario_4 = [
		[Vector2(1, 0), 1], [Vector2(1, 1), 1], [Vector2(3, 2), 1],
		[Vector2(3, 3), 1], [Vector2(1, 4), 1], [Vector2(1, 5), 1],
		[Vector2(1, 6), 1], [Vector2(1, 7), 1], [Vector2(2, 2), 2],
		[Vector2(4, 6), 3]
	]

	# Execute moves for each scenario
	if check_positions(scenario_1):
		board[6][3] = 0
		board[4][3] = -1
		display_board()
		print("The Queen’s Gambit Declined 1")
	elif check_positions(scenario_2):
		board[6][2] = 0
		board[5][2] = -1
		display_board()
		print("The Queen’s Gambit Declined 2")
	elif check_positions(scenario_3):
		board[7][6] = 0
		board[5][5] = -2
		display_board()
		print("The Queen’s Gambit Declined 3")
	elif check_positions(scenario_4):
		board[7][1] = 0
		board[6][3] = -2
		display_board()
		print("The Queen’s Gambit Declined 4")
	else:
		make_greed_move()

	# Ensure the turn is set to white if it was black
	if not white:
		white = true

# Helper function to invert a dictionary
func invert_dictionary(original: Dictionary) -> Dictionary:
	var inverted = {}
	for key in original.keys():
		inverted[original[key]] = key
	return inverted

#endregion
