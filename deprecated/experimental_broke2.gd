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

#region piece_value/mapping
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
#endregion

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
# Helper function to flatten a nested array
func flatten_array(nested_array: Array) -> Array:
	var flat_array = []
	for sub_array in nested_array:
		flat_array += sub_array
	return flat_array

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
@onready var reload_button: Button = $"../reload_button"
@onready var undo_button: Button = $"../undo_button"

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

var fifty_move_rule = 0
# Threefold repetition tracking
var unique_board_moves : Array = []
var amount_of_same : Array = []
# Variables to track the last move and previous board state
var previous_board: Array = []
var last_move: Dictionary = {}
# Variables to track the last two moves and previous board states
var previous_boards: Array = []  # Stores the last two board states
var last_moves: Array = []       # Stores the last two moves

# King positions
var white_king_pos = Vector2(0, 4)
var black_king_pos = Vector2(7, 4)
# AI settings
var ai_enabled := true

#endregion

#region ready/input/board

# Function to handle player 2 button press
func _on_player_2_pressed() -> void:
	player_2.visible = false
	player_1.visible = false
	ai_enabled = false
	undo_button.visible = false

# Function to handle player 1 button press
func _on_player_1_pressed() -> void:
	player_2.visible = false
	player_1.visible = false
	ai_enabled = true

# Function to initialize the board with starting positions
func initialize_board() -> void:
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

# Function called when the node is ready
func _ready() -> void:
	randomize() #Seed Game for opening move and random moves
	
	# Initialize the board with starting positions
	initialize_board()

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
	print("Moving piece from " + str(selected_piece) + " to " + str(Vector2(var2, var1)))
	# Save the current board state and move
	save_board_state(var2, var1)
	# Process the move
	if process_move(var2, var1):
		# Update the board state
		update_board_state(var2, var1)
		# Validate the board state
		if !validate_board_state():
			print("Board state invalid after move!")
			return
		# Update turn and display
		update_turn_and_display()
		# Handle AI move if enabled
		handle_ai_move()
		# Clear move dots and reset state
		reset_move_state()
		# Check for game-ending conditions
		check_game_end_conditions(var2, var1)
	else:
		# If the move is invalid, reset the state and allow selecting a new piece
		print("Invalid move attempted. Resetting state.")
		delete_dots()
		state = false

func save_board_state(var2, var1):
	if previous_boards.size() >= 2:
		previous_boards.pop_front()  # Remove the oldest board state
	if last_moves.size() >= 2:
		last_moves.pop_front()  # Remove the oldest move
	previous_boards.append(board.duplicate(true))  # Deep copy the board
	last_moves.append({
		"from": selected_piece,
		"to": Vector2(var2, var1),
		"captured_piece": board[var2][var1]
	})

# Helper function to handle piece-specific logic
func handle_piece_logic(var2: int, var1: int, i: Vector2):
	var just_now = false
	fifty_move_rule += 1
	if get_position_state(Vector2(var2, var1)) == "enemy":
		fifty_move_rule = 0
	match board[selected_piece.x][selected_piece.y]:
		1:
			fifty_move_rule = 0
			if i.x == 7:
				promote(i)
			if i.x == 3 and selected_piece.x == 1:
				en_passant = i
				just_now = true
			elif en_passant != null:
				if en_passant.y == i.y and selected_piece.y != i.y and en_passant.x == selected_piece.x:
					board[en_passant.x][en_passant.y] = 0
		-1:
			fifty_move_rule = 0
			if ai_enabled == false:
				if i.x == 0:
					promote(i)
			if ai_enabled == true:
				if i.x == 0:
					ai_promote(i)
					return
			if i.x == 4 and selected_piece.x == 6:
				en_passant = i
				just_now = true
			elif en_passant != null:
				if en_passant.y == i.y and selected_piece.y != i.y and en_passant.x == selected_piece.x:
					board[en_passant.x][en_passant.y] = 0
		4:
			if selected_piece.x == 0 and selected_piece.y == 0:
				white_rook_left = true
			elif selected_piece.x == 0 and selected_piece.y == 7:
				white_rook_right = true
		-4:
			if selected_piece.x == 7 and selected_piece.y == 0:
				black_rook_left = true
			elif selected_piece.x == 7 and selected_piece.y == 7:
				black_rook_right = true
		6:
			if selected_piece.x == 0 and selected_piece.y == 4:
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
			if selected_piece.x == 7 and selected_piece.y == 4:
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
	if !just_now:
		en_passant = null

