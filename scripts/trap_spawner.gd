# gdlint:ignore = class-definitions-order
extends Node2D

@export var trap_scene: PackedScene = preload("res://scenes/traps/trap.tscn")
@export var spawn_interval: float = 6.0
@export var max_alive: int = 3
@export var spawn_distance_min: float = 1500.0
@export var spawn_distance_max: float = 2600.0
@export var min_player_x_to_spawn: float = 1200.0
@export var avoid_on_screen: bool = true
@export var player_path: NodePath

var _time_accum := 0.0


func _process(delta: float) -> void:
	_time_accum += delta
	if _time_accum < spawn_interval:
		return
	_time_accum = 0.0

	if _alive_count() >= max_alive:
		return

	var player = get_node_or_null(player_path) as Node2D
	if player == null:
		return

	if player.global_position.x < min_player_x_to_spawn:
		return

	_spawn_trap(player)


func _spawn_trap(player: Node2D) -> void:
	var screen_w = get_viewport_rect().size.x
	if screen_w <= 0.0:
		screen_w = 1280.0
	var surface = _pick_surface_spawn(player, screen_w)
	if surface.is_empty():
		return

	var trap = trap_scene.instantiate()
	var spawn_pos = surface.pos
	var spawn_normal = surface.normal
	var spawn_tangent = surface.tangent
	trap.global_position = spawn_pos

	if avoid_on_screen:
		if abs(spawn_pos.x - player.global_position.x) < screen_w * 0.6:
			return

	if trap is Node2D:
		var tangent = spawn_tangent
		if tangent == Vector2.ZERO and spawn_normal != Vector2.ZERO:
			tangent = Vector2(spawn_normal.y, -spawn_normal.x).normalized()
		if tangent != Vector2.ZERO:
			var angle = atan2(tangent.y, tangent.x)
			if angle > PI / 2.0 or angle < -PI / 2.0:
				angle += PI
			trap.rotation = angle
	add_child(trap)


func _alive_count() -> int:
	var count := 0
	for child in get_children():
		if child is Area2D:
			count += 1
	return count


func _pick_surface_spawn(player: Node2D, screen_w: float) -> Dictionary:
	var lines = get_tree().get_nodes_in_group("terrain_surface")
	if lines.is_empty():
		return {}
	var min_x = player.global_position.x + screen_w * 0.8
	var max_x = player.global_position.x + spawn_distance_max
	var candidates: Array = []
	for line in lines:
		if not (line is Line2D):
			continue
		var pts: PackedVector2Array = line.points
		if pts.size() < 2:
			continue
		for i in range(pts.size() - 1):
			var p1 = line.to_global(pts[i])
			var p2 = line.to_global(pts[i + 1])
			var mid_x = (p1.x + p2.x) * 0.5
			if mid_x < min_x or mid_x > max_x:
				continue
			candidates.append({"p1": p1, "p2": p2})
	if candidates.is_empty():
		return {}
	var seg = candidates[randi() % candidates.size()]
	var t = randf()
	var p1: Vector2 = seg.p1
	var p2: Vector2 = seg.p2
	var point = p1.lerp(p2, t)
	var tangent = (p2 - p1).normalized()
	var normal = Vector2(-tangent.y, tangent.x)
	if normal.y > 0.0:
		normal = -normal
	return {"pos": point, "normal": normal, "tangent": tangent}
