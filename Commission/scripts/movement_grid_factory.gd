extends  ChessboardElementFactory

class_name MovementGridFactory

static func create(type: MovementGrid.Type, pos: Vector2i) -> MovementGrid:
	var grid: MovementGrid = MovementGrid.new(type)
	grid.position = get_pos(pos)
	return grid
