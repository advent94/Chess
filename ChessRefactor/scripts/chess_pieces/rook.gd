extends ChessPiece

class_name RookChessPiece

var moved: bool = false

func _init(_color: ChessColor):
	type = Type.ROOK
	initialize(_color)

static func create_move_pattern() -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for i in range(1, 8):
		moves.push_back(Vector2i(0, i))
		moves.push_back(Vector2i(0, -i))
		moves.push_back(Vector2i(i, 0))
		moves.push_back(Vector2i(-i, 0))
	return moves

func get_move_pattern() -> Array[Vector2i]:
	return RookChessPiece.create_move_pattern()
