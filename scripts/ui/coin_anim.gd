extends TextureRect

@export var frame_size := Vector2i(120, 120)
@export var frame_count := 8
@export var fps := 12.0

var _atlas: AtlasTexture
var _time := 0.0


func _ready() -> void:
	var source := load("res://assets/coin.png") as Texture2D
	if source == null:
		return
	_atlas = AtlasTexture.new()
	_atlas.atlas = source
	_atlas.region = Rect2i(0, 0, frame_size.x, frame_size.y)
	texture = _atlas


func _process(delta: float) -> void:
	if _atlas == null:
		return
	_time += delta
	var frame := int(_time * fps) % frame_count
	_atlas.region = Rect2i(frame * frame_size.x, 0, frame_size.x, frame_size.y)
