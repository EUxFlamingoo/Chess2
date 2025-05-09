extends Node2D

const OBSTACLE_SCENE = preload("res://Scenes/maps/map_elements/obstacles.tscn")
const PIXEL_OPERATOR_8 = preload("res://Assets/font/PixelOperator8.ttf")
const MapSaveManager = preload("res://Scenes/Managers/map_save_manager.gd")



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
	{ "name": "BuildingFactory", "pos": Vector2(0, 0) },
]
const PIECE_VALUES = {
	"WhitePawn": 1, "WhiteKnight": 3, "WhiteBishop": 4, "WhiteRook": 5, "WhiteQueen": 9, "WhiteKing": 2,
	"BlackPawn": 1, "BlackKnight": 3, "BlackBishop": 4, "BlackRook": 5, "BlackQueen": 9, "BlackKing": 2
}
@export var STARTING_INVENTORY = {
	"WhitePawn": 0, "WhiteKing": 0, "WhiteKnight": 0, "WhiteBishop": 0, "WhiteRook": 0, "WhiteQueen": 0
}
# --- END MAP CONFIGURATION ---

var board_state = [] # Per-map board state

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

var input_enabled := false
var in_home_1 = true

func _ready():
	GameManager.current_map = self
	TurnManager.initialize()
	# Initialize per-map board state
	board_state.clear()
	for y in range(MAP_BOARD_HEIGHT):
		var row = []
		for x in range(MAP_BOARD_WIDTH):
			row.append(null)
		board_state.append(row)
	BoardManager.set_board_size(MAP_BOARD_WIDTH, MAP_BOARD_HEIGHT)
	BoardManager.set_tile_colors(MAP_LIGHT_COLOR, MAP_DARK_COLOR)
	BoardManager.initialize() # Still needed for visuals/utility
	TurnManager.is_white_turn = true
	default_camera_zoom = $Camera2D.zoom
	BoardManager.clear_custom_highlights()
	place_starting_pieces()
	var camera = $Camera2D
	camera.position = BoardManager.get_centered_position(int(CAMERA_CENTER_TILE.x), int(CAMERA_CENTER_TILE.y))
	draw_board_numbers()
	update_value_label()
	TurnManager.update_max_moves_per_turn()
	track_piece_info()

func place_starting_pieces():
	# Only set the position of already-instanced piece nodes in the scene (children of the map node)
	for child in get_children():
		# Only operate on nodes that actually have the 'is_white' property
		if child is Node2D and child.has_method("get") and "is_white" in child:
			for piece_info in STARTING_PIECES:
				# Debug: print the child and piece_info names
				print("[Map1] Checking child:", child.name, "against", piece_info["name"])
				if piece_info["name"] == child.name:
					var pos = piece_info["pos"]
					child.position = BoardManager.get_centered_position(pos.x, pos.y)
					board_state[pos.y][pos.x] = child
					break
	# Debug: print all STARTING_PIECES
	print("[Map1] STARTING_PIECES:", STARTING_PIECES)

