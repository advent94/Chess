extends Node

signal pressed
signal released

var holding: bool = false

func _process(_delta):
	if Game.state == Game.State.RUNNING:
		_parse_input()

func _parse_input():
	if Input.is_action_just_pressed("click"):
		pressed.emit()
		holding = true
	elif Input.is_action_just_released("click"):
		released.emit()
		holding = false
