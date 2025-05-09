extends Node2D

@onready var undo_button: Button = $CanvasLayer/undo_button
@onready var end_turn_button: Button = $CanvasLayer/end_turn_button
@onready var reload_button: Button = $CanvasLayer/reload_button
@onready var turn_label: Label = $CanvasLayer/turn_label


@onready var value_label: Label = $CanvasLayer/value_label
@onready var piece_shop: VBoxContainer = $CanvasLayer/PieceShop
@onready var inventory: VBoxContainer = $CanvasLayer/Inventory
@onready var wpawn: Button = $CanvasLayer/PieceShop/HBoxContainer/wpawn
@onready var wking: Button = $CanvasLayer/PieceShop/HBoxContainer/wking
@onready var wknight: Button = $CanvasLayer/PieceShop/HBoxContainer/wknight
@onready var wbishop: Button = $CanvasLayer/PieceShop/HBoxContainer/wbishop
@onready var wrook: Button = $CanvasLayer/PieceShop/HBoxContainer/wrook
@onready var wqueen: Button = $CanvasLayer/PieceShop/HBoxContainer/wqueen
@onready var iwpawn: Button = $CanvasLayer/Inventory/iwpawn
@onready var iwking: Button = $CanvasLayer/Inventory/iwking
@onready var iwknight: Button = $CanvasLayer/Inventory/iwknight
@onready var iwbishop: Button = $CanvasLayer/Inventory/iwbishop
@onready var iwrook: Button = $CanvasLayer/Inventory/iwrook
@onready var iwqueen: Button = $CanvasLayer/Inventory/iwqueen
@onready var moves_left_label: Label = $CanvasLayer/MovesLeftLabel

@onready var place_units_button: Button = $CanvasLayer/PlaceUnitsButton
@onready var start: Button = $CanvasLayer/Start
@onready var back_to_shop: Button = $CanvasLayer/BackToShop

@onready var info_panel: Panel = $InfoPanel
@onready var info_text: RichTextLabel = $InfoPanel/MarginContainer/InfoText

@onready var save_button: Button = $CanvasLayer2/SaveButton
@onready var load_button: Button = $CanvasLayer2/LoadButton
@onready var current_map: Label = $CanvasLayer2/CurrentMap
@onready var switch_to: Button = $CanvasLayer2/switchTo


func _ready():
	# Wait for BoardManager to be initialized
	await get_tree().process_frame
	TurnManager.connect("turn_ended", Callable(self, "update_turn_label"))

	# Set the current_map label to the name of the current scene
	current_map.text = "Current Map: " + get_tree().current_scene.name

	# Set the switch button text based on the current scene
	var scene_name = get_tree().current_scene.name
	if scene_name == "Map1":
		switch_to.text = "Switch to Home"
	elif scene_name == "Home1":
		switch_to.text = "Switch to Map"

	# Auto-load the save file for this scene on enter
	var _scene_name = get_tree().current_scene.name
	if _scene_name == "Map1":
		if get_tree().current_scene.has_method("load_map_1"):
			get_tree().current_scene.load_map_1()
	elif _scene_name == "Home1":
		if get_tree().current_scene.has_method("load_map_1"):
			get_tree().current_scene.load_map_1()

func _on_scene_changed():
	_update_switch_button_text()

func _update_switch_button_text():
	var scene_name = get_tree().current_scene.name
	if scene_name == "map_1":
		switch_to.text = "Switch to Home"
	elif scene_name == "home1":
		switch_to.text = "Switch to Map"

func _on_end_turn_button_pressed() -> void:
	# Reset en_passant variables
	if TurnManager.is_white_turn:
		Rules.en_passant_capture_white = false
		TurnManager.post_move_attack_pending = false
	else:
		Rules.en_passant_capture_black = false
	BoardManager.deselect_piece()
	TurnManager.end_turn()

func _on_reload_button_pressed() -> void:
	# Show the main menu buttons
	GameManager.reset_game_state()
	BoardManager.remove_all_pieces()
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func update_turn_label(is_white_turn = null):
	if is_white_turn == null:
		is_white_turn = TurnManager.is_white_turn
	if is_white_turn:
		turn_label.text = "White's turn"
	else:
		turn_label.text = "Black's turn"

