extends Area2D
class_name PowerUp

@export var effect_name: String = "unknown"
@export var duration: float = 5.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	"""Called when player collides with powerup"""
	if body is Player:
		apply_effect(body)
		queue_free()

func apply_effect(player: Player) -> void:
	"""Override in child classes"""
	print("PowerUp effect: %s" % effect_name)
	SignalBus.powerup_collected.emit(effect_name, player)
