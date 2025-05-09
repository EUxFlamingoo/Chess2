extends Node2D

const TILE_SIZE = 64  # Modify
const adjust_height = TILE_SIZE / 1.01  # Modify
const TILE_Z_INDEX = 0  # Set your desired z-index for board tiles here

var BOARD_WIDTH := 1
var BOARD_HEIGHT := 1

var First_Rank = 0  # Modify with caution
var Last_Rank = BOARD_HEIGHT - 1 # Modify with caution
var First_File = 0  # Modify with caution
var Last_File = BOARD_WIDTH - 1  # Modify with caution

var LIGHT_COLOR := Color(0.4, 0.3, 0.2)
var DARK_COLOR := Color(0.3, 0.2, 0.1)

var custom_highlights := []
#region var

var board_state = []
var selected_piece = null
var selected_piece_position = null
var can_select_piece := true
var selecting_ok = true

#endregion

#region create/initialize_board

func initialize():
	board_state = []
	for y in range(BOARD_HEIGHT):
		var row = []
		for x in range(BOARD_WIDTH):
			row.append(null)
		board_state.append(row)
	create_chessboard()

func set_board_size(width: int, height: int):
	BOARD_WIDTH = width
	BOARD_HEIGHT = height

func set_tile_colors(light: Color, dark: Color):
	LIGHT_COLOR = light
	DARK_COLOR = dark

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
			tile.z_index = TILE_Z_INDEX  # Use the custom z-index
			add_child(tile)

#endregion

#region grid

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
	print("[select_piece] Called with x:", x, " y:", y)
	if TurnManager.has_node("/root/TurnManager") and get_node("/root/TurnManager").post_move_attack_pending:
		print("[select_piece] post_move_attack_pending is TRUE")
		# Only allow selecting enemy pieces during post-move attack phase
		if not is_within_board(x, y) or not is_tile_occupied(x, y):
			print("[select_piece] No piece found at: ", x, ", ", y)
			return
		var piece = board_state[y][x]
		# Use is_white property if available, else fallback to name
		var is_white_piece = "is_white" in piece and piece.is_white or piece.name.begins_with("White")
		print("[select_piece] Piece at (", x, ",", y, "): ", piece.name, " is_white_piece: ", is_white_piece, " TurnManager.is_white_turn: ", TurnManager.is_white_turn)
		# Only allow selecting enemy pieces
		if (is_white_piece == TurnManager.is_white_turn):
			print("[select_piece] You can only select enemy pieces for attack during the attack phase!")
			return
		print("[select_piece] Enemy piece selected for attack phase: ", piece.name)
		# --- Perform attack instead of just selecting ---
		var attacker = selected_piece
		var attacker_pos = selected_piece_position
		var target_pos = Vector2(x, y)
		# Try melee attack first
		var melee_tiles = MoveUtils.get_melee_attack_tiles(attacker, attacker_pos.x, attacker_pos.y)
		if target_pos in melee_tiles:
			print("[select_piece] Performing melee attack!")
			MoveUtils.perform_melee_attack(attacker, target_pos)
			deselect_piece()
			return
		# Try ranged attack
		var ranged_tiles = MoveUtils.get_range_attack_tiles(attacker, attacker_pos.x, attacker_pos.y)
		if target_pos in ranged_tiles:
			print("[select_piece] Performing ranged attack!")
			MoveUtils.perform_range_attack(attacker, target_pos)
			deselect_piece()
			return
		print("[select_piece] Selected enemy is not in attack range.")

	if selecting_ok == true:
		print("[select_piece] selecting_ok is TRUE")
		if not can_select_piece:
			print("[select_piece] Waiting for board update from host.")
			return
		if not is_within_board(x, y) or not is_tile_occupied(x, y):
			print("[select_piece] No piece found at: ", x, ", ", y)
			return
		var piece = board_state[y][x]
		# Use is_white property if available, else fallback to name
		var is_white_piece = "is_white" in piece and piece.is_white or piece.name.begins_with("White")
		print("[select_piece] Piece at (", x, ",", y, "): ", piece.name, " is_white_piece: ", is_white_piece, " TurnManager.is_white_turn: ", TurnManager.is_white_turn)
		# --- Prevent selecting piece if it reached its move limit ---
		if piece.has_method("can_move_this_turn") and not piece.can_move_this_turn():
			print("[select_piece] This piece has reached its move limit for this turn.")
			return
		if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
			if is_white_piece == Rules.player_is_white and NetworkManager.can_local_player_move():
				print("[select_piece] Local player can move and selected their own piece.")
				selected_piece = piece
				selected_piece_position = Vector2(x, y)
				Player.on_piece_selected(x, y)
				highlight_piece_moves_and_attacks(piece, x, y)
			else:
				print("[select_piece] Cannot select opponent's piece or not your turn.")
		else:
			if is_white_piece == TurnManager.is_white_turn and NetworkManager.can_local_player_move():
				print("[select_piece] Local player can move and selected their own piece.")
				selected_piece = piece
				selected_piece_position = Vector2(x, y)
				Player.on_piece_selected(x, y)
				highlight_piece_moves_and_attacks(piece, x, y)
			else:
				print("[select_piece] Cannot select piece: Not your turn or not your piece.")

