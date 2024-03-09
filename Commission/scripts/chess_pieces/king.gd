extends ChessPiece

class_name KingChessPiece

const KING_MOVE_PATTERN: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0),                   Vector2i(1, 0),
	Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1)
]

var moved: bool = false

func _init(color: ChessColor):
	_type = Type.KING
	initialize(color)

func get_move_pattern() -> Array[Vector2i]:
	return KING_MOVE_PATTERN
