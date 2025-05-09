extends Node

static func to_dict(piece: Node, x: int, y: int) -> Dictionary:
	# Use a canonical piece ID for serialization (prefer template_name or UNIT_NAME if available)
	var piece_id = ""
	if "template_name" in piece:
		piece_id = piece.template_name
	elif "UNIT_NAME" in piece:
		piece_id = piece.UNIT_NAME
	else:
		# Fallback: use scene_name logic as before
		piece_id = piece.name
		var parts = piece_id.split("_")
		if parts.size() > 2 and parts[-1].is_valid_int() and parts[-2].is_valid_int():
			piece_id = "_".join(parts.slice(0, parts.size() - 2))
		# Convert snake_case to PascalCase for chess pieces (e.g., black_rook -> BlackRook)
		if piece_id == piece.name:
			var pascal = ""
			for part in piece_id.split("_"):
				if part.length() > 0:
					pascal += part.capitalize()
			piece_id = pascal
	# --- PATCH: Map scene node names to PIECE_SCENES keys for standard pieces ---
	# If the piece is a standard chess piece and the id is e.g. 'black_king', force to 'BlackKing'
	var standard_pieces = ["pawn", "knight", "bishop", "rook", "queen", "king"]
	for suffix in standard_pieces:
		if piece_id.to_lower().ends_with("_" + suffix):
			var parts = piece_id.split("_")
			if parts.size() == 2:
				piece_id = parts[0].capitalize() + suffix.capitalize()
				break
	return {
		"piece_id": piece_id,
		"name": piece.name,
		"x": x,
		"y": y,
		"is_white": "is_white" in piece and piece.is_white or false,
		"moves_made_this_turn": "moves_made_this_turn" in piece and piece.moves_made_this_turn or 0
	}

static func from_dict(data: Dictionary) -> Node:
	var x = int(data.get("x", 0))
	var y = int(data.get("y", 0))
	var piece_id = "WhiteCustomPiece"
	if data.has("piece_id"):
		piece_id = data["piece_id"]
	elif data.has("scene_name"):
		piece_id = data["scene_name"]
	elif data.has("type"):
		piece_id = data["type"]

	# --- PATCH: Map snake_case to PascalCase for standard pieces on load ---
	var standard_pieces = ["pawn", "knight", "bishop", "rook", "queen", "king"]
	for suffix in standard_pieces:
		if piece_id.to_lower().ends_with("_" + suffix):
			var parts = piece_id.split("_")
			if parts.size() == 2:
				piece_id = parts[0].capitalize() + suffix.capitalize()
				break

	# Final debug before instantiation
	print("[PieceSerializer] Instantiating:", piece_id, "at", x, y)

	var new_piece = UnitManager.place_piece_by_name(
		piece_id,
		x,
		y
	)
	if new_piece:
		new_piece.name = data.get("name", "%s_%d_%d" % [piece_id, x, y])
		new_piece.is_white = bool(data.get("is_white", true))
		if new_piece.has_method("update_appearance"):
			new_piece.update_appearance()
		if data.has("moves_made_this_turn"):
			new_piece.moves_made_this_turn = int(data["moves_made_this_turn"])
	return new_piece

static func restore_from_data(board_state: Array, pieces_data: Array):
	# Clear board
	for y in range(board_state.size()):
		for x in range(board_state[y].size()):
			var piece = board_state[y][x]
			if piece:
				piece.queue_free()
			board_state[y][x] = null
	# Place pieces
	for data in pieces_data:
		var new_piece = from_dict(data)
		if new_piece:
			var x = int(data["x"])
			var y = int(data["y"])
			board_state[y][x] = new_piece
			# Ensure the piece is added to the scene tree
			if not new_piece.get_parent():
				BoardManager.add_child(new_piece)
