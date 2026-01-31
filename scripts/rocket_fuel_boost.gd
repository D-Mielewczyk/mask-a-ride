# gdlint:ignore = class-definitions-order
extends Area2D

@export var fuel_percent := 0.2


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if has_node("VisibleOnScreenNotifier2D"):
		var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
		if not notifier.screen_exited.is_connected(_on_screen_exited):
			notifier.screen_exited.connect(_on_screen_exited)


func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if not (body is RigidBody2D) and not body.is_in_group("player"):
		return
	if "max_fuel" in body:
		var amount = body.max_fuel * fuel_percent
		body.add_fuel(amount)
	queue_free()


func _on_screen_exited() -> void:
	queue_free()
