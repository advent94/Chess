class_name ChessboardElementFactory

static func get_pos(pos: Vector2i) -> Vector2:
	assert(Chessboard.initialized, "Can't calculate position without pos and origin")
	const square_size = Chessboard.SQUARE_SIZE
	pos = pos.clamp(Vector2i(0,0), Vector2i(Chessboard.COLUMNS - Constants.ZERO_INDEXING_OFFSET, Chessboard.ROWS - Constants.ZERO_INDEXING_OFFSET))
	var offset: Vector2 = Chessboard.origin + Vector2(round(square_size.x/2.0), round(square_size.y/2.0))
	
	return Vector2(square_size.x * pos.x, square_size.y * pos.y) + offset
