class_name ChessPieceFactory

static func create(type: ChessPiece.Type, color: ChessPiece.ChessColor) -> ChessPiece:
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
	return piece
