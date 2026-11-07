class_name TextAnswer
extends RefCounted
## Respuestas escritas: se comparan sin mayúsculas, sin tildes y sin signos ni espacios de más.
## Así «Pero», « pero. » y «PERO» valen lo mismo.

const _PLAIN := {"á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ü": "u", "ñ": "n"}
## Signos y espacios especiales (incluido el espacio que no se corta) que cuentan como espacio.
const _MARKS := ".,;:¡!¿?\"'«»()\t\n\r\u00a0\u202f"


static func normalize(text: String) -> String:
	var plain := ""
	for character in text.to_lower():
		if _MARKS.contains(character):
			plain += " "
		else:
			plain += _PLAIN.get(character, character)
	return " ".join(plain.split(" ", false))


## true si el texto coincide con alguna de las respuestas aceptadas.
static func matches(text: String, accepted: Array) -> bool:
	var wanted := normalize(text)
	if wanted.is_empty():
		return false
	for option in accepted:
		if normalize(str(option)) == wanted:
			return true
	return false
