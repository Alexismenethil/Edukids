class_name StarRule
extends RefCounted
## Estrellas de un nivel de práctica (RN-11).
##
## ★ completar el nivel.
## ★★ aciertos válidos de 70 % o más.
## ★★★ aciertos válidos de 90 % o más y sin perder vidas.
## Un acierto válido es una respuesta correcta al primer intento y sin pista.

const TWO_STARS_MIN_PERCENT := 70
const THREE_STARS_MIN_PERCENT := 90


## Devuelve de 0 a 3 estrellas. Usa aritmética entera para evitar errores de redondeo.
static func stars_for(valid_hits: int, total_items: int, lives_lost: int, completed: bool) -> int:
	if not completed or total_items <= 0:
		return 0
	var hits := clampi(valid_hits, 0, total_items)
	if hits * 100 >= THREE_STARS_MIN_PERCENT * total_items and lives_lost <= 0:
		return 3
	if hits * 100 >= TWO_STARS_MIN_PERCENT * total_items:
		return 2
	return 1