func set_value_label(value):
	if value_label:
		value_label.text = "Value: %s" % str(value)
	else:
		print("[MapUI] Warning: value_label is null when trying to set value label.")

func _set_inventory_button_text(button: Button, value):
	if button:
		button.text = str(value)

# Safely get a property from a node if it exists
func get_node_property(node: Object, property_name: String, default_value = null):
	if node and property_name in node:
		return node.get(property_name)
	return default_value

# Helper to get the current map node from the tab container
func get_current_map_node():
	# CentralMap1 is the parent of MapUi
	var central_map = get_parent()
	if not central_map:
		return null
	if not central_map.has_node("MainTabs"):
		return null
	var main_tabs = central_map.get_node("MainTabs")
	var tab_idx = main_tabs.current_tab
	if tab_idx == 0:
		# Map1 tab
		if main_tabs.has_node("Map1Panel/Map1"):
			return main_tabs.get_node("Map1Panel/Map1")
	elif tab_idx == 1:
		# Home1 tab
		if main_tabs.has_node("Home1Panel/Home1"):
			return main_tabs.get_node("Home1Panel/Home1")
	return null

# Helper to decrement inventory and spend value for a piece type
func decrement_inventory_and_spend_value(piece_type: String):
	var map_node = get_current_map_node()
	if not map_node:
		return
	match piece_type:
		"WhitePawn":
			if "iwpawn_count" in map_node:
				map_node.iwpawn_count -= 1
				_set_inventory_button_text(iwpawn, map_node.iwpawn_count)
			if "current_value" in map_node:
				map_node.current_value -= 1
		"WhiteKnight":
			if "iwknight_count" in map_node:
				map_node.iwknight_count -= 1
				_set_inventory_button_text(iwknight, map_node.iwknight_count)
			if "current_value" in map_node:
				map_node.current_value -= 3
		"WhiteBishop":
			if "iwbishop_count" in map_node:
				map_node.iwbishop_count -= 1
				_set_inventory_button_text(iwbishop, map_node.iwbishop_count)
			if "current_value" in map_node:
				map_node.current_value -= 4
		"WhiteRook":
			if "iwrook_count" in map_node:
				map_node.iwrook_count -= 1
				_set_inventory_button_text(iwrook, map_node.iwrook_count)
			if "current_value" in map_node:
				map_node.current_value -= 5
		"WhiteQueen":
			if "iwqueen_count" in map_node:
				map_node.iwqueen_count -= 1
				_set_inventory_button_text(iwqueen, map_node.iwqueen_count)
			if "current_value" in map_node:
				map_node.current_value -= 9
		"WhiteKing":
			if "iwking_count" in map_node:
				map_node.iwking_count -= 1
				_set_inventory_button_text(iwking, map_node.iwking_count)
			if "current_value" in map_node:
				map_node.current_value -= 2
	set_value_label(get_node_property(map_node, "current_value", 0))

# Helper to increment inventory and refund value for a piece type
func increment_inventory_and_refund_value(piece_type: String):
	var map_node = get_current_map_node()
	if not map_node:
		return
	match piece_type:
		"white_pawn":
			if "iwpawn_count" in map_node:
				map_node.iwpawn_count += 1
				_set_inventory_button_text(iwpawn, map_node.iwpawn_count)
			if "current_value" in map_node:
				map_node.current_value += 1
		"white_knight":
			if "iwknight_count" in map_node:
				map_node.iwknight_count += 1
				_set_inventory_button_text(iwknight, map_node.iwknight_count)
			if "current_value" in map_node:
				map_node.current_value += 3
		"white_bishop":
			if "iwbishop_count" in map_node:
				map_node.iwbishop_count += 1
				_set_inventory_button_text(iwbishop, map_node.iwbishop_count)
			if "current_value" in map_node:
				map_node.current_value += 4
		"white_rook":
			if "iwrook_count" in map_node:
				map_node.iwrook_count += 1
				_set_inventory_button_text(iwrook, map_node.iwrook_count)
			if "current_value" in map_node:
				map_node.current_value += 5
		"white_queen":
			if "iwqueen_count" in map_node:
				map_node.iwqueen_count += 1
				_set_inventory_button_text(iwqueen, map_node.iwqueen_count)
			if "current_value" in map_node:
				map_node.current_value += 9
		"white_king":
			if "iwking_count" in map_node:
				map_node.iwking_count += 1
				_set_inventory_button_text(iwking, map_node.iwking_count)
			if "current_value" in map_node:
				map_node.current_value += 2
	set_value_label(get_node_property(map_node, "current_value", 0))

