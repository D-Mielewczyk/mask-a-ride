# gdlint:ignore = class-definitions-order
extends Area2D


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
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("death"):
			body.death()
		queue_free()


func _on_screen_exited() -> void:
	queue_free()
