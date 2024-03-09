extends CanvasLayer

signal restarted

@onready var _init_size: int = $Background/Text.label_settings.font_size
var _step: int = 10
var _reverse: bool = false
var restart_callable: Callable
const MIN_STEPS: int = 0
const MAX_STEPS: int = 10

func set_title(title: String):
	$Background/Text.text = title

func set_restart_callable(restart: Callable):
	restart_callable = restart

func _update():
	var iterator: int = 1
	
	if _reverse:
		iterator = -iterator
		
	_step += iterator
	if _step >= MAX_STEPS:
		_reverse = true
	elif _step <= MIN_STEPS:
		_reverse = false
	
	$Background/Text.label_settings.font_size = _init_size + _step

func _on_exit_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _on_restart_pressed():
	restarted.emit()
	queue_free()

const COLOR_CHOICE_SCENE: PackedScene =preload("res://scenes/promotion/pick_color.tscn")

func _on_color_choice():
	var color_choice = COLOR_CHOICE_SCENE.instantiate()
	color_choice.started.connect(restart_callable)
	get_parent().add_child(color_choice)
	queue_free()
