extends Node2D

const OBSTACLE_SCENE = preload("res://Scenes/maps/map_elements/obstacles.tscn")
const PIXEL_OPERATOR_8 = preload("res://Assets/font/PixelOperator8.ttf")
const MapSaveManager = preload("res://Scenes/Managers/map_save_manager.gd")

@onready var black_bishop: Sprite2D = $black_bishop
@onready var black_king: Sprite2D = $black_king
@onready var black_knight: Sprite2D = $black_knight
@onready var black_pawn: Sprite2D = $black_pawn
@onready var black_queen: Sprite2D = $black_queen
@onready var black_rook: Sprite2D = $black_rook
@onready var white_bishop: Sprite2D = $white_bishop
@onready var white_king: Sprite2D = $white_king
@onready var white_knight: Sprite2D = $white_knight
@onready var white_pawn: Sprite2D = $white_pawn
@onready var white_queen: Sprite2D = $white_queen
@onready var white_rook: Sprite2D = $white_rook
@onready var custom_piece: Sprite2D = $custom_piece


@onready var right_menu: VBoxContainer = $CanvasLayer2/RightMenu
@onready var info_button: Button = $CanvasLayer2/RightMenu/InfoButton
@onready var promote_button: Button = $CanvasLayer2/RightMenu/PromoteButton
@onready var abilities_button: Button = $CanvasLayer2/RightMenu/AbilitiesButton


@export var camera_speed := 450.0 # Pixels per second

# --- END CONDITION CONFIGURATION ---
# Set these to enable/disable win/draw conditions for this map
@export var END_CHECKMATE_ENABLED := false # Enable/disable checkmate win
@export var END_CAPTURE_ENABLED := false   # Enable/disable capture win
@export var END_FIFTY_MOVE_RULE_ENABLED := false # Enable/disable fifty-move rule draw

# --- MAP CONFIGURATION ---
@export var MAP_BOARD_WIDTH := 10
@export var MAP_BOARD_HEIGHT := 8
@export var CAMERA_CENTER_TILE := Vector2(5, 3)
@export var MAP_LIGHT_COLOR := Color(0.4, 0.3, 0.2)
@export var MAP_DARK_COLOR := Color(0.3, 0.2, 0.1)
@export var STARTING_VALUE := 15
@export var MAX_MOVES_PER_TURN := 1
@export var MOVES_PER_TURN_MODE := "piece_count"
@export var ALLOWED_INVENTORY_TILES := [
	Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0)
]
@export var STARTING_PIECES := [
	{ "name": "custom_piece", "pos": Vector2(0, 0) },
	{ "name": "black_king", "pos": Vector2(9, 7) },
	{ "name": "black_rook", "pos": Vector2(8, 7) }
]

const PIECE_VALUES = {
	"WhitePawn": 1, "WhiteKnight": 3, "WhiteBishop": 4, "WhiteRook": 5, "WhiteQueen": 9, "WhiteKing": 2,
	"BlackPawn": 1, "BlackKnight": 3, "BlackBishop": 4, "BlackRook": 5, "BlackQueen": 9, "BlackKing": 2
}
@export var STARTING_INVENTORY = {
	"WhitePawn": 0, "WhiteKing": 0, "WhiteKnight": 0, "WhiteBishop": 0, "WhiteRook": 0, "WhiteQueen": 0
}
# --- END MAP CONFIGURATION ---

var First_Rank = 0
var Last_Rank = MAP_BOARD_HEIGHT - 1
var First_File = 0
var Last_File = MAP_BOARD_WIDTH - 1

var default_camera_zoom := Vector2(0.8, 0.8)
var file_labels := []
var rank_labels := []

var shopping = true
var current_value := STARTING_VALUE
var iwpawn_count = 0
var iwking_count = 0
var iwknight_count = 0
var iwbishop_count = 0
var iwrook_count = 0
var iwqueen_count = 0
var inventory_locked := false
var selected_inventory_piece = null
var allowed_inventory_tiles = ALLOWED_INVENTORY_TILES
var last_selected_piece = Vector2(-1, -1)

