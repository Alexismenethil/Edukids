extends Node
## Navegador: crea cada pantalla, le inyecta su presentador, hace las transiciones
## y pone la música de cada lugar. Junto con la raíz de composición, es el único
## código que conoce todas las capas.

const TITLE_SCREEN := preload("res://scenes/ui/title/title_screen.tscn")
const TITLE_MUSIC := preload("res://assets/audio/music/mus_sierra_title.ogg")
const FADE_SECONDS := 0.6

@onready var _screens: Node = $Screens
@onready var _fade: ColorRect = $Curtain/Fade
@onready var _music: AudioStreamPlayer = $Music
@onready var _diagnostics: DiagnosticsOverlay = $Overlay/Diagnostics

var _current: Node
var _title_ready_ms := 0


func _ready() -> void:
	open_title()
	if OS.get_cmdline_user_args().has("--diagnostics"):
		_toggle_diagnostics.call_deferred()


func _exit_tree() -> void:
	_music.stop()


func open_title() -> void:
	var view: TitleScreen = TITLE_SCREEN.instantiate()
	view.setup(CompositionRoot.title_presenter())
	view.play_requested.connect(_on_play_requested)
	view.diagnostics_requested.connect(_toggle_diagnostics)
	_show(view)
	_play_music(TITLE_MUSIC)
	if OS.get_cmdline_user_args().has("--demo"):
		_run_demo(view)


func _show(view: Node) -> void:
	var tween := create_tween()
	if _current:
		tween.tween_property(_fade, "modulate:a", 1.0, FADE_SECONDS * 0.5)
		tween.tween_callback(_current.queue_free)
	tween.tween_callback(func() -> void:
		_screens.add_child(view)
		_current = view
		if _title_ready_ms == 0:
			_title_ready_ms = Time.get_ticks_msec())
	tween.tween_property(_fade, "modulate:a", 0.0, FADE_SECONDS).set_trans(Tween.TRANS_SINE)


## La música entra con un fundido suave y no se reinicia si ya está sonando.
func _play_music(stream: AudioStream) -> void:
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.volume_db = -28.0
	_music.play()
	create_tween().tween_property(_music, "volume_db", 0.0, 2.5).set_trans(Tween.TRANS_SINE)


func _toggle_diagnostics() -> void:
	var info := CompositionRoot.diagnostics()
	info.startup_ms = _title_ready_ms
	_diagnostics.toggle(info)


func _on_play_requested() -> void:
	# Sprint 3: abrir la selección de perfil del estudiante.
	pass


## Modo demostración (godot -- --demo): toca a Quwi, luego Jugar, y avanza el diálogo solo,
## para grabar videos o capturas con el Movie Maker de Godot.
func _run_demo(view: TitleScreen) -> void:
	var tween := create_tween()
	tween.tween_interval(4.6)
	tween.tween_callback(view.tap_quwi)
	tween.tween_interval(1.8)
	tween.tween_callback(view.press_play)
	for i in 4:
		tween.tween_interval(3.4)
		tween.tween_callback(view.advance_dialogue)
