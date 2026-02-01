# gdlint:ignore = class-definitions-order
extends Node2D

@export var creature_scene: PackedScene = preload("res://scenes/creatures/creature.tscn")
@export var spawn_interval: float = 0.4
@export var max_alive: int = 99999999999999999999
@export var spawn_distance_min: float = 1200.0
@export var spawn_distance_max: float = 2200.0
@export var raycast_height: float = 1600.0
@export var ground_offset: float = 10.0
@export var feet_offset: float = 18.0
@export var surface_clearance: float = 10.0
@export var min_player_x_to_spawn: float = 400.0
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

	_spawn_creature(player)


func _spawn_creature(player: Node2D) -> void:
	var dir = 1.0
	var screen_w = get_viewport_rect().size.x
	if screen_w <= 0.0:
		screen_w = 1280.0
	var dist = randf_range(spawn_distance_min, spawn_distance_max)
	dist = max(dist, screen_w * 0.7)
	var x = player.global_position.x + dir * dist
	var start = Vector2(x, player.global_position.y - raycast_height)
	var end = Vector2(x, player.global_position.y + raycast_height)

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(start, end)
	query.exclude = [player]
	var hit = space_state.intersect_ray(query)
	var creature = creature_scene.instantiate()
	_apply_sprite_scale(creature)
	var spawn_pos = start
	var spawn_normal: Vector2
	var spawn_tangent: Vector2
	var surface_data = _pick_surface_spawn(player, screen_w)
	if surface_data.size() > 0:
		var offset = _surface_offset_for(creature)
		spawn_pos = surface_data.pos + surface_data.normal * offset
		spawn_normal = surface_data.normal
		spawn_tangent = surface_data.tangent
	elif hit:
		var offset = _surface_offset_for(creature)
		# Place the creature slightly above the surface along the normal.
		spawn_pos = hit.position + hit.normal * offset
		spawn_normal = hit.normal
	else:
		# No reliable ground found, skip this spawn.
		return

	if avoid_on_screen:
		if abs(spawn_pos.x - player.global_position.x) < screen_w * 0.6:
			return

	creature.global_position = spawn_pos
	if creature is Node2D:
		var tangent = spawn_tangent
		if tangent == Vector2.ZERO and spawn_normal != Vector2.ZERO:
			tangent = Vector2(spawn_normal.y, -spawn_normal.x).normalized()
		if tangent != Vector2.ZERO:
			var angle = atan2(tangent.y, tangent.x)
			if angle > PI / 2.0 or angle < -PI / 2.0:
				angle += PI
			creature.rotation = angle
	add_child(creature)
	if creature.has_method("set_player"):
		creature.set_player(player)
	print("Creature spawned at ", spawn_pos)


func _alive_count() -> int:
	var count := 0
	for child in get_children():
		if child is CharacterBody2D:
			count += 1
	return count


func _surface_offset_for(creature: Node) -> float:
	var offset = max(ground_offset, feet_offset) + surface_clearance
	if creature == null:
		return offset
	var shape_node = creature.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return offset
	var shape = shape_node.shape
	var scale_y = shape_node.scale.y
	if shape is CircleShape2D:
		offset = max(offset, shape.radius * scale_y)
	elif shape is CapsuleShape2D:
		offset = max(offset, (shape.height * 0.5 + shape.radius) * scale_y)
	var sprite = creature.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null and sprite.sprite_frames != null:
		var tex = sprite.sprite_frames.get_frame_texture("idle", 0)
		if tex != null:
			var half_h = tex.get_size().y * sprite.scale.y * 0.5
			offset = max(offset, half_h)
	return offset


func _apply_sprite_scale(creature: Node) -> void:
	var sprite = creature.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	var scale_value := _get_creature_scale(creature)
	if scale_value > 0.0:
		sprite.scale = Vector2(scale_value, scale_value)


func _get_creature_scale(creature: Node) -> float:
	var scale_value := 0.0
	for prop in creature.get_property_list():
		if prop.name == "sprite_scale":
			scale_value = float(creature.get("sprite_scale"))
			break
	return scale_value


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
	# Ensure the normal points "up" (lower y value).
	if normal.y > 0.0:
		normal = -normal
	return {"pos": point, "normal": normal, "tangent": tangent}
