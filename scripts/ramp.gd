@tool
extends StaticBody2D

@export_category("Ustawienia Zjazdu (In-run)")
@export var start_height: float = 800.0:
	set(value):
		start_height = value
		generate_ramp()
@export var slope_length: float = 1000.0:
	set(value):
		slope_length = value
		generate_ramp()
@export_range(0.1, 1.5) var curve_power_0: float = 0.5:
	set(value):
		curve_power_0 = value
		generate_ramp()
		
@export_category("Przejście")
@export_range(0.1, 1.5) var curve_power: float = 0.5:
	set(value):
		curve_power = value
		generate_ramp()

@export_category("Ustawienia Wybicia (Table)")
@export var ramp_length: float = 400.0:
	set(value):
		ramp_length = value
		generate_ramp()
@export var ramp_height: float = 200.0:
	set(value):
		ramp_height = value
		generate_ramp()
@export_range(0.1, 1.5) var curve_power_end: float = 0.5:
	set(value):
		curve_power_end = value
		generate_ramp()

var smoothness: float = 0.4
@export var tile_uv_scale: float = 0.2

@onready var visual_poly = $Polygon2D
@onready var collision_poly = $CollisionPolygon2D
@onready var line_outline = $Line2D


func _ready():
	generate_ramp()


func generate_ramp():
	var curve = Curve2D.new()

	var p1_pos = Vector2(0, -start_height)
	var p1_out = Vector2(slope_length * curve_power_0, 0)

	curve.add_point(p1_pos, Vector2.ZERO, p1_out)

	var p2_pos = Vector2(slope_length, 0)
	var handle_in_len = slope_length * curve_power
	var p2_in = Vector2(-handle_in_len, 0)
	var handle_out_len = ramp_length * curve_power
	var p2_out = Vector2(handle_out_len, 0)

	curve.add_point(p2_pos, p2_in, p2_out)

	var p3_pos = Vector2(slope_length + ramp_length, -ramp_height)
	var p3_in = Vector2(-ramp_length * curve_power_end, 0)

	curve.add_point(p3_pos, p3_in, Vector2.ZERO)

	curve.bake_interval = 100.0
	var baked_points = curve.get_baked_points()

	var polygon_points = PackedVector2Array(baked_points)

	var bottom_depth = 500.0
	polygon_points.append(Vector2(slope_length + ramp_length, bottom_depth))
	polygon_points.append(Vector2(0, bottom_depth))

	if visual_poly:
		visual_poly.polygon = polygon_points
		var uv = PackedVector2Array()
		for p in polygon_points:
			uv.append(p * tile_uv_scale)
		visual_poly.uv = uv

	if collision_poly:
		collision_poly.polygon = polygon_points

	if line_outline:
		line_outline.points = baked_points
