class_name DemoDirector
extends RefCounted
## Modo demostración para grabar videos con el Movie Maker de Godot y probar los recorridos
## sin tocar la pantalla. Cada opción abre una pantalla y la recorre sola:
##   --demo            pantalla de inicio (Quwi, Jugar y el diálogo)
##   --demo-profiles   elegir perfil, un PIN incorrecto y el correcto (usar con --demo-data)
##   --demo-editor     un estudiante sin personaje lo crea (usar con --demo-data)
##   --demo-teacher    PIN docente y lista de estudiantes (usar con --demo-data)
##   --demo-setup      configuración inicial completa (usar con --demo-empty)
##   --demo-home       inicio del estudiante con los niveles (usar con --demo-data)
##   --demo-level      juega el nivel de Matemática: falla una, pide una pista y repasa
##                     (también --demo-level-language y --demo-level-science; con --demo-data)

const MODES := {
	"--demo-level-language": "level:language",
	"--demo-level-science": "level:science",
	"--demo-level": "level:math",
	"--demo-home": "home",
	"--demo-profiles": "profiles",
	"--demo-editor": "editor",
	"--demo-teacher": "teacher",
	"--demo-setup": "setup",
	"--demo": "title",
}

var _navigator: Node
var _mode := ""


func start(navigator: Node, args: PackedStringArray) -> void:
	_navigator = navigator
	for flag: String in MODES:
		if args.has(flag):
			_mode = MODES[flag]
			break
	if _mode.begins_with("level:") or _mode == "home":
		var root: Node = navigator.get_node("/root/CompositionRoot")
		if root.demo_login():
			if _mode == "home":
				navigator.open_student_home.call_deferred()
			else:
				root.demo_choose_level(StringName(_mode.get_slice(":", 1)))
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
	return _mode in ["profiles", "editor", "teacher", "setup", "home"] or _mode.begins_with("level:")


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


func on_student_home(_view: Node) -> void:
	pass


## Juega el nivel solo: responde bien casi todo, falla la segunda pregunta (vuelve al final),
## pide una pista en la quinta y termina en los resultados.
func on_level(view: Node) -> void:
	if not _mode.begins_with("level:"):
		return
	_mode = "done"
	_autopilot(view)


func _autopilot(view: Node) -> void:
	var tree := _navigator.get_tree()
	var root: Node = _navigator.get_node("/root/CompositionRoot")
	await tree.create_timer(6.5).timeout
	var answered := 0
	var idle := 0
	while is_instance_valid(view) and view.is_inside_tree() and idle < 12:
		if view.demo_showing_results():
			await tree.create_timer(7.5).timeout
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
		var solution: Variant = root.demo_solution(question)
		await tree.create_timer(1.4).timeout
		if answered == 4:
			view.demo_hint()
			await tree.create_timer(3.2).timeout
			view.demo_close_bubble()
			await tree.create_timer(0.6).timeout
		var value: Variant = DemoClassroom.wrong_answer(solution) if answered == 1 else solution
		view.demo_answer(value)
		await tree.create_timer(DemoClassroom.answer_seconds(value)).timeout
		view.demo_check()
		await tree.create_timer(3.4 if answered == 1 else 2.6).timeout
		view.demo_continue()
		answered += 1
		await tree.create_timer(0.8).timeout


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
