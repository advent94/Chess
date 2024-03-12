extends Node2D

class_name Chess

signal next_turn_initialized
signal piece_obtained

const PROMOTION_SCENE: PackedScene = preload("res://scenes/promotion/promo.tscn")
const COLOR_CHOICE_SCENE: PackedScene = preload("res://scenes/pick_color.tscn")
const DRAW_PROPOSAL_SCENE: PackedScene = preload("res://scenes/draw_proposal.tscn")
const END_GAME_SCENE: PackedScene = preload("res://scenes/end.tscn")

@onready var chessboard: Chessboard = $Chessboard
@onready var move_maker: MoveMaker = $MoveMaker

var draw_counter: int = 0

#region Ready
func _ready():
	const INITIAL_SCREEN_CHESS_PIECE_COLOR: ChessPiece.ChessColor = ChessPiece.ChessColor.WHITE
	
	connect_all_signals()
	chessboard.fill(INITIAL_SCREEN_CHESS_PIECE_COLOR)
	var color_selection: Node = create_color_selection()
	add_child(color_selection)

func connect_all_signals():
	move_maker.grabbed.connect(grab_piece)
	piece_obtained.connect(move_maker.validate_held_piece)
	move_maker.holding.connect(chessboard.draw_movement_grid)
	move_maker.hovering.connect(update_hovered_piece_pos)
	move_maker.moved.connect(chessboard.move)
	chessboard.pawn_moved.connect(restart_counter)
	chessboard.captured.connect(restart_counter)
	chessboard.movement_finished.connect(new_turn)
	chessboard.promoting.connect(start_promotion)
	chessboard.promoted.connect(Game.resume)
	
func create_color_selection() -> Node:
	var color_selection = COLOR_CHOICE_SCENE.instantiate()
	color_selection.started.connect(start)
	return color_selection
#endregion
#region Main Functionalities
func restart(color: ChessPiece.ChessColor = Game.player_color):
	restart_counter()
	start(color)

func start(color: ChessPiece.ChessColor = Game.player_color):
	Game.initialize(color)
	await chessboard.reset()
	Game.run()
	new_turn()


func new_turn():
	if should_draw():
		return end("Draw!")
	elif should_propose_draw():
		propose_draw()
	
	Game.switch_player()
	await chessboard.capture_snapshot()
	await check_game_status()
	increment_counter()
	next_turn_initialized.emit()

func grab_piece():
	var pointed_piece: ChessPiece = await chessboard.get_pointed_piece()
	
	if pointed_piece != null && pointed_piece.color == Game.turn:
		move_maker.held_piece = pointed_piece
	piece_obtained.emit()

func update_hovered_piece_pos(piece: ChessPiece):
	piece.position = chessboard.to_local(get_local_mouse_position())
	
#endregion
#region Counter Helpers
func restart_counter():
	draw_counter = 0

func increment_counter():
	draw_counter += 1
#endregion
#region Draw
func should_draw() -> bool:
	const WEAK_MOVES_BEFORE_FORCED_DRAW: int = 75
	return insufficient_mating_material() || move_pattern_repeated() || draw_counter >= WEAK_MOVES_BEFORE_FORCED_DRAW


func insufficient_mating_material() -> bool:
	var statistics: Dictionary = chessboard.snapshot.statistics
	
	if statistics.is_empty(): 
		return false

	# King vs King, 
	# King & Bishop vs King, 
	# King & Knight vs King
	if ((statistics["count"] <= 4 && (statistics["white_count"] <= 2 && statistics["black_count"] <= 2) &&	
		statistics["both_colors"][ChessPiece.Type.QUEEN] == 0 && 
		statistics["both_colors"][ChessPiece.Type.ROOK] == 0 && 
		statistics["both_colors"][ChessPiece.Type.PAWN] == 0) || (
			
		# King & Two Knights vs King
		statistics["count"] == 3 &&
		(statistics["white_count"] == 2 || statistics["black_count"] == 2) &&
		statistics["both_colors"][ChessPiece.Type.KNIGHT] == 2)):
		return true
	
	return false


func move_pattern_repeated() -> bool:	
	return should_verify_move_history() && repeated_moves_limit_passed()

const MAX_RECORDED_ACTIONS_PER_PLAYER: int = 3
const MAX_RECORDED_ACTIONS: int = MAX_RECORDED_ACTIONS_PER_PLAYER * 2
	
func should_verify_move_history() -> bool:
	return chessboard.move_history.size() == MAX_RECORDED_ACTIONS

func repeated_moves_limit_passed() -> bool:
	var move_history: Array[Chessboard.Move] = chessboard.move_history
	assert(move_history.size() == MAX_RECORDED_ACTIONS)
	
	return move_history[0].eq(move_history[4]) && move_history[1].eq(move_history[5])
#endregion
#region End Game
func end(title: String):
	Game.start_event()
	var end_game_screen: Node = create_end_screen(title)
	add_child(end_game_screen)

func create_end_screen(title: String) -> Node:
	var end_game = END_GAME_SCENE.instantiate()
	end_game.set_title(title)
	end_game.restarted.connect(restart)
	end_game.set_restart_callable(restart)
	return end_game
#endregion
#region Draw Proposal
func should_propose_draw() -> bool:
	const WEAK_MOVES_BEFORE_DRAW_SUGGESTION: int = 50
	return draw_counter >= WEAK_MOVES_BEFORE_DRAW_SUGGESTION
	
func propose_draw():
	Game.start_event()
	var draw_proposal: Node = create_draw_proposal()
	add_child(draw_proposal)

func create_draw_proposal() -> Node:
	var draw_proposal = DRAW_PROPOSAL_SCENE.instantiate()
	draw_proposal.draw.connect(restart)
	return draw_proposal
#endregion
#region Game Status
func check_game_status():
	if victory():
		return end("VICTORY!")
	elif defeat():
		return end("DEFEAT")
	elif stalemate():
		return end("Stalemate!")
	
	if is_king_checked():
		print("Check")


func victory() -> bool:
	return session_finished() && is_king_checked() && not Game.is_player_turn()

func defeat() -> bool:
	return session_finished() && is_king_checked() && Game.is_player_turn()

func stalemate() -> bool:
	return session_finished() && not is_king_checked()
	
func session_finished() -> bool:
	return not chessboard.snapshot.safe_moves_available

func is_king_checked() -> bool:
	return chessboard.snapshot.king_checked
#endregion
#region Promotion
func start_promotion(pawn: PawnChessPiece):
	Game.start_event()
	var promotion: Node = create_promotion(pawn)
	add_child(promotion)

func create_promotion(pawn: PawnChessPiece) -> Node:
	var promotion = PROMOTION_SCENE.instantiate()
	promotion._set_parameters(pawn)
	promotion.promote_request.connect(chessboard.promote)
	return promotion
#endregion
