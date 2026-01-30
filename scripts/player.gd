# gdlint:ignore = class-definitions-order
class_name Player
extends CharacterBody2D

# Movement properties
@export var move_speed: float = 200.0
@export var gravity: float = 800.0
@export var air_friction: float = 0.99
@export var terrain_friction: float = 0.95
@export var bounce_force: float = 400.0
@export var collision_cooldown_duration: float = 0.2

# State
var distance_traveled: float = 0.0
var money_collected: float = 0.0
var is_alive: bool = true
var current_terrain: String = "air"  # "air" or terrain type name
var is_on_ground: bool = false
var last_collided_obstacle: Node = null
var collision_cooldown: float = 0.0
var _last_position: Vector2 = Vector2.ZERO
var _default_terrain_friction: float = 0.0


func _ready() -> void:
	# Initial horizontal velocity
	velocity.x = move_speed
	_last_position = position
	_default_terrain_friction = terrain_friction


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Update collision cooldown
	if collision_cooldown > 0:
		collision_cooldown = maxf(collision_cooldown - delta, 0.0)

	# Apply gravity (vertical velocity)
	velocity.y += gravity * delta

	# Move using CharacterBody2D built-in physics
	move_and_slide()

	# Check if on ground
	is_on_ground = is_on_floor()

	# Update terrain based on what we're standing on
	_update_current_terrain()

	# Apply appropriate friction based on terrain
	var current_friction = air_friction if not is_on_ground else terrain_friction
	velocity.x *= current_friction

	# Maintain a minimum forward speed while allowing downhill boosts
	if velocity.x < move_speed:
		velocity.x = move_speed

	# Track distance traveled
	var delta_x = position.x - _last_position.x
	if delta_x > 0:
		distance_traveled += delta_x
	_last_position = position

	# Check if player fell off world
	if position.y > 1200:
		die()


func _update_current_terrain() -> void:
	"""Check what terrain player is standing on and update friction accordingly"""
	if not is_on_ground:
		current_terrain = "air"
		return

	# Get the colliding body
	var colliding_body = get_last_slide_collision()
	if colliding_body:
		var collider = colliding_body.get_collider()
		if collider:
			# Check if collider has a terrain_type property or group
			if collider.is_in_group("terrain_grass"):
				current_terrain = "grass"
				terrain_friction = 0.95
			elif collider.is_in_group("terrain_ice"):
				current_terrain = "ice"
				terrain_friction = 0.98
			elif collider.is_in_group("terrain_mud"):
				current_terrain = "mud"
				terrain_friction = 0.85
			else:
				current_terrain = "default"
				terrain_friction = _default_terrain_friction


func collide(collider: Node) -> void:
	"""Handle collision with obstacle based on its type/groups"""
	if not is_alive:
		return

	# Prevent multiple collisions with same object within cooldown
	if collider == last_collided_obstacle and collision_cooldown > 0:
		return

	# Reset cooldown for this obstacle
	last_collided_obstacle = collider
	collision_cooldown = collision_cooldown_duration

	# Bouncy obstacles - balloon, trampoline, etc
	if collider.is_in_group("obstacle_bounce"):
		velocity.y = -bounce_force
		velocity.x *= 0.7

	# Spike/lethal obstacles - instant death
	elif collider.is_in_group("obstacle_spike"):
		die()

	# Heavy obstacles - smaller bounce, damage could be added later
	elif collider.is_in_group("obstacle_heavy"):
		velocity.y = -bounce_force * 0.5
		velocity.x *= 0.5

	# Default collision - slight bounce
	else:
		velocity.y = -bounce_force * 0.3
		velocity.x *= 0.8


func collect_money(amount: float) -> void:
	"""Called when hitting money/powerup"""
	money_collected += amount
	if get_tree().get_first_node_in_group("signal_bus"):
		get_tree().get_first_node_in_group("signal_bus").money_collected.emit(amount, position)


func die() -> void:
	"""End game"""
	if is_alive:
		is_alive = false
		if get_tree().get_first_node_in_group("signal_bus"):
			get_tree().get_first_node_in_group("signal_bus").player_died.emit(
				distance_traveled, money_collected
			)


func get_stats() -> Dictionary:
	return {
		"distance": distance_traveled,
		"money": money_collected,
		"alive": is_alive,
		"position": position,
		"velocity": velocity,
		"terrain": current_terrain,
		"on_ground": is_on_ground
	}
