extends CanvasLayer

signal started(color: ChessPiece.ChessColor)

var _step: int = 0
var _reverse: bool = false
const MIN_STEPS: int = 0
const MAX_STEPS: int = 30

func _update():
	var iterator: int = 1
	
	if _reverse:
		iterator = -iterator
	_step += iterator
	
	if _step >= MAX_STEPS:
		_reverse = true
	elif _step <= MIN_STEPS:
		_reverse = false
	
	$Background/Text.label_settings.font_color = Color.BLACK + _step * (Color.WHEAT / MAX_STEPS)
	
func _on_button_press(piece):
	started.emit(piece.color)
	queue_free()
