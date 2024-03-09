extends CanvasLayer

signal draw
signal resume

var _step: int = 10
var _reverse: bool = false
@onready var _init_size: int = $Background/Text.label_settings.font_size
const MIN_STEPS: int = 0
const MAX_STEPS: int = 30

func _update():
	var iterator: int = 2
	
	if _reverse:
		iterator = -iterator
		
	_step += iterator
	if _step >= MAX_STEPS:
		_reverse = true
	elif _step <= MIN_STEPS:
		_reverse = false
	
	$Background/Text.label_settings.font_size = _init_size + _step

func _on_yes_pressed():
	draw.emit()
	queue_free()

func _on_no_pressed():
	resume.emit()
	queue_free()
