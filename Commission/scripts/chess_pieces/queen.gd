extends ChessPiece

class_name QueenChessPiece

func _init(color: ChessColor):
	_type = Type.QUEEN
	initialize(color)

func get_move_pattern() -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	moves.append_array(RookChessPiece.get_move_pattern_static())
	moves.append_array(BishopChessPiece.get_move_pattern_static())
	return moves
