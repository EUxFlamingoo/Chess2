extends Node

#region onready

@onready var white_2: Button = $white2
@onready var white_3: Button = $white3
@onready var white_4: Button = $white4
@onready var white_5: Button = $white5
@onready var black_2: Button = $black2
@onready var black_3: Button = $black3
@onready var black_4: Button = $black4
@onready var black_5: Button = $black5

#endregion

var enemy_logic_on = false
const chess_mode = true     # Modify
const en_passant_enabled = true # Modify
const max_moves_per_turn = 1   # Modify
const castling_enabled = true # Modify
const fifty_move_rule_enabled = true  # Modify

#region var

var promotion_pawn = null  # Stores the pawn to be promoted
var promotion_position = null  # Stores the position of the pawn to be promoted
var is_promotion_in_progress = false  # Tracks if a pawn promotion is in progress
var en_passant = null
var en_passant_capture_white = false
var en_passant_capture_black = false
# Track whether the king or rooks have moved
var white_king_moved = false
var black_king_moved = false
var white_rook_kingside_moved = false
var white_rook_queenside_moved = false
var black_rook_kingside_moved = false
var black_rook_queenside_moved = false
# Tracks the number of moves since the last pawn move or capture
var move_counter = 0

var player_is_white = true

#endregion

#region promotion


func handle_promotion(pawn, target_position: Vector2):
	# Only allow promotion if the piece is a pawn
	if pawn == null or pawn.name.find("Pawn") == -1:
		return
	# Check if the pawn has reached the last rank
	if pawn.name.begins_with("White") and target_position.y == BoardManager.Last_Rank:
		if Rules.enemy_logic_on:
			promote_pawn("Queen", UnitManager.WHITE_QUEEN)
			return
		print("White pawn reached the last rank at position: ", target_position)
		promotion_pawn = pawn
		promotion_position = target_position
		is_promotion_in_progress = true  # Set promotion in progress
		if GameManager.online_enabled:
			if multiplayer.get_unique_id() == 1:
				# Host: only notify client if it's their pawn
				if not pawn.name.begins_with("White"):
					for peer_id in multiplayer.get_peers():
						if peer_id != multiplayer.get_unique_id():
							NetworkManager.rpc_id(peer_id, "request_promotion", target_position, false)
				else:
					# Host's own pawn, show UI locally
					Player.show_promotion_ui(target_position, true)
			else:
				# Client: show UI locally (shouldn't happen, but for completeness)
				Player.show_promotion_ui(target_position, pawn.name.begins_with("White"))
		else:
			# Local play: show UI locally
			Player.show_promotion_ui(target_position, pawn.name.begins_with("White"))
	elif pawn.name.begins_with("Black") and target_position.y == BoardManager.First_Rank:
		if Rules.enemy_logic_on:
			promote_pawn("Queen", UnitManager.BLACK_QUEEN)
			return
		print("Black pawn reached the last rank at position: ", target_position)
		promotion_pawn = pawn
		promotion_position = target_position
		is_promotion_in_progress = true  # Set promotion in progress
		if GameManager.online_enabled:
			if multiplayer.get_unique_id() == 1:
				# Host: only notify client if it's their pawn
				if not pawn.name.begins_with("White"):
					for peer_id in multiplayer.get_peers():
						if peer_id != multiplayer.get_unique_id():
							NetworkManager.rpc_id(peer_id, "request_promotion", target_position, false)
				else:
					# Host's own pawn, show UI locally
					Player.show_promotion_ui(target_position, true)
			else:
				# Client: show UI locally (shouldn't happen, but for completeness)
				Player.show_promotion_ui(target_position, pawn.name.begins_with("White"))
		else:
			# Local play: show UI locally
			Player.show_promotion_ui(target_position, pawn.name.begins_with("White"))

func _on_white_5_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Queen")
	else:
		promote_pawn("Queen", UnitManager.WHITE_QUEEN)

# Repeat for other promotion buttons:
func _on_white_4_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Rook")
	else:
		promote_pawn("Rook", UnitManager.WHITE_ROOK)

func _on_white_3_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Bishop")
	else:
		promote_pawn("Bishop", UnitManager.WHITE_BISHOP)

func _on_white_2_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Knight")
	else:
		promote_pawn("Knight", UnitManager.WHITE_KNIGHT)

func _on_black_5_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Queen")
	else:
		promote_pawn("Queen", UnitManager.BLACK_QUEEN)

