class_name CnebGrade
extends RefCounted
## Calificación referencial de la escala del CNEB: AD, A, B o C (RN-12).

enum Achievement { C, B, A, AD }

const CODES := {
	Achievement.AD: "AD",
	Achievement.A: "A",
	Achievement.B: "B",
	Achievement.C: "C",
}

const DESCRIPTIONS := {
	Achievement.AD: "Logro destacado",
	Achievement.A: "Logro esperado",
	Achievement.B: "En proceso",
	Achievement.C: "En inicio",
}

var level: Achievement:
	get:
		return _level

## Porcentaje de aciertos entre 0 y 100.
var percent: float:
	get:
		return _percent

var _level: Achievement
var _percent: float


func _init(grade_level: Achievement, grade_percent: float) -> void:
	_level = grade_level
	_percent = clampf(grade_percent, 0.0, 100.0)


func code() -> String:
	return CODES[_level]


func description() -> String:
	return DESCRIPTIONS[_level]
