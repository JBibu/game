extends Node

@onready var slideshow = $IntroSlideshow

func _ready() -> void:
	var slides: Array[Dictionary] = [
		{
			"image": load("res://Assets/Intro/tasca_gente.png"),
			"text": "Se está celebrando el aniversario 1200 de la ciudad de Murcia. Todos están festejando..."
		},
		{
			"image": load("res://Assets/Intro/tasca_gente.png"),
			"text": "Un chaval está festejando mucho... demasiado."
		},
		{
			"image": load("res://Assets/Intro/tasca_vacia.png"),
			"text": "...¿Dónde estoy?"
		},
	]

	slideshow.setup(slides)
	slideshow.finished.connect(_on_intro_finished)

func _on_intro_finished() -> void:
	SceneTransition.change_scene("res://Scenes/floor1.tscn")
