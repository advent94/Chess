extends ChessPiece

class_name KnightChessPiece

#      ? x ?
#    ? x x x ?
#    x x o x x
#    ? x x x ?
#      ? x ?

const KNIGHT_MOVE_PATTERN: Array[Vector2i] = [
				  Vector2i(-1, -2), Vector2i(1, -2),
	Vector2i(-2, -1),                              Vector2i(2, -1),
	
	Vector2i(-2, 1),                               Vector2i(2, 1),
				  Vector2i(-1, 2), Vector2i(1, 2),
]

func _init(color: ChessColor):
	_type = Type.KNIGHT
	initialize(color)

func get_move_pattern() -> Array[Vector2i]:
	return KNIGHT_MOVE_PATTERN
