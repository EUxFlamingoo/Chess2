extends Sprite2D

#region const
const BOARD_SIZE = 8
const CELL_WIDTH = 18

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")

const BLACK_BISHOP = preload("res://Assets/black_bishop.png")
const BLACK_KING = preload("res://Assets/black_king.png")
const BLACK_KNIGHT = preload("res://Assets/black_knight.png")
const BLACK_PAWN = preload("res://Assets/black_pawn.png")
const BLACK_QUEEN = preload("res://Assets/black_queen.png")
const BLACK_ROOK = preload("res://Assets/black_rook.png")
const WHITE_BISHOP = preload("res://Assets/white_bishop.png")
const WHITE_KING = preload("res://Assets/white_king.png")
const WHITE_KNIGHT = preload("res://Assets/white_knight.png")
const WHITE_PAWN = preload("res://Assets/white_pawn.png")
const WHITE_QUEEN = preload("res://Assets/white_queen.png")
const WHITE_ROOK = preload("res://Assets/white_rook.png")

const TURN_WHITE = preload("res://Assets/turn-white.png")
const TURN_BLACK = preload("res://Assets/turn-black.png")

const PIECE_MOVE = preload("res://Assets/Piece_move.png")

const PIECE_VALUES = {
	1: 10,    # White Pawn
	2: 30,    # White Knight
	3: 30,    # White Bishop
	4: 50,    # White Rook
	5: 90,    # White Queen
	6: 900,    # White King (never scored)
}

const PIECE_TEXTURES = {
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

#endregion

#region var
@onready var pieces = $Pieces
@onready var dots = $Dots
@onready var turn = $Turn
@onready var white_pieces = $"../CanvasLayer/white_pieces"
@onready var black_pieces = $"../CanvasLayer/black_pieces"
@onready var player_2: Button = $"../player_2"
@onready var player_1: Button = $"../player_1"
@onready var game_finish: Button = $"../game_finish"
@onready var game_finish_2: Button = $"../game_finish2"


#Variables
# -6 = black king
# -5 = black queen
# -4 = black rook
# -3 = black bishop
# -2 = black knight
# -1 = black pawn
# 0 = empty
# 6 = white king
# 5 = white queen
# 4 = white rook
# 3 = white bishop
# 2 = white knight
# 1 = white pawn

var board : Array
var white : bool = true
var state : bool = false
var moves = []
var selected_piece : Vector2

var promotion_square = null

var white_king = false
var black_king = false
var white_rook_left = false
var white_rook_right = false
var black_rook_left = false
var black_rook_right = false

var en_passant = null

var white_king_pos = Vector2(0, 4)
var black_king_pos = Vector2(7, 4)

var fifty_move_rule = 0

var unique_board_moves : Array = []
var amount_of_same : Array = []

var ai_enabled := true #TODO AI 1
#endregion

#region ready/input/board

func _on_player_2_pressed() -> void:
	player_2.visible = false
	player_1.visible = false
	ai_enabled = false

func _on_player_1_pressed() -> void:
	player_2.visible = false
	player_1.visible = false
	ai_enabled = true

func initialize_board():
	return [
	[4, 2, 3, 5, 6, 3, 2, 4],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[-1, -1, -1, -1, -1, -1, -1, -1],
	[-4, -2, -3, -5, -6, -3, -2, -4]
	]

func _ready():
	board = initialize_board()
	display_board()
	
	var white_buttons = get_tree().get_nodes_in_group("white_pieces")
	var black_buttons = get_tree().get_nodes_in_group("black_pieces")
	
	for button in white_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
		
	for button in black_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
	
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
			
func is_mouse_out():
	if get_rect().has_point(to_local(get_global_mouse_position())): return false
	return true

func display_board():
	@warning_ignore("integer_division") 
	for child in pieces.get_children():
		child.queue_free()
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			@warning_ignore("integer_division")
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2), -i * CELL_WIDTH - (CELL_WIDTH / 2))
			
			holder.texture = PIECE_TEXTURES.get(board[i][j], null)
				
	if white: turn.texture = TURN_WHITE
	else: turn.texture = TURN_BLACK
#endregion

#region set_moves/dots
func show_options():
	moves = get_moves(selected_piece)
	if moves == []:
		state = false
		return
	show_dots()
	
