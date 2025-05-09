extends Node

const BoardStateManager = preload("res://Scenes/Managers/board_state_manager.gd")

static func save_map(map_node, board_state, save_path="user://map_1_save.sav", save_key="map_1"):
	var save_dict = {
		# Map variables
		"shopping": map_node.shopping,
		"current_value": map_node.current_value,
		"iwpawn_count": map_node.iwpawn_count,
		"iwking_count": map_node.iwking_count,
		"iwknight_count": map_node.iwknight_count,
		"iwbishop_count": map_node.iwbishop_count,
		"iwrook_count": map_node.iwrook_count,
		"iwqueen_count": map_node.iwqueen_count,
		"inventory_locked": map_node.inventory_locked,
		"selected_inventory_piece": map_node.selected_inventory_piece,
		"allowed_inventory_tiles": map_node.allowed_inventory_tiles,
		"last_selected_piece": map_node.last_selected_piece,
		# Turn manager state
		"turn_manager": {
			"is_white_turn": TurnManager.is_white_turn,
			"moves_this_turn_white": TurnManager.moves_this_turn_white,
			"moves_this_turn_black": TurnManager.moves_this_turn_black,
			"max_moves_per_turn_white": TurnManager.max_moves_per_turn_white,
			"max_moves_per_turn_black": TurnManager.max_moves_per_turn_black
		},
		# Pieces
		"pieces": BoardStateManager.get_all_pieces_data(board_state)
	}
	SaveSystem.set_var(save_key, save_dict)
	SaveSystem.save(save_path)

static func _has_exported_property(node, prop_name):
	for prop in node.get_property_list():
		if prop.name == prop_name:
			return true
	return false

static func load_map(map_node, board_state, save_path="user://map_1_save.sav", save_key="map_1"):
	var save_dict = SaveSystem.get_var(save_key, null)
	if not save_dict:
		return

	# Restore map variables (only if the property exists on the map_node)
	if _has_exported_property(map_node, "shopping"):
		map_node.shopping = save_dict.get("shopping", true)
	if _has_exported_property(map_node, "current_value"):
		map_node.current_value = int(save_dict.get("current_value", 0))
	if _has_exported_property(map_node, "iwpawn_count"):
		map_node.iwpawn_count = int(save_dict.get("iwpawn_count", 0))
	if _has_exported_property(map_node, "iwking_count"):
		map_node.iwking_count = int(save_dict.get("iwking_count", 0))
	if _has_exported_property(map_node, "iwknight_count"):
		map_node.iwknight_count = int(save_dict.get("iwknight_count", 0))
	if _has_exported_property(map_node, "iwbishop_count"):
		map_node.iwbishop_count = int(save_dict.get("iwbishop_count", 0))
	if _has_exported_property(map_node, "iwrook_count"):
		map_node.iwrook_count = int(save_dict.get("iwrook_count", 0))
	if _has_exported_property(map_node, "iwqueen_count"):
		map_node.iwqueen_count = int(save_dict.get("iwqueen_count", 0))
	if _has_exported_property(map_node, "inventory_locked"):
		map_node.inventory_locked = bool(save_dict.get("inventory_locked", false))
	if _has_exported_property(map_node, "selected_inventory_piece"):
		map_node.selected_inventory_piece = save_dict.get("selected_inventory_piece", null)
	if _has_exported_property(map_node, "allowed_inventory_tiles"):
		map_node.allowed_inventory_tiles = save_dict.get("allowed_inventory_tiles", [])

	var vec = save_dict.get("last_selected_piece", Vector2(-1, -1))
	if typeof(vec) == TYPE_DICTIONARY:
		vec = Vector2(vec["x"], vec["y"])
	elif typeof(vec) == TYPE_ARRAY:
		vec = Vector2(vec[0], vec[1])
	if _has_exported_property(map_node, "last_selected_piece"):
		map_node.last_selected_piece = vec

	# Restore turn manager state
	if save_dict.has("turn_manager"):
		var tm = save_dict["turn_manager"]
		TurnManager.is_white_turn = tm.get("is_white_turn", true)
		TurnManager.moves_this_turn_white = tm.get("moves_this_turn_white", 0)
		TurnManager.moves_this_turn_black = tm.get("moves_this_turn_black", 0)
		TurnManager.max_moves_per_turn_white = tm.get("max_moves_per_turn_white", 1)
		TurnManager.max_moves_per_turn_black = tm.get("max_moves_per_turn_black", 1)
		TurnManager.post_move_attack_pending = false
		TurnManager.update_max_moves_per_turn()

	# Restore board state
	BoardStateManager.restore_from_data(board_state, save_dict.get("pieces", []))

	# Optionally update UI
	if map_node.has_node("MapUi"):
		map_node.get_node("MapUi").set_value_label(map_node.current_value)
	if map_node.has_node("MapUi"):
		map_node.get_node("MapUi").update_turn_label(TurnManager.is_white_turn)
