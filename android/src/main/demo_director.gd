class_name DemoDirector
extends RefCounted
## Modo demostración para grabar videos con el Movie Maker de Godot y probar los recorridos
## sin tocar la pantalla. Cada opción abre una pantalla y la recorre sola:
##   --demo            pantalla de inicio (Quwi, Jugar y el diálogo)
##   --demo-profiles   elegir perfil, un PIN incorrecto y el correcto (usar con --demo-data)
##   --demo-editor     un estudiante sin personaje lo crea (usar con --demo-data)
##   --demo-teacher    PIN docente y lista de estudiantes (usar con --demo-data)
##   --demo-setup      configuración inicial completa (usar con --demo-empty)
##   --demo-map        mapa de la Sierra, entra a Huamanga y abre un nivel (usar con --demo-data)
##   --demo-chase      persecución de Atoq: aciertos, tropiezos y un nudo perdido
##   --demo-caiman     Coco, el caimán glotón: frutas, mordiscos y el cruce del río
##   --demo-bridge     el puente colgante: tablas, sacudidas y una caída al río
##   --demo-classic    tarjetas con Quwi y Atoq asomándose
##   --demo-gameover   se pierden las tres vidas
##   --demo-final      desafío final: portada, respuestas guardadas y calificación
## Con --demo-area=language o --demo-area=science se elige el área (por defecto, la que tenga
## esa mecánica primero). Todas se usan con --demo-data.

## Modo → [mecánica del nivel, patrón de respuestas]. c: correcta, w: equivocada, h: pista y correcta.
const PLAYS := {
	"chase": [&"chase", "cwwwcchcccc"],
	"caiman": [&"caiman", "cwcwwwccccccc"],
	"bridge": [&"bridge", "cwwwcccccccccc"],
	"classic": [&"classic", "cwccwcccccc"],
	"gameover": [&"chase", "wwwwwwwwwwww"],
	"final": [&"final", "ccwcccccwccccc"],
}

const MODES := {
	"--demo-map": "map",
	"--demo-chase": "chase",
	"--demo-caiman": "caiman",
	"--demo-bridge": "bridge",
	"--demo-classic": "classic",
	"--demo-gameover": "gameover",
	"--demo-final": "final",
	"--demo-profiles": "profiles",
	"--demo-editor": "editor",
	"--demo-teacher": "teacher",
	"--demo-setup": "setup",
	"--demo": "title",
}

var _navigator: Node
var _mode := ""
var _area: StringName = &""
var _pattern := ""


func start(navigator: Node, args: PackedStringArray) -> void:
	_navigator = navigator
	for flag: String in MODES:
		if args.has(flag):
			_mode = MODES[flag]
			break
	for arg in args:
		if arg.begins_with("--demo-area="):
			_area = StringName(arg.get_slice("=", 1))
	if PLAYS.has(_mode) or _mode == "map":
		var root: Node = navigator.get_node("/root/CompositionRoot")
		if not root.demo_login():
			return
		if _mode == "map":
			navigator.open_map.call_deferred()
			return
		var play: Array = PLAYS[_mode]
		_pattern = play[1]
		var found: PackedStringArray = root.demo_find(_area, play[0])
		if found.is_empty():
			push_warning("Demostración: no hay un nivel con la mecánica %s." % play[0])
			return
		root.demo_choose(found[0], found[1])
		navigator.open_level.call_deferred()
		return
	match _mode:
		"profiles", "editor":
			navigator.open_profiles.call_deferred()
		"teacher":
			navigator.open_teacher_gate.call_deferred()
		"setup":
			navigator.open_setup.call_deferred()


func opens_own_screen() -> bool:
	return _mode in ["profiles", "editor", "teacher", "setup", "map"] or PLAYS.has(_mode)


func on_title(view: Node) -> void:
	if _mode == "title":
		_script(view, [[4.6, "tap_quwi", []], [1.8, "press_play", []], [3.4, "advance_dialogue", []],
			[3.4, "advance_dialogue", []], [3.4, "advance_dialogue", []], [3.4, "advance_dialogue", []]])


func on_profiles(view: Node) -> void:
	if _mode == "profiles":
		_script(view, [[2.6, "choose", [2]], [2.0, "type_pin", ["1111"]], [2.6, "type_pin", [DemoClassroom.STUDENT_PIN]]])
	elif _mode == "editor":
		_script(view, [[2.2, "choose", [3]], [1.8, "type_pin", [DemoClassroom.STUDENT_PIN]]])


