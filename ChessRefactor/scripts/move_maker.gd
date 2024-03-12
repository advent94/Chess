extends Node

class_name MoveMaker

signal grabbed
signal hovering(piece: ChessPiece)
signal holding(piece: ChessPiece)
signal moved(piece: ChessPiece)

@onready var input_relay: Node = $"Input Relay"

var held_piece: ChessPiece = null

func _ready():
	input_relay.pressed.connect(hold)
	input_relay.released.connect(_on_release)

func _physics_process(_delta):
	if held_piece != null && Game.is_running():
		hovering.emit(held_piece)

func hold():
	grabbed.emit()

func validate_held_piece():
	if held_piece != null:
		held_piece.z_index += 1
		holding.emit(held_piece)

func _on_release():
	if held_piece != null:
		remove_grid()
		moved.emit(held_piece)
		held_piece = null

func remove_grid():
	get_tree().call_group("Grid", "queue_free")