# Track if the Start button has ever been pressed in this map
var start_pressed_once := false

var input_enabled := false

var board_state = [] # Per-map board state

var selected_piece = null
var selected_piece_pos = Vector2(-1, -1)

# Track if the Start button has ever been pressed in this map
var game_started := false

var can_place_inventory_piece := true

func get_shared_map_ui():
	return get_tree().get_root().find_child("MapUi", true, false)

func update_value_label():
	# Always fetch the authoritative value from MapUi if available
	var shared_map_ui = get_shared_map_ui()
	if shared_map_ui:
		# Always call set_value_label with the authoritative value
		if "current_value" in shared_map_ui:
			shared_map_ui.set_value_label(shared_map_ui.current_value)
		else:
			shared_map_ui.set_value_label(current_value)
	# If no MapUi, do nothing (silent fail)

func update_inventory_labels():
	var shared_map_ui = get_shared_map_ui()
	if shared_map_ui:
		shared_map_ui.iwpawn.text = str(iwpawn_count)
		shared_map_ui.iwking.text = str(iwking_count)
		shared_map_ui.iwknight.text = str(iwknight_count)
		shared_map_ui.iwbishop.text = str(iwbishop_count)
		shared_map_ui.iwrook.text = str(iwrook_count)
		shared_map_ui.iwqueen.text = str(iwqueen_count)

func track_moves_left_label():
	var shared_map_ui = get_shared_map_ui()
	if shared_map_ui:
		shared_map_ui.track_moves_left_label()

func _ready():
	GameManager.current_map = self
	TurnManager.initialize()
	BoardManager.set_board_size(MAP_BOARD_WIDTH, MAP_BOARD_HEIGHT)
	BoardManager.set_tile_colors(MAP_LIGHT_COLOR, MAP_DARK_COLOR)
	BoardManager.initialize()
	TurnManager.is_white_turn = true
	default_camera_zoom = $Camera2D.zoom
	BoardManager.clear_custom_highlights()
	draw_board_numbers()

func place_starting_pieces():
	# Ensure board_state is the correct size
	if BoardManager.board_state.size() != MAP_BOARD_HEIGHT or BoardManager.board_state.any(func(row): return row.size() != MAP_BOARD_WIDTH):
		BoardManager.board_state.clear()
		for y in range(MAP_BOARD_HEIGHT):
			var row = []
			for x in range(MAP_BOARD_WIDTH):
				row.append(null)
			BoardManager.board_state.append(row)

	# Always set the intended positions for each piece node by name
	var positions = {
		"custom_piece": Vector2(0, 0),
		"black_king": Vector2(9, 7),
		"black_rook": Vector2(8, 7)
	}
	for piece_name in positions.keys():
		if has_node(piece_name):
			var piece = get_node(piece_name)
			var pos = positions[piece_name]
			piece.position = BoardManager.get_centered_position(pos.x, pos.y)
			piece.visible = true
			# Set board_state reference
			if BoardManager.board_state.size() > int(pos.y) and BoardManager.board_state[int(pos.y)].size() > int(pos.x):
				BoardManager.board_state[int(pos.y)][int(pos.x)] = piece

	# Optionally, hide any other piece nodes not in the list
	for child in get_children():
		if child is Node2D and child.name in ["custom_piece", "black_king", "black_rook"]:
			continue
		if child.has_method("set_visible"):
			child.visible = false

func place_obstacle(x: int, y: int):
	var obstacle = OBSTACLE_SCENE.instantiate()
	obstacle.position = BoardManager.get_centered_position(x, y)
	BoardManager.add_child(obstacle)
	board_state[y][x] = obstacle # Mark the tile as occupied by an obstacle

