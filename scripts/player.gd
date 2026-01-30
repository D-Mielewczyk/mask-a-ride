extends CharacterBody2D
class_name Player

@export var move_speed: float = 200.0
@export var gravity: float = 800.0
@export var bounce_force: float = 400.0
@export var friction: float = 0.98

var distance_traveled: float = 0.0
var money_collected: float = 0.0
var is_alive: bool = true

func _ready() -> void:
	velocity.x = move_speed

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	# Apply gravity
	velocity.y += gravity * delta
	
	# Apply friction
	velocity.x *= friction
	
	# Move
	move_and_slide()
	
	# Track distance
	distance_traveled += move_speed * delta
	
	# Check if fell off world
	if position.y > 1200:
		die()

func bounce(force: float = bounce_force) -> void:
	"""Called when hitting an obstacle"""
	if not is_alive:
		return
	velocity.y = -force
	velocity.x *= 0.7

func collect_money(amount: float) -> void:
	"""Called when hitting money powerup"""
	money_collected += amount
	SignalBus.money_collected.emit(amount, position)

func die() -> void:
	"""End game"""
	if is_alive:
		is_alive = false
		SignalBus.player_died.emit(distance_traveled, money_collected)

func get_stats() -> Dictionary:
	return {
		"distance": distance_traveled,
		"money": money_collected,
		"alive": is_alive
	}
