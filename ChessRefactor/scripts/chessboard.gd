extends TileMap

class_name Chessboard

signal pawn_moved
signal captured
signal promoting(pawn: PawnChessPiece)
signal promoted
signal clearing_completed
signal movement_finished

const ROWS: int = 8
const COLUMNS: int = 8
const SQUARE_SIZE: Vector2i = Vector2i(39, 36)
const SIZE: Vector2 = Vector2(SQUARE_SIZE.x * COLUMNS, SQUARE_SIZE.y * ROWS)
const OFFSET: Vector2 = Vector2(SIZE) / 2

var state: Array[ChessPiece] = []
var snapshot: Snapshot = Snapshot.new()
var move_history: Array[Move] = []
var en_passant: EnPassant = null

func _ready():
	_initialize()

func _initialize():
	state.resize(ROWS * COLUMNS)
	state.fill(null)

func reset():
	await clear_board()
	fill(Game.player_color)
	move_history.clear()
#region Classes
class Snapshot:
	var statistics: Dictionary = {}
	var enemy_moves: Array[Vector2i] = []
	var king_checked: bool = false
	var castles: Array[Vector2i] = []
	var safe_moves: Dictionary = {}
	var safe_moves_available: bool = false

class Move:
	var piece: ChessPiece
	var from: Vector2i
	var to: Vector2i
	
	func _init(_piece: ChessPiece, _from: Vector2i, _to: Vector2i):
		assert(_piece != null, "Move can't be done by invalid piece.")
		piece = _piece
		from = _from
		to = _to
	
	func eq(move: Move) -> bool:
		return (move.piece == piece) && (move.from == from) && (move.to == to)


class EnPassant:
	func _init(_pawn: PawnChessPiece, _pos: Vector2i):
		pawn = _pawn
		pos = _pos

	var pawn: PawnChessPiece
	var pos: Vector2i
#endregion
#region Clear
func clear_board():
	await remove_all_pieces()
	state.fill(null)

var removed_pieces: int = 0
var pieces_to_remove: int = 0

func remove_all_pieces():
	var pieces: Array[Node] = get_tree().get_nodes_in_group("Pieces")
	pieces_to_remove = pieces.size()
	for piece in pieces:
		piece.tree_exited.connect(increment_removed)
	get_tree().call_group("Pieces", "queue_free")
	await clearing_completed
	removed_pieces = 0

func increment_removed():
	removed_pieces += 1
	if removed_pieces == pieces_to_remove:
		clearing_completed.emit()
#endregion
#region Fill
func fill(player_color: ChessPiece.ChessColor = ChessPiece.ChessColor.WHITE):
	const OPPONENT_PREMIUM_ROW_INDEX: int = 0
	const OPPONENT_PAWN_ROW_INDEX: int = 1
	const SQUARES_BETWEEN_PLAYERS: int = 4
	const PLAYER_PAWN_ROW_INDEX: int = OPPONENT_PAWN_ROW_INDEX + SQUARES_BETWEEN_PLAYERS + 1
	const PLAYER_PREMIUM_ROW_INDEX: int = PLAYER_PAWN_ROW_INDEX + 1

	const PREMIUM_PIECE_ORDER: Array[ChessPiece.Type] = [
		ChessPiece.Type.ROOK,
		ChessPiece.Type.KNIGHT,
		ChessPiece.Type.BISHOP,
		ChessPiece.Type.QUEEN,
		ChessPiece.Type.KING,
	]

	var opponent_color: ChessPiece.ChessColor = Utilities.get_opposite_color(player_color)
	
	for i in range(COLUMNS):
		add_piece(ChessPieceFactory.create(ChessPiece.Type.PAWN, opponent_color), Vector2i(i, OPPONENT_PAWN_ROW_INDEX))
		add_piece(ChessPieceFactory.create(ChessPiece.Type.PAWN, player_color), Vector2i(i, PLAYER_PAWN_ROW_INDEX))
		
	var premium_piece_order: Array[ChessPiece.Type] = PREMIUM_PIECE_ORDER
	for i in range(premium_piece_order.size()):
		add_piece(ChessPieceFactory.create(premium_piece_order[i], opponent_color), Vector2i(i, OPPONENT_PREMIUM_ROW_INDEX))
		add_piece(ChessPieceFactory.create(premium_piece_order[i], player_color), Vector2i(i, PLAYER_PREMIUM_ROW_INDEX))
	
	const UNIQUE_PIECES: Array[ChessPiece.Type] = [ChessPiece.Type.QUEEN, ChessPiece.Type.KING]
	
	for i in range(premium_piece_order.size() - UNIQUE_PIECES.size()):
		add_piece(ChessPieceFactory.create(premium_piece_order[UNIQUE_PIECES.size() - i], opponent_color), 
				Vector2i(premium_piece_order.size() + i, OPPONENT_PREMIUM_ROW_INDEX))
		add_piece(ChessPieceFactory.create(premium_piece_order[UNIQUE_PIECES.size()- i], player_color), 
				Vector2i(premium_piece_order.size() + i, PLAYER_PREMIUM_ROW_INDEX))