# Helper function to process the move
func process_move(var2: int, var1: int) -> bool:
	for i in moves:
		if i.x == var2 and i.y == var1:
			handle_piece_logic(var2, var1, i)  # Call the helper function
			return true
	return false

# Helper function to update the board state
func update_board_state(var2: int, var1: int):
	# Explicitly update the board state
	board[var2][var1] = board[selected_piece.x][selected_piece.y]  # Move the piece
	board[selected_piece.x][selected_piece.y] = 0  # Clear the original position

# Helper function to update turn and display
func update_turn_and_display():
	# Update turn and display
	white = !white
	print("Turn changed. White's turn: " + str(white))
	threefold_position(board)
	display_board()

# Helper function to handle AI move if enabled
func handle_ai_move():
	# Handle AI move if enabled
	if !white and ai_enabled:
		await get_tree().create_timer(0.3).timeout
		ai_move()  # FIXME change ai

# Helper function to reset move state
func reset_move_state():
	# Clear move dots and reset state
	delete_dots()
	state = false

# Helper function to check for game-ending conditions
func check_game_end_conditions(var2: int, var1: int):
	# Check for stalemate or checkmate
	if (selected_piece.x != var2 or selected_piece.y != var1) and (white and board[var2][var1] > 0 or !white and board[var2][var1] < 0):
		selected_piece = Vector2(var2, var1)
		show_options()
		state = true
		return  # Exit early if a piece is selected

	if is_stalemate():
		if white and is_in_check(white_king_pos) or !white and is_in_check(black_king_pos):
			print("CHECKMATE")
			white = true
			game_finish.text = "Checkmate"
			game_finish.visible = true
		else:
			print("DRAW")
			white = true
			game_finish.text = "Draw"
			game_finish.visible = true
		return  # Exit early if the game ends

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
	match abs(board[selected.x][selected.y]):
		1: return get_pawn_moves(selected)
		2: return get_knight_moves(selected)
		3: return get_bishop_moves(selected)
		4: return get_rook_moves(selected)
		5: return get_queen_moves(selected)
		6: return get_king_moves(selected)
	return []

# Function to get moves for sliding pieces (rook, bishop, queen)
func get_sliding_piece_moves(piece_position: Vector2, directions: Array, piece_value: int) -> Array:
	var _moves = []
	for direction in directions:
		var pos = piece_position + direction
		while is_valid_position(pos):
			var position_state = get_position_state(pos)
			if position_state == "empty":
				_moves.append(pos)
			elif position_state == "enemy":
				_moves.append(pos)
				break
			else:  # Stop if the square is occupied by a friendly piece
				break
			pos += direction
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
func get_knight_moves(piece_position: Vector2) -> Array:
	var _moves = []
	for i in KNIGHT_DIRECTIONS:
		var pos = piece_position + i
		if is_valid_position(pos):
			var position_state = get_position_state(pos)
			if position_state == "empty" or position_state == "enemy":
				# Simulate the move
				var original_piece = board[pos.x][pos.y]
				board[pos.x][pos.y] = board[piece_position.x][piece_position.y]
				board[piece_position.x][piece_position.y] = 0

				# Check if the move is valid
				if white and !is_in_check(white_king_pos) or !white and !is_in_check(black_king_pos):
					_moves.append(pos)

				# Restore the board state
				board[piece_position.x][piece_position.y] = board[pos.x][pos.y]
				board[pos.x][pos.y] = original_piece
	return _moves

# Function to get pawn moves
func get_pawn_moves(piece_position: Vector2) -> Array:
	var _moves = []
	var direction
	var is_first_move = false

	# Determine pawn direction based on color
	if white:
		direction = Vector2(1, 0)
	else:
		direction = Vector2(-1, 0)

	# Check if it's the pawn's first move
	if white and piece_position.x == 1 or !white and piece_position.x == 6:
		is_first_move = true

	# Check for en passant move
	check_en_passant(piece_position, direction, _moves)

	# Check for standard pawn move
	var pos = piece_position + direction
	if is_empty(pos):
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		if white and !is_in_check(white_king_pos) or !white and !is_in_check(black_king_pos):
			_moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = 1 if white else -1

	# Check for pawn capture moves
	pos = piece_position + Vector2(direction.x, 1)
	if is_valid_position(pos):
		if is_enemy(pos):
			var t = board[pos.x][pos.y]
			board[pos.x][pos.y] = 1 if white else -1
			board[piece_position.x][piece_position.y] = 0
			if white and !is_in_check(white_king_pos) or !white and !is_in_check(black_king_pos):
				_moves.append(pos)
			board[pos.x][pos.y] = t
			board[piece_position.x][piece_position.y] = 1 if white else -1
	pos = piece_position + Vector2(direction.x, -1)
	if is_valid_position(pos):
		if is_enemy(pos):
			var t = board[pos.x][pos.y]
			board[pos.x][pos.y] = 1 if white else -1
			board[piece_position.x][piece_position.y] = 0
			if white and !is_in_check(white_king_pos) or !white and !is_in_check(black_king_pos):
				_moves.append(pos)
			board[pos.x][pos.y] = t
			board[piece_position.x][piece_position.y] = 1 if white else -1

	# Check for double move on first move
	pos = piece_position + direction * 2
	if is_first_move and is_empty(pos) and is_empty(piece_position + direction):
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		if white and !is_in_check(white_king_pos) or !white and !is_in_check(black_king_pos):
			_moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = 1 if white else -1

	return _moves

