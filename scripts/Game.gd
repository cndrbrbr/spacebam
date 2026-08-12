extends Node

signal score_changed(new_score)
signal lives_changed(new_lives)
signal game_over

var score: int = 0
var lives: int = 3

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()

func reset() -> void:
	score = 0
	lives = 3
	score_changed.emit(score)
	lives_changed.emit(lives)
