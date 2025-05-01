extends Sprite2D

@export var is_white: bool = true


# Name of the unit (e.g., "Knight", "Archbishop")
const UNIT_NAME := "custom_piece"
# Value of the unit for evaluation (e.g., 3 for Knight, 9 for Queen)
const UNIT_VALUE := 8
# List of movesets to inherit (e.g., ["bishop", "knight"])
var movesets := ["bishop", "knight"]
const PROMOTION_OPTIONS := ["Queen", "Rook", "Bishop", "Knight"]
const ABILITIES := ["jump", "double_move"]
const AI_PRIORITY := 1.2  # Multiplier for AI evaluation

const MOVE_RESTRICTIONS := ["no_capture", "must_move"]

# Example triggers (customize per unit)
const PROMOTION_TRIGGER_DEFEATS := 2           # Promote after defeating 3 pieces
const PROMOTION_TRIGGER_VALUE := 10            # Promote after accruing 10 value
const PROMOTION_TRIGGER_SPOTS := [Vector2(4, 4)] # Promote if reaching (4,4)
# Starting positions for white and black as arrays of Vector2
const START_POS_WHITE := [Vector2(4, 5), Vector2(4, 6)]
#const START_POS_BLACK := [Vector2(0, 0), Vector2(0, 0)]

var defeated_count: int = 0
var accrued_value: int = 0

func get_moves(x: int, y: int, is_white_override: bool = self.is_white) -> Array:
	var moves = []
	for moveset in movesets:
		match moveset:
			"bishop":
				moves += MoveUtils.get_bishop_moves(x, y, is_white_override)
			"rook":
				moves += MoveUtils.get_rook_moves(x, y, is_white_override)
			"knight":
				moves += MoveUtils.get_knight_moves(x, y, is_white_override)
			"queen":
				moves += MoveUtils.get_bishop_moves(x, y, is_white_override)
				moves += MoveUtils.get_rook_moves(x, y, is_white_override)
			"king":
				moves += MoveUtils.get_king_moves(x, y, is_white_override)
			"pawn":
				moves += MoveUtils.get_pawn_moves(x, y, is_white_override)
			_:
				push_warning("Unknown moveset: %s" % moveset)
	return moves


func get_promotion_options() -> Array:
	return PROMOTION_OPTIONS

func handle_promotion(piece, target_position: Vector2):
	UnitManager.handle_promotion(piece, target_position)