func check_en_passant(piece_position: Vector2, direction: Vector2, _moves: Array) -> void:
	if en_passant != null and (white and piece_position.x == 4 or !white and piece_position.x == 3) and abs(en_passant.y - piece_position.y) == 1:
		@warning_ignore("confusable_local_declaration")
		var pos = en_passant + direction
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		board[en_passant.x][en_passant.y] = 0
		if white and !is_in_check(white_king_pos) or !white and !is_in_check(black_king_pos):
			_moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = 1 if white else -1
		board[en_passant.x][en_passant.y] = -1 if white else 1

#endregion

#region features

func _on_undo_button_pressed() -> void:
	undo_last_move()

# Function to undo the last move (or last two moves if AI is enabled)
func undo_last_move():
	if previous_boards.size() == 0 or last_moves.size() == 0:
		print("No move to undo!")
		return
	# If AI is enabled, undo the last two moves
	if ai_enabled and previous_boards.size() >= 2 and last_moves.size() >= 2:
		# Restore the board state from two moves ago
		board = previous_boards[0].duplicate(true)
		# Remove the last two moves from the history
		previous_boards.pop_back()
		previous_boards.pop_back()
		last_moves.pop_back()
		last_moves.pop_back()
		print("Last two moves undone!")
	else:
		# Restore the previous board state
		board = previous_boards.back().duplicate(true)
		# Remove the last move from the history
		previous_boards.pop_back()
		last_moves.pop_back()
		print("Last move undone!")
	# Restore the turn
	white = true
	# Update the board display
	display_board()

func _on_reload_button_pressed() -> void:
	get_tree().reload_current_scene()

# Function to check if a position is valid on the board
func is_valid_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE

# Function to get the state of a position (empty, enemy, ally)
func get_position_state(pos: Vector2) -> String:
	if !is_valid_position(pos):
		return "invalid"
	var piece = board[pos.x][pos.y]
	if piece == 0:
		return "empty"
	elif (white and piece < 0) or (!white and piece > 0):
		return "enemy"
	else:
		return "ally"

# Function to check if a position on the board is empty
func is_empty(pos: Vector2) -> bool:
	return is_valid_position(pos) and board[pos.x][pos.y] == 0
# Function to check if a position on the board contains an enemy piece

func is_enemy(pos: Vector2) -> bool:
	return (white and board[pos.x][pos.y] < 0) or (!white and board[pos.x][pos.y] > 0)

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
				elif (i.x != 0 && i.y != 0) && (white && piece in [-3, -5] || !white and piece in [3, 5]):
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
	if promotion_square != null:
		return
	print("AI evaluating board advantage.")
	evaluate_board_advantage()
	print("AI checks for opening.")
	if respond_to_opening():
		white = true
		return  # Stop if a move is made in respond_to_opening()
	if french_defense():
		white = true
		return  # Stop if a move is made in french_defense()
	# Handle threatened pieces
	if decide_on_threatened_piece():
		return  # Stop if a threat was handled

	# Validate board state before fallback strategies
	if !validate_board_state():
		print("Invalid board state detected. Skipping fallback strategies.")
		return
	# If no threats were handled, proceed with fallback strategies
	print("AI could not handle the threat. Proceeding with fallback strategies.")
	# Attempt a greedy move
	print("AI makes a greed move.")
	if make_greed_move():
		return  # Stop if a move is made in make_greed_move()
	# Attempt a random move
	print("AI makes a random move.")
	make_random_move()

