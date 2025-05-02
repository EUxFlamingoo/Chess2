extends Node2D

const OBSTACLE_SCENE = preload("res://Scenes/maps/map_elements/obstacles.tscn")

var MAP_BOARD_WIDTH = 12
var MAP_BOARD_HEIGHT = 8

var First_Rank = 0  # Modify with caution
var Last_Rank = MAP_BOARD_HEIGHT - 1 # Modify with caution
var First_File = 0  # Modify with caution
var Last_File = MAP_BOARD_WIDTH - 1  # Modify with caution

var MAP_LIGHT_COLOR = Color(0.4, 0.3, 0.2)
var MAP_DARK_COLOR = Color(0.3, 0.2, 0.1)

func _ready():
	BoardManager.set_board_size(MAP_BOARD_WIDTH, MAP_BOARD_HEIGHT)
	BoardManager.set_tile_colors(MAP_LIGHT_COLOR, MAP_DARK_COLOR)
	BoardManager.initialize()
	place_starting_pieces()
	
	# Focus camera on the center of the map
	var camera = $Camera2D
	var center_x = (MAP_BOARD_WIDTH - 1) / 2.0
	var center_y = (MAP_BOARD_HEIGHT - 1) / 2.0
	camera.position = BoardManager.get_centered_position(center_x, center_y)

func place_starting_pieces():
	# Remove all existing pieces from the board and scene tree
	for y in range(BoardManager.BOARD_HEIGHT):
		for x in range(BoardManager.BOARD_WIDTH):
			var piece = BoardManager.board_state[y][x]
			if piece != null:
				piece.queue_free()
			BoardManager.board_state[y][x] = null
	for child in BoardManager.get_children():
		if child.name.begins_with("White") or child.name.begins_with("Black"):
			child.queue_free()
	
	# Now place only the pieces you want for this map:
	UnitManager.place_piece_by_name("WhiteKing", First_File, First_Rank)
	UnitManager.place_piece_by_name("BlackKing", Last_File, Last_Rank)
	UnitManager.place_piece_by_name("WhiteSidePawn", First_File + 1, First_Rank + 2)
	UnitManager.place_piece_by_name("BlackSidePawn", Last_File - 1, Last_Rank - 2)
	# Place obstacles at desired positions:
	#place_obstacle(3, 4)
	#place_obstacle(5, 2)



func place_obstacle(x: int, y: int):
	var obstacle = OBSTACLE_SCENE.instantiate()
	obstacle.position = BoardManager.get_centered_position(x, y)
	BoardManager.add_child(obstacle)
	BoardManager.board_state[y][x] = obstacle # Mark the tile as occupied by an obstacle