#region Shop

func _on_wpawn_pressed() -> void:
	var map_node = get_current_map_node()
	var current_value = get_node_property(map_node, "current_value", 0)
	if current_value > 0:
		if "current_value" in map_node:
			map_node.current_value -= 1
		if "iwpawn_count" in map_node:
			map_node.iwpawn_count += 1
		_set_inventory_button_text(iwpawn, get_node_property(map_node, "iwpawn_count", 0))
		set_value_label(get_node_property(map_node, "current_value", 0))

func _on_wking_pressed() -> void:
	var map_node = get_current_map_node()
	var current_value = get_node_property(map_node, "current_value", 0)
	if current_value > 1:
		if "current_value" in map_node:
			map_node.current_value -= 2
		if "iwking_count" in map_node:
			map_node.iwking_count += 1
		_set_inventory_button_text(iwking, get_node_property(map_node, "iwking_count", 0))
		set_value_label(get_node_property(map_node, "current_value", 0))

func _on_wknight_pressed() -> void:
	var map_node = get_current_map_node()
	var current_value = get_node_property(map_node, "current_value", 0)
	if current_value > 2:
		if "current_value" in map_node:
			map_node.current_value -= 3
		if "iwknight_count" in map_node:
			map_node.iwknight_count += 1
		_set_inventory_button_text(iwknight, get_node_property(map_node, "iwknight_count", 0))
		set_value_label(get_node_property(map_node, "current_value", 0))

func _on_wbishop_pressed() -> void:
	var map_node = get_current_map_node()
	var current_value = get_node_property(map_node, "current_value", 0)
	if current_value > 3:
		if "current_value" in map_node:
			map_node.current_value -= 4
		if "iwbishop_count" in map_node:
			map_node.iwbishop_count += 1
		_set_inventory_button_text(iwbishop, get_node_property(map_node, "iwbishop_count", 0))
		set_value_label(get_node_property(map_node, "current_value", 0))

func _on_wrook_pressed() -> void:
	var map_node = get_current_map_node()
	var current_value = get_node_property(map_node, "current_value", 0)
	if current_value > 4:
		if "current_value" in map_node:
			map_node.current_value -= 5
		if "iwrook_count" in map_node:
			map_node.iwrook_count += 1
		_set_inventory_button_text(iwrook, get_node_property(map_node, "iwrook_count", 0))
		set_value_label(get_node_property(map_node, "current_value", 0))

func _on_wqueen_pressed() -> void:
	var map_node = get_current_map_node()
	var current_value = get_node_property(map_node, "current_value", 0)
	if current_value > 8:
		if "current_value" in map_node:
			map_node.current_value -= 9
		if "iwqueen_count" in map_node:
			map_node.iwqueen_count += 1
		_set_inventory_button_text(iwqueen, get_node_property(map_node, "iwqueen_count", 0))
		set_value_label(get_node_property(map_node, "current_value", 0))

#endregion

#region Inventory

func _on_iwpawn_pressed() -> void:
	var map_node = get_current_map_node()
	var iwpawn_count = get_node_property(map_node, "iwpawn_count", 0)
	if get_node_property(map_node, "inventory_locked", false):
		if iwpawn_count > 0:
			Input.set_custom_mouse_cursor(load("res://Assets/pieces/white/white_pawn.png"))
			if "selected_inventory_piece" in map_node:
				map_node.selected_inventory_piece = "WhitePawn"
			return
	if iwpawn_count > 0:
		if "current_value" in map_node:
			map_node.current_value += 1
		if "iwpawn_count" in map_node:
			map_node.iwpawn_count -= 1
		_set_inventory_button_text(iwpawn, get_node_property(map_node, "iwpawn_count", 0))
		set_value_label(get_node_property(map_node, "current_value", 0))