# Helper function to validate the board state
func validate_board_state() -> bool:
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			if board[x][y] != int(board[x][y]):  # Ensure all board values are integers
				print("Invalid board value at (" + str(x) + ", " + str(y) + "): " + str(board[x][y]))
				return false
	return true

func make_random_move() -> bool:
	print("AI attempting a random move.")

	# Collect all possible moves for black pieces
	var all_moves = collect_all_moves()
	if all_moves.is_empty():
		print("No valid moves available for AI.")
		return false  # No moves available

	# Choose a random move
	var random_move = all_moves[randi() % all_moves.size()]
	var from_position = random_move[0]
	var to_position = random_move[1]

	# Execute the move
	print("Random move selected: Piece at " + str(from_position) + " moves to " + str(to_position))
	move_piece(from_position, to_position)
	return true  # Move made successfully

func collect_all_moves() -> Array:
	var all_moves = []
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			if (white and board[x][y] > 0) or (!white and board[x][y] < 0):  # Only consider pieces of the current player
				var piece_position = Vector2(x, y)
				var legal_moves = get_moves(piece_position)
				for move in legal_moves:
					if get_position_state(move) != "ally":  # Exclude moves to friendly-occupied squares
						all_moves.append([piece_position, move])
	return all_moves

# Function to make a greedy AI move (capture highest value piece)
func make_greed_move() -> bool:
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
			process_move(best_to.x, best_to.y)
			print("Greed move")
			return true  # Move made, return true
	return false  # No move made, return false

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
	return value

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
	return PIECE_VALUES[abs(piece)] if piece != 0 else 0

#endregion

#region tactics

# Function to execute the AI's response to the opening move
func respond_to_opening() -> bool:
	# Define the shared opening move for both defenses
	var opening_move = [
		["A2", "WHITE_PAWN"], ["B2", "WHITE_PAWN"],   ["C2", "WHITE_PAWN"],
		["D2", "WHITE_PAWN"], ["E2", "EMPTY_FIELD"],  ["F2", "WHITE_PAWN"],
		["H2", "WHITE_PAWN"], ["B1", "WHITE_KNIGHT"], ["G1", "WHITE_KNIGHT"],
		["E4", "WHITE_PAWN"],
	]
	# Check if the opening move matches
	if check_positions(convert_scenario(opening_move)):
		# Randomly choose between openings
		print("AI chooses French Defense")
		if french_defense():
			return true  # Move made, return true
	return false  # No move made, return false

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
		var chess_position = CHESS_NOTATION_TO_INDEX[entry[0]]  # Convert "A2" to Vector2
		var piece_value = INVERTED_PIECE_MAPPING[entry[1]]  # Convert "WHITE_PAWN" to 1
		result.append([chess_position, piece_value])
	return result

# Function to execute the French Defense opening
func french_defense() -> bool:
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
		["E4", "WHITE_PAWN"], ["E6", "BLACK_PAWN"]
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
		return true
	elif check_positions(convert_scenario(scenario_2)):
		board[CHESS_NOTATION_TO_INDEX["D7"].x][CHESS_NOTATION_TO_INDEX["D7"].y] = INVERTED_PIECE_MAPPING["EMPTY_FIELD"]
		board[CHESS_NOTATION_TO_INDEX["D5"].x][CHESS_NOTATION_TO_INDEX["D5"].y] = INVERTED_PIECE_MAPPING["BLACK_PAWN"]
		display_board()
		print("French Defense 2")
		return true
	elif check_positions(convert_scenario(scenario_3)):
		board[CHESS_NOTATION_TO_INDEX["C7"].x][CHESS_NOTATION_TO_INDEX["C7"].y] = INVERTED_PIECE_MAPPING["EMPTY_FIELD"]
		board[CHESS_NOTATION_TO_INDEX["C5"].x][CHESS_NOTATION_TO_INDEX["C5"].y] = INVERTED_PIECE_MAPPING["BLACK_PAWN"]
		display_board()
		print("French Defense 3")
		return true

	# No move made
	return false

