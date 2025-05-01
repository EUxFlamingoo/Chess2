extends Node

var BishopMoves = preload("res://Scripts/pieces/bishop.gd").new()
var RookMoves = preload("res://Scripts/pieces/rook.gd").new()
var KnightMoves = preload("res://Scripts/pieces/knight.gd").new()
var KingMoves = preload("res://Scripts/pieces/king.gd").new()
var PawnMoves = preload("res://Scripts/pieces/pawn.gd").new()

func get_bishop_moves(x, y, is_white):
	return BishopMoves.get_bishop_moves(x, y, is_white)

func get_rook_moves(x, y, is_white):
	return RookMoves.get_rook_moves(x, y, is_white)

func get_knight_moves(x, y, is_white):
	return KnightMoves.get_knight_moves(x, y, is_white)

func get_king_moves(x, y, is_white):
	return KingMoves.get_king_moves(x, y, is_white)

func get_pawn_moves(x, y, is_white):
	return PawnMoves.get_pawn_moves(x, y, is_white)