func _on_iwking_pressed() -> void:
	var map_node = get_current_map_node()
	var iwking_count = get_node_property(map_node, "iwking_count", 0)
	if get_node_property(map_node, "inventory_locked", false):
		if iwking_count > 0:
			Input.set_custom_mouse_cursor(load("res://Assets/pieces/white/white_king.png"))
			if "selected_inventory_piece" in map_node:
				map_node.selected_inventory_piece = "WhiteKing"
			return
	if iwking_count > 0:
		if "current_value" in map_node:
			map_node.current_value += 2
		if "iwking_count" in map_node:
			map_node.iwking_count -= 1
		_set_inventory_button_text(iwking, get_node_property(map_node, "iwking_count", 0))
		set_value_label(get_node_property(map_node, "current_value", 0))

func _on_iwknight_pressed() -> void:
	var map_node = get_current_map_node()
	var iwknight_count = get_node_property(map_node, "iwknight_count", 0)
	if get_node_property(map_node, "inventory_locked", false):
		if iwknight_count > 0:
			Input.set_custom_mouse_cursor(load("res://Assets/pieces/white/white_knight.png"))
			if "selected_inventory_piece" in map_node:
				map_node.selected_inventory_piece = "WhiteKnight"
			return
	if iwknight_count > 0:
		if "current_value" in map_node:
			map_node.current_value += 3
		if "iwknight_count" in map_node:
			map_node.iwknight_count -= 1
		_set_inventory_button_text(iwknight, get_node_property(map_node, "iwknight_count", 0))
		set_value_label(get_node_property(map_node, "current_value", 0))

func _on_iwbishop_pressed() -> void:
	var map_node = get_current_map_node()
	var iwbishop_count = get_node_property(map_node, "iwbishop_count", 0)
	if get_node_property(map_node, "inventory_locked", false):
		if iwbishop_count > 0:
			Input.set_custom_mouse_cursor(load("res://Assets/pieces/white/white_bishop.png"))
			if "selected_inventory_piece" in map_node:
				map_node.selected_inventory_piece = "WhiteBishop"
			return
	if iwbishop_count > 0:
		if "current_value" in map_node:
			map_node.current_value += 4
		if "iwbishop_count" in map_node:
			map_node.iwbishop_count -= 1
		_set_inventory_button_text(iwbishop, get_node_property(map_node, "iwbishop_count", 0))
		set_value_label(get_node_property(map_node, "current_value", 0))

func _on_iwrook_pressed() -> void:
	var map_node = get_current_map_node()
	var iwrook_count = get_node_property(map_node, "iwrook_count", 0)
	if get_node_property(map_node, "inventory_locked", false):
		if iwrook_count > 0:
			Input.set_custom_mouse_cursor(load("res://Assets/pieces/white/white_rook.png"))
			if "selected_inventory_piece" in map_node:
				map_node.selected_inventory_piece = "WhiteRook"
			return
	if iwrook_count > 0:
		if "current_value" in map_node:
			map_node.current_value += 5
		if "iwrook_count" in map_node:
			map_node.iwrook_count -= 1
		_set_inventory_button_text(iwrook, get_node_property(map_node, "iwrook_count", 0))
		set_value_label(get_node_property(map_node, "current_value", 0))

func _on_iwqueen_pressed() -> void:
	var map_node = get_current_map_node()
	var iwqueen_count = get_node_property(map_node, "iwqueen_count", 0)
	if get_node_property(map_node, "inventory_locked", false):
		if iwqueen_count > 0:
			Input.set_custom_mouse_cursor(load("res://Assets/pieces/white/white_queen.png"))
			if "selected_inventory_piece" in map_node:
				map_node.selected_inventory_piece = "WhiteQueen"
			return
	if iwqueen_count > 0:
		if "current_value" in map_node:
			map_node.current_value += 9
		if "iwqueen_count" in map_node:
			map_node.iwqueen_count -= 1
		_set_inventory_button_text(iwqueen, get_node_property(map_node, "iwqueen_count", 0))
		set_value_label(get_node_property(map_node, "current_value", 0))

