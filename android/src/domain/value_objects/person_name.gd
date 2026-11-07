class_name PersonName
extends RefCounted
## Nombre de una persona tal como se ve en la tablet: sin espacios de más, de 2 a 40
## caracteres, con letras (tildes y ñ incluidas), espacios, apóstrofo, guion o punto.

const MIN_LENGTH := 2
const MAX_LENGTH := 40
const ACCENTS := {
	"á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ü": "u", "ñ": "n",
	"à": "a", "è": "e", "ì": "i", "ò": "o", "ù": "u",
}


## Devuelve un Result con el nombre limpio (String).
static func parse(text: String) -> Result:
	var clean := normalize(text)
	if clean.length() < MIN_LENGTH:
		return Result.fail(&"name_too_short", "El nombre tiene al menos 2 letras.")
	if clean.length() > MAX_LENGTH:
		return Result.fail(&"name_too_long", "El nombre tiene como máximo 40 caracteres.")
	if not is_letter(clean.unicode_at(0)) or not _has_only_name_characters(clean):
		return Result.fail(&"name_invalid", "El nombre solo lleva letras, espacios, apóstrofos o guiones.")
	return Result.ok(clean)


## Quita los espacios de los extremos y deja uno solo entre palabras.
static func normalize(text: String) -> String:
	var spaced := text.replace("\t", " ").replace("\n", " ").replace("\r", " ")
	return " ".join(spaced.strip_edges().split(" ", false))


## Clave para comparar nombres sin distinguir mayúsculas ni tildes: «Ána» y «ana» son iguales.
static func comparison_key(text: String) -> String:
	var key := normalize(text).to_lower()
	for accented: String in ACCENTS:
		key = key.replace(accented, ACCENTS[accented])
	return key


static func _has_only_name_characters(text: String) -> bool:
	for i in text.length():
		var code := text.unicode_at(i)
		if not (is_letter(code) or code in [32, 39, 45, 46, 0x2019]):
			return false
	return true


## Letras latinas: A-Z, a-z y las letras con tilde, diéresis o virgulilla (Latin-1 y Latin Extended-A).
static func is_letter(code: int) -> bool:
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122) \
		or (code >= 192 and code <= 214) or (code >= 216 and code <= 246) \
		or (code >= 248 and code <= 383)
