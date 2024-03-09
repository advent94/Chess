extends Node

var active: bool = true
var should_log_moves: bool = false

func log(string: String):
	if active:
		print(string)

func log_moves(moves, _name: String):
	if should_log_moves:
		print("%s : %s" % [_name, str(moves)])