# Function to execute the Queen's Gambit Declined opening
func queens_gambit_declined():
	# Define scenarios for the Queen's Gambit Declined using chess notation and descriptive names
	var scenario_1 = [
		["A2", "WHITE_PAWN"], ["B2", "WHITE_PAWN"], ["C2", "WHITE_PAWN"],
		["D4", "WHITE_PAWN"], ["E2", "WHITE_PAWN"], ["F2", "WHITE_PAWN"],
		["G2", "WHITE_PAWN"], ["H2", "WHITE_PAWN"], ["B1", "WHITE_KNIGHT"],
		["G1", "WHITE_KNIGHT"]
]

	var scenario_2 = [
		["A2", "WHITE_PAWN"], ["B2", "WHITE_PAWN"], ["C4", "WHITE_PAWN"],
		["D4", "WHITE_PAWN"], ["E2", "WHITE_PAWN"], ["F2", "WHITE_PAWN"],
		["G2", "WHITE_PAWN"], ["H2", "WHITE_PAWN"], ["B1", "WHITE_KNIGHT"],
		["G1", "WHITE_KNIGHT"]
		
	]

	var scenario_3 = [
		["A2", "WHITE_PAWN"], ["B2", "WHITE_PAWN"], ["C4", "WHITE_PAWN"],
		["D4", "WHITE_PAWN"], ["E2", "WHITE_PAWN"], ["F2", "WHITE_PAWN"],
		["G2", "WHITE_PAWN"], ["H2", "WHITE_PAWN"], ["C3", "WHITE_KNIGHT"],
		["A1", "WHITE_ROOK"], ["C1", "WHITE_BISHOP"], ["G1", "WHITE_KNIGHT"]
	]

	var scenario_4 = [
		["A2", "WHITE_PAWN"], ["B2", "WHITE_PAWN"], ["C4", "WHITE_PAWN"],
		["D4", "WHITE_PAWN"], ["E2", "WHITE_PAWN"], ["F2", "WHITE_PAWN"],
		["G2", "WHITE_PAWN"], ["H2", "WHITE_PAWN"], ["C3", "WHITE_KNIGHT"],
		["G5", "WHITE_BISHOP"], ["G1", "WHITE_KNIGHT"]
	]

	# Execute moves for each scenario
	if check_positions(convert_scenario(scenario_1)):
		board[CHESS_NOTATION_TO_INDEX["D7"].x][CHESS_NOTATION_TO_INDEX["D7"].y] = INVERTED_PIECE_MAPPING["EMPTY_FIELD"]
		board[CHESS_NOTATION_TO_INDEX["D5"].x][CHESS_NOTATION_TO_INDEX["D5"].y] = INVERTED_PIECE_MAPPING["BLACK_PAWN"]
		display_board()
		print("Queen's Gambit Declined 1")
	elif check_positions(convert_scenario(scenario_2)):
		board[CHESS_NOTATION_TO_INDEX["E7"].x][CHESS_NOTATION_TO_INDEX["E7"].y] = INVERTED_PIECE_MAPPING["EMPTY_FIELD"]
		board[CHESS_NOTATION_TO_INDEX["E6"].x][CHESS_NOTATION_TO_INDEX["E6"].y] = INVERTED_PIECE_MAPPING["BLACK_PAWN"]
		display_board()
		print("Queen's Gambit Declined 2")
	elif check_positions(convert_scenario(scenario_3)):
		board[CHESS_NOTATION_TO_INDEX["G8"].x][CHESS_NOTATION_TO_INDEX["G8"].y] = INVERTED_PIECE_MAPPING["EMPTY_FIELD"]
		board[CHESS_NOTATION_TO_INDEX["F6"].x][CHESS_NOTATION_TO_INDEX["F6"].y] = INVERTED_PIECE_MAPPING["BLACK_KNIGHT"]
		display_board()
		print("Queen's Gambit Declined 3")
	elif check_positions(convert_scenario(scenario_4)):
		board[CHESS_NOTATION_TO_INDEX["B8"].x][CHESS_NOTATION_TO_INDEX["B8"].y] = INVERTED_PIECE_MAPPING["EMPTY_FIELD"]
		board[CHESS_NOTATION_TO_INDEX["D7"].x][CHESS_NOTATION_TO_INDEX["D7"].y] = INVERTED_PIECE_MAPPING["BLACK_KNIGHT"]
		display_board()
		print("Queen's Gambit Declined 4")
	else:
		return

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

#region threat_detection & response

