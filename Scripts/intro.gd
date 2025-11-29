extends Node

@onready var slideshow = $IntroSlideshow

func _ready() -> void:
	var slides: Array[Dictionary] = [
		{"text": "En un mundo olvidado por el tiempo..."},
		{"text": "Donde la oscuridad consume todo a su paso..."},
		{"text": "Un viajero despierta sin recuerdos..."},
		{"text": "Solo una linterna ilumina su camino..."},
	]

	slideshow.setup(slides)
	slideshow.finished.connect(_on_intro_finished)

func _on_intro_finished() -> void:
	SceneTransition.change_scene("res://Scenes/devroom.tscn")