func place_obstacle(x: int, y: int):
	var obstacle = OBSTACLE_SCENE.instantiate()
	obstacle.position = BoardManager.get_centered_position(x, y)
	BoardManager.add_child(obstacle)
	board_state[y][x] = obstacle

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
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.add_theme_font_override("font", PIXEL_OPERATOR_8)
		label.position = Vector2(
			x * tile_size + tile_size / 2.5,
			board_height + tile_size
		)
		add_child(label)
		file_labels.append(label)
	for y in range(board_height):
		var label = Label.new()
		label.text = str(y + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", PIXEL_OPERATOR_8)
		label.position = Vector2(-tile_size * 0.5, -y * tile_size + tile_size / 2.5)
		add_child(label)
		rank_labels.append(label)

func _process(delta):
	var camera = $Camera2D
	var move = Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("d") && in_home_1 == true:
		move.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("a") && in_home_1 == true:
		move.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("s") && in_home_1 == true:
		move.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("w") && in_home_1 == true:
		move.y -= 1
	if move != Vector2.ZERO:
		camera.position += move.normalized() * camera_speed * delta
	if Input.is_action_just_pressed("ui_select") && in_home_1 == true:
		camera.position = BoardManager.get_centered_position(int(CAMERA_CENTER_TILE.x), int(CAMERA_CENTER_TILE.y))
	var shared_map_ui = get_shared_map_ui()
	if shared_map_ui:
		shared_map_ui.set_value_label(current_value)
	if TurnManager.post_move_attack_pending:
		right_menu.visible = true
	track_moves_left_label()

func _input(event):
	if in_home_1 == false:
		return
	if not input_enabled:
		return
	if event is InputEventMouseButton && in_home_1 == true:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			$Camera2D.zoom *= 1.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed && in_home_1 == true:
			$Camera2D.zoom *= 0.9
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed && in_home_1 == true:
			$Camera2D.zoom = default_camera_zoom
		elif event.pressed && in_home_1 == true:
			if event.button_index == MOUSE_BUTTON_LEFT && in_home_1 == true:
				_handle_board_click(event)
			elif event.button_index == MOUSE_BUTTON_RIGHT && in_home_1 == true:
				_handle_board_right_click(event)

func _handle_board_click(_event):
	var mouse_pos = get_global_mouse_position()
	var grid_coordinates = BoardManager.get_grid_coordinates(mouse_pos)
	var x = grid_coordinates.x
	var y = grid_coordinates.y
	if not BoardManager.is_within_board(x, y):
		return
	if inventory_locked and board_state[y][x] && in_home_1 == true:
		var piece = board_state[y][x]
		if piece.has_meta("from_inventory") and piece.get_meta("from_inventory") == true && in_home_1 == true:
			var piece_name = piece.name
			piece.queue_free()
			board_state[y][x] = null
			if piece_name.begins_with("WhitePawn"):
				iwpawn_count += 1
			elif piece_name.begins_with("WhiteKing"):
				iwking_count += 1
			elif piece_name.begins_with("WhiteKnight"):
				iwknight_count += 1
			elif piece_name.begins_with("WhiteBishop"):
				iwbishop_count += 1
			elif piece_name.begins_with("WhiteRook"):
				iwrook_count += 1
			elif piece_name.begins_with("WhiteQueen"):
				iwqueen_count += 1
			update_inventory_labels()
			return
	right_menu.visible = false
	if inventory_locked and selected_inventory_piece == null && in_home_1 == true:
		return
	if selected_inventory_piece != null and not board_state[y][x] && in_home_1 == true:
		if Vector2(x, y) in allowed_inventory_tiles:
			place_white_piece_at(selected_inventory_piece, x, y)
			match selected_inventory_piece:
				"WhitePawn":
					iwpawn_count -= 1
				"WhiteKing":
					iwking_count -= 1
				"WhiteKnight":
					iwknight_count -= 1
				"WhiteBishop":
					iwbishop_count -= 1
				"WhiteRook":
					iwrook_count -= 1
				"WhiteQueen":
					iwqueen_count -= 1
			update_inventory_labels()
			selected_inventory_piece = null
			Input.set_custom_mouse_cursor(null)
		else:
			print("You cannot place a piece on this tile.")
		return
	if shopping == true:
		return
	if get_node("/root/TurnManager").post_move_attack_pending:
		BoardManager.select_piece(x, y)
		return
	if board_state[y][x] == null:
		BoardManager.select_piece(x, y)
	else:
		if _handle_friendly_piece_selection(x, y):
			return
		_handle_move_or_attack(x, y)
	right_menu.visible = false
	$MapInfo/CanvasLayer.visible = false

func _handle_board_right_click(_event):
	track_piece_info()
	var mouse_pos = get_global_mouse_position()
	var grid_coordinates = BoardManager.get_grid_coordinates(mouse_pos)
	var x = grid_coordinates.x
	var y = grid_coordinates.y
	if shopping == true && in_home_1 == true:
		return
	if not BoardManager.is_within_board(x, y) && in_home_1 == true:
		right_menu.visible = false
		return
	right_menu.visible = true
	info_button.visible = true
	if board_state[y][x] && in_home_1 == true:
		var piece = board_state[y][x]
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
	if board_state[y][x] && in_home_1 == true:
		var piece = board_state[y][x]
		# Use is_white property if available, else fallback to name
		var is_white_piece = "is_white" in piece and piece.is_white or piece.name.begins_with("White")
		if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
			if is_white_piece == Rules.player_is_white and NetworkManager.can_local_player_move() && in_home_1 == true:
				BoardManager.select_piece(x, y)
				return true
		else:
			if is_white_piece == TurnManager.is_white_turn and NetworkManager.can_local_player_move() && in_home_1 == true:
				BoardManager.select_piece(x, y)
				return true
	return false

func _handle_move_or_attack(x, y):
	var move_tiles = []
	if board_state[BoardManager.selected_piece_position.y][BoardManager.selected_piece_position.x].has_method("get_moves") && in_home_1 == true:
		move_tiles = board_state[BoardManager.selected_piece_position.y][BoardManager.selected_piece_position.x].get_moves(BoardManager.selected_piece_position.x, BoardManager.selected_piece_position.y)
	var attack_tiles = []
	var unique_attack_tiles = []
	if "get_attack_range" in board_state[BoardManager.selected_piece_position.y][BoardManager.selected_piece_position.x] && in_home_1 == true:
		attack_tiles = board_state[BoardManager.selected_piece_position.y][BoardManager.selected_piece_position.x].get_attack_range(BoardManager.selected_piece_position.x, BoardManager.selected_piece_position.y)
		for tile in attack_tiles:
			if tile not in move_tiles:
				unique_attack_tiles.append(tile)
	if Vector2(x, y) in move_tiles:
		MoveManager.move_selected_piece(x, y)
	elif Vector2(x, y) in unique_attack_tiles:
		_handle_range_attack(x, y)
	else:
		print("Invalid move")
		BoardManager.deselect_piece()

func _handle_range_attack(x, y):
	if board_state[y][x] && in_home_1 == true:
		var target_piece = board_state[y][x]
		if target_piece.is_white != board_state[BoardManager.selected_piece_position.y][BoardManager.selected_piece_position.x].is_white:
			MoveUtils.perform_range_attack(board_state[BoardManager.selected_piece_position.y][BoardManager.selected_piece_position.x], Vector2(x, y))
			TurnManager.moves_this_turn += 1
			TurnManager.check_turn_end()
			BoardManager.deselect_piece()
		else:
			print("Invalid move: Cannot attack your own piece.")
	else:
		print("Missed attack: No piece to capture.")
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
	var piece = board_state[y][x]
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
		print("No piece selected for promotion.")
		$PromotionUi.piece_promotion.visible = false
		return
	if not piece_values.has(piece_name):
		print("Unknown piece for promotion.")
		$PromotionUi.piece_promotion.visible = false
		return
	var cost = piece_values[piece_name]
	if current_value < cost:
		print("Not enough value to promote to %s (need %d, have %d)" % [piece_name, cost, current_value])
		$PromotionUi.piece_promotion.visible = false
		return
	var x = int(last_selected_piece.x)
	var y = int(last_selected_piece.y)
	var old_piece = board_state[y][x]
	if old_piece:
		if old_piece.name.begins_with("WhiteKing") or old_piece.name.begins_with("BlackKing"):
			print("A king cannot be promoted into another piece.")
			$PromotionUi.piece_promotion.visible = false
			return
		current_value -= cost
		update_value_label()
		old_piece.queue_free()
		board_state[y][x] = null
		var new_piece = UnitManager.place_piece_by_name(piece_name, x, y)
		if new_piece == null:
			new_piece = board_state[y][x]
		else:
			board_state[y][x] = new_piece
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
		if board_state[y][x] != null and board_state[y][x].has_method("can_move_this_turn"):
			if board_state[y][x].moves_made_this_turn == 0:
				board_state[y][x].moves_made_this_turn = MAX_MOVES_PER_TURN
				MoveManager.enable_post_move_attack(board_state[y][x], BoardManager.selected_piece_position)
				TurnManager.post_move_attack_pending = true
				return
	TurnManager.post_move_attack_pending = false
	TurnManager.check_turn_end()
	MoveManager.clear_move_highlights()
	right_menu.visible = false

func save_map_1():
	# Save the current map state using the MapSaveManager
	MapSaveManager.save_map(self, board_state, "user://home_1_save.sav", "home_1")

func load_map_1():
	# Load the map state using the MapSaveManager
	MapSaveManager.load_map(self, board_state, "user://home_1_save.sav", "home_1")
	# Update UI after loading
	if has_node("MapUi"):
		get_node("MapUi").update_turn_label(TurnManager.is_white_turn)
	track_piece_info()

func track_piece_info():
	for y in range(board_state.size()):
		for x in range(board_state[y].size()):
			var piece = board_state[y][x]
			if piece:
				print("[track_piece_info] Piece Name: %s, Color: %s, Position: %s, Max Turns: %s, Executed Turns: %s, Script: %s" % [
					piece.name,
					"White" if piece.is_white else "Black",
					Vector2(x, y),
					piece.MOVES_PER_TURN if "MOVES_PER_TURN" in piece else "?",
					piece.moves_made_this_turn if "moves_made_this_turn" in piece else "?",
					piece.get_script() if piece.has_method("get_script") else "?"
				])


func get_shared_map_ui():
	return get_tree().get_root().find_child("MapUi", true, false)

func update_value_label():
	var shared_map_ui = get_shared_map_ui()
	if shared_map_ui:
		shared_map_ui.set_value_label(current_value)

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

func on_tab_selected():
	in_home_1 = true
	# Remove only piece nodes, not UI or essential nodes
	for child in get_children():
		if child.name.begins_with("White") or child.name.begins_with("Black") or child.name in ["custom_piece", "black_king", "black_rook"]:
			remove_child(child)
			child.queue_free()

	# Reset board state for Home1
	BoardManager.set_board_size(MAP_BOARD_WIDTH, MAP_BOARD_HEIGHT)
	BoardManager.set_tile_colors(MAP_LIGHT_COLOR, MAP_DARK_COLOR)
	BoardManager.initialize()
	BoardManager.remove_all_pieces()
	place_starting_pieces()

	# Ensure board coordinate indicators are drawn if needed
	if has_method("draw_board_numbers"):
		draw_board_numbers()

	# Ensure BuildingFactory is visible (if it exists)
	var factory = $BuildingFactory if has_node("BuildingFactory") else null
	if factory:
		factory.visible = true

	# If this is Home1, set in_home_1 depending on tab selection
	if has_node("../.."):
		var parent = get_node("../..")
		if parent.has_node("MainTabs"):
			var main_tabs = parent.get_node("MainTabs")
			if main_tabs.current_tab == 0:
				in_home_1 = false
			else:
				in_home_1 = true
