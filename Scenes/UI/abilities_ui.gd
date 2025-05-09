extends Node2D


@onready var abilities_container: HBoxContainer = $CanvasLayer/AbilitiesContainer
@onready var ranged_attacks_button: Button = $CanvasLayer/AbilitiesContainer/RangedAttacksButton
@onready var more_movement_button: Button = $CanvasLayer/AbilitiesContainer/MoreMovementButton
@onready var add_jump_button: Button = $CanvasLayer/AbilitiesContainer/AddJumpButton

@onready var ranged_pieces: HBoxContainer = $CanvasLayer/RangedPieces
@onready var wking: Button = $CanvasLayer/RangedPieces/wking
@onready var wknight: Button = $CanvasLayer/RangedPieces/wknight
@onready var wbishop: Button = $CanvasLayer/RangedPieces/wbishop
@onready var wrook: Button = $CanvasLayer/RangedPieces/wrook
@onready var wqueen: Button = $CanvasLayer/RangedPieces/wqueen

@onready var movement_adder: HBoxContainer = $CanvasLayer/MovementAdder
@onready var minus_movement: Button = $CanvasLayer/MovementAdder/MinusMovement
@onready var current_movement: Label = $CanvasLayer/MovementAdder/CurrentMovement
@onready var plus_movement: Button = $CanvasLayer/MovementAdder/PlusMovement
@onready var done_button: Button = $CanvasLayer/MovementAdder/DoneButton

var current_ability: String = ""
var selected_attack_pattern: String = ""


# Grant an ability to the current piece
func grant_ability_to_current_piece(ability_name: String) -> void:
	if not self.current_piece:
		print("No piece selected for ability granting.")
		return
	if not self.current_piece.has_method("grant_ability"):
		print("Piece does not support abilities.")
		return
	self.current_piece.grant_ability(ability_name)
	print("Granted ability '%s' to %s" % [ability_name, self.current_piece.name])

# Example button handlers (connect these to your UI buttons)
func _on_grant_ranged_attack_pressed():
	grant_ability_to_current_piece("ranged_attack")


# Call this from the Abilities button in your main UI
func show_abilities_ui():
	self.visible = true
	abilities_container.visible = true
	current_ability = ""
	selected_attack_pattern = ""

# Called when RangedAttacksButton is pressed
func _on_ranged_attacks_button_pressed():
	current_ability = "ranged_attack"
	abilities_container.visible = false
	ranged_pieces.visible = true

# Piece button handlers
func _on_wrook_pressed():
	grant_ranged_attack_to_selected("rook")
	ranged_pieces.visible = false
	BoardManager.selecting_ok = true

func _on_wqueen_pressed():
	grant_ranged_attack_to_selected("queen")
	ranged_pieces.visible = false
	BoardManager.selecting_ok = true

func _on_wbishop_pressed():
	grant_ranged_attack_to_selected("bishop")
	ranged_pieces.visible = false
	BoardManager.selecting_ok = true

func _on_wknight_pressed():
	grant_ranged_attack_to_selected("knight")
	ranged_pieces.visible = false
	BoardManager.selecting_ok = true

func _on_wking_pressed():
	grant_ranged_attack_to_selected("king")
	ranged_pieces.visible = false
	BoardManager.selecting_ok = true

# Grant the ranged attack pattern to the selected piece
func grant_ranged_attack_to_selected(pattern: String):
	if not has_node("/root/Map1"):
		print("Map1 not found.")
		return
	var map_node = get_node("/root/Map1")
	var pos = map_node.last_selected_piece
	if pos == Vector2(-1, -1):
		print("No piece selected for ability granting.")
		return
	var x = int(pos.x)
	var y = int(pos.y)
	var piece = BoardManager.board_state[y][x]
	if piece == null:
		print("No piece at selected position.")
		return
	# Grant the ranged_attack ability and set the pattern
	if not ("abilities" in piece):
		piece.abilities = []
	if "ranged_attack" not in piece.abilities:
		piece.abilities.append("ranged_attack")
	if not ("ATTACK_RANGE" in piece):
		piece.ATTACK_RANGE = []
	if pattern not in piece.ATTACK_RANGE:
		piece.ATTACK_RANGE.append(pattern)
	piece.RANGE_ATTACK_INTERRUPTED = true # or false if you want
	print("Granted ranged attack pattern '%s' to %s" % [pattern, piece.name], " at: ", pos)
	self.visible = false # Hide abilities UI after granting