# Function to check if a black piece is threatened and return the threatening piece's position
func is_black_piece_threatened(piece_position: Vector2) -> Vector2:
	# print("Checking threats for black piece at " + str(piece_position))
	
	# Check for threats from pawns
	var pawn_directions = [Vector2(-1, -1), Vector2(-1, 1)]  # Diagonal attacks for white pawns
	for dir in pawn_directions:
		var pos = piece_position + dir
		if is_valid_position(pos) and board[pos.x][pos.y] == 1:  # White pawn
			print("Threat detected from white pawn at " + str(pos))
			return pos

	# Check for threats from knights
	for dir in KNIGHT_DIRECTIONS:
		var pos = piece_position + dir
		if is_valid_position(pos) and board[pos.x][pos.y] == 2:  # White knight
			print("Threat detected from white knight at " + str(pos))
			return pos

	# Check for threats from sliding pieces (rooks, bishops, queens)
	var sliding_directions = ROOK_DIRECTIONS + BISHOP_DIRECTIONS
	for dir in sliding_directions:
		var pos = piece_position + dir
		while is_valid_position(pos):
			var piece = board[pos.x][pos.y]
			if piece != 0:  # Stop at the first piece
				if dir in ROOK_DIRECTIONS and piece in [4, 5]:  # White rook or queen
					print("Threat detected from white rook/queen at " + str(pos))
					return pos
				elif dir in BISHOP_DIRECTIONS and piece in [3, 5]:  # White bishop or queen
					print("Threat detected from white bishop/queen at " + str(pos))
					return pos
				break
			pos += dir

	# Check for threats from the white king
	for dir in KING_DIRECTIONS:
		var pos = piece_position + dir
		if is_valid_position(pos) and board[pos.x][pos.y] == 6:  # White king
			print("Threat detected from white king at " + str(pos))
			return pos

	# No threats detected
	# print("No threats detected for black piece at " + str(piece_position))
	return Vector2(-1, -1)

# Function to get all threatened black pieces and their threatening pieces
func get_threatened_black_pieces() -> Array:
	var threatened_pieces = []
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			if board[x][y] < 0:  # Black piece
				var pos = Vector2(x, y)
				var threatening_piece = is_black_piece_threatened(pos)
				if threatening_piece != Vector2(-1, -1):  # Only add valid threats
					threatened_pieces.append([pos, threatening_piece])  # Add array (black piece, threatening piece)
	return threatened_pieces

# Helper function to compare the value of two pieces
func _compare_piece_value(a: Array, b: Array) -> int:
	var piece_a_value = get_piece_value(board[a[0].x][a[0].y])
	var piece_b_value = get_piece_value(board[b[0].x][b[0].y])

	# Debug print for comparison
	print("Comparing pieces:")
	print("Piece A at " + str(a[0]) + " with value " + str(piece_a_value))
	print("Piece B at " + str(b[0]) + " with value " + str(piece_b_value))

	# Return the difference in values (descending order)
	return piece_b_value - piece_a_value

# Helper function to handle threatened pieces
func decide_on_threatened_piece() -> bool:
	print("AI checking for threatened pieces.")
	var threatened_pieces = get_threatened_black_pieces()
	print("Threatened black pieces:")
	var most_valuable_piece = null
	var most_valuable_threat = null
	var highest_value = -INF

	# Iterate through the threatened pieces to find the most valuable one
	for pair in threatened_pieces:
		var piece = pair[0]
		var threat = pair[1]
		var piece_value = get_piece_value(board[piece.x][piece.y])
		print("Black piece at " + str(piece) + " (value: " + str(piece_value) + ") is threatened by white piece at " + str(threat))

		if piece_value > highest_value:
			highest_value = piece_value
			most_valuable_piece = piece
			most_valuable_threat = threat

	# If a most valuable piece is found, attempt to handle the threat
	if most_valuable_piece != null:
		print("Most valuable black piece at " + str(most_valuable_piece) + " is threatened by white piece at " + str(most_valuable_threat))
		print("AI needs to protect piece at " + str(most_valuable_piece) + " from " + str(most_valuable_threat))

		# Attempt to capture the threatening piece
		if attempt_capture(most_valuable_piece, most_valuable_threat):
			print("Threat handled by capture.")
			return true  # Stop further processing

		# If capture fails, attempt to evade
		if attempt_evade(most_valuable_piece):
			print("Threat handled by evasion.")
			return true  # Stop further processing

		# If evasion fails, attempt to block
		if attempt_block(most_valuable_piece, most_valuable_threat):
			print("Threat handled by blocking.")
			return true  # Stop further processing

		print("AI could not handle the threat.")
		return false  # Threat not handled

	print("No threats to handle.")
	return false  # No threats to handle