func show_dots():
	for i in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		@warning_ignore("integer_division")
		holder.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH / 2), -i.x * CELL_WIDTH - (CELL_WIDTH / 2))

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(var2, var1):
	var just_now = false
	for i in moves:
		if i.x == var2 && i.y == var1:
			fifty_move_rule += 1
			if is_enemy(Vector2(var2, var1)): fifty_move_rule = 0
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
	
	if (selected_piece.x != var2 || selected_piece.y != var1) && (white && board[var2][var1] > 0 || !white && board[var2][var1] < 0):
		selected_piece = Vector2(var2, var1)
		show_options()
		state = true
	elif is_stalemate():
		if white && is_in_check(white_king_pos) || !white && is_in_check(black_king_pos): 
			print("CHECKMATE")
			white = true
			game_finish.visible = true
			
		else: 
			print("DRAW")
			white = true
			game_finish_2.visible = true
		
	if fifty_move_rule == 50: 
		print("DRAW")
		white = true
		game_finish_2.visible = true
	elif insuficient_material(): 
		print("DRAW")
		white = true
		game_finish_2.visible = true

#endregion

#region get_moves
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

func update_and_check_board(pos: Vector2, piece_position: Vector2, piece_value: int) -> bool:
	board[pos.x][pos.y] = piece_value
	board[piece_position.x][piece_position.y] = 0
	var is_safe = (white && !is_in_check(white_king_pos)) || (!white && !is_in_check(black_king_pos))
	board[pos.x][pos.y] = 0
	board[piece_position.x][piece_position.y] = piece_value
	return is_safe

func get_rook_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
	var piece_value = 4 if white else -4

	for i in directions:
		var pos = piece_position
		pos += i
		while is_valid_position(pos):
			if is_empty(pos) or is_enemy(pos):
				if update_and_check_board(pos, piece_position, piece_value):
					_moves.append(pos)
				if is_enemy(pos):
					break
				else: break
			
			pos += i
	
	return _moves

func get_bishop_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	var piece_value = 3 if white else -3

	for i in directions:
		var pos = piece_position
		pos += i
		while is_valid_position(pos):
			if is_empty(pos) or is_enemy(pos):
				if update_and_check_board(pos, piece_position, piece_value):
					_moves.append(pos)
				if is_enemy(pos):
					break
				else: break
	
			pos += i
	
	return _moves

func get_queen_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	var piece_value = 5 if white else -5

	for i in directions:
		var pos = piece_position
		pos += i
		while is_valid_position(pos):
			if is_empty(pos) or is_enemy(pos):
				if update_and_check_board(pos, piece_position, piece_value):
					_moves.append(pos)
				if is_enemy(pos):
					break
			else: break
	
			pos += i
	
	return _moves

func get_king_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]

	if white:
		board[white_king_pos.x][white_king_pos.y] = 0
	else:
		board[black_king_pos.x][black_king_pos.y] = 0
	
	for i in directions:
		var pos = piece_position + i
		if is_valid_position(pos):
			if !is_in_check(pos):
				if is_empty(pos): _moves.append(pos)
				elif is_enemy(pos):
					_moves.append(pos)
	
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
	
	if white:
		board[white_king_pos.x][white_king_pos.y] = 6
	else:
		board[black_king_pos.x][black_king_pos.y] = -6
	
	return _moves

func get_knight_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(1, -2),
	Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)]
	var piece_value = 2 if white else -2
	
	for i in directions:
		var pos = piece_position + i
		if is_valid_position(pos):
			if is_empty(pos) or is_enemy(pos):
				if update_and_check_board(pos, piece_position, piece_value):
					_moves.append(pos)
	
	return _moves

func get_pawn_moves(piece_position : Vector2):
	var _moves = []
	var direction
	var is_first_move = false
	
	if white: direction = Vector2(1, 0)
	else: direction = Vector2(-1, 0)
	
	if white && piece_position.x == 1 || !white && piece_position.x == 6: is_first_move = true
	
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
	
	var pos = piece_position + direction
	if is_empty(pos):
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		if white && !is_in_check(white_king_pos) || !white && !is_in_check(black_king_pos): _moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = 1 if white else -1
	
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

func is_valid_position(pos : Vector2):
	if pos.x >= 0 && pos.x < BOARD_SIZE && pos.y >= 0 && pos.y < BOARD_SIZE: return true
	return false
	