func add_piece(piece: ChessPiece, pos: Vector2i):
	state[pos_to_index(pos)] = piece
	piece.position = get_pixel_pos(pos)
	piece.add_to_group("Pieces")
	match(piece.color):
		ChessPiece.ChessColor.WHITE:
			piece.add_to_group("White")
		ChessPiece.ChessColor.BLACK:
			piece.add_to_group("Black")
	add_child.call_deferred(piece)
#endregion
#region Snapshot
func capture_snapshot():
	snapshot = Snapshot.new()
	snapshot.statistics = await get_statistics()
	snapshot.enemy_moves = await get_possible_moves_for_all_pieces(Utilities.get_opposite_color(Game.turn))
	snapshot.king_checked = await is_king_checked()
	snapshot.castles = await get_possible_castle()
	snapshot.safe_moves = await get_moves_safe_for_king()
	snapshot.safe_moves_available =  not (snapshot.safe_moves.values().all(func(array): return array.is_empty()))

func get_statistics() -> Dictionary:
	var statistics: Dictionary = {}
	var white: Array[int] = []
	var black: Array[int] = []
	var both_colors: Array[int] = []
	var all_pieces: int = 0
	var white_pieces: int = 0
	var black_pieces: int = 0
	
	both_colors.resize(ChessPiece.Type.size())
	both_colors.fill(0)
	black = both_colors.duplicate()
	white = both_colors.duplicate()
	
	for piece in state:
		if piece != null:
			if piece.color == ChessPiece.ChessColor.WHITE:
				white[piece.type] += 1
			else:
				black[piece.type] += 1


	for i in range(ChessPiece.Type.size()):
		both_colors[i] += white[i] + black[i]
		all_pieces += white[i] + black[i]
		white_pieces += white[i]
		black_pieces += black[i]
		
	statistics["both_colors"] = both_colors
	statistics[ChessPiece.ChessColor.WHITE] = white
	statistics[ChessPiece.ChessColor.BLACK] = black	
	statistics["count"] = all_pieces
	statistics["white_count"] = white_pieces
	statistics["black_count"] = black_pieces
	
	return statistics
#endregion
#region Possible Moves (Unsafe)
func get_possible_moves_for_all_pieces(color: ChessPiece.ChessColor, _state: Array[ChessPiece] = state) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for piece in _state:
		if piece != null && piece.color == color:
			moves.append_array(await get_possible_moves(piece, _state))
			moves.sort()
	return moves
	
func get_possible_moves(piece: ChessPiece, _state: Array[ChessPiece] = state) -> Array[Vector2i]:
	var possible_moves: Array[Vector2i] = []
	var piece_index: int = _state.find(piece)
	
	if piece != null && piece_index != Constants.NOT_FOUND:
		var moves: Array[Vector2i] = piece.get_move_pattern()
		
		if piece is PawnChessPiece && piece.color != Game.player_color:
			moves.assign(moves.map(func(vec): return -vec ))
		
		var directional_moves: Dictionary = possible_moves_to_dir_vectors(moves)
		var board_pos: Vector2i = index_to_pos(piece_index)
		
		for key in directional_moves.keys():
			directional_moves[key] = get_moves_relative_to_pos(board_pos, directional_moves[key])

		# Remove moves outside the chessboard area
		for key in directional_moves.keys():
			directional_moves[key] = get_valid_moves(directional_moves[key])
			if directional_moves[key].is_empty():
				directional_moves.erase(key)		
		
		for key in directional_moves.keys():
			if piece is PawnChessPiece:
				directional_moves[key] = adjust_moves_for_pawn(piece, key, directional_moves[key], _state)
			else:
				directional_moves[key] = remove_blocked_moves(piece, directional_moves[key], _state)
			possible_moves.append_array(directional_moves[key])
		
		if piece is KingChessPiece:
			possible_moves = keep_distance_from_enemy_king(piece, possible_moves, _state)
			if not piece.moved && piece.color == Game.turn:
				if not snapshot.castles.is_empty():
					possible_moves.append_array(snapshot.castles)
			
	possible_moves.sort()
	return possible_moves


