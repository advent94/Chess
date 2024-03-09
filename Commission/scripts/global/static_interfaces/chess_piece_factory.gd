extends  ChessboardElementFactory

class_name ChessPieceFactory

static func create(type: ChessPiece.Type, color: ChessPiece.ChessColor, pos: Vector2i) -> ChessPiece:
	var piece: ChessPiece
	match(type):
		ChessPiece.Type.PAWN:
			piece = PawnChessPiece.new(color)
		ChessPiece.Type.ROOK:
			piece = RookChessPiece.new(color)
		ChessPiece.Type.BISHOP:
			piece = BishopChessPiece.new(color)
		ChessPiece.Type.KNIGHT:
			piece = KnightChessPiece.new(color)
		ChessPiece.Type.QUEEN:
			piece = QueenChessPiece.new(color)
		ChessPiece.Type.KING:
			piece = KingChessPiece.new(color)
	Chessboard.state[Chessboard.pos_to_index(pos)] = piece
	piece.position = get_pos(pos)
	Debug.log("New ChessPiece(%s) has been created!" % piece)
	return piece