func draw_board_numbers():
	for label in file_labels + rank_labels:
		if is_instance_valid(label):
			label.queue_free()
	file_labels.clear()
	rank_labels.clear()
	var board_width = BoardManager.BOARD_WIDTH
	var board_height = BoardManager.BOARD_HEIGHT
	var tile_size = BoardManager.TILE_SIZE
	for x in range(board_width):
		var label = Label.new()
		label.text = char(65 + x)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP # Fixed constant name
		label.add_theme_font_override("font", PIXEL_OPERATOR_8)
		label.position = Vector2(
			x * tile_size + tile_size / 2.5,
			board_height + tile_size
		)
		label.z_index = 100 # Ensure label is above board tiles
		add_child(label)
		file_labels.append(label)
	for y in range(board_height):
		var label = Label.new()
		label.text = str(y + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", PIXEL_OPERATOR_8)
		label.position = Vector2(-tile_size * 0.5, -y * tile_size + tile_size / 2.5)
		label.z_index = 100 # Ensure label is above board tiles
		add_child(label)
		rank_labels.append(label)

func _process(delta):
	var camera = $Camera2D
	var move = Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("d"):
		move.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("a"):
		move.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("s"):
		move.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("w"):
		move.y -= 1
	if move != Vector2.ZERO:
		camera.position += move.normalized() * camera_speed * delta
	if Input.is_action_just_pressed("ui_select"):
		camera.position = BoardManager.get_centered_position(int(CAMERA_CENTER_TILE.x), int(CAMERA_CENTER_TILE.y))
	if TurnManager.post_move_attack_pending:
		right_menu.visible = true
	track_moves_left_label()
	update_value_label()

func _input(event):
	if not input_enabled:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			$Camera2D.zoom *= 1.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			$Camera2D.zoom *= 0.9
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			$Camera2D.zoom = default_camera_zoom
		elif event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_handle_board_click(event)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_handle_board_right_click(event)

func _handle_board_click(_event):
	# Use unique variable names to avoid redeclaration
	var _mouse_pos = get_global_mouse_position()
	var _grid_coordinates = BoardManager.get_grid_coordinates(_mouse_pos)
	var _x = _grid_coordinates.x
	var _y = _grid_coordinates.y
	if not BoardManager.is_within_board(_x, _y):
		return

	# ...existing code for normal piece selection/movement...
	var mouse_pos = get_global_mouse_position()
	var grid_coordinates = BoardManager.get_grid_coordinates(mouse_pos)
	var x = grid_coordinates.x
	var y = grid_coordinates.y
	if not BoardManager.is_within_board(x, y):
		return

	# Prevent piece selection before the game starts
	if !start_pressed_once:
		# Only allow inventory/shop placement/removal before game starts
		if inventory_locked and selected_inventory_piece != null:
			if Vector2(x, y) in allowed_inventory_tiles and not BoardManager.is_tile_occupied(x, y):
				# Place inventory piece
				place_inventory_piece(selected_inventory_piece, x, y)
				selected_inventory_piece = null
				return
		if inventory_locked and BoardManager.is_tile_occupied(x, y):
			var piece = BoardManager.board_state[y][x]
			var piece_name = piece.name
			# Only allow removal if the piece is a white inventory type and the game hasn't started
			if not start_pressed_once:
				var map_ui = get_shared_map_ui()
				if map_ui:
					map_ui.increment_inventory_and_refund_value(piece_name)
				# Remove the piece from the board and hide it (do not queue_free, just hide for reuse)
				piece.visible = false
				BoardManager.board_state[y][x] = null
				return
		return # Prevent any piece selection or movement before game starts

	# If a piece is already selected, always try to move or attack
	if BoardManager.selected_piece:
		_handle_move_or_attack(x, y)
		return

	# If no piece is selected, try to select a piece at the clicked tile, but only if it's your turn and the piece color matches
	if y >= 0 and y < BoardManager.board_state.size() and typeof(BoardManager.board_state[y]) == TYPE_ARRAY and x >= 0 and x < BoardManager.board_state[y].size() and BoardManager.board_state[y][x]:
		var piece = BoardManager.board_state[y][x]
		# Only allow selection if it's your turn and the piece color matches
		if (TurnManager.is_white_turn and piece.is_white) or (not TurnManager.is_white_turn and not piece.is_white):
			BoardManager.selected_piece = piece
			BoardManager.selected_piece_position = Vector2(x, y)
			BoardManager.highlight_piece_moves_and_attacks(piece, x, y)

func _handle_board_right_click(_event):
	track_piece_info()
	var mouse_pos = get_global_mouse_position()
	var grid_coordinates = BoardManager.get_grid_coordinates(mouse_pos)
	var x = grid_coordinates.x
	var y = grid_coordinates.y
	if shopping == true:
		return
	if not BoardManager.is_within_board(x, y):
		right_menu.visible = false
		return
	right_menu.visible = true
	info_button.visible = true
	if BoardManager.board_state[y][x]:
		var piece = BoardManager.board_state[y][x]
		# Use is_white property if available, else fallback to name
		var is_white_piece = "is_white" in piece and piece.is_white or piece.name.begins_with("White")
		var owned = false
		if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
			owned = is_white_piece == Rules.player_is_white and NetworkManager.can_local_player_move()
		else:
			owned = is_white_piece == is_white_piece == TurnManager.is_white_turn and NetworkManager.can_local_player_move()
		promote_button.visible = owned
		abilities_button.visible = owned
		last_selected_piece = BoardManager.get_grid_coordinates(mouse_pos)
	else:
		promote_button.visible = false
		abilities_button.visible = false

func _handle_friendly_piece_selection(x, y) -> bool:
	if BoardManager.is_tile_occupied(x, y):
		var piece = BoardManager.board_state[y][x]
		# Use is_white property if available, else fallback to name
		var is_white_piece = "is_white" in piece and piece.is_white or piece.name.begins_with("White")
		if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
			if is_white_piece == Rules.player_is_white and NetworkManager.can_local_player_move():
				BoardManager.select_piece(x, y)
				return true
		else:
			if is_white_piece == TurnManager.is_white_turn and NetworkManager.can_local_player_move():
				BoardManager.select_piece(x, y)
				return true
	return false

func _handle_move_or_attack(x, y):
	if BoardManager.selected_piece == null:
		return
	var move_tiles = []
	if BoardManager.selected_piece.has_method("get_moves"):
		move_tiles = BoardManager.selected_piece.get_moves(BoardManager.selected_piece_position.x, BoardManager.selected_piece_position.y)
	var attack_tiles = []
	var unique_attack_tiles = []
	if "get_attack_range" in BoardManager.selected_piece:
		attack_tiles = BoardManager.selected_piece.get_attack_range(BoardManager.selected_piece_position.x, BoardManager.selected_piece_position.y)
		for tile in attack_tiles:
			if tile not in move_tiles:
				unique_attack_tiles.append(tile)
	if Vector2(x, y) in move_tiles:
		MoveManager.move_selected_piece(x, y)
	elif Vector2(x, y) in unique_attack_tiles:
		_handle_range_attack(x, y)
	else:
		BoardManager.deselect_piece()

func _handle_range_attack(x, y):
	if BoardManager.is_tile_occupied(x, y):
		var target_piece = BoardManager.board_state[y][x]
		if target_piece.is_white != BoardManager.selected_piece.is_white:
			MoveUtils.perform_range_attack(BoardManager.selected_piece, Vector2(x, y))
			TurnManager.moves_this_turn += 1
			TurnManager.check_turn_end()
			BoardManager.deselect_piece()
	else:
		BoardManager.deselect_piece()

func _on_info_button_pressed():
	right_menu.visible = false
	$MapInfo/CanvasLayer.visible = true

func _on_promote_button_pressed():
	right_menu.visible = false
	$PromotionUi.piece_promotion.visible = true
	BoardManager.selecting_ok = false

func _on_abilities_button_pressed() -> void:
	$AbilitiesUi/CanvasLayer/AbilitiesContainer.visible = true
	right_menu.visible = false
	BoardManager.selecting_ok = false

func place_white_piece_at(piece_name: String, x: int, y: int):
	UnitManager.place_piece_by_name(piece_name, x, y)
	var piece = BoardManager.board_state[y][x]
	if piece:
		piece.set_meta("from_inventory", true)

func promote_to(piece_name: String) -> void:
	var piece_values = {
		"WhitePawn": 1,
		"WhiteKnight": 3,
		"WhiteBishop": 4,
		"WhiteRook": 5,
		"WhiteQueen": 9,
		"WhiteKing": 2
	}
	if last_selected_piece == Vector2(-1, -1):
		$PromotionUi.piece_promotion.visible = false
		return
	if not piece_values.has(piece_name):
		$PromotionUi.piece_promotion.visible = false
		return
	var cost = piece_values[piece_name]
	if current_value < cost:
		$PromotionUi.piece_promotion.visible = false
		return
	var x = int(last_selected_piece.x)
	var y = int(last_selected_piece.y)
	var old_piece = BoardManager.board_state[y][x]
	if old_piece:
		if old_piece.name.begins_with("WhiteKing") or old_piece.name.begins_with("BlackKing"):
			$PromotionUi.piece_promotion.visible = false
			return
		current_value -= cost
		update_value_label()
		old_piece.queue_free()
		BoardManager.board_state[y][x] = null
		var new_piece = UnitManager.place_piece_by_name(piece_name, x, y)
		if new_piece == null:
			new_piece = BoardManager.board_state[y][x]
		else:
			BoardManager.board_state[y][x] = new_piece
		BoardManager.deselect_piece()
		$PromotionUi.piece_promotion.visible = false
		last_selected_piece = Vector2(-1, -1)

func get_piece_value(piece_name: String) -> int:
	var piece_values = {
		"WhitePawn": 1,
		"WhiteKnight": 3,
		"WhiteBishop": 4,
		"WhiteRook": 5,
		"WhiteQueen": 9,
		"WhiteKing": 2,
		"BlackPawn": 1,
		"BlackKnight": 3,
		"BlackBishop": 4,
		"BlackRook": 5,
		"BlackQueen": 9,
		"BlackKing": 2
	}
	for key in piece_values.keys():
		if piece_name.begins_with(key):
			return piece_values[key]
	return 0

func _on_do_nothing_pressed() -> void:
	if BoardManager.selected_piece != null and BoardManager.selected_piece.has_method("can_move_this_turn"):
		var pos = BoardManager.selected_piece_position
		var x = int(pos.x)
		var y = int(pos.y)
		if BoardManager.board_state[y][x] != null and BoardManager.board_state[y][x].has_method("can_move_this_turn"):
			if BoardManager.board_state[y][x].moves_made_this_turn == 0:
				BoardManager.board_state[y][x].moves_made_this_turn = MAX_MOVES_PER_TURN
				MoveManager.enable_post_move_attack(BoardManager.board_state[y][x], BoardManager.selected_piece_position)
				TurnManager.post_move_attack_pending = true
				return
	TurnManager.post_move_attack_pending = false
	TurnManager.check_turn_end()
	MoveManager.clear_move_highlights()
	right_menu.visible = false

func save_map_1():
	# Save the current map state using the MapSaveManager
	MapSaveManager.save_map(self, board_state, "user://map_1_save.sav", "map_1")

func load_map_1():
	# Load the map state using the MapSaveManager
	MapSaveManager.load_map(self, board_state, "user://map_1_save.sav", "map_1")
	# If the board is empty after loading, place starting pieces
	var is_empty = true
	for y in range(MAP_BOARD_HEIGHT):
		for x in range(MAP_BOARD_WIDTH):
			if BoardManager.board_state[y][x] != null:
				is_empty = false
				break
		if not is_empty:
			break
	if is_empty:
		place_starting_pieces()
	# Update UI after loading
	if has_node("MapUi"):
		get_node("MapUi").set_value_label(current_value)
		get_node("MapUi").update_turn_label(TurnManager.is_white_turn)
	track_piece_info()

func track_piece_info():
	for y in range(BoardManager.board_state.size()):
		for x in range(BoardManager.board_state[y].size()):
			var piece = BoardManager.board_state[y][x]
			if piece:
				# Debug print removed
				pass

# This can be placed in map_1.gd, map_ui.gd, or a global manager


func on_tab_selected():
	board_state = []
	for y in range(MAP_BOARD_HEIGHT):
		var row = []
		for x in range(MAP_BOARD_WIDTH):
			row.append(null)
		board_state.append(row)
	# 1. Clear board_state
	for y in range(MAP_BOARD_HEIGHT):
		for x in range(MAP_BOARD_WIDTH):
			board_state[y][x] = null

	# 2. Assign each visible, valid piece node to its current board position
	for child in get_children():
		if child is Sprite2D and child.has_method("get_moves") and child.visible:
			# Convert the piece's position to board coordinates
			var grid_pos = BoardManager.get_grid_coordinates(child.position)
			var x = int(grid_pos.x)
			var y = int(grid_pos.y)
			if x >= 0 and x < MAP_BOARD_WIDTH and y >= 0 and y < MAP_BOARD_HEIGHT:
				if board_state[y][x] != null:
					# Debug print removed
					pass
				board_state[y][x] = child
				# Debug print removed

	# Debug print removed

	# Redraw board numbers if needed
	if has_method("draw_board_numbers"):
		draw_board_numbers()
	# Optionally update UI
	var map_ui = get_shared_map_ui()
	if map_ui:
		map_ui.set_value_label(current_value)
	# --- FIX: Sync BoardManager.board_state to this board_state ---
	BoardManager.board_state = board_state
	# Always update max moves per turn after board state is rebuilt
	TurnManager.update_max_moves_per_turn()
	var camera = $Camera2D
	camera.position = BoardManager.get_centered_position(int(CAMERA_CENTER_TILE.x), int(CAMERA_CENTER_TILE.y))
	# Only place starting pieces if the start button hasn't been pressed before
	if not start_pressed_once:
		place_starting_pieces()
		BoardManager.highlight_tiles_custom([Vector2(Last_File, Last_Rank)], Color(1, 0, 0, 0.5))
		BoardManager.highlight_tiles_custom([Vector2(First_File, First_Rank), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0)], Color(0, 0, 1, 0.5))
	track_piece_info()
	input_enabled = true


# Helper to place an inventory piece on the board
func place_inventory_piece(piece_type: String, x: int, y: int):
	# Make the corresponding piece node visible and move it to the correct spot
	var piece_node = null
	match piece_type:
		"WhitePawn":
			piece_node = $white_pawn
		"WhiteKnight":
			piece_node = $white_knight
		"WhiteBishop":
			piece_node = $white_bishop
		"WhiteRook":
			piece_node = $white_rook
		"WhiteQueen":
			piece_node = $white_queen
		"WhiteKing":
			piece_node = $white_king
		"custom_piece":
			piece_node = $custom_piece
		_:
			return # Unknown piece type
	if piece_node:
		# Set the color property for black/white pieces
		if piece_type.begins_with("White"):
			piece_node.is_white = true
		elif piece_type.begins_with("Black"):
			piece_node.is_white = false
		piece_node.visible = true
		piece_node.position = BoardManager.get_centered_position(x, y)
		BoardManager.board_state[y][x] = piece_node
		# Update inventory counts and value via MapUi
		var map_ui = get_shared_map_ui()
		if map_ui:
			map_ui.decrement_inventory_and_spend_value(piece_type)
		# Reset the mouse cursor to normal after placing a piece
		Input.set_custom_mouse_cursor(null)
