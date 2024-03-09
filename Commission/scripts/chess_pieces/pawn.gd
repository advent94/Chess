extends ChessPiece

class_name PawnChessPiece

signal applied_for_promotion

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

func _init(color: ChessColor):
	_type = Type.PAWN
	initialize(color)
	applied_for_promotion.connect(func(): Game.instance.start_promotion(self))

func get_move_pattern() -> Array[Vector2i]:
	var move_pattern: Array[Vector2i] = PAWN_CAPTURE_PATTERN
	var result: Array[Vector2i] = []
	if first_move:
		move_pattern += PAWN_FIRST_MOVE_PATTERN
	else:
		move_pattern += PAWN_MOVING_PATTERN
	
	if _color != Game.player:
		result.assign(move_pattern.map(func(vec): return -vec ))
	else:
		result = move_pattern
	return result

func should_be_promoted() -> bool:
	assert(Chessboard.state.has(self))
	var required_row_index = 0
	if _color == ChessColor.BLACK:
		required_row_index = Chessboard.ROWS - Constants.ZERO_INDEXING_OFFSET
	var pos: Vector2i = Chessboard.index_to_pos(Chessboard.state.find(self))
	return pos.y == required_row_index