#endregion


func _on_place_units_button_pressed() -> void:
	var map_node = get_current_map_node()
	if "inventory_locked" in map_node:
		map_node.inventory_locked = true
	piece_shop.visible = false
	place_units_button.visible = false
	start.visible = true
	back_to_shop.visible = true
	BoardManager.selecting_ok = true

func _on_back_to_shop_pressed() -> void:
	piece_shop.visible = true
	place_units_button.visible = true
	start.visible = false
	back_to_shop.visible = false
	var map_node = get_current_map_node()
	if "inventory_locked" in map_node:
		map_node.inventory_locked = false
	BoardManager.selecting_ok = false

func _on_start_pressed() -> void:
	track_moves_left_label()
	var map_node = get_current_map_node()
	if map_node and "start_pressed_once" in map_node:
		map_node.start_pressed_once = true
	piece_shop.visible = false
	start.visible = false
	place_units_button.visible = false
	inventory.visible = false
	if map_node and "inventory_locked" in map_node:
		map_node.inventory_locked = false
	if map_node and "shopping" in map_node:
		map_node.shopping = false
	back_to_shop.visible = false
	BoardManager.clear_custom_highlights_color(Color(0, 0, 1, 0.5))
	BoardManager.clear_custom_highlights_color(Color(1, 0, 0, 0.5))
	BoardManager.selecting_ok = true
	TurnManager.update_max_moves_per_turn()


func _on_save_button_pressed() -> void:
	var scene_name = get_tree().current_scene.name
	print("Current scene name: ", scene_name) # Debug!
	if scene_name == "Map1":
		var map_node = get_tree().current_scene
		map_node.save_map_1()

func _on_load_button_pressed() -> void:
	var scene_name = get_tree().current_scene.name
	if scene_name == "Map1":
		var map_node = get_tree().current_scene
		map_node.load_map_1()

func _on_switch_to_pressed() -> void:
	var _scene_name = get_tree().current_scene.name
	if _scene_name == "Map1":
		var map_node = get_tree().current_scene
		if map_node.has_method("save_map_1"):
			map_node.save_map_1()
		GameManager.reset_game_state()
		BoardManager.remove_all_pieces()
		get_tree().change_scene_to_file("res://Scenes/UI/MapSelect.tscn")
	elif _scene_name == "Home1":
		var map_node = get_tree().current_scene
		if map_node.has_method("save_map_1"):
			map_node.save_map_1()
		GameManager.reset_game_state()
		BoardManager.remove_all_pieces()
		get_tree().change_scene_to_file("res://Scenes/UI/MapSelect.tscn")


func _on_reset_button_pressed() -> void:
	var map_node = get_tree().current_scene
	if map_node.has_method("reset_to_starting_values"):
		map_node.reset_to_starting_values()
		GameManager.reset_game_state()
		TurnManager.initialize()
		TurnManager.is_white_turn = true
		BoardManager.initialize()
		BoardManager.clear_custom_highlights()

func track_moves_left_label():
	var map_node = get_current_map_node()
	if TurnManager.is_white_turn:
		moves_left_label.text = "Moves Left: %s" % str(TurnManager.max_moves_per_turn_white - TurnManager.moves_this_turn_white)
	else:
		moves_left_label.text = "Moves Left: %s" % str(TurnManager.max_moves_per_turn_black	- TurnManager.moves_this_turn_black)

func set_shop_and_place_unit_visible(is_shop_visible: bool):
	var map_node = get_current_map_node()
	# Use 'if "start_pressed_once" in map_node' instead of has_variable
	if map_node and "start_pressed_once" in map_node and map_node.start_pressed_once:
		is_shop_visible = false
	if piece_shop:
		piece_shop.visible = is_shop_visible
	if place_units_button:
		place_units_button.visible = is_shop_visible
	if start:
		start.visible = false
	if back_to_shop:
		back_to_shop.visible = false
