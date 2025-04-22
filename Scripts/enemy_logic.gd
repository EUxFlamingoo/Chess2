extends Node

func make_random_move():
	var ai_is_white = not Rules.player_is_white
	var all_moves = MoveManager.get_all_valid_moves(ai_is_white)
	if all_moves.size() == 0:
		print("No valid moves for enemy!")
		return
	var move_data = all_moves[randi() % all_moves.size()]
	var piece = move_data["piece"]
	var from_pos = move_data["position"]
	var moves = move_data["moves"]
	var to_pos = moves[randi() % moves.size()]
	print("make random move")
	MoveManager.move_piece(piece, from_pos, to_pos)
	TurnManager.moves_this_turn += 1
	TurnManager.check_turn_end()

func make_no_risk_move():
	var ai_is_white = not Rules.player_is_white
	var all_moves = MoveManager.get_all_valid_moves(ai_is_white)
	var safe_moves = []
	for move_data in all_moves:
		var piece = move_data["piece"]
		var from_pos = move_data["position"]
		for to_pos in move_data["moves"]:
			var captured_piece = MoveManager.simulate_move(from_pos, to_pos)
			var attackers = MoveManager.get_attackers(to_pos, not ai_is_white)
			var pawn_attack = is_square_attacked_by_pawn(to_pos, not ai_is_white)
			MoveManager.revert_move(from_pos, to_pos, captured_piece)
			# Only add the move if the destination is not threatened (including pawns)
			if attackers.size() == 0 and not pawn_attack and not exposes_more_valuable_piece(from_pos, to_pos, UnitManager.get_piece_value(piece)):
				safe_moves.append({ "piece": piece, "from": from_pos, "to": to_pos })
	if safe_moves.size() > 0:
		var chosen = safe_moves[randi() % safe_moves.size()]
		MoveManager.move_piece(chosen["piece"], chosen["from"], chosen["to"])
		TurnManager.moves_this_turn += 1
		TurnManager.check_turn_end()
		print("taking no risks.")
	else:
		make_random_move()

func make_greed_move():
	var ai_is_white = not Rules.player_is_white
	var all_moves = MoveManager.get_all_valid_moves(ai_is_white)
	if all_moves.size() == 0:
		print("No valid moves for enemy!")
		return
	var best_value = -1
	var best_moves = []
	for move_data in all_moves:
		var current_piece = move_data["piece"]
		var current_from_pos = move_data["position"]
		var current_piece_value = UnitManager.get_piece_value(current_piece)
		for to_pos in move_data["moves"]:
			if BoardManager.is_tile_occupied(to_pos.x, to_pos.y):
				var target_piece = BoardManager.board_state[to_pos.y][to_pos.x]
				var target_value = UnitManager.get_piece_value(target_piece)
				# Simulate the capture
				var captured_piece = MoveManager.simulate_move(current_from_pos, to_pos)
				var attackers = MoveManager.get_attackers(to_pos, not ai_is_white)
				var pawn_attack = is_square_attacked_by_pawn(to_pos, not ai_is_white)
				MoveManager.revert_move(current_from_pos, to_pos, captured_piece)
				var safe_capture = attackers.size() == 0 and not pawn_attack
				var worth_it = target_value >= current_piece_value
				if safe_capture or worth_it:
					if target_value > best_value:
						best_value = target_value
						best_moves = [{ "piece": current_piece, "from": current_from_pos, "to": to_pos }]
					elif target_value == best_value and target_value > 0:
						best_moves.append({ "piece": current_piece, "from": current_from_pos, "to": to_pos })
	if best_moves.size() > 0:
		var chosen = best_moves[randi() % best_moves.size()]
		MoveManager.move_piece(chosen["piece"], chosen["from"], chosen["to"])
		TurnManager.moves_this_turn += 1
		TurnManager.check_turn_end()
		print("make greedy move")
		return
	make_no_risk_move()

func make_defensive_move():
	var ai_is_white = not Rules.player_is_white
	var threatened = get_threatened_pieces(ai_is_white)
	if threatened.size() == 0:
		make_greed_move()
		return
	threatened.sort_custom(func(a, b): return b["value"] - a["value"])
	for threat in threatened:
		var piece = threat["piece"]
		var from_pos = threat["position"]
		var attackers = threat["attackers"]
		var value = threat["value"]
		var capture_found = false
		for attacker in attackers:
			var capture = can_capture_attacker(piece, attacker)
			if capture:
				print("Defending by capture: ", piece.name, " at ", from_pos, " captures ", attacker["piece"].name, " at ", attacker["position"])
				MoveManager.move_piece(capture["piece"], capture["from"], capture["to"])
				TurnManager.moves_this_turn += 1
				TurnManager.check_turn_end()
				print("defended by capture")
				return
			else:
				print("Capture not possible or not safe for ", piece.name, " at ", from_pos, " against ", attacker["piece"].name, " at ", attacker["position"])
		var evade = can_evade_threat(piece, from_pos)
		if evade:
			print("Defending by evasion: ", piece.name, " at ", from_pos, " moves to ", evade["to"])
			MoveManager.move_piece(evade["piece"], evade["from"], evade["to"])
			TurnManager.moves_this_turn += 1
			TurnManager.check_turn_end()
			print("defended by evasion")
			return
		for attacker in attackers:
			var block = can_block_attack(attacker, from_pos, value)
			if block:
				print("Defending by blocking: ", block["piece"].name, " at ", block["from"], " moves to ", block["to"])
				MoveManager.move_piece(block["piece"], block["from"], block["to"])
				TurnManager.moves_this_turn += 1
				TurnManager.check_turn_end()
				print("defended by blocking")
				return
	print("nothing to defend or defense failed")
	make_greed_move()

