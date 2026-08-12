extends Node2D

const ASTEROID_SCENE = preload("res://scenes/Asteroid.tscn")
const PLAYER_SCENE = preload("res://scenes/Player.tscn")

const INITIAL_ASTEROIDS = 4

var player: Area2D
var wave: int = 1
var restart_pressed_last := false

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var lives_label: Label = $CanvasLayer/LivesLabel
@onready var message_label: Label = $CanvasLayer/MessageLabel

func _ready() -> void:
	randomize()
	Game.score_changed.connect(_on_score_changed)
	Game.lives_changed.connect(_on_lives_changed)
	Game.game_over.connect(_on_game_over)
	_start_game()

func _start_game() -> void:
	Game.reset()
	message_label.hide()
	get_tree().call_group("asteroids", "queue_free")
	get_tree().call_group("bullets", "queue_free")

	if player:
		player.queue_free()
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.died.connect(_on_player_died)
	player.reset(get_viewport_rect().size / 2.0)

	wave = 1
	_spawn_wave(INITIAL_ASTEROIDS)

func _spawn_wave(count: int) -> void:
	var view_size := get_viewport_rect().size
	for i in range(count):
		var asteroid := ASTEROID_SCENE.instantiate()
		add_child(asteroid)
		asteroid.setup(3, _random_edge_position(view_size))

func _random_edge_position(view_size: Vector2) -> Vector2:
	var side := randi() % 4
	match side:
		0: return Vector2(randf() * view_size.x, -40.0)
		1: return Vector2(view_size.x + 40.0, randf() * view_size.y)
		2: return Vector2(randf() * view_size.x, view_size.y + 40.0)
		_: return Vector2(-40.0, randf() * view_size.y)

func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE %d" % new_score

func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = "LIVES %d" % new_lives

func _on_player_died() -> void:
	Game.lose_life()
	if Game.lives > 0:
		await get_tree().create_timer(1.2).timeout
		player.reset(get_viewport_rect().size / 2.0)

func _on_game_over() -> void:
	message_label.text = "GAME OVER\nPress R to restart"
	message_label.show()

func _process(_delta: float) -> void:
	if not message_label.visible and get_tree().get_nodes_in_group("asteroids").is_empty():
		wave += 1
		_spawn_wave(INITIAL_ASTEROIDS + wave)

	var restart_now := Input.is_physical_key_pressed(KEY_R)
	if restart_now and not restart_pressed_last:
		_start_game()
	restart_pressed_last = restart_now