func is_empty(pos : Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false
	
func is_enemy(pos : Vector2):
	if white && board[pos.x][pos.y] < 0 || !white && board[pos.x][pos.y] > 0: return true
	return false
	

func promote(_var : Vector2):
	promotion_square = _var
	white_pieces.visible = white
	black_pieces.visible = !white

func ai_promote(pos : Vector2):
	board[selected_piece.x][selected_piece.y] = 0
	board[pos.x][pos.y] = 5 if white else -5
	promotion_square = null
	display_board()
	white = true

func _on_button_pressed(button):
	var num_char = int(button.name.substr(0, 1))
	board[promotion_square.x][promotion_square.y] = -num_char if white else num_char
	white_pieces.visible = false
	black_pieces.visible = false
	promotion_square = null
	display_board()
	if ai_enabled == true:
		ai_move() #FIXME change ai 3


func _on_game_finish_pressed() -> void:
	get_tree().reload_current_scene()

func _on_game_finish_2_pressed() -> void:
	get_tree().reload_current_scene()

#endregion

#region is_in_check/etc.
func is_in_check(king_pos: Vector2):
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	var pawn_direction = 1 if white else -1
	var pawn_attacks = [
		king_pos + Vector2(pawn_direction, 1),
		king_pos + Vector2(pawn_direction, -1)
	]
	
	for i in pawn_attacks:
		if is_valid_position(i):
			if white && board[i.x][i.y] == -1 || !white && board[i.x][i.y] == 1: return true
	
	for i in directions:
		var pos = king_pos + i
		if is_valid_position(pos):
			if white && board[pos.x][pos.y] == -6 || !white && board[pos.x][pos.y] == 6: return true
			
	for i in directions:
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
			
	var knight_directions = [Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(1, -2),
	Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)]
	
	for i in knight_directions:
		var pos = king_pos + i
		if is_valid_position(pos):
			if white && board[pos.x][pos.y] == -2 || !white && board[pos.x][pos.y] == 2:
				return true
				
	return false

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

func ai_move():
	if promotion_square != null: return
	evaluate_board_advantage()
	french_defense()

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