# Helper function to attempt capturing the threatening piece
func attempt_capture(threatened_piece: Vector2, threat: Vector2) -> bool:
	print("Attempting to capture the threatening piece at " + str(threat))

	# Check if the threatened piece itself can capture the threat
	var possible_moves = get_moves(threatened_piece)
	for move in possible_moves:
		if move == threat:  # If the move captures the threatening piece
			print("Threatened piece at " + str(threatened_piece) + " captures the threatening piece at " + str(threat))
			selected_piece = threatened_piece  # Set the selected piece for `set_move`
			process_move(move.x, move.y)  # Move the piece to the threat's position
			return true  # Threat handled by capture

	# Check if any other owned piece can capture the threat
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var piece = board[x][y]
			if (white and piece > 0) or (!white and piece < 0):  # Check if the piece belongs to the current player
				var pos = Vector2(x, y)
				if pos == threatened_piece:
					continue  # Skip the threatened piece (already checked above)
				
				@warning_ignore("shadowed_variable")
				var moves = get_moves(pos)
				for move in moves:
					if move == threat:  # If the move captures the threatening piece
						print("Piece at " + str(pos) + " captures the threatening piece at " + str(threat))
						selected_piece = pos  # Set the selected piece for `set_move`
						process_move(move.x, move.y)  # Move the piece to the threat's position
						return true  # Threat handled by capture

	print("No owned piece can capture the threatening piece at " + str(threat))
	return false  # Capture not possible

# Helper function to attempt evading the threat
func attempt_evade(threatened_piece: Vector2) -> bool:
	print("Attempting to evade with piece at " + str(threatened_piece))

	# Get all possible moves for the threatened piece
	var possible_moves = get_moves(threatened_piece)
	if possible_moves.size() == 0:
		print("No valid moves available for piece at " + str(threatened_piece))
		return false  # No moves available to evade

	# Filter out moves that lead to dangerous tiles
	var safe_moves = filter_safe_moves(possible_moves)
	if safe_moves.size() == 0:
		print("No safe moves available for piece at " + str(threatened_piece))
		return false  # No safe moves available

	# Attempt to execute a safe move
	return execute_safe_move(threatened_piece, safe_moves)

# Helper function to get all blocking positions between the threatened piece and the threat
func get_blocking_positions(threatened_piece: Vector2, threat: Vector2) -> Array:
	var blocking_positions = []

	# Calculate the integer direction of the threat
	var delta = threatened_piece - threat
	var gcd = abs(delta.x) if abs(delta.x) > abs(delta.y) else abs(delta.y)
	if gcd != 0:
		delta /= gcd  # Normalize to integer steps

	# Add all positions between the threat and the threatened piece
	var pos = threat + delta
	while pos != threatened_piece:
		if !is_valid_position(pos):
			break
		blocking_positions.append(pos)
		pos += delta

	print("Blocking positions: " + str(blocking_positions))
	return blocking_positions

func filter_safe_moves(possible_moves: Array) -> Array:
	print("Filtering safe moves.")
	var dangerous_tiles = mark_dangerous_tiles()
	var safe_moves = []
	for move in possible_moves:
		if move not in dangerous_tiles:
			safe_moves.append(move)
	print("Safe moves: " + str(safe_moves))
	return safe_moves

func execute_safe_move(threatened_piece: Vector2, safe_moves: Array) -> bool:
	for move in safe_moves:
		if !exposes_more_valuable_piece(threatened_piece, move):
			print("Piece at " + str(threatened_piece) + " evades to " + str(move))
			move_piece(threatened_piece, move)
			return true  # Evade successful
	print("Evade failed: No valid moves that do not expose a more valuable piece.")
	return false

func exposes_more_valuable_piece(threatened_piece: Vector2, move: Vector2) -> bool:
	# Save the original state
	var original_piece = board[move.x][move.y]
	var original_position_piece = board[threatened_piece.x][threatened_piece.y]

	# Simulate the move
	board[move.x][move.y] = board[threatened_piece.x][threatened_piece.y]
	board[threatened_piece.x][threatened_piece.y] = 0

	# Check if any more valuable pieces are now threatened
	var threatened_pieces = get_threatened_black_pieces()
	var threatened_piece_value = get_piece_value(board[move.x][move.y])
	var exposes_more_valuable_piece = false

	for pair in threatened_pieces:
		var exposed_piece = pair[0]
		var exposed_piece_value = get_piece_value(board[exposed_piece.x][exposed_piece.y])
		if exposed_piece_value > threatened_piece_value:
			print("Evasion exposes more valuable piece at " + str(exposed_piece) + " (value: " + str(exposed_piece_value) + ")")
			exposes_more_valuable_piece = true
			break

	# Restore the original state
	board[threatened_piece.x][threatened_piece.y] = original_position_piece
	board[move.x][move.y] = original_piece

	return exposes_more_valuable_piece

