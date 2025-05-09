extends Sprite2D

var is_white: bool
var abilities: Array = []
var ATTACK_RANGE := []
var RANGE_ATTACK_INTERRUPTED := true

func get_moves(x: int, y: int) -> Array:
	return get_knight_moves(x, y, is_white)

func get_knight_moves(x: int, y: int, is_white_piece: bool) -> Array:
	var moves = []
	var directions = [
		Vector2(2, 1),   # Two right, one up
		Vector2(2, -1),  # Two right, one down
		Vector2(-2, 1),  # Two left, one up
		Vector2(-2, -1), # Two left, one down
		Vector2(1, 2),   # One right, two up
		Vector2(1, -2),  # One right, two down
		Vector2(-1, 2),  # One left, two up
		Vector2(-1, -2)  # One left, two down
	]
	for direction in directions:
		var target_x = x + direction.x
		var target_y = y + direction.y
		if BoardManager.is_within_board(target_x, target_y):
			if "jump" in abilities:
				# Can jump to any square not occupied by friendly or obstacle
				if not BoardManager.is_tile_obstacle(target_x, target_y) and not BoardManager.is_tile_occupied_by_friendly(target_x, target_y, is_white_piece):
					moves.append(Vector2(target_x, target_y))
			else:
				# Normal knight move: can land on empty or opponent, but not obstacle or friendly
				if (not BoardManager.is_tile_occupied(target_x, target_y) or BoardManager.is_tile_occupied_by_opponent(target_x, target_y, is_white_piece)) and not BoardManager.is_tile_obstacle(target_x, target_y):
					moves.append(Vector2(target_x, target_y))
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
