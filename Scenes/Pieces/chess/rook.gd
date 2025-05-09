extends Sprite2D

var is_white: bool
var abilities: Array = []
var ATTACK_RANGE := []
var RANGE_ATTACK_INTERRUPTED := true

func get_moves(x: int, y: int) -> Array:
	return get_rook_moves(x, y, is_white)

func get_rook_attacks(x: int, y: int, _is_white_piece: bool) -> Array:
	var moves = []
	var directions = [
		Vector2(1, 0),   # Right
		Vector2(-1, 0),  # Left
		Vector2(0, 1),   # Down
		Vector2(0, -1)   # Up
	]
	for direction in directions:
		var pos = Vector2(x, y) + direction
		while BoardManager.is_within_board(pos.x, pos.y):
			moves.append(pos)
			if BoardManager.is_tile_occupied(pos.x, pos.y) || !BoardManager.is_tile_obstacle(pos.x, pos.y):
				break  # Stop at the first piece, regardless of color
			pos += direction
	return moves

func get_rook_moves(x: int, y: int, is_white_piece: bool) -> Array:
	var moves = []
	var directions = [
		Vector2(1, 0),  # Right
		Vector2(-1, 0), # Left
		Vector2(0, 1),  # Down
		Vector2(0, -1)  # Up
	]
	if "jump" in abilities:
		for direction in directions:
			var pos = Vector2(x, y) + direction
			while BoardManager.is_within_board(pos.x, pos.y):
				# Skip landing on obstacles or friendly pieces, but keep jumping past them
				if BoardManager.is_tile_obstacle(pos.x, pos.y) or BoardManager.is_tile_occupied_by_friendly(pos.x, pos.y, is_white_piece):
					pos += direction
					continue
				moves.append(pos)
				pos += direction
	else:
		for direction in directions:
			var pos = Vector2(x, y) + direction
			while BoardManager.is_within_board(pos.x, pos.y):
				if not BoardManager.is_tile_occupied(pos.x, pos.y) and not BoardManager.is_tile_obstacle(pos.x, pos.y):
					moves.append(pos)
				elif BoardManager.is_tile_occupied_by_opponent(pos.x, pos.y, is_white_piece):
					moves.append(pos)
					break
				else:
					break
				pos += direction
	return moves

func move_rook(from_position: Vector2, to_position: Vector2):
	var rook = BoardManager.board_state[from_position.y][from_position.x]
	BoardManager.board_state[from_position.y][from_position.x] = null  # Clear the old position
	BoardManager.board_state[to_position.y][to_position.x] = rook  # Set the new position
	rook.position = BoardManager.get_centered_position(int(to_position.x), int(to_position.y))

func get_linear_moves(x: int, y: int, is_white_piece: bool, directions: Array) -> Array:
	var moves = []
	for direction in directions:
		var pos = Vector2(x, y) + direction
		while BoardManager.is_within_board(pos.x, pos.y):  # Ensure position is within bounds
			if not BoardManager.is_tile_occupied(pos.x, pos.y) || !BoardManager.is_tile_obstacle(pos.x, pos.y):
				moves.append(pos)
			elif BoardManager.is_tile_occupied_by_opponent(pos.x, pos.y, is_white_piece):
				moves.append(pos)
				break  # Stop further moves in this direction
			else:
				break  # Stop further moves in this direction
			pos += direction  # Move to the next position in the direction
	return moves

func get_attack_range(x: int, y: int, _is_white_override: bool = self.is_white) -> Array:
	return MoveUtils.get_range_attack_tiles(self, x, y)


var moves_made_this_turn := 0 
@export var MOVES_PER_TURN := 1
func can_move_this_turn() -> bool:
	# Get the global max moves per turn from the map
	var map_node = GameManager.current_map
	var global_max = map_node.MAX_MOVES_PER_TURN
	var allowed_moves = min(MOVES_PER_TURN, global_max)
	return moves_made_this_turn < allowed_moves

func reset_moves_this_turn():
	moves_made_this_turn = 0

func increment_moves_this_turn():
	moves_made_this_turn += 1
