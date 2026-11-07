class_name CnebGrade
extends RefCounted
## Calificación referencial de la escala del CNEB: AD, A, B o C (RN-12).

enum Level { C, B, A, AD }

const CODES := {
	Level.AD: "AD",
	Level.A: "A",
	Level.B: "B",
	Level.C: "C",
}

const DESCRIPTIONS := {
	Level.AD: "Logro destacado",
	Level.A: "Logro esperado",
	Level.B: "En proceso",
	Level.C: "En inicio",
}

var level: Level:
	get:
		return _level

## Porcentaje de aciertos entre 0 y 100.
var percent: float:
	get:
		return _percent

var _level: Level
var _percent: float


func _init(grade_level: Level, grade_percent: float) -> void:
	_level = grade_level
	_percent = clampf(grade_percent, 0.0, 100.0)


func code() -> String:
	return CODES[_level]


func description() -> String:
	return DESCRIPTIONS[_level]
