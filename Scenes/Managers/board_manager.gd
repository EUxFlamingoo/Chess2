extends Node2D

const TILE_SIZE = 64  # Modify
const adjust_height = TILE_SIZE / 1.01  # Modify

var BOARD_WIDTH := 1
var BOARD_HEIGHT := 1

var First_Rank = 0  # Modify with caution
var Last_Rank = BOARD_HEIGHT - 1 # Modify with caution
var First_File = 0  # Modify with caution
var Last_File = BOARD_WIDTH - 1  # Modify with caution

var LIGHT_COLOR := Color(0.4, 0.3, 0.2)
var DARK_COLOR := Color(0.3, 0.2, 0.1)

#region var

var board_state = []
var selected_piece = null
var selected_piece_position = null
var can_select_piece := true

#endregion

#region create/initialize_board

func initialize():
	board_state = []
	for y in range(BOARD_HEIGHT):  # Use BOARD_HEIGHT for the number of rows
		var row = []
		for x in range(BOARD_WIDTH):  # Use BOARD_WIDTH for the number of columns
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
					# If clicking on a friendly piece, select it instead of moving
					if is_tile_occupied(x, y):
						var piece = board_state[y][x]
						var is_white_piece = piece.name.begins_with("White")
						if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
							if is_white_piece == Rules.player_is_white and NetworkManager.can_local_player_move():
								select_piece(x, y)
								return
						else:
							if is_white_piece == TurnManager.is_white_turn and NetworkManager.can_local_player_move():
								select_piece(x, y)
								return
					# --- Gather move and attack tiles ---
					var move_tiles = []
					if selected_piece.has_method("get_moves"):
						move_tiles = selected_piece.get_moves(selected_piece_position.x, selected_piece_position.y)
					var attack_tiles = []
					var unique_attack_tiles = []
					if "get_attack_range" in selected_piece:
						attack_tiles = selected_piece.get_attack_range(selected_piece_position.x, selected_piece_position.y)
						for tile in attack_tiles:
							if tile not in move_tiles:
								unique_attack_tiles.append(tile)

					# --- Check if clicked tile is a valid move or attack ---
					if Vector2(x, y) in move_tiles:
						MoveManager.move_selected_piece(x, y)
					elif Vector2(x, y) in unique_attack_tiles:
						if is_tile_occupied(x, y):
							var target_piece = board_state[y][x]
							if target_piece.is_white != selected_piece.is_white:
								MoveUtils.perform_range_attack(selected_piece, Vector2(x, y))
								TurnManager.moves_this_turn += 1
								TurnManager.check_turn_end()
								deselect_piece()
							else:
								print("Invalid move: Cannot attack your own piece.")
						else:
							print("Missed attack: No piece to capture.")
							deselect_piece()
					else:
						print("Invalid move")
						deselect_piece()

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
	if not can_select_piece:
		print("Waiting for board update from host.")
		return
	if not is_within_board(x, y) or not is_tile_occupied(x, y):
		print("No piece found at: ", x, ", ", y)
		return
	var piece = board_state[y][x]
	var is_white_piece = piece.name.begins_with("White")
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		if is_white_piece == Rules.player_is_white and NetworkManager.can_local_player_move():
			selected_piece = piece
			selected_piece_position = Vector2(x, y)
			Player.on_piece_selected(x, y)
			highlight_piece_moves_and_attacks(piece, x, y)
		else:
			print("Cannot select opponent's piece or not your turn.")
	else:
		if is_white_piece == TurnManager.is_white_turn and NetworkManager.can_local_player_move():
			selected_piece = piece
			selected_piece_position = Vector2(x, y)
			Player.on_piece_selected(x, y)
			highlight_piece_moves_and_attacks(piece, x, y)
		else:
			print("Cannot select piece: Not your turn or not your piece.")

func highlight_piece_moves_and_attacks(piece, x: int, y: int):
	MoveManager.clear_move_highlights() # Only clear once at the start!
	var move_tiles = []
	if piece.has_method("get_moves"):
		move_tiles = piece.get_moves(x, y)
		MoveManager.highlight_possible_moves(move_tiles)
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
