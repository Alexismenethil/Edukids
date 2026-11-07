extends Node
## Navegador: crea cada pantalla, le inyecta su presentador y hace las transiciones.
## Junto con la raíz de composición, es el único código que conoce todas las capas.

const TITLE_SCREEN := preload("res://scenes/ui/title/title_screen.tscn")
const FADE_SECONDS := 0.6

@onready var _screens: Node = $Screens
@onready var _fade: ColorRect = $Curtain/Fade

var _current: Node


func _ready() -> void:
	open_title()


func open_title() -> void:
	var view: TitleScreen = TITLE_SCREEN.instantiate()
	view.setup(CompositionRoot.title_presenter())
	view.play_requested.connect(_on_play_requested)
	_show(view)
	if OS.get_cmdline_user_args().has("--demo"):
		_run_demo(view)


## Modo demostración (godot -- --demo): toca Jugar y avanza el diálogo solo,
## para grabar videos o capturas con el Movie Maker de Godot.
func _run_demo(view: TitleScreen) -> void:
	var tween := create_tween()
	tween.tween_interval(5.0)
	tween.tween_callback(view.press_play)
	for i in 4:
		tween.tween_interval(3.4)
		tween.tween_callback(view.advance_dialogue)


func _show(view: Node) -> void:
	var tween := create_tween()
	if _current:
		tween.tween_property(_fade, "modulate:a", 1.0, FADE_SECONDS * 0.5)
		tween.tween_callback(_current.queue_free)
	tween.tween_callback(func() -> void:
		_screens.add_child(view)
		_current = view)
	tween.tween_property(_fade, "modulate:a", 0.0, FADE_SECONDS).set_trans(Tween.TRANS_SINE)


func _on_play_requested() -> void:
	# Sprint 3: abrir la selección de perfil del estudiante.
	pass
