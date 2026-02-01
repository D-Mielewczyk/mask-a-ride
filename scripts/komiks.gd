extends Node2D

@export var next_scene: PackedScene = preload("res://scenes/main.tscn")
@export var panels: int = 4
@export var cols: int = 2
@export var rows: int = 2

@onready var sprite: Sprite2D = $CanvasLayer/ComicSprite
@onready var brum: AudioStreamPlayer2D = $brum
@onready var awoo: AudioStreamPlayer2D = $awoo
@onready var crash: AudioStreamPlayer2D = $crash

var index: int = 0

# służy do "resetowania" await timera (anulowanie poprzedniego odliczania)
var autoplay_seq: int = 0

func _stop_all_sfx() -> void:
	if brum != null: brum.stop()
	if crash != null: crash.stop()
	if awoo != null: awoo.stop()

func _ready() -> void:
	await get_tree().process_frame
	index = 0
	_show_panel(index)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_next()
		#get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed:
		var k: InputEventKey = event as InputEventKey
		if k.keycode == KEY_SPACE or k.keycode == KEY_ENTER:
			_next()
			get_viewport().set_input_as_handled()
			return

func _next() -> void:
	index += 1
	if index >= panels:
		# unieważnij ewentualny autoplay i wyczyść audio
		autoplay_seq += 1
		_stop_all_sfx()
		get_tree().change_scene_to_packed(next_scene)
		return

	_show_panel(index)

func _show_panel(i: int) -> void:
	var rect: Rect2 = _panel_rect(i)
	sprite.region_enabled = true
	sprite.region_rect = rect

	_stop_all_sfx()
	if i == 0 or i == 1:
		brum.play()
	elif i == 2:
		crash.play()
	elif i == 3:
		awoo.play()

	# dopasuj do ekranu
	var vp: Vector2 = get_viewport_rect().size
	var max_w: float = vp.x * 0.92
	var max_h: float = vp.y * 0.92
	var s: float = minf(max_w / rect.size.x, max_h / rect.size.y)

	sprite.scale = Vector2(s, s)
	sprite.position = vp * 0.5

	_arm_autoplay(i) # <-- jeśli nie klikniesz, po 2s przejdzie dalej

func _arm_autoplay(expected_index: int) -> void:
	autoplay_seq += 1
	var seq: int = autoplay_seq
	_autoplay_after_delay(seq, expected_index)

func _autoplay_after_delay(seq: int, expected_index: int) -> void:
	await get_tree().create_timer(2.0).timeout

	# jeśli w międzyczasie kliknąłeś / zmienił się panel, nic nie rób
	if seq != autoplay_seq:
		return
	if index != expected_index:
		return

	_next()

func _panel_rect(i: int) -> Rect2:
	var tex_size: Vector2i = sprite.texture.get_size()
	var w: float = float(tex_size.x) / float(cols)
	var h: float = float(tex_size.y) / float(rows)

	var col: int = i % cols
	var row: int = i / cols

	return Rect2(float(col) * w, float(row) * h, w, h)