func possible_moves_to_dir_vectors(possible_moves: Array[Vector2i]):
	var direction_to_moves_index: Dictionary = {
		Direction.UP: [],
		Direction.DOWN: [],
		Direction.LEFT: [],
		Direction.RIGHT: [],
		Direction.TOP_LEFT: [],
		Direction.TOP_RIGHT: [],
		Direction.BOTTOM_RIGHT: [],
		Direction.BOTTOM_LEFT: [],
	}

	for key in direction_to_moves_index.keys():
		var array: Array[Vector2i] = []
		direction_to_moves_index[key] = array
			
	for move in possible_moves:
		direction_to_moves_index[vector_to_dir(move)].push_back(move)
	
	for key in direction_to_moves_index.keys():
		if direction_to_moves_index[key].is_empty():
			direction_to_moves_index.erase(key)

	return direction_to_moves_index


func vector_to_dir(vec) -> Direction:
	assert(vec is Vector2 || vec is Vector2i)
	var dir: Direction
	if vec.y < 0 && vec.x == 0:
		dir = Direction.UP
	elif vec.y > 0 && vec.x == 0:
		dir = Direction.DOWN
	elif vec.y == 0 && vec.x < 0:
		dir = Direction.LEFT
	elif vec.y == 0 && vec.x > 0:
		dir = Direction.RIGHT
	elif vec.y < 0 && vec.x < 0:
		dir = Direction.TOP_LEFT
	elif vec.y > 0 && vec.x > 0:
		dir = Direction.BOTTOM_RIGHT
	elif vec.y > 0 && vec.x < 0:
		dir = Direction.BOTTOM_LEFT
	elif vec.y < 0 && vec.x > 0:
		dir = Direction.TOP_RIGHT
	return dir

