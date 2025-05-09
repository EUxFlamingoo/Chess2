extends Node2D

@onready var piece_promotion: VBoxContainer = $CanvasLayer/PiecePromotion

@onready var wpawn: Button = $CanvasLayer/PiecePromotion/HBoxContainer/wpawn
@onready var wking: Button = $CanvasLayer/PiecePromotion/HBoxContainer/wking
@onready var wknight: Button = $CanvasLayer/PiecePromotion/HBoxContainer/wknight
@onready var wbishop: Button = $CanvasLayer/PiecePromotion/HBoxContainer/wbishop
@onready var wrook: Button = $CanvasLayer/PiecePromotion/HBoxContainer/wrook
@onready var wqueen: Button = $CanvasLayer/PiecePromotion/HBoxContainer/wqueen


func _on_wpawn_pressed() -> void:
	get_parent().promote_to("WhitePawn")
	BoardManager.selecting_ok = true

func _on_wking_pressed() -> void:
	get_parent().promote_to("WhiteKing")
	BoardManager.selecting_ok = true

func _on_wknight_pressed() -> void:
	get_parent().promote_to("WhiteKnight")
	BoardManager.selecting_ok = true

func _on_wbishop_pressed() -> void:
	get_parent().promote_to("WhiteBishop")
	BoardManager.selecting_ok = true

func _on_wrook_pressed() -> void:
	get_parent().promote_to("WhiteRook")
	BoardManager.selecting_ok = true

func _on_wqueen_pressed() -> void:
	get_parent().promote_to("WhiteQueen")
	BoardManager.selecting_ok = true
