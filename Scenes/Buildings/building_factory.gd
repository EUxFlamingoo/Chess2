extends Sprite2D

@export var template_name := "WhiteFactory" # Set this in each piece scene

# --- UNIT CONFIGURATION (edit these for new custom pieces) ---
@export var is_white: bool = true
@export var TILE_MOVE_RANGE := 0
@export var MOVES_PER_TURN := 1  # How many times this piece can move per turn

const UNIT_NAME := "white_factory"
const UNIT_VALUE := 8
const MOVES := [""] # or combine with others as needed
#const MOVES := ["bishop", "knight"] # List of movesets to inherit
const PROMOTION_OPTIONS := ["Queen", "Rook", "Bishop", "Knight"]
var ATTACK_RANGE := []
var MELEE_ATTACK_RANGE := [""] # Melee attack range uses king moveset
var MELEE_ATTACK_INTERRUPTED := false
var RANGE_ATTACK_INTERRUPTED := true

# Promotion triggers
const PROMOTION_TRIGGER_DEFEATS := 2
const PROMOTION_TRIGGER_VALUE := 10
const PROMOTION_TRIGGER_SPOTS := [Vector2(2, 2)]

# Starting positions
const START_POS_WHITE := [Vector2(3, 5)]
#const START_POS_BLACK := [Vector2(0, 0), Vector2(0, 0)]

var abilities: Array = []

# --- END UNIT CONFIGURATION ---

# Runtime state
var defeated_count: int = 0
var accrued_value: int = 0
var moves_made_this_turn := 0  # Tracks moves made by this piece in the current turn

func _ready():
	update_appearance()

func update_appearance():
	is_white = true # Ensure is_white is set to true by default or as needed

func get_moves(x: int, y: int, is_white_override: bool = self.is_white) -> Array:
	var moves = []
	for moveset in MOVES:
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
			"side_pawn":
				moves += MoveUtils.get_side_pawn_moves(x, y, is_white_override)
			"move_tiles":
				moves += MoveUtils.get_tile_moves(x, y, is_white_override, TILE_MOVE_RANGE)
			_:
				push_warning("Unknown moveset: %s" % moveset)
	return moves

func get_promotion_options() -> Array:
	return PROMOTION_OPTIONS

func handle_promotion(piece, target_position: Vector2):
	UnitManager.handle_promotion(piece, target_position)

func get_attack_range(x: int, y: int, _is_white_override: bool = self.is_white) -> Array:
	return MoveUtils.get_range_attack_tiles(self, x, y)

func grant_ability(ability_name: String) -> void:
	if ability_name in abilities:
		return # Already has it
	abilities.append(ability_name)
	# Apply immediate effects if needed
	if ability_name == "ranged_attack":
		if not ("ATTACK_RANGE" in self):
			self.ATTACK_RANGE = []
		if "rook" not in self.ATTACK_RANGE:
			self.ATTACK_RANGE.append("rook") # Example: grant rook-style ranged attack
		self.RANGE_ATTACK_INTERRUPTED = true # Or false, as desired
	# Add more abilities here as elifs

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
