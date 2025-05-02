extends Node

const end_piece_capture_enabled = true

# Define win conditions separately for each side:
const WHITE_WIN_CONDITION := {
    "BlackKing": 1,
}
const BLACK_WIN_CONDITION := {
    "WhiteKing": 1,
}

const fifty_move_rule_enabled = false
const checkmate_enabled = false

var move_counter = 0

# Track starting counts for each piece type
var _white_start := {}
var _black_start := {}

func end_piece_capture() -> String:
    var remaining := {}
    # Initialize remaining counts for all relevant pieces
    for piece_name in WHITE_WIN_CONDITION.keys():
        remaining[piece_name] = 0
    for piece_name in BLACK_WIN_CONDITION.keys():
        remaining[piece_name] = 0
    # Count remaining pieces on the board
    for y in range(BoardManager.BOARD_HEIGHT):
        for x in range(BoardManager.BOARD_WIDTH):
            var piece = BoardManager.board_state[y][x]
            if piece:
                for piece_name in remaining.keys():
                    if piece.name.find(piece_name) != -1:
                        remaining[piece_name] += 1
    # On first call, store the starting counts
    if _white_start.size() == 0:
        for piece_name in WHITE_WIN_CONDITION.keys():
            _white_start[piece_name] = remaining[piece_name]
    if _black_start.size() == 0:
        for piece_name in BLACK_WIN_CONDITION.keys():
            _black_start[piece_name] = remaining[piece_name]
    # Check if white's win condition is met
    var white_met = true
    for piece_name in WHITE_WIN_CONDITION.keys():
        var captured = _white_start[piece_name] - remaining[piece_name]
        if captured < WHITE_WIN_CONDITION[piece_name]:
            white_met = false
        print("DEBUG: White needs %d %s, captured: %d" % [WHITE_WIN_CONDITION[piece_name], piece_name, captured])
    # Check if black's win condition is met
    var black_met = true
    for piece_name in BLACK_WIN_CONDITION.keys():
        var captured = _black_start[piece_name] - remaining[piece_name]
        if captured < BLACK_WIN_CONDITION[piece_name]:
            black_met = false
        print("DEBUG: Black needs %d %s, captured: %d" % [BLACK_WIN_CONDITION[piece_name], piece_name, captured])
    if white_met:
        announce_winner("White")
        return "White"
    if black_met:
        announce_winner("Black")
        return "Black"
    return ""

func announce_winner(winner: String):
    print("%s wins! Custom capture condition met." % winner)
    # Add UI/game over logic here

func check_fifty_move_rule() -> bool:
    if not fifty_move_rule_enabled:
        return false
    if move_counter >= 50:
        print("Fifty-move rule triggered. Game is a draw.")
        return true
    return false

func is_checkmate(is_white: bool) -> bool:
    var king_in_check = MoveManager.is_king_in_check(is_white)
    var all_moves = MoveManager.get_all_valid_moves(is_white)
    return king_in_check and all_moves.size() == 0

func is_stalemate(is_white: bool) -> bool:
    var king_in_check = MoveManager.is_king_in_check(is_white)
    var all_moves = MoveManager.get_all_valid_moves(is_white)
    return not king_in_check and all_moves.size() == 0
