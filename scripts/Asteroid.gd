extends Area2D

const SPLIT_COUNT = 2
const POINTS_BY_TIER = {3: 100, 2: 50, 1: 20}
const RADIUS_BY_TIER = {3: 44.0, 2: 26.0, 1: 14.0}
const SPEED_BY_TIER = {3: 90.0, 2: 130.0, 1: 190.0}

var size_tier: int = 3
var radius: float = 44.0
var velocity := Vector2.ZERO
var spin := 0.0
var points := PackedVector2Array()

func _ready() -> void:
	add_to_group("asteroids")
	area_entered.connect(_on_area_entered)

func setup(tier: int, spawn_position: Vector2, direction: Vector2 = Vector2.ZERO) -> void:
	size_tier = tier
	radius = RADIUS_BY_TIER[tier]
	global_position = spawn_position
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	velocity = direction.normalized() * SPEED_BY_TIER[tier] * randf_range(0.7, 1.3)
	spin = randf_range(-1.5, 1.5)
	_generate_shape()
	$CollisionPolygon2D.polygon = points
	queue_redraw()

func _generate_shape() -> void:
	var vertex_count := 10
	points = PackedVector2Array()
	for i in range(vertex_count):
		var angle := (float(i) / vertex_count) * TAU
		var r := radius * randf_range(0.75, 1.15)
		points.append(Vector2(cos(angle), sin(angle)) * r)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	rotation += spin * delta
	_wrap_position()

func _draw() -> void:
	if points.is_empty():
		return
	draw_colored_polygon(points, Color(0.5, 0.5, 0.56))
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, Color(0.85, 0.85, 0.9), 2.0)

func _wrap_position() -> void:
	var view_size := get_viewport_rect().size
	var margin := radius
	if position.x < -margin:
		position.x = view_size.x + margin
	elif position.x > view_size.x + margin:
		position.x = -margin
	if position.y < -margin:
		position.y = view_size.y + margin
	elif position.y > view_size.y + margin:
		position.y = -margin

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("bullets"):
		area.queue_free()
		_break_apart()

func _break_apart() -> void:
	Game.add_score(POINTS_BY_TIER[size_tier])
	if size_tier > 1:
		for i in range(SPLIT_COUNT):
			var child := (load("res://scenes/Asteroid.tscn") as PackedScene).instantiate()
			get_parent().add_child(child)
			child.setup(size_tier - 1, global_position, velocity.rotated(randf_range(-1.2, 1.2)))
	queue_free()
