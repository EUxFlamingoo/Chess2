extends Node

#region const

# set units, start positions and define Moves
const BLACK_BISHOP = preload("res://Scenes/Pieces/chess/black_bishop.tscn")
const BLACK_KING = preload("res://Scenes/Pieces/chess/black_king.tscn")
const BLACK_KNIGHT = preload("res://Scenes/Pieces/chess/black_knight.tscn")
const BLACK_PAWN = preload("res://Scenes/Pieces/chess/black_pawn.tscn")
const BLACK_QUEEN = preload("res://Scenes/Pieces/chess/black_queen.tscn")
const BLACK_ROOK = preload("res://Scenes/Pieces/chess/black_rook.tscn")
const WHITE_BISHOP = preload("res://Scenes/Pieces/chess/white_bishop.tscn")
const WHITE_KING = preload("res://Scenes/Pieces/chess/white_king.tscn")
const WHITE_KNIGHT = preload("res://Scenes/Pieces/chess/white_knight.tscn")
const WHITE_PAWN = preload("res://Scenes/Pieces/chess/white_pawn.tscn")
const WHITE_QUEEN = preload("res://Scenes/Pieces/chess/white_queen.tscn")
const WHITE_ROOK = preload("res://Scenes/Pieces/chess/white_rook.tscn")
const CUSTOM_PIECE = preload("res://Scenes/Pieces/custom/custom_piece.tscn")
const CUSTOM_PIECE_SCRIPT = preload("res://Scenes/Pieces/custom/unit_template.gd")
const BLACK_SIDE_PAWN = preload("res://Scenes/Pieces/custom/black_side_pawn.tscn")
const WHITE_SIDE_PAWN = preload("res://Scenes/Pieces/custom/white_side_pawn.tscn")

const PIECE_SCENES = {
	"WhitePawn": WHITE_PAWN,
	"BlackPawn": BLACK_PAWN,
	"WhiteRook": WHITE_ROOK,
	"BlackRook": BLACK_ROOK,
	"WhiteKnight": WHITE_KNIGHT,
	"BlackKnight": BLACK_KNIGHT,
	"WhiteBishop": WHITE_BISHOP,
	"BlackBishop": BLACK_BISHOP,
	"WhiteKing": WHITE_KING,
	"BlackKing": BLACK_KING,
	"WhiteQueen": WHITE_QUEEN,
	"BlackQueen": BLACK_QUEEN,
	"WhiteCustomPiece": CUSTOM_PIECE,
	"BlackCustomPiece": CUSTOM_PIECE,
	"WhiteSidePawn": WHITE_SIDE_PAWN,
	"BlackSidePawn": BLACK_SIDE_PAWN
}

const PIECE_VALUES = {
	"Pawn": 1,
	"Knight": 3,
	"Bishop": 3,
	"Rook": 5,
	"Queen": 9,
	"King": 1000
}

#endregion

@onready var white_2: Button = $CanvasLayer/white2
@onready var white_3: Button = $CanvasLayer/white3
@onready var white_4: Button = $CanvasLayer/white4
@onready var white_5: Button = $CanvasLayer/white5
@onready var black_2: Button = $CanvasLayer/black2
@onready var black_3: Button = $CanvasLayer/black3
@onready var black_4: Button = $CanvasLayer/black4
@onready var black_5: Button = $CanvasLayer/black5


var promotion_pawn = null  # Stores the pawn to be promoted
var promotion_position = null  # Stores the position of the pawn to be promoted
var is_promotion_in_progress = false  # Tracks if a pawn promotion is in progress

var white_king_pos = Vector2(4, BoardManager.First_Rank)
var black_king_pos = Vector2(4, BoardManager.Last_Rank)

# Track whether the king or rooks have moved
var white_king_moved = false
var black_king_moved = false
var white_rook_kingside_moved = false
var white_rook_queenside_moved = false
var black_rook_kingside_moved = false
var black_rook_queenside_moved = false

func _enter_tree():
	set_multiplayer_authority(name.to_int())

# Helper function to place a piece
func place_piece(piece_scene: PackedScene, board_x: int, board_y: int, name_prefix: String = ""):
	var piece = piece_scene.instantiate()
	if name_prefix != "":
		piece.name = name_prefix
	else:
		piece.name = piece_scene.resource_path.get_file().get_basename() + "_" + str(board_x) + "_" + str(board_y)
	piece.position = BoardManager.get_centered_position(board_x, board_y)
	if piece.name.begins_with("White"):
		piece.is_white = true
	elif piece.name.begins_with("Black"):
		piece.is_white = false
	BoardManager.add_child(piece)
	BoardManager.board_state[board_y][board_x] = piece
	return piece

#region place_pieces

