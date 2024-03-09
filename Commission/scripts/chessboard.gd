extends TileMap

class_name Chessboard

const ROWS: int = 8
const COLUMNS: int = 8
const SQUARE_SIZE: Vector2i = Vector2i(39, 36)
const SIZE: Vector2 = Vector2(SQUARE_SIZE.x * COLUMNS, SQUARE_SIZE.y * ROWS)

static var pos: Vector2
static var origin: Vector2
static var state: Array[ChessPiece] = []
static var initialized: bool = false

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
		return move.piece == piece && move.from == from && move.to == to

static var move_history: Array[Move] = []

class EnPassant:
	func _init(_pawn: PawnChessPiece, _pos: Vector2i):
		pawn = _pawn
		pos = _pos

	var pawn: PawnChessPiece
	var pos: Vector2i

static var en_passant: EnPassant = null

func _ready():
	_initialize()
	initialized = true

func _initialize():
	var window: Vector2 = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), 
	ProjectSettings.get_setting("display/window/size/viewport_height"))
	pos = Vector2(window.x/2, window.y/2)
	origin = pos - SIZE/2
	position = pos
	state.resize(ROWS * COLUMNS)
	state.fill(null)

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

static func fill(player_color: ChessPiece.ChessColor = ChessPiece.ChessColor.WHITE):
	var opponent_color: ChessPiece.ChessColor = ChessPiece.ChessColor.BLACK
	if player_color == opponent_color:
		opponent_color = ChessPiece.ChessColor.WHITE
	
	for i in range(COLUMNS):
		add_piece(ChessPieceFactory.create(ChessPiece.Type.PAWN, opponent_color, Vector2i(i, OPPONENT_PAWN_ROW_INDEX)))
		add_piece(ChessPieceFactory.create(ChessPiece.Type.PAWN, player_color, Vector2i(i, PLAYER_PAWN_ROW_INDEX)))
		
	var premium_piece_order: Array[ChessPiece.Type] = PREMIUM_PIECE_ORDER
	for i in range(premium_piece_order.size()):
		add_piece(ChessPieceFactory.create(premium_piece_order[i], opponent_color, Vector2i(i, OPPONENT_PREMIUM_ROW_INDEX)))
		add_piece(ChessPieceFactory.create(premium_piece_order[i], player_color, Vector2i(i, PLAYER_PREMIUM_ROW_INDEX)))
	
	const UNIQUE_PIECES: Array[ChessPiece.Type] = [ChessPiece.Type.QUEEN, ChessPiece.Type.KING]
	
	for i in range(premium_piece_order.size() - UNIQUE_PIECES.size()):
		add_piece(ChessPieceFactory.create(premium_piece_order[UNIQUE_PIECES.size() - i], opponent_color, 
				Vector2i(premium_piece_order.size() + i, OPPONENT_PREMIUM_ROW_INDEX)))
		add_piece(ChessPieceFactory.create(premium_piece_order[UNIQUE_PIECES.size()- i], player_color, 
				Vector2i(premium_piece_order.size() + i, PLAYER_PREMIUM_ROW_INDEX)))

static func add_piece(piece: ChessPiece):
	piece.add_to_group("Pieces")
	match(piece._color):
		ChessPiece.ChessColor.WHITE:
			piece.add_to_group("White")
		ChessPiece.ChessColor.BLACK:
			piece.add_to_group("Black")
	Game.instance.add_child.call_deferred(piece)

static func get_piece_at_pos(_pos: Vector2i, _state: Array[ChessPiece] = state) -> ChessPiece:
	var piece: ChessPiece = null
	if is_pos_valid(_pos):
		piece = _state[pos_to_index(_pos)]
	return piece

static func show_state(_state: Array[ChessPiece] = state):
	var string = ""
	for i in range(ROWS):
		for j in range(COLUMNS):
			if _state[j + i * COLUMNS] == null:
				string += "0 "
			else:
				string += ChessPiece.TYPE_TO_STR[_state[j + i * COLUMNS]._type][0] + " "
		string += "\n"
	Debug.log(string)