func _on_black_4_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Rook")
	else:
		promote_pawn("Rook", UnitManager.BLACK_ROOK)

func _on_black_3_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Bishop")
	else:
		promote_pawn("Bishop", UnitManager.BLACK_BISHOP)

func _on_black_2_pressed():
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", promotion_position, "Knight")
	else:
		promote_pawn("Knight", UnitManager.BLACK_KNIGHT)


func promote_pawn(piece_name: String, piece_scene: PackedScene):
	if promotion_pawn == null or promotion_position == null:
		print("No pawn to promote!")
		return
	# Remove the pawn from the board and scene tree
	BoardManager.board_state[int(promotion_position.y)][int(promotion_position.x)] = null
	promotion_pawn.queue_free()
	# Instantiate the new piece and place it on the board
	var new_piece = piece_scene.instantiate()
	new_piece.name = promotion_pawn.name.replace("Pawn", piece_name)
	new_piece.position = BoardManager.get_centered_position(int(promotion_position.x), int(promotion_position.y))
	# Add the new piece to the same parent as the pawn
	BoardManager.add_child(new_piece)
	# Update the board state
	BoardManager.board_state[int(promotion_position.y)][int(promotion_position.x)] = new_piece
	# Hide the promotion controls
	white_2.visible = false
	white_3.visible = false
	white_4.visible = false
	white_5.visible = false
	black_2.visible = false
	black_3.visible = false
	black_4.visible = false
	black_5.visible = false
	# Reset promotion variables
	promotion_pawn = null
	promotion_position = null
	is_promotion_in_progress = false  # Reset promotion in progress
	# Check if the turn should end
	TurnManager.check_turn_end()

func promote_pawn_networked(pawn_pos: Vector2, piece_name: String):
	var pawn = BoardManager.board_state[int(pawn_pos.y)][int(pawn_pos.x)]
	if pawn and pawn.name.find("Pawn") != -1:
		promote_pawn(piece_name, UnitManager.get_piece_scene(piece_name, pawn.name.begins_with("White")))

#endregion

#region castling

func can_castle(is_white: bool, kingside: bool) -> bool:
	if not castling_enabled:
		return false

	if is_white:
		if white_king_moved:
			return false
		if kingside:
			if white_rook_kingside_moved:
				return false
			# Check if the squares between the king and rook are empty and not under attack
			if not are_squares_safe_and_empty(Vector2(4, 0), Vector2(5, 0), Vector2(6, 0)):
				return false
		else:
			if white_rook_queenside_moved:
				return false
			if not are_squares_safe_and_empty(Vector2(4, 0), Vector2(3, 0), Vector2(2, 0)):
				return false
	else:
		if black_king_moved:
			return false
		if kingside:
			if black_rook_kingside_moved:
				return false
			if not are_squares_safe_and_empty(Vector2(4, 7), Vector2(5, 7), Vector2(6, 7)):
				return false
		else:
			if black_rook_queenside_moved:
				return false
			if not are_squares_safe_and_empty(Vector2(4, 7), Vector2(3, 7), Vector2(2, 7)):
				return false
	return true

func handle_castling(piece, from_position: Vector2, to_position: Vector2):
	if piece.name.find("King") != -1:
		if from_position == Vector2(4, 0) and to_position == Vector2(6, 0):  # White kingside castling
			UnitManager.move_rook(Vector2(7, 0), Vector2(5, 0))
		elif from_position == Vector2(4, 0) and to_position == Vector2(2, 0):  # White queenside castling
			UnitManager.move_rook(Vector2(0, 0), Vector2(3, 0))
		elif from_position == Vector2(4, 7) and to_position == Vector2(6, 7):  # Black kingside castling
			UnitManager.move_rook(Vector2(7, 7), Vector2(5, 7))
		elif from_position == Vector2(4, 7) and to_position == Vector2(2, 7):  # Black queenside castling
			UnitManager.move_rook(Vector2(0, 7), Vector2(3, 7))

func handle_en_passant(from_position: Vector2, to_position: Vector2):
	UnitManager.handle_en_passant(from_position, to_position)

#endregion

func are_squares_safe_and_empty(_king_pos: Vector2, square1: Vector2, square2: Vector2) -> bool:
	# Check if the squares are empty
	if BoardManager.is_tile_occupied(int(square1.x), int(square1.y)) or BoardManager.is_tile_occupied(int(square2.x), int(square2.y)):
		return false
	# Check if the king's position is safe (you can implement this logic later)
	# For now, assume it is safe
	return true

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