func place_custom_piece():
	for pos in CUSTOM_PIECE_SCRIPT.START_POS_WHITE:
		place_piece(CUSTOM_PIECE, pos.x, pos.y, "WhiteCustomPiece")
	#for pos in CUSTOM_PIECE_SCRIPT.START_POS_BLACK:
		#place_piece(CUSTOM_PIECE, pos.x, pos.y, "BlackCustomPiece")

# Place white pawns
func place_white_pawns():
	for x in range(BoardManager.BOARD_WIDTH):
		var pawn = WHITE_PAWN.instantiate()
		pawn.is_white = true
		pawn.name = "WhitePawn_%d_1" % x
		pawn.position = BoardManager.get_centered_position(x, 1)
		BoardManager.add_child(pawn)
		BoardManager.board_state[1][x] = pawn

# Place black pawns
func place_black_pawns():
	for x in range(BoardManager.BOARD_WIDTH):
		var pawn = BLACK_PAWN.instantiate()
		pawn.is_white = false
		pawn.name = "BlackPawn_%d_6" % x
		pawn.position = BoardManager.get_centered_position(x, 6)
		BoardManager.add_child(pawn)
		BoardManager.board_state[6][x] = pawn

# Place white knights
func place_white_knights():
	for x in [1, 6]:
		place_piece(WHITE_KNIGHT, x, BoardManager.First_Rank, "WhiteKnight")

# Place black knights
func place_black_knights():
	for x in [1, 6]:
		place_piece(BLACK_KNIGHT, x, BoardManager.Last_Rank, "BlackKnight")

# Place white bishops
func place_white_bishops():
	for x in [2, 5]:
		place_piece(WHITE_BISHOP, x, BoardManager.First_Rank, "WhiteBishop")

# Place black bishops
func place_black_bishops():
	for x in [2, 5]:
		place_piece(BLACK_BISHOP, x, BoardManager.Last_Rank, "BlackBishop")

# Place white rooks
func place_white_rooks():
	for x in [0, 7]:  # Place rooks at (0, 0) and (7, 0)
		place_piece(WHITE_ROOK, x, BoardManager.First_Rank, "WhiteRook")

# Place black rooks
func place_black_rooks():
	for x in [BoardManager.First_Rank, 7]:
		place_piece(BLACK_ROOK, x, BoardManager.Last_Rank, "BlackRook")

# Place the white queen
func place_white_queen():
	place_piece(WHITE_QUEEN, 3, BoardManager.First_Rank, "WhiteQueen")

# Place the black queen
func place_black_queen():
	place_piece(BLACK_QUEEN, 3, BoardManager.Last_Rank, "BlackQueen")

# Place the white king
func place_white_king():
	place_piece(WHITE_KING, 4, BoardManager.First_Rank, "WhiteKing")

# Place the black king
func place_black_king():
	place_piece(BLACK_KING, 4, BoardManager.Last_Rank, "BlackKing")
#endregion

#region unit_specific_moves

# Get value for any piece (including custom)
func get_piece_value(piece) -> int:
	if piece == null:
		return 0
	var script = piece.get_script()
	if script != null and "UNIT_VALUE" in script:
		return script.UNIT_VALUE
	# fallback to PIECE_VALUES for standard pieces
	var piece_name = piece.name
	for key in PIECE_VALUES.keys():
		if piece_name.find(key) != -1:
			return PIECE_VALUES[key]
	return 0

func place_piece_by_name(type: String, x: int, y: int):
	var scene = get_piece_scene(type)
	if scene:
		place_piece(scene, x, y, type)
	if GameManager.online_enabled and multiplayer.get_unique_id() == 1:
		var state = NetworkManager.get_board_state_as_array()
		for peer_id in multiplayer.get_peers():
			if peer_id != multiplayer.get_unique_id():
				NetworkManager.rpc_id(peer_id, "receive_full_board_state", state, TurnManager.is_white_turn)

func get_piece_scene(piece_name: String, is_white: bool = true) -> PackedScene:
	# Try direct match first
	if PIECE_SCENES.has(piece_name):
		return PIECE_SCENES[piece_name]
	# Try to find by suffix (e.g. "Queen", "CustomPiece")
	for key in PIECE_SCENES.keys():
		if piece_name in key:
			# Optionally, check color
			if (is_white and key.begins_with("White")) or (not is_white and key.begins_with("Black")):
				return PIECE_SCENES[key]
	return null

#region promotion

func handle_promotion(piece, target_position: Vector2, skip_last_rank_check := false):
	if piece == null or not piece.has_method("get_promotion_options"):
		return
	# Only check last rank for pawn-like promotion
	if not skip_last_rank_check:
		var is_white = piece.is_white
		var last_rank = BoardManager.Last_Rank if is_white else BoardManager.First_Rank
		if target_position.y != last_rank:
			return

	var promotion_options = piece.get_promotion_options()
	if promotion_options.size() == 0:
		return

	promotion_pawn = piece
	promotion_position = target_position
	is_promotion_in_progress = true

	_show_promotion_ui(promotion_options, piece.is_white)

