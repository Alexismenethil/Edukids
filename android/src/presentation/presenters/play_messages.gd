class_name PlayMessages
extends RefCounted
## Textos del motor de actividades: tono amable, frases cortas y sin regañar.

const GUIDE := "Quwi"
const CHECK := "Comprobar"
const HINT := "Pista"
const CONTINUE := "Seguir"
const RESULTS := "Ver resultados"
const EXIT := "Salir"
const RETRY := "¡Otra oportunidad!"
const RIGHT_TITLES: Array[String] = ["¡Muy bien!", "¡Excelente!", "¡Así se hace!", "¡Genial!", "¡Bien pensado!"]
const WRONG_TITLES: Array[String] = ["¡Casi!", "Revisemos juntos", "¡Buen intento!"]
const WILL_RETURN := "Esta pregunta volverá al final para que la intentes otra vez."
const SOLUTION := "La respuesta era: %s"
const INCOMPLETE := "Completa tu respuesta y vuelve a tocar «Comprobar»."
const NOT_SAVED := "No se pudo guardar esta respuesta en la tablet."
const HINT_OFFER := "Esta parece difícil. Si quieres, toca «Pista» y te ayudo."
const HINT_THANKS := "¡Gracias!"
const RESUMED := "¡Seguimos donde te quedaste! Ya respondiste %d de %d preguntas."
const LEVEL_UNAVAILABLE := "Este nivel no se pudo abrir. Avísale a tu docente."
const INTRO_CLOSE := "¡Vamos!"
const NEXT := "Seguir"
const SKIP := "Saltar"
const EXIT_QUESTION := "¿Quieres salir del nivel?"
const EXIT_DETAIL := "Tus respuestas ya están guardadas: cuando vuelvas, seguirás donde te quedaste."
const EXIT_CANCEL := "Seguir jugando"
const TIPS := {
	"multiple_choice": "",
	"multi_select": "Puedes marcar varias.",
	"true_false": "Elige Verdadero o Falso en cada afirmación.",
	"ordering": "Arrastra las tarjetas o toca dos para cambiarlas de lugar.",
	"matching": "Toca un elemento y luego su pareja, o únelos con el dedo.",
	"classification": "Arrastra cada tarjeta a su canasta, o tócala y luego toca la canasta.",
	"fill_blank": "Toca un espacio y luego una palabra, o arrástrala.",
	"numeric": "Escribe tu respuesta con el teclado.",
}
const LABELS := {
	"true": "Verdadero",
	"false": "Falso",
	"bank": "Palabras",
	"drop": "Suelta aquí",
	"write": "Escribe aquí",
	"answer": "Tu respuesta",
}
const RECORD := "¡Nuevo récord!"
const REPLAY := "Otra vez"
const BACK_TO_STOP := "Volver a la parada"

## Lo que cuenta Quwi al empezar, según la mecánica.
const MECHANIC_INTROS := {
	&"chase": "¡Cuidado! Atoq quiere tus nudos. Cada acierto te hace correr más rápido; cada error lo acerca a ti.",
	&"bridge": "Crucemos el río: cada acierto pone una tabla del puente. Si fallas, el puente se tambalea… ¡y el río está frío!",
	&"caiman": "Él es Coco, un caimán glotón que ama las frutas de la feria. Cada acierto es una fruta para él; si fallas, se pone gruñón y muerde.",
	&"classic": "Resolvamos estas tarjetas con calma. Atoq anda cerca: si te equivocas, se asoma.",
}
## Lo que dice Quwi cuando el medidor llega a 0 y se pierde una vida (RN-13).
const LIFE_LOST := {
	&"chase": "¡Atoq te alcanzó y se llevó un nudo! Respira y sigue corriendo.",
	&"bridge": "¡Splash! El puente se sacudió y caíste al río. ¡Arriba, que todavía puedes cruzar!",
	&"caiman": "¡Ñac! Coco mordió uno de tus nudos. Dale una buena respuesta para calmarlo.",
	&"classic": "Atoq se llevó un nudo. ¡Tú puedes recuperarlo!",
}
const GAME_OVER_TITLES := {
	&"chase": "¡Atoq se llevó tus nudos!",
	&"bridge": "¡El puente se vino abajo!",
	&"caiman": "¡Coco se comió tus nudos!",
	&"classic": "¡Atoq se llevó tus nudos!",
}
const GAME_OVER_MESSAGE := "Equivocarse también es aprender. Lee las explicaciones con calma y vuelve a intentarlo: ¡esta vez llegas!"
const GAME_OVER_RETRY := "Reintentar"
const STREAK := "¡Racha de %d!"

const SAVE_ANSWER := "Guardar respuesta"
const ANSWER_SAVED := "¡Respuesta guardada!"
const FINAL_HEADING := "Desafío final"
const FINAL_INTRO := "¡Llegó el desafío final! Demuestra todo lo que practicaste. Lee con calma: aquí no hay prisa."
const FINAL_RULES: Array[String] = [
	"Respondes cada pregunta una sola vez.",
	"No hay vidas ni pistas: confía en lo que aprendiste.",
	"Al entregar verás tu calificación y la explicación de cada pregunta.",
]
const FINAL_START := "¡Comenzar!"
const FINAL_REVIEW := "Revisa tus respuestas"
const FINAL_SEE := "Ver mi calificación"
## Cuerda del quipu que se recupera al completar el desafío final de cada área.
const CORDS := {&"math": "la cuerda de los números", &"language": "la cuerda de las palabras", &"science": "la cuerda de la naturaleza"}
const GRADE_COLORS := {"AD": Color("#C99A1E"), "A": Color("#2E9E5B"), "B": Color("#E07B1F"), "C": Color("#D1495B")}
const GRADE_LINES := {
	"AD": "¡Logro destacado! Tu cuerda lleva un nudo dorado. Mama Sisa estará orgullosa.",
	"A": "¡Logro esperado! Tu cuerda lleva un nudo dorado. ¡Lo lograste!",
	"B": "Vas en camino. Repasa las explicaciones y, si te queda un intento, ¡ve por el nudo dorado!",
	"C": "Estás empezando y eso está bien. Repasa los niveles de práctica y vuelve con más fuerza.",
}