static func index_to_pos(index: int) -> Vector2i:
	var pos_y: int = index/COLUMNS
	return Vector2i(index - (pos_y * COLUMNS), pos_y)

static func pos_to_index(_pos: Vector2i) -> int:
	return _pos.x + _pos.y * COLUMNS

static func is_pos_valid(_pos: Vector2i) -> bool:
	return (_pos.x >= 0 && _pos.x < COLUMNS) && (_pos.y >= 0 && _pos.y < ROWS)

enum Direction { UP, DOWN, LEFT, RIGHT, TOP_LEFT, TOP_RIGHT, BOTTOM_RIGHT, BOTTOM_LEFT }

static func vector_to_dir(vec) -> Direction:
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
	
static func possible_moves_to_dir_vectors(possible_moves: Array[Vector2i]):
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

static var protected_positions: Array[Vector2i] = []

static func remove_blocked_moves(piece: ChessPiece, moves: Array[Vector2i], _state: Array[ChessPiece] = state) -> Array[Vector2i]:
	if not (piece is KnightChessPiece):			
		var valid_moves: int = moves.size()
		for i in range(moves.size()):
			var other_piece = get_piece_at_pos(moves[i], _state)
			if other_piece != null:
				valid_moves = i
				if other_piece._color != piece._color && not (piece is PawnChessPiece):
					valid_moves += 1
				elif other_piece._color == piece._color:
					protected_positions.push_back(moves[i])
				break
		if valid_moves != moves.size():
			moves = moves.slice(0, valid_moves)
	else :
		var valid_moves: Array[Vector2i] = []
		for i in range(moves.size()):
			var other_piece = get_piece_at_pos(moves[i], _state)
			if other_piece != null && other_piece._color == piece._color:
				protected_positions.push_back(moves[i])
			else:
				valid_moves.push_back(moves[i])
		moves = valid_moves
	return moves

static func get_simulated_board_state(valid_move: Move) -> Array[ChessPiece]:
	var simulated_state: Array[ChessPiece] = state.duplicate()
	simulated_state[pos_to_index(valid_move.from)] = null
	simulated_state[pos_to_index(valid_move.to)] = valid_move.piece
	return simulated_state

static func get_moves_safe_for_king() -> Dictionary:
	var king_pos: Vector2i = INVALID_POS
	for i in range(state.size()):
		if state[i] != null && state[i] is KingChessPiece && state[i]._color == Game.instance.turn:
			king_pos = index_to_pos(i)
			break
	assert(king_pos != INVALID_POS, "Guard")
	
	var safe_moves: Dictionary = {}
	var use_new_king_pos: bool = false
	for i in range(state.size()):
		if state[i] != null && state[i]._color == Game.instance.turn:
			if state[i] is KingChessPiece:
				use_new_king_pos = true
			else:
				use_new_king_pos = false
			var moves: Array[Vector2i] = await get_possible_moves(state[i])
			var temp_safe_moves: Array[Vector2i] = []
			for move in moves:
				var new_state = get_simulated_board_state(Move.new(state[i], index_to_pos(i), move))
				var new_enemy_moves = await get_possible_moves_for_all_pieces(get_enemy_color(state[i]._color), new_state)
				if use_new_king_pos:
					var new_king_pos: Vector2i = index_to_pos(new_state.find(state[i]))
					assert(new_king_pos != INVALID_POS)
					if not new_enemy_moves.has(new_king_pos):
						temp_safe_moves.push_back(move)
				else:
					if not new_enemy_moves.has(king_pos):
						temp_safe_moves.push_back(move)
			print("Piece: %s. Moves: %s" % [str(state[i]), str(temp_safe_moves)])
			safe_moves[state[i]] = temp_safe_moves
	return safe_moves
					
static func is_diagonal(dir: Direction) -> bool:
	return dir == Direction.BOTTOM_LEFT || dir == Direction.BOTTOM_RIGHT || dir == Direction.TOP_LEFT || dir == Direction.TOP_RIGHT