func protect_threatened_piece():
	if promotion_square != null:
		return
	
	var threat_map = get_threat_map(board, true)  # We're black, check white threats
	var best_score = -INF
	var best_from = null
	var best_to = null
	
	# First priority: Check if king is in danger
	var king_pos = black_king_pos
	if threat_map.has(king_pos):
		# King is threatened - highest priority
		var threats: Array = threat_map[king_pos]
		
		# Try to capture the threatening piece
		for threat_pos in threats:
			for x in BOARD_SIZE:
				for y in BOARD_SIZE:
					if board[x][y] < 0:  # Our piece
						var piece_pos = Vector2(x, y)
						var piece_moves = get_moves(piece_pos)
						for move in piece_moves:
							if move == threat_pos:
								selected_piece = piece_pos
								moves = piece_moves
								set_move(move.x, move.y)
								print("Captured piece threatening king")
								return
		
		# Try to move king to safety
		var king_moves = get_moves(king_pos)
		if king_moves.size() > 0:
			selected_piece = king_pos
			moves = king_moves
			set_move(king_moves[0].x, king_moves[0].y)
			print("Moved king to safety")
			return
		
		# Try to block the check
		for threat_pos in threats:
			var direction = Vector2(
				sign(king_pos.x - threat_pos.x),
				sign(king_pos.y - threat_pos.y)
			)
			
			# Only try to block if it's a sliding piece (bishop, rook, queen)
			var threat_piece = abs(board[threat_pos.x][threat_pos.y])
			if threat_piece in [3, 4, 5]:
				var block_pos = threat_pos
				while block_pos != king_pos:
					block_pos += direction
					if block_pos == king_pos:
						break
						
					for x in BOARD_SIZE:
						for y in BOARD_SIZE:
							if board[x][y] < 0 and board[x][y] != -6:  # Our piece, not king
								var piece_pos = Vector2(x, y)
								var piece_moves = get_moves(piece_pos)
								for move in piece_moves:
									if move == block_pos:
										selected_piece = piece_pos
										moves = piece_moves
										set_move(move.x, move.y)
										print("Blocked check")
										return
	
	# Second priority: Handle other threatened pieces
	for target in threat_map.keys():
		if target == king_pos:
			continue  # Already handled king
			
		var target_value = PIECE_VALUES.get(abs(board[target.x][target.y]), 0)
		var threats: Array = threat_map[target]
		
		# Try to capture threat(s) with a less valuable piece
		for threat_pos in threats:
			var threat_value = PIECE_VALUES.get(abs(board[threat_pos.x][threat_pos.y]), 0)
			
			for x in BOARD_SIZE:
				for y in BOARD_SIZE:
					if board[x][y] < 0:  # Our piece
						var piece_pos = Vector2(x, y)
						var piece_value = PIECE_VALUES.get(abs(board[x][y]), 0)
						
						# Only capture if our piece is less valuable or equal to the threat
						if piece_value <= threat_value:
							var piece_moves = get_moves(piece_pos)
							for move in piece_moves:
								if move == threat_pos:
									var score = threat_value - piece_value
									if score > best_score:
										best_score = score
										best_from = piece_pos
										best_to = move
		
		# Try to move piece out of danger
		var legal_escapes = get_moves(target)
		for escape in legal_escapes:
			var temp_piece = board[escape.x][escape.y]
			if temp_piece == 0 or (temp_piece < 0 and PIECE_VALUES.get(abs(temp_piece), 0) < target_value):
				# Escape is valid and doesn't sacrifice something more valuable
				if target_value > best_score:  # Prioritize saving valuable pieces
					best_score = target_value
					best_from = target
					best_to = escape
		
		# Try blocking with a lower value piece
		for threat_pos in threats:
			var threat_piece = abs(board[threat_pos.x][threat_pos.y])
			
			# Only try to block if it's a sliding piece (bishop, rook, queen)
			if threat_piece in [3, 4, 5]:
				var direction = Vector2(
					sign(target.x - threat_pos.x),
					sign(target.y - threat_pos.y)
				)
				
				var block_pos = threat_pos
				while block_pos != target:
					block_pos += direction
					if block_pos == target:
						break
						
					for x in BOARD_SIZE:
						for y in BOARD_SIZE:
							var blocker = board[x][y]
							if blocker < 0:
								var blocker_pos = Vector2(x, y)
								var blocker_value = PIECE_VALUES.get(abs(blocker), 0)
								
								if blocker_value < target_value:
									var block_moves = get_moves(blocker_pos)
									for move in block_moves:
										if move == block_pos:
											var score = target_value - blocker_value
											if score > best_score:
												best_score = score
												best_from = blocker_pos
												best_to = move
	
	# Third priority: Develop pieces if no immediate threats
	if best_from == null:
		# Try to develop center pawns
		var center_pawns = [Vector2(6, 3), Vector2(6, 4)]
		for pawn_pos in center_pawns:
			if board[pawn_pos.x][pawn_pos.y] == -1:
				var pawn_moves = get_moves(pawn_pos)
				if pawn_moves.size() > 0:
					best_from = pawn_pos
					best_to = pawn_moves[0]
					best_score = 1
		
		# Try to develop knights
		var knights = [Vector2(7, 1), Vector2(7, 6)]
		for knight_pos in knights:
			if board[knight_pos.x][knight_pos.y] == -2:
				var knight_moves = get_moves(knight_pos)
				for move in knight_moves:
					if move.x == 5 and (move.y == 2 or move.y == 5):  # Good knight development
						best_from = knight_pos
						best_to = move
						best_score = 2  # Higher priority than pawns
	
	if best_from != null and best_to != null:
		selected_piece = best_from
		moves = get_moves(best_from)
		set_move(best_to.x, best_to.y)
		print("Defended threatened piece")
	else:
		make_greed_move()




#endregion

#region value_system

func evaluate_board_advantage():
	var value = 0
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var piece = board[x][y]
			if piece > 0:
				value += PIECE_VALUES.get(piece, 0)
			elif piece < 0:
				value -= PIECE_VALUES.get(-piece, 0)
	print(value)
	return value

func get_all_enemy_moves(board: Array, is_white_turn: bool) -> Dictionary:
	var enemy_moves: Dictionary = {}

	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var piece = board[x][y]
			if is_white_turn and piece < 0 or not is_white_turn and piece > 0:
				var pos = Vector2(x, y)
				var moves = get_piece_moves(pos, board, not is_white_turn)
				enemy_moves[pos] = moves

	return enemy_moves

