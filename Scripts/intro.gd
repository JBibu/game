extends Node

@onready var slideshow = $IntroSlideshow

func _ready() -> void:
	var slides: Array[Dictionary] = [
		{
			"image": load("res://Assets/Intro/tasca_gente@2x.png"),
			"text": "Año 2025. Murcia celebra el 1200 aniversario de su fundación. Las calles rebosan de alegría y el alcohol corre sin cesar..."
		},
		{
			"image": load("res://Assets/Intro/tasca_javi_bailando@2x.png"),
			"text": "Entre la multitud, un joven murciano se entrega a la fiesta con devoción absoluta..."
		},
		{
			"image": load("res://Assets/Intro/tasca_javi_bailando_mucho@2x.png"),
			"text": "...quizás con demasiada devoción."
		},
		{
			"image": load("res://Assets/Intro/tasca_javi_wasted@2x.png"),
			"text": "..."
		},
		{
			"image": load("res://Assets/Intro/cave@2x.png"),
			"text": "...¿Qué leches...?"
		},
	]

	slideshow.setup(slides)
	slideshow.finished.connect(_on_intro_finished)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_intro_finished()

func _on_intro_finished() -> void:
	set_process_input(false)
	SceneTransition.change_scene("res://Scenes/floor1.tscn")
