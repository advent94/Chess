extends Node

signal pressed
signal released

func _process(_delta):
	if Game.is_running():
		_parse_input()

func _parse_input():
	if Input.is_action_just_pressed("click"):
		pressed.emit()
	elif Input.is_action_just_released("click"):
		released.emit()
