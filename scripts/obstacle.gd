extends StaticBody2D
class_name Obstacle

@export var health: int = 1
@export var bounce_force: float = 300.0
@export var money_value: float = 10.0
@export var width: float = 60.0
@export var height: float = 40.0

var is_destroyed: bool = false

func _ready() -> void:
	# Setup collision if not already done
	if get_node_or_null("CollisionShape2D") == null:
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(width, height)
		collision.shape = shape
		add_child(collision)

func hit_by_player(player: Player) -> void:
	"""Called when player hits this obstacle"""
	if is_destroyed:
		return
	
	health -= 1
	player.bounce(bounce_force)
	
	if health <= 0:
		destroy()
	
	SignalBus.obstacle_hit.emit(self, money_value)

func destroy() -> void:
	"""Remove this obstacle"""
	if is_destroyed:
		return
	is_destroyed = true
	
	# Spawn effect
	var effect = preload("res://scenes/effects/crash_effect.tscn").instantiate()
	get_parent().add_child(effect)
	effect.position = position
	
	# Emit money
	SignalBus.money_spawned.emit(money_value, position)
	
	queue_free()

func get_info() -> Dictionary:
	return {
		"health": health,
		"destroyed": is_destroyed,
		"money": money_value
	}
