extends Node

@onready var slideshow = $EndingSlideshow

func _ready() -> void:
	var slides: Array[Dictionary] = [
		{
			"image": load("res://Assets/Intro/finale@2x.png"),
			"text": "Después de sortear criaturas y resolver enigmas..."
		},
		{
			"image": load("res://Assets/Intro/finale@2x.png"),
			"text": "Por fin veo la luz. Ya casi estoy fuera."
		},
		{
			"image": load("res://Assets/Intro/tasca_vacia.png"),
			"text": "Pero al salir... silencio total."
		},
		{
			"image": load("res://Assets/Intro/tasca_vacia.png"),
			"text": "La fiesta ha terminado. Las calles vacías. Todos se han ido a casa."
		},
		{
			"image": load("res://Assets/Intro/tasca_vacia.png"),
			"text": "Espera... ¿Esa es la Catedral de Murcia? ¡He estado en la catedral todo este tiempo!"
		},
		{
			"image": load("res://Assets/Intro/tasca_vacia.png"),
			"text": "Menuda resaca me espera..."
		},
		{
			"image": null,
			"text": "FIN"
		},
	]

	slideshow.setup(slides)
	slideshow.finished.connect(_on_ending_finished)

func _on_ending_finished() -> void:
	Inventory.clear()
	SceneTransition.change_scene("res://Scenes/main_menu.tscn")