static func is_horizontal(dir: Direction) -> bool:
	return dir == Direction.LEFT || dir == Direction.RIGHT


static func adjust_moves_for_pawn(pawn: PawnChessPiece, direction: Direction, moves: Array[Vector2i], _state: Array[ChessPiece] = state):
	if not is_diagonal(direction):
		return remove_blocked_moves(pawn, moves, _state)
		
	var valid_moves: Array[Vector2i] = []
	for move in moves:
		var piece: ChessPiece = get_piece_at_pos(move, _state)
		if (piece != null && piece._color != pawn._color) || (en_passant != null && move == en_passant.pos):
			valid_moves.push_back(move)
			
	return valid_moves


class RookToCastle:
	var rook: RookChessPiece = null
	var pos: Vector2
	var tiles: Array[Vector2i] = []
	
	func _init(_rook: RookChessPiece, _pos: Vector2):
		rook = _rook
		pos = _pos

static func get_position_between(v1: Vector2i, v2: Vector2i) -> Array[Vector2i]:
	assert(v1.x == v2.x || v1.y == v2.y)
	var iterator: Vector2i = Vector2i(0, 1)
	if v1.y == v2.y:
		iterator = Vector2i(1, 0)
	
	if v1.x > v2.x || v1.y > v2.y:
		iterator = -iterator
	
	var iterated_value: Vector2i = v1 + iterator
	var positions: Array[Vector2i] = []
		
	while (iterated_value != v2):
		positions.push_back(iterated_value)
		iterated_value += iterator
	return positions

static func get_possible_moves_for_all_pieces(color: ChessPiece.ChessColor, _state: Array[ChessPiece] = state) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for piece in _state:
		if piece != null && piece._color == color:
			moves.append_array(await get_possible_moves(piece, _state))
			moves.sort()
	return moves

static func get_enemy_color(color: ChessPiece.ChessColor) -> ChessPiece.ChessColor:
	match(color):
		ChessPiece.ChessColor.WHITE:
			return ChessPiece.ChessColor.BLACK
		ChessPiece.ChessColor.BLACK:
			return ChessPiece.ChessColor.WHITE
		_:
			push_error("Shouldn't happen, modify method if you added new colors")
			return 0

const INVALID_INDEX: int = -1

static func is_king_checked() -> bool:
	var index: int = INVALID_INDEX
	for i in range(state.size()):
		if state[i] is KingChessPiece && state[i]._color == Game.instance.turn:
			index = i
			break
	assert(index != INVALID_INDEX, "Guard")
	return Game.instance.enemy_moves.has(index_to_pos(index))

static func get_possible_castle() -> Array[Vector2i]:
	var king: KingChessPiece = null
	var king_board_pos: Vector2i = INVALID_POS
	for i in range(state.size()):
		if state[i] != null && state[i] is KingChessPiece && state[i]._color == Game.instance.turn:
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
		if state[i] != null && state[i] is RookChessPiece && state[i]._color == king._color && not state[i].moved:
			available_rooks.push_back(RookToCastle.new(state[i], index_to_pos(i)))
	
	if available_rooks.is_empty():
		return castles
	
	for rook in available_rooks:
		rook.tiles.append_array(get_position_between(king_board_pos, rook.pos).slice(0, 3))
		var valid: bool = true
		for tile in rook.tiles:
			if get_piece_at_pos(tile) != null || Game.instance.enemy_moves.has(tile):
				valid = false
				break
		if not valid:
			rook.tiles.clear()
	
	for rook in available_rooks:
		if not rook.tiles.is_empty():
			castles.push_back(rook.tiles[1])
			Debug.log("Castling available (%s)" % rook.tiles[1])

	return castles

const INVALID_POS: Vector2i = Vector2i(-1, -1)