func _on_add_jump_button_pressed():
	grant_jump_to_selected()
	abilities_container.visible = false

func grant_jump_to_selected():
	if not has_node("/root/Map1"):
		print("Map1 not found.")
		return
	var map_node = get_node("/root/Map1")
	var pos = map_node.last_selected_piece
	if pos == Vector2(-1, -1):
		print("No piece selected for ability granting.")
		return
	var x = int(pos.x)
	var y = int(pos.y)
	var piece = BoardManager.board_state[y][x]
	if piece == null:
		print("No piece at selected position.")
		return
	if not ("abilities" in piece):
		piece.abilities = []
	if "jump" not in piece.abilities:
		piece.abilities.append("jump")
	print("Granted jump ability to %s at: %s" % [piece.name, pos])
	self.visible = false
	BoardManager.selecting_ok = true


func _on_more_movement_button_pressed() -> void:
	movement_adder.visible = true
	abilities_container.visible = false
	var map_node = get_node("/root/Map1")
	var pos = map_node.last_selected_piece
	var x = int(pos.x)
	var y = int(pos.y)
	var piece = BoardManager.board_state[y][x]
	if piece == null:
		print("No piece at selected position.")
		return
	if not ("abilities" in piece):
		piece.abilities = []
	if not ("TILE_MOVE_RANGE" in piece):
		current_movement.text = "-"
	else:
		current_movement.text = str(piece.TILE_MOVE_RANGE)
		

func _on_minus_movement_pressed() -> void:
	movement_adder.visible = true
	abilities_container.visible = false
	var map_node = get_node("/root/Map1")
	var pos = map_node.last_selected_piece
	var x = int(pos.x)
	var y = int(pos.y)
	var piece = BoardManager.board_state[y][x]
	if piece == null:
		print("No piece at selected position.")
		return
	if ("TILE_MOVE_RANGE" in piece):
		piece.TILE_MOVE_RANGE = max(1, piece.TILE_MOVE_RANGE - 1)
		current_movement.text = str(piece.TILE_MOVE_RANGE)

func _on_plus_movement_pressed() -> void:
	movement_adder.visible = true
	abilities_container.visible = false
	var map_node = get_node("/root/Map1")
	var pos = map_node.last_selected_piece
	var x = int(pos.x)
	var y = int(pos.y)
	var piece = BoardManager.board_state[y][x]
	if piece == null:
		print("No piece at selected position.")
		return
	if ("TILE_MOVE_RANGE" in piece):
		piece.TILE_MOVE_RANGE = max(1, piece.TILE_MOVE_RANGE + 1)
		current_movement.text = str(piece.TILE_MOVE_RANGE)



func _on_done_button_pressed() -> void:
	movement_adder.visible = false
	BoardManager.selecting_ok = true

func grant_movement_to_selected():
	if not has_node("/root/Map1"):
		print("Map1 not found.")
		return
	var map_node = get_node("/root/Map1")
	var pos = map_node.last_selected_piece
	if pos == Vector2(-1, -1):
		print("No piece selected for ability granting.")
		return
	var x = int(pos.x)
	var y = int(pos.y)
	var piece = BoardManager.board_state[y][x]
	if piece == null:
		print("No piece at selected position.")
		return
	if not ("abilities" in piece):
		piece.abilities = []
	if "jump" not in piece.abilities:
		piece.abilities.append("jump")
	print("Granted jump ability to %s at: %s" % [piece.name, pos])
	self.visible = false
	BoardManager.selecting_ok = true