func on_avatar_editor(view: Node) -> void:
	if _mode == "editor":
		_script(view, [[1.8, "pick", ["hair_style", 3]], [1.0, "pick", ["skin", 4]], [1.0, "pick", ["top_color", 0]],
			[1.0, "pick", ["bottom_color", 6]], [1.2, "surprise", []], [1.4, "surprise", []], [1.6, "save", []]])


func on_setup(view: Node) -> void:
	if _mode == "setup":
		_script(view, [
			[2.4, "fill_and_next", [{}]],
			[1.6, "fill_and_next", [{"institution_name": "Escuela de demostración", "school_year": 2026}]],
			[1.8, "fill_and_next", [{"sections": ["A", "B"]}]],
			[1.8, "fill_and_next", [{"teacher_name": "Docente de prueba", "teacher_pin": DemoClassroom.TEACHER_PIN,
				"teacher_pin_confirmation": DemoClassroom.TEACHER_PIN}]],
		])


func on_teacher_gate(view: Node) -> void:
	if _mode == "teacher":
		_script(view, [[1.8, "type_pin", [DemoClassroom.TEACHER_PIN]]])


func on_teacher_panel(view: Node) -> void:
	if _mode == "teacher":
		_script(view, [[3.2, "open_add_dialog", []]])


## Mapa: saluda, entra a Huamanga.
func on_map(view: Node) -> void:
	if _mode != "map":
		return
	_script(view, [[5.5, "demo_enter_stop", [0]]])


## Parada: abre la ficha del primer nivel de Matemática y juega.
func on_stop(view: Node) -> void:
	if _mode != "map":
		return
	_mode = "map-level"
	_pattern = "ccwccccccc"
	var tween := _navigator.create_tween()
	tween.tween_interval(4.2)
	tween.tween_callback(func() -> void:
		if is_instance_valid(view) and view.is_inside_tree():
			var root: Node = _navigator.get_node("/root/CompositionRoot")
			var found: PackedStringArray = root.demo_find(&"math", &"chase")
			if not found.is_empty():
				view.demo_open(found[1], found[0]))
	tween.tween_interval(2.6)
	tween.tween_callback(func() -> void:
		if is_instance_valid(view) and view.is_inside_tree():
			view.demo_play())


## Juega el nivel solo, con el patrón de respuestas del modo.
func on_level(view: Node) -> void:
	if _pattern.is_empty() or _mode == "done":
		return
	_mode = "done"
	_autopilot(view)


func _autopilot(view: Node) -> void:
	var tree := _navigator.get_tree()
	var root: Node = _navigator.get_node("/root/CompositionRoot")
	await tree.create_timer(3.0).timeout
	if is_instance_valid(view):
		view.demo_start_cover()
	await tree.create_timer(2.6).timeout
	if is_instance_valid(view) and view.is_inside_tree():
		view.demo_tap_guide()
	await tree.create_timer(1.4).timeout
	var answered := 0
	var idle := 0
	while is_instance_valid(view) and view.is_inside_tree() and idle < 40:
		if view.demo_showing_results():
			await tree.create_timer(9.0).timeout
			if is_instance_valid(view) and view.is_inside_tree():
				view.demo_leave_results()
			return
		view.demo_close_bubble()
		var question: String = view.demo_question_id()
		if question.is_empty():
			idle += 1
			await tree.create_timer(0.5).timeout
			continue
		idle = 0
		var move := _pattern[answered] if answered < _pattern.length() else "c"
		await tree.create_timer(1.3).timeout
		if move == "h":
			view.demo_hint()
			await tree.create_timer(3.0).timeout
			view.demo_close_bubble()
			await tree.create_timer(0.5).timeout
		var value: Variant = root.demo_solution(question, move == "w")
		view.demo_answer(value)
		await tree.create_timer(DemoClassroom.answer_seconds(value)).timeout
		view.demo_check()
		var waited := 0.0
		while waited < 9.0 and is_instance_valid(view) and view.is_inside_tree() and not view.demo_feedback_ready():
			await tree.create_timer(0.25).timeout
			waited += 0.25
		await tree.create_timer(2.0 if move == "w" else 1.5).timeout
		if not is_instance_valid(view) or not view.is_inside_tree():
			return
		view.demo_continue()
		answered += 1
		await tree.create_timer(0.9).timeout


## Llama a los métodos de la vista con las pausas indicadas, si la vista sigue abierta.
func _script(view: Node, steps: Array) -> void:
	var tween := _navigator.create_tween()
	for step: Array in steps:
		tween.tween_interval(step[0])
		var method: String = step[1]
		var arguments: Array = step[2]
		tween.tween_callback(func() -> void:
			if is_instance_valid(view) and view.is_inside_tree():
				view.callv(method, arguments))
