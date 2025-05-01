extends Sprite2D

var is_white: bool

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
            if not BoardManager.is_tile_occupied(target_x, target_y) or BoardManager.is_tile_occupied_by_opponent(target_x, target_y, is_white_piece):
                moves.append(Vector2(target_x, target_y))
    return moves
