class_name Utilities

static func get_position_between(v1: Vector2i, v2: Vector2i) -> Array[Vector2i]:
	assert(v1.x == v2.x || v1.y == v2.y)
	var iterator: Vector2i = Vector2i(0, 1)
	if v1.y == v2.y:
		iterator = Vector2i(1, 0)
	
	if v1.x > v2.x || v1.y > v2.y:
		iterator = -iterator
	
	var iterated_value: Vector2i = v1 + iterator
	var positions: Array[Vector2i] = []
		
	while (iterated_value != v2):
		positions.push_back(iterated_value)
		iterated_value += iterator
	return positions

static func get_opposite_color(color: ChessPiece.ChessColor) -> ChessPiece.ChessColor:
	match(color):
		ChessPiece.ChessColor.WHITE:
			return ChessPiece.ChessColor.BLACK
		ChessPiece.ChessColor.BLACK:
			return ChessPiece.ChessColor.WHITE
		_:
			push_error("Shouldn't happen, modify method if you added new colors")
			return ChessPiece.ChessColor.WHITE
