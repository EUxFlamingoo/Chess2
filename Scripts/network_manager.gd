extends Node

const PORT = 135
@export var player_scene: PackedScene

var peer = ENetMultiplayerPeer.new()

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)

func host_game():
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	_add_player()
	if multiplayer.get_unique_id() == 1:
		Rules.player_is_white = true
	else:
		Rules.player_is_white = false
	print(multiplayer.get_unique_id())

func join_game():
	peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = peer
	Rules.player_is_white = false
	print(multiplayer.get_unique_id())

func _add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id):
	rpc("_del_player", id)

@rpc("any_peer", "call_local") func _del_player(id):
	get_node(str(id)).queue_free()

func _on_peer_connected(id):
	if multiplayer.is_server():
		var state = get_board_state_as_array()
		rpc_id(id, "receive_full_board_state", state, TurnManager.is_white_turn)

@rpc("any_peer")
func receive_full_board_state(state: Array, is_white_turn: bool):
	BoardManager.can_select_piece = false
	BoardManager.remove_all_pieces()
	for piece_data in state:
		UnitManager.place_piece_by_name(piece_data["type"], piece_data["x"], piece_data["y"])
	TurnManager.is_white_turn = is_white_turn
	BoardManager.deselect_piece()
	BoardManager.can_select_piece = true

func get_board_state_as_array() -> Array:
	var state = []
	for y in range(BoardManager.BOARD_HEIGHT):
		for x in range(BoardManager.BOARD_WIDTH):
			var piece = BoardManager.board_state[y][x]
			if piece:
				state.append({
					"type": piece.name, # or a custom type identifier
					"x": x,
					"y": y
				})
	return state

func can_local_player_move() -> bool:
	if not GameManager.online_enabled:
		return true
	return (TurnManager.is_white_turn and multiplayer.get_unique_id() == 1) or \
		(not TurnManager.is_white_turn and multiplayer.get_unique_id() != 1)

@rpc("any_peer")
func remote_move(from_pos: Vector2, to_pos: Vector2):
	var piece = BoardManager.board_state[from_pos.y][from_pos.x]
	var moves = MoveManager.get_valid_moves(piece, int(from_pos.x), int(from_pos.y))
	if to_pos in moves:
		MoveManager.move_piece(piece, from_pos, to_pos)
		TurnManager.moves_this_turn += 1
		TurnManager.check_turn_end()
	else:
		print("Invalid move from client: ", from_pos, " -> ", to_pos)
	# Always send the board state back, valid or not
	var state = get_board_state_as_array()
	for peer_id in multiplayer.get_peers():
		if peer_id != multiplayer.get_unique_id():
			rpc_id(peer_id, "receive_full_board_state", state, TurnManager.is_white_turn)