# Wrapper for move generation without side effects
func get_piece_moves(pos: Vector2, board: Array, is_white: bool) -> Array:
	# backup original state
	var original_white = white
	white = is_white
	
	var result = []
	match abs(board[pos.x][pos.y]):
		1: result = get_pawn_moves(pos)
		2: result = get_knight_moves(pos)
		3: result = get_bishop_moves(pos)
		4: result = get_rook_moves(pos)
		5: result = get_queen_moves(pos)
		6: result = get_king_moves(pos)

	# restore state
	white = original_white
	return result

func get_threatened_pieces(board: Array, is_white_turn: bool) -> Array:
	var threatened_pieces: Array = []
	var enemy_moves = get_all_enemy_moves(board, is_white_turn)
	
	for moves in enemy_moves.values():
		for target in moves:
			var piece = board[target.x][target.y]
			if (is_white_turn and piece > 0) or (not is_white_turn and piece < 0):
				if not threatened_pieces.has(target):
					threatened_pieces.append(target)
	
	return threatened_pieces

func get_threat_map(board: Array, is_white_turn: bool) -> Dictionary:
	var threat_map: Dictionary = {}
	
	# Directly check for threats without using get_all_enemy_moves for efficiency
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var piece = board[x][y]
			# Only consider enemy pieces
			if (is_white_turn and piece > 0) or (not is_white_turn and piece < 0):
				var attacker_pos = Vector2(x, y)
				var piece_type = abs(piece)
				
				match piece_type:
					1: # Pawn
						var direction = 1 if piece > 0 else -1
						var attack_positions = [
							Vector2(x + direction, y - 1),
							Vector2(x + direction, y + 1)
						]
						
						for attack_pos in attack_positions:
							if is_valid_position(attack_pos):
								var target_piece = board[attack_pos.x][attack_pos.y]
								if (is_white_turn and target_piece < 0) or (not is_white_turn and target_piece > 0):
									if not threat_map.has(attack_pos):
										threat_map[attack_pos] = []
									threat_map[attack_pos].append(attacker_pos)
					
					2: # Knight
						var knight_moves = [
							Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(1, -2),
							Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)
						]
						
						for move in knight_moves:
							var target = attacker_pos + move
							if is_valid_position(target):
								var target_piece = board[target.x][target.y]
								if (is_white_turn and target_piece < 0) or (not is_white_turn and target_piece > 0):
									if not threat_map.has(target):
										threat_map[target] = []
									threat_map[target].append(attacker_pos)
					
					3, 4, 5: # Bishop, Rook, Queen
						var directions = []
						if piece_type == 3 or piece_type == 5: # Bishop or Queen
							directions += [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
						if piece_type == 4 or piece_type == 5: # Rook or Queen
							directions += [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
						
						for direction in directions:
							var target = attacker_pos + direction
							while is_valid_position(target):
								var target_piece = board[target.x][target.y]
								if target_piece != 0: # Hit a piece
									if (is_white_turn and target_piece < 0) or (not is_white_turn and target_piece > 0):
										if not threat_map.has(target):
											threat_map[target] = []
										threat_map[target].append(attacker_pos)
									break
								target += direction
					
					6: # King
						var king_moves = [
							Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
							Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)
						]
						
						for move in king_moves:
							var target = attacker_pos + move
							if is_valid_position(target):
								var target_piece = board[target.x][target.y]
								if (is_white_turn and target_piece < 0) or (not is_white_turn and target_piece > 0):
									if not threat_map.has(target):
										threat_map[target] = []
									threat_map[target].append(attacker_pos)
	
	return threat_map




#endregion

#region tactics

func piece_loaction(pos: Vector2, piece_id: int) -> bool:
	if not is_valid_position(pos):
		return false
	return board[pos.x][pos.y] == piece_id

func french_defense():
	if  piece_loaction(Vector2(6,3), -1) && piece_loaction(Vector2(3,4), 1) && piece_loaction(Vector2(1,0), 1) && \
	piece_loaction(Vector2(1,1), 1) && piece_loaction(Vector2(1,2), 1) && piece_loaction(Vector2(1,4), 0) && piece_loaction(Vector2(5,4), 0) &&\
	piece_loaction(Vector2(1,5), 1) && piece_loaction(Vector2(1,6), 1) && piece_loaction(Vector2(1,7), 1) && piece_loaction(Vector2(1,3), 1):
		board[6][4] = 0
		board[5][4] = -1
		display_board()
		print("French Defense 1")
		if !white: white = true
		return
	
	if  piece_loaction(Vector2(3,3), 1) && piece_loaction(Vector2(1,0), 1) && piece_loaction(Vector2(3,4), 1) &&\
	piece_loaction(Vector2(1,1), 1) && piece_loaction(Vector2(1,2), 1) && piece_loaction(Vector2(1,4), 0) && \
	piece_loaction(Vector2(1,5), 1) && piece_loaction(Vector2(1,6), 1) && piece_loaction(Vector2(1,7), 1) && piece_loaction(Vector2(4,3), 0):
		board[6][3] = 0
		board[4][3] = -1
		display_board()
		print("French Defense 2")
		if !white: white = true
		return
	
	if  piece_loaction(Vector2(1,0), 1) && piece_loaction(Vector2(1,1), 1) && piece_loaction(Vector2(1,2), 1)\
	 && piece_loaction(Vector2(3,3), 1) && piece_loaction(Vector2(4,4), 1) && piece_loaction(Vector2(1,5), 1)\
	 && piece_loaction(Vector2(1,6), 1) && piece_loaction(Vector2(1,7), 1) && piece_loaction(Vector2(1,3), 0):
		board[6][2] = 0
		board[4][2] = -1
		display_board()
		print("French Defense 3")
		if !white: white = true
		return
	
	else:
		queens_gambit_declined()


func queens_gambit_declined():
	if  piece_loaction(Vector2(1,0), 1) && piece_loaction(Vector2(1,1), 1) && piece_loaction(Vector2(1,2), 1)\
	 && piece_loaction(Vector2(3,3), 1) && piece_loaction(Vector2(1,4), 1) && piece_loaction(Vector2(1,5), 1)\
	 && piece_loaction(Vector2(1,6), 1) && piece_loaction(Vector2(1,7), 1):
		board[6][3] = 0
		board[4][3] = -1
		display_board()
		print("The Queen’s Gambit Declined 1")
		if !white: white = true
		return
	
	if  piece_loaction(Vector2(1,0), 1) && piece_loaction(Vector2(1,1), 1) && piece_loaction(Vector2(3,2), 1)\
	 && piece_loaction(Vector2(3,3), 1) && piece_loaction(Vector2(1,4), 1) && piece_loaction(Vector2(1,5), 1)\
	 && piece_loaction(Vector2(1,6), 1) && piece_loaction(Vector2(1,7), 1) && piece_loaction(Vector2(0,1), 2):
		board[6][2] = 0
		board[5][2] = -1
		display_board()
		print("The Queen’s Gambit Declined 2")
		if !white: white = true
		return
	
	if  piece_loaction(Vector2(1,0), 1) && piece_loaction(Vector2(1,1), 1) && piece_loaction(Vector2(3,2), 1)\
	 && piece_loaction(Vector2(3,3), 1) && piece_loaction(Vector2(1,4), 1) && piece_loaction(Vector2(1,5), 1)\
	 && piece_loaction(Vector2(1,6), 1) && piece_loaction(Vector2(1,7), 1) && piece_loaction(Vector2(2,2), 2)\
	 && piece_loaction(Vector2(0,2), 3):
		board[7][6] = 0
		board[5][5] = -2
		display_board()
		print("The Queen’s Gambit Declined 3")
		if !white: white = true
		return
	
	if  piece_loaction(Vector2(1,0), 1) && piece_loaction(Vector2(1,1), 1) && piece_loaction(Vector2(3,2), 1)\
	 && piece_loaction(Vector2(3,3), 1) && piece_loaction(Vector2(1,4), 1) && piece_loaction(Vector2(1,5), 1)\
	 && piece_loaction(Vector2(1,6), 1) && piece_loaction(Vector2(1,7), 1) && piece_loaction(Vector2(2,2), 2)\
	 && piece_loaction(Vector2(4,6), 3):
		board[7][1] = 0
		board[6][3] = -2
		display_board()
		print("The Queen’s Gambit Declined 4")
		if !white: white = true
		return
	
	else:
		protect_threatened_piece()
#endregion
