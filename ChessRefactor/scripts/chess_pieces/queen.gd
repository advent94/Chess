extends ChessPiece

class_name QueenChessPiece

func _init(_color: ChessColor):
	type = Type.QUEEN
	initialize(_color)

func get_move_pattern() -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	moves.append_array(RookChessPiece.get_move_pattern_static())
	moves.append_array(BishopChessPiece.get_move_pattern_static())
	return moves
