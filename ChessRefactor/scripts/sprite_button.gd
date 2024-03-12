extends ChessPiece

@export var _color: ChessColor
@export var _type: Type

signal pressed(piece: ChessPiece)

func _ready():
	type = _type
	initialize(_color)

func _on_button_pressed():
	pressed.emit(self)


func _on_button_hover():
	scale += Vector2(1.0, 1.0)

func _on_button_stopped_hovering():
	scale -= Vector2(1.0, 1.0)
