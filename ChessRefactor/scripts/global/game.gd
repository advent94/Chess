extends Node

enum State { UNINITIALIZED, RUNNING, EVENT,  }

var state: State = State.UNINITIALIZED
var player_color: ChessPiece.ChessColor = ChessPiece.ChessColor.WHITE
var turn: ChessPiece.ChessColor = ChessPiece.ChessColor.BLACK

func initialize(color: ChessPiece.ChessColor):
	player_color = color
	turn = ChessPiece.ChessColor.BLACK
	
	
func run():
	state = State.RUNNING

func resume():
	run()

func start_event():
	state = State.EVENT

func is_running() -> bool:
	return state == State.RUNNING

func is_player_turn() -> bool:
	return turn == player_color

func switch_player():
	match(turn):
		ChessPiece.ChessColor.WHITE:
			turn = ChessPiece.ChessColor.BLACK
		ChessPiece.ChessColor.BLACK:
			turn = ChessPiece.ChessColor.WHITE
