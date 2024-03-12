extends Sprite2D

class_name ChessPiece

const CHESS_PIECES_TEXTURE: CompressedTexture2D = preload("res://assets/chess_pieces.png")
const CHESS_PIECES_COUNT: int = 6
const COLORS: int = 2

enum ChessColor { WHITE, BLACK }
enum Type { KING, QUEEN, BISHOP, KNIGHT, ROOK, PAWN }

const TYPE_TO_STR: Dictionary = {
	Type.KING: "King",
	Type.QUEEN: "Queen",
	Type.BISHOP: "Bishop",
	Type.KNIGHT: "Knight",
	Type.ROOK: "Rook",
	Type.PAWN: "Pawn",
}

const COLOR_TO_STR: Dictionary = {
	ChessColor.WHITE: "White",
	ChessColor.BLACK: "Black",
}

var color: ChessColor
var type: Type

func initialize(_color: ChessColor):
	texture = CHESS_PIECES_TEXTURE
	hframes = CHESS_PIECES_COUNT
	vframes = COLORS
	color = _color
	frame = _get_sprite_frame()
	z_index += 1

const FIRST_ELEMENT: int = 0
const LAST_PIECE_INDEX: int = (CHESS_PIECES_COUNT * COLORS) - Constants.ZERO_INDEXING_OFFSET

func _get_sprite_frame() -> int:
	var index: int = type + (color * CHESS_PIECES_COUNT)
	return clamp(index, FIRST_ELEMENT, LAST_PIECE_INDEX)

func _to_string() -> String:
	return COLOR_TO_STR[color] + " " + TYPE_TO_STR[type]

func get_move_pattern() -> Array[Vector2i]:
	return []
