extends Area2D

const SPEED = 720.0
const LIFETIME = 0.9

var direction := Vector2.UP
var life := LIFETIME

func _ready() -> void:
	add_to_group("bullets")

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	life -= delta
	if life <= 0.0:
		queue_free()
	_wrap_position()

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

func _draw() -> void:
	draw_circle(Vector2.ZERO, 2.5, Color(1, 1, 1))