func _show_promotion_ui(options: Array, is_white: bool):
	# Hide all buttons first
	for btn in [white_2, white_3, white_4, white_5, black_2, black_3, black_4, black_5]:
		btn.visible = false

	var button_map = {}

	if is_white:
		button_map = {
			"Queen": white_5,
			"Rook": white_4,
			"Bishop": white_3,
			"Knight": white_2,
		}
	else:
		button_map = {
			"Queen": black_5,
			"Rook": black_4,
			"Bishop": black_3,
			"Knight": black_2,
		}

	for option in options:
		if button_map.has(option):
			button_map[option].visible = true

func _on_white_5_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Queen")
	else:
		promote_pawn("Queen", UnitManager.WHITE_QUEEN)

# Repeat for other promotion buttons:
func _on_white_4_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Rook")
	else:
		promote_pawn("Rook", UnitManager.WHITE_ROOK)

func _on_white_3_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Bishop")
	else:
		promote_pawn("Bishop", UnitManager.WHITE_BISHOP)

func _on_white_2_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Knight")
	else:
		promote_pawn("Knight", UnitManager.WHITE_KNIGHT)

func _on_black_5_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Queen")
	else:
		promote_pawn("Queen", UnitManager.BLACK_QUEEN)

func _on_black_4_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Rook")
	else:
		promote_pawn("Rook", UnitManager.BLACK_ROOK)

func _on_black_3_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Bishop")
	else:
		promote_pawn("Bishop", UnitManager.BLACK_BISHOP)

func _on_black_2_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Knight")
	else:
		promote_pawn("Knight", UnitManager.BLACK_KNIGHT)


func promote_pawn(piece_name: String, piece_scene: PackedScene):
	if promotion_pawn == null or promotion_position == null:
		print("No pawn to promote!")
		return
	# Remove the pawn from the board and scene tree
	BoardManager.board_state[int(promotion_position.y)][int(promotion_position.x)] = null
	var was_white = promotion_pawn.is_white  # Store the original color
	promotion_pawn.queue_free()
	# Instantiate the new piece and place it on the board
	var new_piece = piece_scene.instantiate()
	var color_prefix = "White" if was_white else "Black"
	new_piece.name = color_prefix + piece_name + "_" + str(promotion_position.x) + "_" + str(promotion_position.y)
	new_piece.position = BoardManager.get_centered_position(int(promotion_position.x), int(promotion_position.y))
	new_piece.is_white = was_white  # Ensure the promoted piece keeps the original color!
	BoardManager.add_child(new_piece)
	BoardManager.board_state[int(promotion_position.y)][int(promotion_position.x)] = new_piece
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
	# Check if the turn should end
	TurnManager.check_turn_end()

func promote_pawn_networked(pawn_pos: Vector2, piece_name: String):
	var pawn = BoardManager.board_state[int(pawn_pos.y)][int(pawn_pos.x)]
	if pawn and pawn.name.find("Pawn") != -1:
		promote_pawn(piece_name, UnitManager.get_piece_scene(piece_name, pawn.name.begins_with("White")))

func check_custom_promotion(piece, new_position: Vector2) -> void:
	var script = piece.get_script()
	if script == null:
		print("No script found on piece for custom promotion.")
		return
	# Defeats-based promotion
	var needed = null
	if "PROMOTION_TRIGGER_DEFEATS" in script:
		needed = script.PROMOTION_TRIGGER_DEFEATS
		print("PROMOTION_TRIGGER_DEFEATS found, needed:", needed, " defeated_count:", piece.defeated_count)
	if needed != null and piece.defeated_count >= needed:
		print("Triggering promotion by defeats for", piece.name)
		handle_promotion(piece, new_position, true)
		return
	# Value-based promotion
	var needed_value = null
	if "PROMOTION_TRIGGER_VALUE" in script:
		needed_value = script.PROMOTION_TRIGGER_VALUE
		print("PROMOTION_TRIGGER_VALUE found, needed:", needed_value, " accrued_value:", piece.accrued_value)
	if needed_value != null and piece.accrued_value >= needed_value:
		print("Triggering promotion by value for", piece.name)
		handle_promotion(piece, new_position, true)
		return
	# Position-based promotion
	var spots = null
	if "PROMOTION_TRIGGER_SPOTS" in script:
		spots = script.PROMOTION_TRIGGER_SPOTS
		print("PROMOTION_TRIGGER_SPOTS found:", spots)
	if spots != null:
		for spot in spots:
			if new_position == spot:
				print("Triggering promotion by spot for", piece.name, "at", new_position)
				handle_promotion(piece, new_position, true)
				return

#endregion
