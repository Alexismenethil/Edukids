class_name MapMessages
extends RefCounted
## Textos del mapa: capítulos, paradas, senderos y mecánicas de juego.

const CHAPTER_NAME := "Sierra"
const CHAPTER_TITLE := "Las alturas de Ayacucho"
const LOCKED := "Tu docente lo abrirá pronto."
const BACK := "Mapa"
const EDIT := "Mi personaje"
const STORY := "Historia"
const EXIT := "Salir"
const PLAY := "¡Jugar!"
const RESUME := "Seguir"
const REPLAY := "Otra vez"
const HALF_DONE := "A medias"
const CLOSE := "Cerrar"
const MAP_GUIDE := "Atoq esparció los nudos del quipu por la Sierra. ¡Empecemos por Huamanga!"
const STOP_GUIDE := "Cada sendero es una cuerda del quipu. ¡Ata sus nudos y llega al desafío final!"
const NO_ATTEMPTS := "Ya usaste tus intentos. Tu docente puede darte otro."

const STOPS := {
	"huamanga": {"name": "Huamanga", "about": "Plaza, mercado y talleres de retablos", "icon": "stop_huamanga"},
	"quinua": {"name": "Quinua", "about": "Pueblo de ceramistas y pampa histórica", "icon": "stop_quinua"},
	"pampa-galeras": {"name": "Pampa Galeras", "about": "Puna abierta con vicuñas", "icon": "stop_pampa_galeras"},
	"vilcashuaman": {"name": "Vilcashuamán", "about": "Templo inca, ushnu y andenes", "icon": "stop_vilcashuaman"},
}

const MECHANICS := {
	&"chase": {
		"name": "Persecución",
		"about": "¡Que Atoq no te alcance! Cada acierto te hace correr más rápido.",
		"icon": "mech_chase",
	},
	&"bridge": {
		"name": "El puente colgante",
		"about": "Cada acierto pone una tabla. Con cada error, el puente se tambalea.",
		"icon": "mech_bridge",
	},
	&"caiman": {
		"name": "Coco, el caimán glotón",
		"about": "Cada acierto es una fruta para Coco. Si fallas, se pone gruñón y muerde.",
		"icon": "mech_caiman",
	},
	&"classic": {
		"name": "Tarjetas con Quwi",
		"about": "Resuelve las tarjetas con calma. Atoq se asoma cuando te equivocas.",
		"icon": "mech_classic",
	},
	&"final": {
		"name": "Desafío final",
		"about": "Sin vidas ni pistas: al entregar verás tu calificación.",
		"icon": "mech_final",
	},
}


static func stop_name(stop_id: String) -> String:
	return STOPS.get(stop_id, {}).get("name", stop_id.capitalize())


static func stop_about(stop_id: String) -> String:
	return STOPS.get(stop_id, {}).get("about", "")


static func stop_icon(stop_id: String) -> String:
	return STOPS.get(stop_id, {}).get("icon", "star")


static func mechanic_of(mechanic: StringName, final: bool) -> Dictionary:
	return MECHANICS[&"final"] if final else MECHANICS.get(mechanic, MECHANICS[&"classic"])


static func trail_title(area_name: String) -> String:
	return "Sendero de %s" % area_name


static func stars(earned: int, maximum: int) -> String:
	return "%d / %d" % [earned, maximum]


static func greeting(first_name: String) -> String:
	return "¡Hola, %s!" % first_name if not first_name.is_empty() else "¡Hola!"


static func locked_by(title: String) -> String:
	return "Completa «%s» para abrir este nivel." % title if not title.is_empty() else LOCKED


static func final_locked(package_title: String) -> String:
	return "Completa los niveles de práctica para abrir el desafío final."


static func attempts(left: int, maximum: int) -> String:
	if left <= 0:
		return NO_ATTEMPTS
	return "Te %s %d de %d %s." % ["queda" if left == 1 else "quedan", left, maximum, "intento" if maximum == 1 else "intentos"]


static func lives(count: int) -> String:
	return "%d %s" % [count, "vida" if count == 1 else "vidas"]
