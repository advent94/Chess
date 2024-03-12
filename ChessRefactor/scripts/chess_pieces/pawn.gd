extends ChessPiece

class_name PawnChessPiece

var first_move = true

const PAWN_FIRST_MOVE_PATTERN: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(0, -2),
]
const PAWN_MOVING_PATTERN: Array[Vector2i] = [Vector2i(0, -1)]
const PAWN_CAPTURE_PATTERN: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(1, -1),
]

func _init(_color: ChessColor):
	type = Type.PAWN
	initialize(_color)

func get_move_pattern() -> Array[Vector2i]:
	var move_pattern: Array[Vector2i] = PAWN_CAPTURE_PATTERN
	var result: Array[Vector2i] = []
	if first_move:
		move_pattern += PAWN_FIRST_MOVE_PATTERN
	else:
		move_pattern += PAWN_MOVING_PATTERN

	result = move_pattern
	return result
