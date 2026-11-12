class_name TrailRule
extends RefCounted
## Orden de los niveles de un módulo (RN-18): los niveles de práctica se abren uno tras otro y
## el desafío final se abre al completar todos los de práctica, o antes si el docente lo abrió
## para la sección (RF-09).

const LOCKED := &"locked"
const OPEN := &"open"
const DONE := &"done"


## Estado de cada nivel del módulo: id del nivel → LOCKED, OPEN o DONE.
## `completed` tiene los ids de los niveles que el estudiante ya completó al menos una vez y
## `final_open` dice si el docente abrió el desafío final antes de tiempo.
static func states(entries: Array[LevelEntry], completed: Dictionary, final_open: bool = false) -> Dictionary:
	var result := {}
	var practice_done := true
	var previous_done := true
	var ordered := entries.duplicate()
	ordered.sort_custom(func(a: LevelEntry, b: LevelEntry) -> bool: return a.position < b.position)
	for entry: LevelEntry in ordered:
		if entry.is_final():
			continue
		var done := completed.has(entry.id)
		if done:
			result[entry.id] = DONE
		else:
			result[entry.id] = OPEN if previous_done else LOCKED
		previous_done = done
		practice_done = practice_done and done
	for entry: LevelEntry in ordered:
		if entry.is_final():
			if completed.has(entry.id):
				result[entry.id] = DONE
			else:
				result[entry.id] = OPEN if practice_done or final_open else LOCKED
	return result


## Intentos que le quedan en un desafío final.
static func attempts_left(entry: LevelEntry, used: int) -> int:
	return maxi(0, entry.max_attempts - used) if entry.is_final() else 0
