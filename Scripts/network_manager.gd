extends Node

const PORT = 12345


var is_host = false
var network_connected = false


func host_game():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	is_host = true
	network_connected = true
	print("Hosting game on port ", PORT)

func join_game(ip_address: String):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, PORT)
	multiplayer.multiplayer_peer = peer
	is_host = false
	network_connected = true
	print("Joining game at ", ip_address, ":", PORT)

# Call this when a move is made locally
func send_move(from: Vector2, to: Vector2):
	rpc("receive_move", from, to)

@rpc("any_peer")
func receive_move(from: Vector2, to: Vector2):
	MoveManager.move_piece_networked(from, to) # Implement this in your MoveManager

func disconnect_network():
	multiplayer.multiplayer_peer = null
	network_connected = false
	is_host = false
	print("Disconnected from network game")

func send_full_board_state():
	var state = BoardManager.get_board_state_as_array()
	print("Host sending board state to clients")
	rpc("receive_full_board_state", state)
	for peer_id in multiplayer.get_peers():
		if peer_id != multiplayer.get_unique_id():
			rpc_id(peer_id, "test_rpc", "hello from host")

@rpc("any_peer")
func receive_full_board_state(state: Array):
	print("Client received board state: ", state)
	BoardManager.remove_all_pieces()
	for piece_data in state:
		UnitManager.place_piece_by_name(piece_data["type"], piece_data["x"], piece_data["y"])

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	set_multiplayer_authority(1) # 1 is usually the host, but try both 1 and your own id

func _on_peer_connected(id):
	if is_host:
		rpc_id(id, "remote_start_game")

@rpc("authority")
func remote_start_game():
	UnitManager.place_starting_pieces()
	TurnManager.initialize()

@rpc("any_peer")
func test_rpc(msg):
	print("RPC received: ", msg)
