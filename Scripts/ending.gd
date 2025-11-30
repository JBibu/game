extends Node

@onready var slideshow = $EndingSlideshow

func _ready() -> void:
	var slides: Array[Dictionary] = [
		{
			"image": load("res://Assets/Intro/finale@2x.png"),
			"text": "Tras sortear criaturas de ultratumba y resolver antiguos enigmas..."
		},
		{
			"image": load("res://Assets/Intro/finale@2x.png"),
			"text": "Javi divisó por fin la luz del exterior. La libertad estaba al alcance de su mano."
		},
		{
			"image": load("res://Assets/Intro/tasca_vacia.png"),
			"text": "Pero al emerger a la superficie, un silencio sepulcral lo recibió."
		},
		{
			"image": load("res://Assets/Intro/tasca_vacia.png"),
			"text": "La fiesta había terminado. Las calles, vacías. Todos se habían marchado a casa."
		},
		{
			"image": load("res://Assets/Intro/tasca_vacia.png"),
			"text": "Javi suspiró, contemplando el amanecer sobre una Murcia desierta. Menuda resaca le esperaba..."
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
