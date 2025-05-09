extends Node

const PieceSerializer = preload("res://Scripts/misc/piece_serializer.gd")

static func get_all_pieces_data(board_state: Array) -> Array:
	var pieces = []
	for y in range(board_state.size()):
		for x in range(board_state[y].size()):
			var piece = board_state[y][x]
			if piece:
				pieces.append(PieceSerializer.to_dict(piece, x, y))
	return pieces

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
		var new_piece = PieceSerializer.from_dict(data)
		if new_piece:
			var x = int(data["x"])
			var y = int(data["y"])
			board_state[y][x] = new_piece
