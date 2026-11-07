class_name Avatar
extends RefCounted
## Avatar del estudiante (RF-31): niño o niña, tono de piel, peinado, color del cabello
## y colores de la ropa. Guarda índices de catálogos; los colores y el dibujo los decide
## la interfaz. Es inmutable y se guarda como JSON en student.avatar_json.

const GIRL := &"girl"
const BOY := &"boy"
const BODIES: Array[StringName] = [GIRL, BOY]
const SKIN_TONES := 6
const HAIR_STYLES := 6
const HAIR_COLORS := 5
const OUTFIT_COLORS := 8

var body: StringName:
	get:
		return _body

var skin: int:
	get:
		return _values["skin"]

var hair_style: int:
	get:
		return _values["hair_style"]

var hair_color: int:
	get:
		return _values["hair_color"]

var top_color: int:
	get:
		return _values["top_color"]

var bottom_color: int:
	get:
		return _values["bottom_color"]

var _body: StringName
var _values: Dictionary


func _init(avatar_body: StringName, values: Dictionary) -> void:
	_body = avatar_body
	_values = values


## Cuántas opciones hay de cada rasgo.
static func option_counts() -> Dictionary:
	return {
		"skin": SKIN_TONES,
		"hair_style": HAIR_STYLES,
		"hair_color": HAIR_COLORS,
		"top_color": OUTFIT_COLORS,
		"bottom_color": OUTFIT_COLORS,
	}


## Valida un avatar descrito como diccionario y devuelve un Result con el Avatar.
static func create(data: Dictionary) -> Result:
	var avatar_body := StringName(str(data.get("body", "")))
	if not avatar_body in BODIES:
		return Result.fail(&"avatar_body", "El avatar es niña o niño.")
	var values := {}
	var counts := option_counts()
	for trait_name: String in counts:
		var raw: Variant = data.get(trait_name)
		if not (raw is int or raw is float) or int(raw) != raw:
			return Result.fail(&"avatar_trait", "Falta el rasgo %s del avatar." % trait_name)
		var index := int(raw)
		if index < 0 or index >= counts[trait_name]:
			return Result.fail(&"avatar_trait", "El rasgo %s del avatar no existe." % trait_name)
		values[trait_name] = index
	return Result.ok(Avatar.new(avatar_body, values))


## Lee el JSON guardado. Devuelve null si el estudiante todavía no creó su personaje.
static func from_dict(data: Dictionary) -> Avatar:
	if data.is_empty():
		return null
	var created := create(data)
	return created.value if created.is_ok() else null


func to_dict() -> Dictionary:
	var data := {"body": String(_body)}
	for trait_name: String in _values:
		data[trait_name] = _values[trait_name]
	return data


func equals(other: Avatar) -> bool:
	return other != null and to_dict() == other.to_dict()