static func keep_distance_from_enemy_king(king: KingChessPiece, moves: Array[Vector2i], _state: Array[ChessPiece] = state) -> Array[Vector2i]:
	var enemy_king_pos: Vector2i = INVALID_POS
	for i in range(_state.size()):
		if _state[i] is KingChessPiece && _state[i]._color != king._color:
			enemy_king_pos = index_to_pos(i)
			break
	assert(enemy_king_pos != INVALID_POS, "Shouldn't happen, game is expecting king to exist")
	var adjusted_moves: Array[Vector2i] = []
	for move in moves:
		if (enemy_king_pos - move).length() >= 2.0:
			adjusted_moves.push_back(move)
	return adjusted_moves
	
static func get_possible_moves(piece: ChessPiece, _state: Array[ChessPiece] = state) -> Array[Vector2i]:
	var possible_moves: Array[Vector2i] = []
	var piece_index: int = _state.find(piece)
	
	if piece != null && piece_index != Constants.NOT_FOUND:
		var directional_moves: Dictionary = possible_moves_to_dir_vectors(piece.get_move_pattern())
		var board_pos: Vector2i = index_to_pos(piece_index)
		
		for key in directional_moves.keys():
			directional_moves[key] = piece.get_relative_move_pattern(board_pos, directional_moves[key])
		Debug.log_moves(directional_moves, "Directional Moves before snapping")

		for key in directional_moves.keys():
			var valid_moves: Array[Vector2i] = []
			valid_moves.assign(directional_moves[key].filter(func(vec): return is_pos_valid(vec)))
			directional_moves[key] = valid_moves
			if directional_moves[key].is_empty():
				directional_moves.erase(key)		
		Debug.log_moves(directional_moves, "Directional Moves after snapping")
		
		for key in directional_moves.keys():
			if piece is PawnChessPiece:
				directional_moves[key] = adjust_moves_for_pawn(piece, key, directional_moves[key], _state)
			else:
				directional_moves[key] = remove_blocked_moves(piece, directional_moves[key], _state)
			possible_moves.append_array(directional_moves[key])
		Debug.log_moves(possible_moves, "Possible Moves")
		
		if piece is KingChessPiece:
			possible_moves = keep_distance_from_enemy_king(piece, possible_moves, _state)
			if not piece.moved && piece._color == Game.turn:
				if not Game.instance.castles.is_empty():
					possible_moves.append_array(Game.instance.castles)
			
	possible_moves.sort()
	return possible_moves
	
static func can_move(piece: ChessPiece, _pos: Vector2i) -> bool:
	var possible_moves: Array[Vector2i] = await get_possible_moves(piece)
	print("Piece: %s, Possible moves: %s" % [piece, str(possible_moves)])
	print("All safe moveS: %s" % str(Game.instance.safe_moves))
	var valid_moves: Array[Vector2i] = []
	for move in possible_moves:
		if Game.instance.safe_moves[piece].has(move):
			valid_moves.push_back(move)
	possible_moves = valid_moves
	return possible_moves.has(_pos)
	
static func get_statistics() -> Dictionary:
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
			if piece._color == ChessPiece.ChessColor.WHITE:
				white[piece._type] += 1
			else:
				black[piece._type] += 1
	for i in range(white.size()):
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

static func should_draw() -> bool:
	var statistics: Dictionary = get_statistics()
	if (statistics["count"] <= 4 && (statistics["white_count"] <= 2 && statistics["black_count"] <= 2) &&	
		statistics["both_colors"][ChessPiece.Type.QUEEN] == 0 && 
		statistics["both_colors"][ChessPiece.Type.ROOK] == 0 && 
		statistics["both_colors"][ChessPiece.Type.PAWN] == 0):
		return true
	elif move_history.size() == MAX_RECORDED_ACTIONS:
		if move_history[0].eq(move_history[4]) && move_history[1].eq(move_history[5]):
			return true
		move_history = move_history.slice(2)
	return false

const MAX_PLAYER_RECORDED_ACTIONS: int = 3
const MAX_RECORDED_ACTIONS: int = MAX_PLAYER_RECORDED_ACTIONS * 2

static func update_move_history(new_move: Move):
	assert(new_move != null, "Guard")
	move_history.push_back(new_move) 