func move_piece(from: Vector2, to: Vector2):
	board[to.x][to.y] = board[from.x][from.y]  # Move the piece to the new position
	board[from.x][from.y] = 0  # Clear the original position

	white = !white
	print("Turn changed. White's turn: " + str(white))

	# Display the updated board
	display_board()


# Helper function to attempt blocking the threat
func attempt_block(threatened_piece: Vector2, threat: Vector2) -> bool:
	print("Attempting to block the threat to piece at " + str(threatened_piece) + " from " + str(threat))

	# Get all possible blocking positions
	var blocking_positions = get_blocking_positions(threatened_piece, threat)
	if blocking_positions.size() == 0:
		print("No valid blocking positions available.")
		return false  # No blocking positions available

	# Get the value of the threatened piece
	var threatened_piece_value = get_piece_value(board[threatened_piece.x][threatened_piece.y])

	# Find the least valuable pieces that can block
	var least_valuable_pieces = []
	var lowest_value = INF

	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var piece = board[x][y]
			var pos = Vector2(x, y)

			# Exclude the threatened piece itself
			if pos == threatened_piece:
				continue

			# Check if the piece belongs to the current player
			if (white and piece > 0) or (!white and piece < 0):
				var piece_value = get_piece_value(piece)

				# Exclude pieces with a value greater than or equal to the threatened piece
				if piece_value >= threatened_piece_value:
					continue

				@warning_ignore("confusable_local_declaration", "shadowed_variable")
				var moves = get_moves(pos)

				# Check if the piece can move to any blocking position
				for move in moves:
					if move in blocking_positions:
						if piece_value < lowest_value:
							least_valuable_pieces = [pos]  # Reset the list with the new least valuable piece
							lowest_value = piece_value
						elif piece_value == lowest_value:
							least_valuable_pieces.append(pos)  # Add to the list of least valuable pieces

	# If no pieces can block, return false
	if least_valuable_pieces.size() == 0:
		print("No pieces can block the threat.")
		return false

	# Choose a random least valuable piece
	var blocking_piece = least_valuable_pieces[randi() % least_valuable_pieces.size()]
	print("Least valuable piece chosen to block: " + str(blocking_piece))

	# Get the moves of the chosen piece and find a blocking move
	@warning_ignore("shadowed_variable")
	var moves = get_moves(blocking_piece)
	var blocking_moves = []
	for move in moves:
		if move in blocking_positions:
			blocking_moves.append(move)

	# If no blocking moves are found, return false
	if blocking_moves.size() == 0:
		print("No valid blocking moves available for piece at " + str(blocking_piece))
		return false

	# Choose a random blocking move
	var blocking_move = blocking_moves[randi() % blocking_moves.size()]
	print("Blocking move chosen: " + str(blocking_move))

	# Directly update the board state
	print("Before move: Board[" + str(blocking_piece.x) + "][" + str(blocking_piece.y) + "] = " + str(board[blocking_piece.x][blocking_piece.y]))
	print("Before move: Board[" + str(blocking_move.x) + "][" + str(blocking_move.y) + "] = " + str(board[blocking_move.x][blocking_move.y]))

	# Move the piece on the board
	board[blocking_move.x][blocking_move.y] = board[blocking_piece.x][blocking_piece.y]  # Move the piece to the new position
	board[blocking_piece.x][blocking_piece.y] = 0  # Clear the original position

	# Debug: Verify board state after the move
	print("After move: Board[" + str(blocking_piece.x) + "][" + str(blocking_piece.y) + "] = " + str(board[blocking_piece.x][blocking_piece.y]))
	print("After move: Board[" + str(blocking_move.x) + "][" + str(blocking_move.y) + "] = " + str(board[blocking_move.x][blocking_move.y]))

	# Update the turn
	white = !white
	print("Turn changed. White's turn: " + str(white))

	# Display the updated board
	display_board()

	# Confirm the move was successful
	if board[blocking_move.x][blocking_move.y] != 0:
		print("Block successful: Piece moved to " + str(blocking_move))
		return true  # Threat handled by blocking
	else:
		print("Block failed: Piece did not move to " + str(blocking_move))
		return false  # Block failed

# Function to mark all tiles threatened by white pieces as "dangerous tiles"
func mark_dangerous_tiles() -> Array:
	print("Marking dangerous tiles threatened by white pieces.")
	# Initialize an array to store dangerous tiles
	var dangerous_tiles = []
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			if board[x][y] > 0:  # White piece
				dangerous_tiles += get_moves(Vector2(x, y))
	return dangerous_tiles

#endregion
