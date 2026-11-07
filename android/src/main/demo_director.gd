class_name DemoDirector
extends RefCounted
## Modo demostración para grabar videos con el Movie Maker de Godot y probar los recorridos
## sin tocar la pantalla. Cada opción abre una pantalla y la recorre sola:
##   --demo            pantalla de inicio (Quwi, Jugar y el diálogo)
##   --demo-profiles   elegir perfil, un PIN incorrecto y el correcto (usar con --demo-data)
##   --demo-editor     un estudiante sin personaje lo crea (usar con --demo-data)
##   --demo-teacher    PIN docente y lista de estudiantes (usar con --demo-data)
##   --demo-setup      configuración inicial completa (usar con --demo-empty)

const MODES := {
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
	match _mode:
		"profiles", "editor":
			navigator.open_profiles.call_deferred()
		"teacher":
			navigator.open_teacher_gate.call_deferred()
		"setup":
			navigator.open_setup.call_deferred()


func opens_own_screen() -> bool:
	return _mode in ["profiles", "editor", "teacher", "setup"]


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
