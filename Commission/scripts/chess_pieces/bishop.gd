extends ChessPiece

class_name BishopChessPiece

func _init(color: ChessColor):
	_type = Type.BISHOP
	initialize(color)

static func get_move_pattern_static() -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for i in range(1, 8):
		moves.push_back(Vector2i(-i, -i))
		moves.push_back(Vector2i(i, -i))
		moves.push_back(Vector2i(-i, i))
		moves.push_back(Vector2i(i, i))
	return moves
		
func get_move_pattern() -> Array[Vector2i]:
	return BishopChessPiece.get_move_pattern_static()