func highlight_piece_moves_and_attacks(piece, x: int, y: int):
	MoveManager.clear_move_highlights() # Only clear once at the start!
	var move_tiles = []
	if piece.has_method("get_moves"):
		move_tiles = piece.get_moves(x, y)
		MoveManager.highlight_possible_moves(move_tiles)
	# --- Highlight melee attack tiles ---
	var melee_tiles = MoveUtils.get_melee_attack_tiles(piece, x, y)
	if melee_tiles.size() > 0:
		MoveUtils.highlight_melee_attack_tiles(melee_tiles)
	# --- Highlight ranged attack tiles ---
	if "get_attack_range" in piece:
		var attack_tiles = piece.get_attack_range(x, y)
		var unique_attack_tiles = []
		for tile in attack_tiles:
			if tile not in move_tiles:
				unique_attack_tiles.append(tile)
		if unique_attack_tiles.size() > 0:
			MoveUtils.highlight_range_attack_tiles(unique_attack_tiles)

func deselect_piece():
	BoardManager.selected_piece = null
	BoardManager.selected_piece_position = null
	MoveManager.clear_move_highlights()

#endregion

#region tile_occupience

func is_tile_occupied(x: int, y: int) -> bool:
	if not is_within_board(x, y):
		return false
	return board_state[y][x] != null

func is_tile_occupied_by_opponent(x: int, y: int, is_white_piece: bool) -> bool:
	if not is_within_board(x, y):
		return false
	if not is_tile_occupied(x, y):
		return false
	var piece = BoardManager.board_state[y][x]
	return (is_white_piece and piece.name.begins_with("Black")) or (not is_white_piece and piece.name.begins_with("White"))

func is_tile_obstacle(x: int, y: int) -> bool:
	if not is_within_board(x, y):
		return false
	var obj = board_state[y][x]
	return obj != null and obj is Node2D and obj.get_script() == preload("res://Scenes/maps/map_elements/obstacles.gd")
#endregion

func remove_all_pieces():
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			var piece = board_state[y][x]
			if piece != null:
				piece.queue_free()
			board_state[y][x] = null

func clear_custom_highlights():
	for highlight in custom_highlights:
		if is_instance_valid(highlight):
			highlight.queue_free()
	custom_highlights.clear()

func highlight_tiles_custom(tiles: Array, color: Color):
	# Do NOT clear previous highlights here!
	for tile in tiles:
		var highlight = ColorRect.new()
		highlight.color = color
		highlight.size = Vector2(TILE_SIZE, TILE_SIZE)
		highlight.position = Vector2(tile.x * TILE_SIZE, -tile.y * TILE_SIZE)
		highlight.z_index = 99  # Ensure it's above the board but below pieces
		add_child(highlight)
		custom_highlights.append(highlight)

func clear_custom_highlights_color(target_color: Color):
	for child in get_children():
		if child is ColorRect and child.color == target_color:
			child.queue_free()

func delete_all_tiles():
	# Removes all ColorRect tiles from the board
	for child in get_children():
		if child is ColorRect:
			child.queue_free()

func is_tile_occupied_by_friendly(x: int, y: int, is_white_piece: bool) -> bool:
	if not is_within_board(x, y):
		return false
	if not is_tile_occupied(x, y):
		return false
	var piece = board_state[y][x]
	return (is_white_piece and piece.name.begins_with("White")) or (not is_white_piece and piece.name.begins_with("Black"))
