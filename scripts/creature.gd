# gdlint:ignore = class-definitions-order
extends CharacterBody2D

@export var sprite_sheet: Texture2D
@export var frame_size: Vector2i = Vector2i(0, 0)
@export var columns: int = 9
@export var rows: int = 0
@export var margin: Vector2i = Vector2i(0, 0)
@export var spacing: Vector2i = Vector2i(0, 0)
@export var color_row: int = 0
@export var random_row: bool = true
@export var idle_start_col: int = 5
@export var idle_frame_count: int = 4
@export var idle_fps: float = 6.0
@export var death_start_col: int = 0
@export var death_frame_count: int = 4
@export var death_fps: float = 10.0
@export var coin_reward: int = 1
@export var sprite_scale: float = 8.0
@export var feet_offset: float = 40.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

var _player: Node2D = null
var _dying := false

@onready var death1 = $DeathSound1
@onready var death2 = $DeathSound2


func _ready() -> void:
	_pick_row()
	_build_animations()
	anim.play("idle")
	if anim.sprite_frames != null and anim.sprite_frames.has_animation("death"):
		anim.sprite_frames.set_animation_loop("death", false)
	anim.scale = Vector2(sprite_scale, sprite_scale)
	collision_layer = 0
	collision_mask = 0
	z_index = 5
	if hitbox != null and not hitbox.body_entered.is_connected(_on_body_entered):
		hitbox.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _dying:
		return
	# Standing idle; no movement.


func set_player(node: Node2D) -> void:
	_player = node


func _pick_row() -> void:
	if random_row:
		color_row = randi() % max(1, rows)


func _build_animations() -> void:
	if anim == null:
		return
	# If no sheet is provided, keep frames from the scene (AsepriteWizard output).
	if sprite_sheet == null:
		return
	_ensure_sheet_metrics()
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", idle_fps)
	frames.set_animation_loop("idle", true)

	for i in range(idle_frame_count):
		var col = idle_start_col + i
		if col >= columns:
			break
		frames.add_frame("idle", _frame_at(col, color_row))

	frames.add_animation("death")
	frames.set_animation_speed("death", death_fps)
	frames.set_animation_loop("death", false)

	for i in range(death_frame_count):
		var col = death_start_col + i
		if col >= columns:
			break
		frames.add_frame("death", _frame_at(col, color_row))

	anim.frames = frames


func _frame_at(col: int, row: int) -> AtlasTexture:
	var x = margin.x + col * (frame_size.x + spacing.x)
	var y = margin.y + row * (frame_size.y + spacing.y)
	var region = Rect2i(x, y, frame_size.x, frame_size.y)
	var atlas := AtlasTexture.new()
	atlas.atlas = sprite_sheet
	atlas.region = region
	return atlas


func _ensure_sheet_metrics() -> void:
	if frame_size.x > 0 and frame_size.y > 0 and rows > 0:
		return
	var tex_size = sprite_sheet.get_size()
	if columns <= 0:
		columns = 1
	var auto_w = int(tex_size.x / columns)
	var auto_h = auto_w if rows <= 0 else int(tex_size.y / max(1, rows))
	if rows <= 0 and auto_h > 0:
		rows = int(tex_size.y / auto_h)
	if frame_size.x <= 0 or frame_size.y <= 0:
		frame_size = Vector2i(auto_w, auto_h)


func _on_body_entered(body: Node) -> void:
	if _dying:
		return
	if body == null:
		return
	if body.is_in_group("player") or body.name == "Player":
		_die()


func _die() -> void:
	_dying = true
	anim.play("death")
	_award_coins()
	anim.animation_finished.connect(_on_death_finished, CONNECT_ONE_SHOT)
	if randf() < 0.25:
		if randf() < 0.5:
			death1.play()
			return
		death2.play()


func _on_death_finished() -> void:
	queue_free()


func _award_coins() -> void:
	if _player != null:
		_player.add_coins(coin_reward)
