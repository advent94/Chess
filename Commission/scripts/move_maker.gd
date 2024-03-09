extends Node

signal turn_finished

var held_piece: ChessPiece = null
var action_in_process: bool = false

func _ready():
	$"Input Relay".pressed.connect(_on_click)
	$"Input Relay".released.connect(_on_release)

func _physics_process(_delta):
	if held_piece != null && Game.state == Game.State.RUNNING:
		held_piece.position = Game.instance.get_local_mouse_position()

func get_mouse_chessboard_pos() -> Vector2i:
	var pos = Game.instance.get_local_mouse_position()
	pos = pos / Vector2(Chessboard.SQUARE_SIZE)
	return Vector2i(pos)

func _on_click():
	hold()

func draw_movement_grid():
	var moves: Array[Vector2i] = Game.instance.safe_moves[held_piece]
	if not moves.is_empty():
		for move in moves:
			var grid_type: MovementGrid.Type = MovementGrid.Type.MOVEMENT
			var piece = Chessboard.get_piece_at_pos(move)
			if (piece != null && piece._color != Game.turn) || (held_piece is PawnChessPiece && (Chessboard.en_passant != null && move == Chessboard.en_passant.pos)):
				grid_type = MovementGrid.Type.ATTACK
			var tile: MovementGrid = MovementGridFactory.create(grid_type, move)
			tile.add_to_group("Grid")
			tile.z_index -= 1
			get_parent().add_child(tile)
	
func hold() -> bool:
	var pos: Vector2i = get_mouse_chessboard_pos()
	held_piece = get_piece(pos)
	if held_piece != null:
		held_piece.z_index += 1
		draw_movement_grid()
		#Debug.log("Grabbed %s" % held_piece)
	return held_piece != null

func get_piece(pos: Vector2i) -> ChessPiece:
	var piece: ChessPiece = Chessboard.get_piece_at_pos(pos)
	if piece != null:
		if piece._color != Game.instance.turn:
			piece = null
	return piece

func remove_grid():
	get_tree().call_group("Grid", "queue_free")

func _on_release():
	print("on_release")
	if held_piece != null:
		remove_grid()
		var pos: Vector2i = get_mouse_chessboard_pos()
		await move_held_piece_to(pos)
		if held_piece != null:
			held_piece.z_index -= 1
			held_piece = null

func move_held_piece_to(new_chessboard_pos: Vector2i):
	print("move_held...")
	var piece_index: int = Chessboard.state.find(held_piece)
	assert(piece_index != Constants.NOT_FOUND)
	
	var piece_chessboard_pos = Chessboard.index_to_pos(piece_index)
	var pixel_pos: Vector2 = ChessPieceFactory.get_pos(piece_chessboard_pos)
	
	if not await Chessboard.can_move(held_piece, new_chessboard_pos):
		held_piece.position = pixel_pos
		return
	
	await _move(piece_chessboard_pos, new_chessboard_pos)
	pixel_pos = ChessPieceFactory.get_pos(new_chessboard_pos)
	
	if held_piece != null:
		held_piece.position = pixel_pos
		held_piece.z_index -= 1
		held_piece = null
	turn_finished.emit()
	await Game.instance.next_turn_initialized

func _move(from: Vector2i, to: Vector2i):
	print("_move")
	Chessboard.update_move_history(Chessboard.Move.new(held_piece, from, to))
	Chessboard.state[Chessboard.pos_to_index(from)] = null
	var captured: ChessPiece = Chessboard.state[Chessboard.pos_to_index(to)]
	if held_piece is PawnChessPiece && Chessboard.en_passant != null && to == Chessboard.en_passant.pos:
		captured = Chessboard.en_passant.pawn
		Chessboard.state[Chessboard.state.find(captured)] = null
	Chessboard.state[Chessboard.pos_to_index(to)] = held_piece
	Chessboard.en_passant = null
	
	if captured != null:
		Debug.log("%s has captured %s!" % [held_piece, captured])
		captured.queue_free()
		Game.instance.restart_counter()
	var distance: Vector2i = to - from
	if held_piece is PawnChessPiece:
		Game.instance.restart_counter()
		if held_piece.first_move:
			held_piece.first_move = false
			if abs(distance).length() == 2:
				Chessboard.en_passant = Chessboard.EnPassant.new(held_piece, from + (to - from)/2)
				Debug.log("En Passant added(%s)" % Chessboard.en_passant.pos)
		elif held_piece.should_be_promoted():
			held_piece.position = ChessPieceFactory.get_pos(to)
			Debug.log("%s has been promoted!" % held_piece)
			held_piece.applied_for_promotion.emit()
			await Game.instance.promotion_ended
			held_piece = Chessboard.get_piece_at_pos(to)
	elif (held_piece is KingChessPiece && (abs(distance).length() == 2)):
		var rook_column: int = 0
		if (Chessboard.vector_to_dir(distance)) == Chessboard.Direction.RIGHT:
			rook_column = 7
		var rook_pos: Vector2i = Vector2i(rook_column, to.y)
		var rook_new_pos: Vector2i = Vector2i(from + distance/2)
		var rook: RookChessPiece = Chessboard.get_piece_at_pos(rook_pos)
		Chessboard.state[Chessboard.pos_to_index(rook_pos)] = null
		Chessboard.state[Chessboard.pos_to_index(rook_new_pos)] = rook
		rook.position = ChessPieceFactory.get_pos(rook_new_pos)
		rook.moved = true
		Debug.log("Castling done!")
		held_piece.moved = true
	elif (held_piece is RookChessPiece || held_piece is KingChessPiece) && not held_piece.moved:
		Debug.log("%s moved and won't be able to castle!" % held_piece)
		held_piece.moved = true
		
	Debug.log("Moved %s" % held_piece)
