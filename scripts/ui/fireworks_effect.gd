# gdlint:ignore = class-definitions-order
extends CanvasLayer

signal finished

@export var duration := 1.2
@onready var particles: CPUParticles2D = $CPUParticles2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if particles != null:
		particles.position = get_viewport_rect().size * 0.5
		particles.emitting = true
	if particles != null and particles.texture == null:
		particles.texture = _make_particle_texture()
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = duration
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(timer)
	timer.timeout.connect(_on_timeout)
	timer.start()


func _on_timeout() -> void:
	finished.emit()
	queue_free()


func _make_particle_texture() -> Texture2D:
	var size := 8
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)