func get_moves_relative_to_pos(pos: Vector2i, move_pattern: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(move_pattern.map(func(vec): return (vec + pos)))
	return result

func get_valid_moves(moves: Array[Vector2i]):
	var valid_moves: Array[Vector2i] = []
	valid_moves.assign(moves.filter(func(vec): return is_pos_valid(vec)))
	return valid_moves


func adjust_moves_for_pawn(pawn: PawnChessPiece, direction: Direction, moves: Array[Vector2i], _state: Array[ChessPiece] = state):	
	if not is_diagonal(direction):
		return remove_blocked_moves(pawn, moves, _state)
		
	var valid_moves: Array[Vector2i] = []
	for move in moves:
		var piece: ChessPiece = get_piece_at_pos(move, _state)
		if (piece != null && piece.color != pawn.color) || (en_passant != null && move == en_passant.pos):
			valid_moves.push_back(move)
			
	return valid_moves


func is_diagonal(dir: Direction) -> bool:
	return dir == Direction.BOTTOM_LEFT || dir == Direction.BOTTOM_RIGHT || dir == Direction.TOP_LEFT || dir == Direction.TOP_RIGHT

func remove_blocked_moves(piece: ChessPiece, moves: Array[Vector2i], _state: Array[ChessPiece] = state) -> Array[Vector2i]:
	if not (piece is KnightChessPiece):			
		var valid_moves: int = moves.size()
		for i in range(moves.size()):
			var other_piece = get_piece_at_pos(moves[i], _state)
			if other_piece != null:
				valid_moves = i
				if other_piece.color != piece.color && not (piece is PawnChessPiece):
					valid_moves += 1
				break
		if valid_moves != moves.size():
			moves = moves.slice(0, valid_moves)
	else :
		var valid_moves: Array[Vector2i] = []
		for i in range(moves.size()):
			var other_piece = get_piece_at_pos(moves[i], _state)
			if other_piece == null || other_piece.color != piece.color:
				valid_moves.push_back(moves[i])
		moves = valid_moves
	return moves


func keep_distance_from_enemy_king(king: KingChessPiece, moves: Array[Vector2i], _state: Array[ChessPiece] = state) -> Array[Vector2i]:
	var enemy_king_pos: Vector2i = Constants.INVALID_CHESSBOARD_POS
	for i in range(_state.size()):
		if _state[i] is KingChessPiece && _state[i].color != king.color:
			enemy_king_pos = index_to_pos(i)
			break
	assert(enemy_king_pos != Constants.INVALID_CHESSBOARD_POS, "Shouldn't happen, game is expecting king to exist")
	var adjusted_moves: Array[Vector2i] = []
	for move in moves:
		if (enemy_king_pos - move).length() >= 2.0:
			adjusted_moves.push_back(move)
	return adjusted_moves
#endregion
#region Possible Moves (Safe)
func get_moves_safe_for_king() -> Dictionary:
	var king_pos: Vector2i = Constants.INVALID_CHESSBOARD_POS
	for i in range(state.size()):
		if state[i] != null && state[i] is KingChessPiece && state[i].color == Game.turn:
			king_pos = index_to_pos(i)
			break
	assert(king_pos != Constants.INVALID_CHESSBOARD_POS, "Guard")
	
	var safe_moves: Dictionary = {}
	var use_new_king_pos: bool = false
	for i in range(state.size()):
		if state[i] != null && state[i].color == Game.turn:
			if state[i] is KingChessPiece:
				use_new_king_pos = true
			else:
				use_new_king_pos = false
			var moves: Array[Vector2i] = await get_possible_moves(state[i])
			var temp_safe_moves: Array[Vector2i] = []
			for move in moves:
				var new_state = get_simulated_board_state(Move.new(state[i], index_to_pos(i), move))
				var new_enemy_moves = await get_possible_moves_for_all_pieces(Utilities.get_opposite_color(Game.turn), new_state)
				if use_new_king_pos:
					var new_king_pos: Vector2i = index_to_pos(new_state.find(state[i]))
					assert(new_king_pos != Constants.INVALID_CHESSBOARD_POS)
					if not new_enemy_moves.has(new_king_pos):
						temp_safe_moves.push_back(move)
				else:
					if not new_enemy_moves.has(king_pos):
						temp_safe_moves.push_back(move)
			Debug.log("Piece: %s. Moves: %s" % [str(state[i]), str(temp_safe_moves)])
			safe_moves[state[i]] = temp_safe_moves
	return safe_moves


func get_simulated_board_state(valid_move: Move) -> Array[ChessPiece]:
	var simulated_state: Array[ChessPiece] = state.duplicate()
	simulated_state[pos_to_index(valid_move.from)] = null
	simulated_state[pos_to_index(valid_move.to)] = valid_move.piece
	return simulated_state
#endregion
#region Movement Grid
func draw_movement_grid(held_piece: ChessPiece):
	var moves: Array[Vector2i] = snapshot.safe_moves[held_piece]
	if not moves.is_empty():
		for move in moves:
			var grid_type: MovementGrid.Type = MovementGrid.Type.MOVEMENT
			var piece: ChessPiece = state[pos_to_index(move)]
			if (piece != null && piece.color != Game.turn) || (held_piece is PawnChessPiece && (en_passant != null && move == en_passant.pos)):
				grid_type = MovementGrid.Type.ATTACK
			var tile: MovementGrid = create_grid(grid_type)
			tile.position = get_pixel_pos(move)
			tile.add_to_group("Grid")
			add_child(tile)

func create_grid(type: MovementGrid.Type) -> MovementGrid:
	var grid: MovementGrid = MovementGrid.new(type)
	return grid
#endregion
#region Movement
func move(piece: ChessPiece):
	var piece_index: int = state.find(piece)
	assert(piece_index != Constants.NOT_FOUND)
	
	var piece_chessboard_pos = index_to_pos(piece_index)
	var pixel_pos: Vector2 = get_pixel_pos(piece_chessboard_pos)
	var new_chessboard_pos: Vector2i = get_mouse_chessboard_pos()
	
	if not can_move(piece, new_chessboard_pos):
		piece.position = pixel_pos
		piece.z_index -= 1
		return
	
	await execute_movement(piece, piece_chessboard_pos, new_chessboard_pos)
	pixel_pos = get_pixel_pos(new_chessboard_pos)
	
	if piece != null:
		piece.position = pixel_pos
		piece.z_index -= 1
	
	movement_finished.emit()

func can_move(piece: ChessPiece, _pos: Vector2i) -> bool:
	return snapshot.safe_moves[piece].has(_pos)

## Handle Pawn's special actions, first movement, en passant opportunity for enemy and promotion
func execute_movement(piece: ChessPiece, from: Vector2i, to: Vector2i):
	update_move_history(Move.new(piece, from, to))
	
	# Handle state update, nullifying captured piece and square where piece was before movement
	# was initiated. After clear up, set our piece as destination's new content.
	state[pos_to_index(from)] = null
	var captured_piece: ChessPiece = state[pos_to_index(to)]
	if piece is PawnChessPiece && en_passant != null && to == en_passant.pos:
		captured_piece = en_passant.pawn
		state[state.find(captured_piece)] = null
	en_passant = null
	state[pos_to_index(to)] = piece
	
	if captured_piece != null:
		Debug.log("%s has captured %s!" % [piece, captured_piece])
		captured_piece.queue_free()
		captured.emit()
	
	if piece is PawnChessPiece:
		await handle_pawn_special_moves(piece, from, to)
	
	elif (piece is KingChessPiece && (abs(to - from).length() == 2)):
		await castle(from, to)
	
	if (piece is RookChessPiece || piece is KingChessPiece) && not piece.moved:
		piece.moved = true

	Debug.log("Moved %s" % piece)

func update_move_history(new_move: Move):
	assert(new_move != null, "Guard")
	if move_history.size() == Constants.MAX_RECORDED_ACTIONS:
		move_history = move_history.slice(2)
	move_history.push_back(new_move)

func handle_pawn_special_moves(pawn: ChessPiece, from: Vector2i, to: Vector2i):
	if pawn.first_move:
		pawn.first_move = false
		
	if abs(to - from).length() == 2:
		en_passant = EnPassant.new(pawn, from + (to - from)/2)
		Debug.log("En Passant added(%s)" % en_passant.pos)
		
	elif should_promote(pawn):
		pawn.position = get_pixel_pos(to)
		Debug.log("%s has been promoted!" % pawn)
		promoting.emit(pawn)
		await promoted
		pawn = get_piece_at_pos(to)
		
	pawn_moved.emit()

enum Direction { UP, DOWN, LEFT, RIGHT, TOP_LEFT, TOP_RIGHT, BOTTOM_RIGHT, BOTTOM_LEFT }

func castle(from: Vector2i, to: Vector2i):
	var distance: Vector2i = to - from
	var rook_column: int = 0
	
	if (vector_to_dir(distance)) == Direction.RIGHT:
		rook_column = COLUMNS - Constants.ZERO_INDEXING_OFFSET
	
	var rook_pos: Vector2i = Vector2i(rook_column, to.y)
	var rook_new_pos: Vector2i = Vector2i(from + distance/2)
	var rook: RookChessPiece = get_piece_at_pos(rook_pos)
	execute_movement(rook, rook_pos, rook_new_pos)
	rook.position = get_pixel_pos(rook_new_pos)
	Debug.log("Castling done!")
#endregion
#region Promotion
func promote(pawn: PawnChessPiece, promotion: ChessPiece):
	var type: ChessPiece.Type = promotion.type
	var board_pos: Vector2i = index_to_pos(state.find(pawn))
	var promoted_piece = ChessPieceFactory.create(type, pawn.color)
	add_piece(promoted_piece, board_pos)
	Debug.log("%s has been promoted to %s!" % [pawn, promoted_piece])
	pawn.queue_free()
	await pawn.tree_exiting
	promoted.emit()
	
func should_promote(pawn: PawnChessPiece) -> bool:
	var index: int = state.find(pawn)
	assert(index != Constants.NOT_FOUND , "Guard")
	var required_row_index = 0
	if pawn.color != Game.player_color:
		required_row_index = ROWS - Constants.ZERO_INDEXING_OFFSET
	var pos: Vector2i = index_to_pos(index)
	return pos.y == required_row_index
#endregion
#region Check
func is_king_checked() -> bool:
	var index: int = Constants.INVALID_INDEX
	for i in range(state.size()):
		if state[i] is KingChessPiece && state[i].color == Game.turn:
			index = i
			break
	assert(index != Constants.INVALID_INDEX, "Guard")
	return snapshot.enemy_moves.has(index_to_pos(index))
#endregion
#region Castle
class RookToCastle:
	var rook: RookChessPiece = null
	var pos: Vector2
	var tiles: Array[Vector2i] = []
	
	func _init(_rook: RookChessPiece, _pos: Vector2):
		rook = _rook
		pos = _pos

func get_possible_castle() -> Array[Vector2i]:
	var king: KingChessPiece = null
	var king_board_pos: Vector2i = Constants.INVALID_CHESSBOARD_POS
	for i in range(state.size()):
		if state[i] != null && state[i] is KingChessPiece && state[i].color == Game.turn:
			king_board_pos = index_to_pos(i)
			king = state[i]
	assert(king != null)
	var castles: Array[Vector2i] = []
	
	if king.moved: 
		return castles
	
	if is_king_checked():
		Debug.log("Can't perform castling, the King is checked!")
		return castles
	
	var available_rooks: Array[RookToCastle] = []
	for i in range(state.size()):
		if state[i] != null && state[i] is RookChessPiece && state[i].color == king.color && not state[i].moved:
			available_rooks.push_back(RookToCastle.new(state[i], index_to_pos(i)))
	
	if available_rooks.is_empty():
		return castles
	
	for rook in available_rooks:
		rook.tiles.append_array(Utilities.get_position_between(king_board_pos, rook.pos).slice(0, 3))
		var valid: bool = true
		for tile in rook.tiles:
			if get_piece_at_pos(tile) != null || snapshot.enemy_moves.has(tile):
				valid = false
				break
		if not valid:
			rook.tiles.clear()
	
	for rook in available_rooks:
		if not rook.tiles.is_empty():
			castles.push_back(rook.tiles[1])
			Debug.log("Castling available (%s)" % rook.tiles[1])

	return castles
#endregion
#region Core Utilities
func get_pointed_piece() -> ChessPiece:
	var pos: Vector2i = get_mouse_chessboard_pos()
	if not is_pos_valid(pos):
		return null
		
	var piece = get_piece_at_pos(pos)
	return piece


func get_piece_at_pos(_pos: Vector2i, _state: Array[ChessPiece] = state) -> ChessPiece:
	var piece: ChessPiece = null
	if is_pos_valid(_pos):
		piece = _state[pos_to_index(_pos)]
	return piece

func is_pos_valid(pos: Vector2i) -> bool:
	const ORIGIN: Vector2i = Vector2i(0, 0)
	
	return (pos.x >= ORIGIN.x && pos.x < COLUMNS) && (pos.y >= ORIGIN.y && pos.y < ROWS)


func get_pixel_pos(pos: Vector2i) -> Vector2:
	pos = pos.clamp(Vector2i(0,0), Vector2i(COLUMNS - Constants.ZERO_INDEXING_OFFSET, ROWS - Constants.ZERO_INDEXING_OFFSET))
	const PIXEL_OFFSET: Vector2 = round(SQUARE_SIZE/2)
	return to_local(Vector2(SQUARE_SIZE * pos) + PIXEL_OFFSET)

func get_mouse_chessboard_pos() -> Vector2i:
	var pos = get_local_mouse_position() + OFFSET
	pos = pos / Vector2(SQUARE_SIZE)
	return Vector2i(pos)
#endregion
#region Indexing Utilities
func index_to_pos(index: int) -> Vector2i:
	var pos_y: int = index/COLUMNS
	return Vector2i(index - (pos_y * COLUMNS), pos_y)

func pos_to_index(_pos: Vector2i) -> int:
	return _pos.x + _pos.y * COLUMNS
#endregion
#region Debug Utilities
func show_state(_state: Array[ChessPiece] = state):
	var string = ""
	for i in range(ROWS):
		for j in range(COLUMNS):
			if _state[j + i * COLUMNS] == null:
				string += "0 "
			else:
				string += ChessPiece.TYPE_TO_STR[_state[j + i * COLUMNS].type][0] + " "
		string += "\n"
	Debug.log(string)
#endregion
