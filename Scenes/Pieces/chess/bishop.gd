extends Sprite2D

var is_white: bool

func get_moves(x: int, y: int) -> Array:
	return get_bishop_moves(x, y, is_white)

func get_bishop_moves(x: int, y: int, is_white_piece: bool) -> Array:
	var moves = []
	var directions = [
		Vector2(1, 1),   # Diagonal up-right
		Vector2(-1, 1),  # Diagonal up-left
		Vector2(1, -1),  # Diagonal down-right
		Vector2(-1, -1)  # Diagonal down-left
	]
	for direction in directions:
		var pos = Vector2(x, y) + direction
		while BoardManager.is_within_board(pos.x, pos.y):
			if not BoardManager.is_tile_occupied(pos.x, pos.y) || !BoardManager.is_tile_obstacle(pos.x, pos.y):
				moves.append(pos)
			elif BoardManager.is_tile_occupied_by_opponent(pos.x, pos.y, is_white_piece):
				moves.append(pos)
				break  # Stop further moves in this direction
			else:
				break  # Stop further moves in this direction
			pos += direction  # Move to the next position in the direction
	return moves

func get_bishop_attacks(x: int, y: int, _is_white_piece: bool) -> Array:
	var moves = []
	var directions = [
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
	]
	for direction in directions:
		var pos = Vector2(x, y) + direction
		while BoardManager.is_within_board(pos.x, pos.y):
			moves.append(pos)
			if BoardManager.is_tile_occupied(pos.x, pos.y) || BoardManager.is_tile_obstacle(pos.x, pos.y):
				break  # Stop at the first piece, regardless of color
			pos += direction
	return moves