## Espacio que no se corta: «1 254 300» y «S/ 45» nunca quedan partidos entre dos líneas.
const NO_BREAK := "\u00a0"


static func keep_numbers_together(text: String) -> String:
	var result := text.replace("S/ ", "S/" + NO_BREAK)
	var joined := ""
	for index in result.length():
		var character := result[index]
		if character == " " and index > 0 and index + 1 < result.length() \
				and _is_digit(result[index - 1]) and _is_digit(result[index + 1]):
			joined += NO_BREAK
		else:
			joined += character
	return joined


## Aplica `keep_numbers_together` a todos los textos de una lista o diccionario.
static func tidy(value: Variant) -> Variant:
	if value is String:
		return keep_numbers_together(value)
	if value is Array:
		return value.map(func(entry: Variant) -> Variant: return tidy(entry))
	if value is Dictionary:
		var copy := {}
		for key: Variant in value:
			copy[key] = tidy(value[key]) if str(key) != "id" and str(key) != "blank" else value[key]
		return copy
	return value


static func _is_digit(character: String) -> bool:
	return character >= "0" and character <= "9"


static func counter(number: int, total: int) -> String:
	return "Pregunta %d de %d" % [number, total]


static func right_title(index: int) -> String:
	return RIGHT_TITLES[posmod(index, RIGHT_TITLES.size())]


static func wrong_title(index: int) -> String:
	return WRONG_TITLES[posmod(index, WRONG_TITLES.size())]


## «¡Exacto! 3 × 480 = 1 440» → «¡Exacto!». Vacío si el texto no empieza con una exclamación corta.
static func opening_exclamation(text: String) -> String:
	if not text.begins_with("¡"):
		return ""
	var end := text.find("!")
	if end <= 1 or end > 32 or text.substr(end + 1).strip_edges().is_empty():
		return ""
	return text.substr(0, end + 1)


static func partial(hits: int, total: int) -> String:
	return "Tienes %d de %d bien." % [hits, total]


static func missing(count: int) -> String:
	return "Te faltó marcar %d %s." % [count, "opción" if count == 1 else "opciones"]


static func resumed(answered: int, total: int) -> String:
	return RESUMED % [answered, total]


static func details(question_count: int, minutes: int) -> String:
	var text := "%d preguntas" % question_count
	return text + (" · %d min" % minutes if minutes > 0 else "")


static func duration(milliseconds: int) -> String:
	var seconds := int(round(milliseconds / 1000.0))
	if seconds < 60:
		return "%d s" % seconds
	return "%d min %02d s" % [seconds / 60, seconds % 60]


static func result_heading(stars: int) -> String:
	return "¡Nivel completado!" if stars > 0 else "Nivel terminado"


static func guide_line(stars: int, new_record: bool) -> String:
	if stars >= 3:
		return "¡Tres estrellas! Respondiste como una persona sabia de los Andes."
	if stars == 2:
		return "¡Dos estrellas! Juega otra vez sin pistas para lograr la tercera." if not new_record \
			else "¡Subiste a dos estrellas! La tercera está muy cerca."
	return "¡Lo terminaste! Cada vez que practicas, tus nudos se hacen más fuertes."


static func result_lines(correct: int, total: int, fixed: int, hints: int, time_ms: int) -> Array[String]:
	var lines: Array[String] = ["Acertaste %d de %d al primer intento." % [correct, total]]
	if fixed > 0:
		lines.append("Corregiste %d en el repaso." % fixed)
	if hints > 0:
		lines.append("Usaste %d %s." % [hints, "pista" if hints == 1 else "pistas"])
	if time_ms > 0:
		lines.append("Tiempo: %s." % duration(time_ms))
	return lines


static func streak(count: int) -> String:
	return STREAK % count if count >= 3 else ""


static func mechanic_intro(mechanic: StringName) -> String:
	return MECHANIC_INTROS.get(mechanic, MECHANIC_INTROS[&"classic"])


static func life_lost(mechanic: StringName) -> String:
	return LIFE_LOST.get(mechanic, LIFE_LOST[&"classic"])


static func game_over_title(mechanic: StringName) -> String:
	return GAME_OVER_TITLES.get(mechanic, GAME_OVER_TITLES[&"classic"])


static func attempt(number: int, maximum: int) -> String:
	return "Intento %d de %d" % [number, maximum]


static func cord(area: StringName) -> String:
	return "¡Recuperaste %s!" % CORDS.get(area, "una cuerda del quipu")


static func percent(value: float) -> String:
	return "%s %%" % (str(int(value)) if is_equal_approx(value, roundf(value)) else String.num(value, 1).replace(".", ","))


static func lives_left(left: int, maximum: int) -> String:
	if left >= maximum:
		return "¡Terminaste sin perder ningún nudo!"
	return "Terminaste con %d de %d %s." % [left, maximum, "vida" if maximum == 1 else "vidas"]


static func game_over_lines(answered: int, total: int) -> Array[String]:
	return ["Respondiste %d de %d preguntas." % [answered, total]]
