extends CanvasLayer

var _piece: ChessPiece = PawnChessPiece.new(ChessPiece.ChessColor.WHITE)

func _set_parameters(pawn: PawnChessPiece):
	assert(pawn != null)
	_piece = pawn

func _ready():
	for button in $Buttons.get_children():
		button.initialize(_piece._color)
		button.pressed.connect(_promote)

func _promote(piece: ChessPiece):
	var type: ChessPiece.Type = piece._type
	var board_pos: Vector2i = Chessboard.index_to_pos(Chessboard.state.find(_piece))
	var promoted_piece = ChessPieceFactory.create(type, _piece._color, board_pos)
	Chessboard.state[Chessboard.pos_to_index(board_pos)] = promoted_piece
	Game.instance._add_new_chess_piece(promoted_piece)
	Debug.log("%s has been promoted to %s!" % [_piece, promoted_piece])
	_piece.queue_free()
	await _piece.tree_exiting
	queue_free()
