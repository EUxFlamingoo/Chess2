extends Control

func _enter_tree():
	set_multiplayer_authority(name.to_int())

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Only allow the client to request moves for their own pieces
func on_piece_selected(x: int, y: int):
	var piece = BoardManager.board_state[y][x]
	var is_white_piece = piece.name.begins_with("White")
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		# Only allow selecting own pieces on own turn
		if is_white_piece == Rules.player_is_white and NetworkManager.can_local_player_move():
			NetworkManager.rpc_id(1, "request_valid_moves", x, y)
		else:
			print("Cannot select opponent's piece or not your turn.")
	else:
		# Local or host: highlight locally
		if piece:
			var moves = MoveManager.get_valid_moves(piece, x, y)
			MoveManager.highlight_possible_moves(moves)

# Called when the client receives moves from the host
func highlight_moves_from_network(moves: Array):
	MoveManager.highlight_possible_moves(moves)

func show_promotion_ui(pawn_pos: Vector2, is_white: bool):
	# Show the appropriate promotion buttons for white/black
	if is_white:
		Rules.white_2.visible = true
		Rules.white_3.visible = true
		Rules.white_4.visible = true
		Rules.white_5.visible = true
	else:
		Rules.black_2.visible = true
		Rules.black_3.visible = true
		Rules.black_4.visible = true
		Rules.black_5.visible = true
	Rules.promotion_position = pawn_pos

# When a promotion button is pressed on the client:
func on_promotion_button_pressed(piece_name: String):
	if GameManager.online_enabled and multiplayer.get_unique_id() != 1:
		NetworkManager.rpc_id(1, "promote_pawn_choice", Rules.promotion_position, piece_name)
	else:
		Rules.promote_pawn(piece_name, UnitManager.get_piece_scene(piece_name, TurnManager.is_white_turn))