func get_threatened_pieces(is_white: bool) -> Array:
	var threatened = []
	for y in range(BoardManager.BOARD_HEIGHT):
		for x in range(BoardManager.BOARD_WIDTH):
			if BoardManager.is_tile_occupied(x, y):
				var piece = BoardManager.board_state[y][x]
				if piece.name.begins_with("White") == is_white:
					var pos = Vector2(x, y)
					var attackers = get_attackers(pos, not is_white)
					if attackers.size() > 0:
						threatened.append({
							"piece": piece,
							"position": pos,
							"value": UnitManager.get_piece_value(piece),
							"attackers": attackers
						})
	return threatened

# In move_manager.gd
func get_attackers(pos: Vector2, by_white: bool) -> Array:
	var attackers = []
	for y in range(BoardManager.BOARD_HEIGHT):
		for x in range(BoardManager.BOARD_WIDTH):
			if BoardManager.is_tile_occupied(x, y):
				var piece = BoardManager.board_state[y][x]
				if piece.name.begins_with("White") == by_white:
					var moves = MoveManager.get_valid_moves(piece, x, y, true)
					if pos in moves:
						attackers.append({"piece": piece, "position": Vector2(x, y), "value": UnitManager.get_piece_value(piece)})
	return attackers

# In enemy_logic.gd
func can_capture_attacker(threatened_piece, attacker) -> Dictionary:
	var ai_is_white = not Rules.player_is_white
	var all_moves = MoveManager.get_all_valid_moves(ai_is_white)
	var own_value = UnitManager.get_piece_value(threatened_piece)
	for move_data in all_moves:
		if move_data["piece"] == threatened_piece:
			for move in move_data["moves"]:
				if move == attacker["position"]:
					var captured_piece = MoveManager.simulate_move(move_data["position"], move)
					var attackers = MoveManager.get_attackers(move, not ai_is_white)
					var pawn_attack = is_square_attacked_by_pawn(move, not ai_is_white)
					MoveManager.revert_move(move_data["position"], move, captured_piece)
					if attackers.size() == 0 and not pawn_attack:
						if not exposes_more_valuable_piece(move_data["position"], move, own_value):
							return {"piece": threatened_piece, "from": move_data["position"], "to": move}
	return {}

# In enemy_logic.gd
func can_evade_threat(threatened_piece, from_pos) -> Dictionary:
	var ai_is_white = not Rules.player_is_white
	var all_moves = MoveManager.get_all_valid_moves(ai_is_white)
	var own_value = UnitManager.get_piece_value(threatened_piece)
	for move_data in all_moves:
		if move_data["piece"] == threatened_piece:
			for move in move_data["moves"]:
				var attackers = MoveManager.get_attackers(move, not ai_is_white)
				var pawn_attack = is_square_attacked_by_pawn(move, not ai_is_white)
				if attackers.size() == 0 and not pawn_attack:
					if not exposes_more_valuable_piece(from_pos, move, own_value):
						return {"piece": threatened_piece, "from": from_pos, "to": move}
	return {}

# In enemy_logic.gd
func can_block_attack(attacker, target_pos, threatened_value) -> Dictionary:
	var ai_is_white = not Rules.player_is_white
	var all_moves = MoveManager.get_all_valid_moves(ai_is_white)
	for move_data in all_moves:
		var piece = move_data["piece"]
		if piece == attacker["piece"]:
			continue
		var piece_value = UnitManager.get_piece_value(piece)
		if piece_value >= threatened_value:
			continue
		for move in move_data["moves"]:
			if is_between(attacker["position"], target_pos, move):
				if not exposes_more_valuable_piece(move_data["position"], move, piece_value):
					return {"piece": piece, "from": move_data["position"], "to": move}
	return {}

# Helper to check if a square is between attacker and target (for sliding pieces)
func is_between(attacker_pos: Vector2, target_pos: Vector2, block_pos: Vector2) -> bool:
	var dir = (target_pos - attacker_pos).normalized()
	var pos = attacker_pos + dir
	while pos != target_pos:
		if pos == block_pos:
			return true
		pos += dir
	return false

func exposes_more_valuable_piece(move_from: Vector2, move_to: Vector2, own_piece_value: int) -> bool:
	var captured_piece = MoveManager.simulate_move(move_from, move_to)
	var threatened = get_threatened_pieces(false)
	var result = false
	for t in threatened:
		if t["value"] > own_piece_value:
			result = true
			break
	MoveManager.revert_move(move_from, move_to, captured_piece)
	return result

func is_square_attacked_by_pawn(pos: Vector2, by_white: bool) -> bool:
	var direction = -1 if by_white else 1
	for dx in [-1, 1]:
		var px = pos.x + dx
		var py = pos.y + direction
		if BoardManager.is_within_board(px, py):
			var piece = BoardManager.board_state[py][px]
			if piece != null and piece.name.find("Pawn") != -1 and piece.name.begins_with("White") == by_white:
				return true
	return false
