extends CanvasLayer

signal promote_request(pawn: PawnChessPiece, promotion: ChessPiece)

var pawn: ChessPiece = PawnChessPiece.new(ChessPiece.ChessColor.WHITE)

func _set_parameters(_pawn: PawnChessPiece):
	assert(pawn != null)
	pawn = _pawn

func _ready():
	for button in $Buttons.get_children():
		button.initialize(pawn.color)
		button.pressed.connect(_promote)

func _promote(promotion: ChessPiece):
	promote_request.emit(pawn, promotion)
	queue_free()
