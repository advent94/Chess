extends Node

var active: bool = false

func log(string: String):
	if active:
		print(string)
