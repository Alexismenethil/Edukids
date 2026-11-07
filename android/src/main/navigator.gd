extends Node
## Navegador: crea cada pantalla, le inyecta su presentador y hace las transiciones.
## Junto con la raíz de composición, es el único código que conoce todas las capas.

const TITLE_SCREEN := preload("res://scenes/ui/title/title_screen.tscn")
const FADE_SECONDS := 0.6

@onready var _screens: Node = $Screens
@onready var _fade: ColorRect = $Curtain/Fade
@onready var _diagnostics: DiagnosticsOverlay = $Overlay/Diagnostics

var _current: Node
var _title_ready_ms := 0
var _demo := DemoDirector.new()


func _ready() -> void:
	_demo.start(self, OS.get_cmdline_user_args())
	if not _demo.opens_own_screen():
		open_title()
	if OS.get_cmdline_user_args().has("--diagnostics"):
		_toggle_diagnostics.call_deferred()


func open_title() -> void:
	var view: TitleScreen = TITLE_SCREEN.instantiate()
	view.setup(CompositionRoot.title_presenter())
	view.play_requested.connect(_on_play_requested.bind(view))
	view.teacher_requested.connect(open_teacher)
	view.diagnostics_requested.connect(_toggle_diagnostics)
	_show(view)
	_demo.on_title(view)


## Estudiantes: elegir perfil y escribir el PIN (RF-05).
func open_profiles() -> void:
	var view := ProfilePickerScreen.new()
	view.setup(CompositionRoot.profile_picker_presenter())
	view.back_requested.connect(open_title)
	view.logged_in.connect(func(needs_avatar: bool) -> void:
		if needs_avatar:
			open_avatar_editor()
		else:
			open_student_home())
	_show(view)
	_demo.on_profiles(view)


## «¡Crea tu personaje!» (RF-31).
func open_avatar_editor() -> void:
	var view := AvatarEditorScreen.new()
	view.setup(CompositionRoot.avatar_editor_presenter())
	view.finished.connect(open_student_home)
	view.back_requested.connect(open_student_home)
	_show(view)
	_demo.on_avatar_editor(view)


func open_student_home() -> void:
	var view := StudentHomeScreen.new()
	view.setup(CompositionRoot.student_home_presenter())
	view.edit_avatar_requested.connect(open_avatar_editor)
	view.exit_requested.connect(open_title)
	_show(view)


## Docente: la primera vez, la configuración inicial (RF-01); después, el PIN (RF-03).
func open_teacher() -> void:
	if CompositionRoot.classroom().configured:
		open_teacher_gate()
	else:
		open_setup()


func open_setup() -> void:
	var view := SetupScreen.new()
	view.setup(CompositionRoot.setup_presenter())
	view.finished.connect(open_teacher_panel)
	view.cancelled.connect(open_title)
	_show(view)
	_demo.on_setup(view)


func open_teacher_gate() -> void:
	var view := TeacherGateScreen.new()
	view.setup(CompositionRoot.teacher_gate_presenter())
	view.unlocked.connect(open_teacher_panel)
	view.back_requested.connect(open_title)
	_show(view)
	_demo.on_teacher_gate(view)


func open_teacher_panel() -> void:
	var view := TeacherPanelScreen.new()
	view.setup(CompositionRoot.teacher_panel_presenter())
	view.exit_requested.connect(open_title)
	_show(view)
	_demo.on_teacher_panel(view)


func _show(view: Node) -> void:
	var tween := create_tween()
	if _current:
		var previous := _current
		tween.tween_property(_fade, "modulate:a", 1.0, FADE_SECONDS * 0.5)
		tween.tween_callback(previous.queue_free)
	_current = view
	tween.tween_callback(func() -> void:
		_screens.add_child(view)
		if _title_ready_ms == 0:
			_title_ready_ms = Time.get_ticks_msec())
	tween.tween_property(_fade, "modulate:a", 0.0, FADE_SECONDS).set_trans(Tween.TRANS_SINE)


func _toggle_diagnostics() -> void:
	var info := CompositionRoot.diagnostics()
	info.startup_ms = _title_ready_ms
	_diagnostics.toggle(info)


func _on_play_requested(view: TitleScreen) -> void:
	if CompositionRoot.classroom().configured:
		open_profiles()
	else:
		view.show_not_configured()
