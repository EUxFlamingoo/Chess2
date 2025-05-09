extends Node2D

@onready var main_tabs = $MainTabs
@onready var map_1_button: Button = $CanvasLayer/Map1Button
@onready var home_1_button: Button = $CanvasLayer/Home1Button

func _ready():
	main_tabs.set_tab_title(0, "Map 1")
	main_tabs.set_tab_title(1, "Home 1")
	main_tabs.current_tab = 1 # Open Home1 as the default tab

	# Set initial shop UI visibility based on default tab
	var map_ui = $MapUi
	if map_ui:
		map_ui.set_shop_and_place_unit_visible(false) # Home1 is default

	# Connect the new tab bar buttons to tab switching
	map_1_button.pressed.connect(_on_map_1_button_pressed)
	home_1_button.pressed.connect(_on_home_1_button_pressed)

	# Connect tab_changed signal to handle tab switching logic
	main_tabs.tab_changed.connect(_on_tab_changed)

func _on_map_1_button_pressed() -> void:
	main_tabs.current_tab = 0

func _on_home_1_button_pressed() -> void:
	main_tabs.current_tab = 1

func _on_tab_changed(tab_idx: int) -> void:
	var map_ui = $MapUi
	var map1 = $MainTabs/Map1Panel/Map1
	var home1 = $MainTabs/Home1Panel/Home1
	if tab_idx == 0:
		# Map1 tab selected
		if map_ui:
			map_ui.set_shop_and_place_unit_visible(true)
		if map1:
			map1.input_enabled = true
		if home1:
			home1.input_enabled = false
		if map1.has_method("on_tab_selected"):
			map1.on_tab_selected()
	elif tab_idx == 1:
		# Home1 tab selected
		if map_ui:
			map_ui.set_shop_and_place_unit_visible(false)
		if map1:
			map1.input_enabled = false
		if home1:
			home1.input_enabled = true
		if home1.has_method("on_tab_selected"):
			home1.on_tab_selected()
