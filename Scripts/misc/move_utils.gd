extends Node

var BishopMoves = preload("res://Scenes/Pieces/chess/bishop.gd").new()
var RookMoves = preload("res://Scenes/Pieces/chess/rook.gd").new()
var KnightMoves = preload("res://Scenes/Pieces/chess/knight.gd").new()
var KingMoves = preload("res://Scenes/Pieces/chess/king.gd").new()
var PawnMoves = preload("res://Scenes/Pieces/chess/pawn.gd").new()
const PIECE_ATTACK = preload("res://Assets/misc/Piece_attack.png")

func get_bishop_moves(x, y, is_white):
	return BishopMoves.get_bishop_moves(x, y, is_white)

func get_rook_moves(x, y, is_white):
	return RookMoves.get_rook_moves(x, y, is_white)

func get_knight_moves(x, y, is_white):
	return KnightMoves.get_knight_moves(x, y, is_white)

func get_king_moves(x, y, is_white):
	return KingMoves.get_king_moves(x, y, is_white)

func get_pawn_moves(x, y, is_white):
	return PawnMoves.get_pawn_moves(x, y, is_white)

# --- Range Attack Implementation ---

# Returns all tiles in attack range, respecting interruption if requested
func get_range_attack_tiles(piece, x, y) -> Array:
	if "RANGE_ATTACK_INTERRUPTED" in piece and piece.RANGE_ATTACK_INTERRUPTED:
		return get_interrupted_attack_tiles(piece, x, y)
	else:
		return get_uninterrupted_attack_tiles(piece, x, y)

# Uninterrupted: current behavior
func get_uninterrupted_attack_tiles(piece, x, y) -> Array:
	var attack_tiles = []
	if not ("ATTACK_RANGE" in piece):
		return attack_tiles
	for moveset in piece.ATTACK_RANGE:
		match moveset:
			"bishop":
				attack_tiles += get_bishop_moves(x, y, piece.is_white)
			"rook":
				attack_tiles += get_rook_moves(x, y, piece.is_white)
			"knight":
				attack_tiles += get_knight_moves(x, y, piece.is_white)
			"queen":
				attack_tiles += get_bishop_moves(x, y, piece.is_white)
				attack_tiles += get_rook_moves(x, y, piece.is_white)
			"king":
				attack_tiles += get_king_moves(x, y, piece.is_white)
			"pawn":
				attack_tiles += get_pawn_moves(x, y, piece.is_white)
			_:
				push_warning("Unknown attack range moveset: %s" % moveset)
	return attack_tiles

# Interrupted: stops at first piece or obstacle in each direction
func get_interrupted_attack_tiles(piece, x, y) -> Array:
	var attack_tiles = []
	if not ("ATTACK_RANGE" in piece):
		return attack_tiles
	for moveset in piece.ATTACK_RANGE:
		match moveset:
			"rook":
				attack_tiles += get_interrupted_line_moves(x, y, piece.is_white, [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)])
			"bishop":
				attack_tiles += get_interrupted_line_moves(x, y, piece.is_white, [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)])
			"queen":
				attack_tiles += get_interrupted_line_moves(x, y, piece.is_white, [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1), Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)])
			"knight":
				attack_tiles += get_knight_moves(x, y, piece.is_white)
			"king":
				attack_tiles += get_king_moves(x, y, piece.is_white)
			"pawn":
				attack_tiles += get_pawn_moves(x, y, piece.is_white)
			"side_pawn":
				attack_tiles += get_side_pawn_moves(x, y, piece.is_white)
			_:
				push_warning("Unknown attack range moveset: %s" % moveset)
	return attack_tiles

# Helper for interrupted line moves (rook, bishop, queen)
func get_interrupted_line_moves(x, y, is_white, directions) -> Array:
	var result = []
	for dir in directions:
		var nx = x
		var ny = y
		while true:
			nx += dir.x
			ny += dir.y
			if not BoardManager.is_within_board(nx, ny):
				break
			if BoardManager.is_tile_obstacle(nx, ny):
				print("Obstacle at: ", nx, ",", ny)
				break
			if BoardManager.is_tile_occupied(nx, ny):
				print("Piece at: ", nx, ",", ny)
				result.append(Vector2(nx, ny))
				break
			result.append(Vector2(nx, ny))
	return result

# Highlight attack range tiles (call this from your UI/highlight system)
func highlight_range_attack_tiles(tiles: Array):
	MoveManager.highlight_range_attack_tiles(tiles, PIECE_ATTACK)

# Perform a range attack: if a piece is on the target tile, capture it (do not move attacker)
func perform_range_attack(attacker, target_pos: Vector2):
	var target_piece = BoardManager.board_state[target_pos.y][target_pos.x]
	if target_piece != null and target_piece.is_white != attacker.is_white:
		# Remove the target piece from the board
		target_piece.queue_free()
		BoardManager.board_state[target_pos.y][target_pos.x] = null
		print("Range attack: ", attacker.name, " captured ", target_piece.name, " at ", target_pos)
	else:
		print("No valid target to attack at ", target_pos)

func get_side_pawn_moves(x, y, is_white):
	var moves = []
	var direction = 1 if is_white else -1  # Right for white, left for black
	var tx = x + direction
	# Forward move (sideways)
	if BoardManager.is_within_board(tx, y) and not BoardManager.is_tile_occupied(tx, y) and not BoardManager.is_tile_obstacle(tx, y):
		moves.append(Vector2(tx, y))
	# Double move from starting file (optional, like normal pawn)
	var starting_file = BoardManager.First_File + 1 if is_white else BoardManager.Last_File - 1
	if x == starting_file and not BoardManager.is_tile_occupied(tx, y) and not BoardManager.is_tile_occupied(x + 2 * direction, y) and not BoardManager.is_tile_obstacle(x + 2 * direction, y):
		moves.append(Vector2(x + 2 * direction, y))
	# Captures (diagonal forward, i.e. up-right/down-right for white, up-left/down-left for black)
	for dy in [-1, 1]:
		var ty = y + dy
		if BoardManager.is_within_board(tx, ty):
			if BoardManager.is_tile_occupied_by_opponent(tx, ty, is_white):
				moves.append(Vector2(tx, ty))
	return moves
