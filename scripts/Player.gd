extends Area2D

signal died

const THRUST = 420.0
const MAX_SPEED = 480.0
const ROTATION_SPEED = 3.6
const DRAG = 0.99
const FIRE_COOLDOWN = 0.22

const BULLET_SCENE = preload("res://scenes/Bullet.tscn")

var SHIP_POINTS := PackedVector2Array([
	Vector2(0, -14),
	Vector2(9, 12),
	Vector2(0, 7),
	Vector2(-9, 12),
])

var velocity := Vector2.ZERO
var fire_timer := 0.0
var alive := true
var thrusting := false

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if not alive:
		return

	var rotate_dir := 0.0
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		rotate_dir -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		rotate_dir += 1.0
	rotation += rotate_dir * ROTATION_SPEED * delta

	thrusting = Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W)
	if thrusting:
		velocity += Vector2.UP.rotated(rotation) * THRUST * delta
		if velocity.length() > MAX_SPEED:
			velocity = velocity.normalized() * MAX_SPEED

	velocity *= DRAG
	position += velocity * delta
	_wrap_position()

	fire_timer -= delta
	if Input.is_physical_key_pressed(KEY_SPACE) and fire_timer <= 0.0:
		_fire()
		fire_timer = FIRE_COOLDOWN

	queue_redraw()

func _draw() -> void:
	draw_colored_polygon(SHIP_POINTS, Color(0.9, 0.95, 1.0))
	if thrusting:
		var flame := PackedVector2Array([
			Vector2(-5, 12),
			Vector2(0, 26),
			Vector2(5, 12),
		])
		draw_colored_polygon(flame, Color(1.0, 0.6, 0.1))

func _wrap_position() -> void:
	var view_size := get_viewport_rect().size
	if position.x < 0:
		position.x += view_size.x
	elif position.x > view_size.x:
		position.x -= view_size.x
	if position.y < 0:
		position.y += view_size.y
	elif position.y > view_size.y:
		position.y -= view_size.y

func _fire() -> void:
	var bullet := BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2.UP.rotated(rotation) * 16.0
	bullet.direction = Vector2.UP.rotated(rotation)

func _on_area_entered(area: Node) -> void:
	if not alive:
		return
	if area.is_in_group("asteroids"):
		alive = false
		hide()
		set_physics_process(false)
		monitoring = false
		died.emit()

func reset(spawn_position: Vector2) -> void:
	global_position = spawn_position
	rotation = 0.0
	velocity = Vector2.ZERO
	thrusting = false
	alive = true
	fire_timer = FIRE_COOLDOWN
	show()
	set_physics_process(true)
	monitoring = true
	queue_redraw()
