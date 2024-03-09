extends Node2D

class_name Game

signal promotion_ended
signal clearing_completed
signal next_turn_initialized

enum State { UNINITIALIZED, RUNNING, EVENT,  }

const PROMOTION_SCENE: PackedScene = preload("res://scenes/promotion/promo.tscn")
const COLOR_CHOICE_SCENE: PackedScene = preload("res://scenes/promotion/pick_color.tscn")
const DRAW_PROPOSAL_SCENE: PackedScene = preload("res://scenes/draw_proposal.tscn")
const END_GAME_SCENE: PackedScene = preload("res://scenes/end.tscn")

static var state: State = State.UNINITIALIZED
static var player: ChessPiece.ChessColor = ChessPiece.ChessColor.WHITE
static var turn: ChessPiece.ChessColor = ChessPiece.ChessColor.BLACK
static var instance: Game = null
static var draw_counter: int = 0
var current_color_moves: Array[Vector2i] = []
var enemy_moves: Array[Vector2i] = []
var castles: Array[Vector2i] = []

func _ready():
	instance = self
	$MoveMaker.turn_finished.connect(next_turn)
	Chessboard.fill(ChessPiece.ChessColor.WHITE)
	var color_choice = COLOR_CHOICE_SCENE.instantiate()
	color_choice.started.connect(start)
	add_child(color_choice)

func start(color: ChessPiece.ChessColor = player):
	player = color
	await remove_all_pieces()
	Chessboard.state.fill(null)
	Chessboard.fill(player)
	state = State.RUNNING
	next_turn()
	
func switch_player():
	match(turn):
		ChessPiece.ChessColor.WHITE:
			turn = ChessPiece.ChessColor.BLACK
		ChessPiece.ChessColor.BLACK:
			turn = ChessPiece.ChessColor.WHITE

func initialize_new_turn():
	Chessboard.protected_positions.clear()
	current_color_moves = await Chessboard.get_possible_moves_for_all_pieces(turn)
	enemy_moves = await Chessboard.get_possible_moves_for_all_pieces(Chessboard.get_enemy_color(turn))
	king_checked = await Chessboard.is_king_checked()
	castles = await Chessboard.get_possible_castle()
	safe_moves = await Chessboard.get_moves_safe_for_king()
	Chessboard.show_state()

func check_game_status():
	if safe_moves.values().all(func(array): return array.is_empty()):
		if king_checked:
			var title: String = "VICTORY!"
			if turn == player:
				title = "DEFEAT!"
			return end(title)
		else:
			return end("Stalemate!")
	elif king_checked:
			print("Check")
	
func next_turn():
	if await Chessboard.should_draw():
		return end()
	else:
		switch_player()
		await initialize_new_turn()
		await check_game_status()
	increment_counter()
	next_turn_initialized.emit()

var removed_nodes: int = 0
var nodes_to_remove: int = 0
var king_checked: bool = false
var safe_moves: Dictionary

func restart(color: ChessPiece.ChessColor = player):
	player = color
	print("restart")
	await remove_all_pieces()
	Chessboard.state.fill(null)
	Chessboard.fill(player)
	Chessboard.move_history.clear()
	Chessboard.protected_positions.clear()
	turn = ChessPiece.ChessColor.BLACK
	restart_counter()
	next_turn()
	print("restart_end")
	Chessboard.show_state()
	state = State.RUNNING

func increment_removed():
	removed_nodes += 1
	if removed_nodes == nodes_to_remove:
		clearing_completed.emit()
	
func remove_all_pieces():
	var nodes: Array[Node] = get_tree().get_nodes_in_group("Pieces")
	nodes_to_remove = nodes.size()
	for node in nodes:
		node.tree_exited.connect(increment_removed)
	get_tree().call_group("Pieces", "queue_free")
	await clearing_completed
	removed_nodes = 0

func _add_new_chess_piece(piece: ChessPiece):
	piece.add_to_group("Pieces")
	add_child(piece)

func start_promotion(pawn: PawnChessPiece):
	state = State.EVENT
	var promotion = PROMOTION_SCENE.instantiate()
	promotion._set_parameters(pawn)
	promotion.tree_exiting.connect(end_promotion)
	add_child(promotion)

func end_promotion():
	promotion_ended.emit()
	state = State.RUNNING

func resume():
	state = State.RUNNING

func end(title: String = "Draw!"):
	state = State.EVENT
	var end_game = END_GAME_SCENE.instantiate()
	end_game.set_title(title)
	end_game.restarted.connect(restart)
	end_game.set_restart_callable(restart)
	add_child(end_game)

func restart_counter():
	draw_counter = 0

const WEAK_MOVES_BEFORE_DRAW: int = 50
const WEAK_MOVES_BEFORE_FORCED_DRAW: int = 75

func propose_draw():
	state = State.EVENT
	var draw_proposal = DRAW_PROPOSAL_SCENE.instantiate()
	draw_proposal.resume.connect(resume)
	draw_proposal.draw.connect(restart)
	add_child(draw_proposal)
	

func increment_counter():
	draw_counter += 1
	if draw_counter > WEAK_MOVES_BEFORE_DRAW:
		propose_draw()
	elif draw_counter > WEAK_MOVES_BEFORE_FORCED_DRAW:
		end()
