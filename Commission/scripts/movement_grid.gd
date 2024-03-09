extends Sprite2D

class_name MovementGrid

const TILE_TEXTURE: Texture2D = preload("res://assets/squares.png")
const TILES: int = 4

enum Type { MOVEMENT, ATTACK }
const TYPE_TO_FRAME: Dictionary = {
	Type.MOVEMENT: 2,
	Type.ATTACK: 3,
}

func _init(type: Type):
	texture = TILE_TEXTURE
	hframes = TILES
	vframes = 1
	frame = TYPE_TO_FRAME[type]

