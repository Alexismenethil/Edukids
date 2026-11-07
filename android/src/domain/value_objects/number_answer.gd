class_name NumberAnswer
extends RefCounted
## Número escrito por el estudiante: entero, decimal (con coma o con punto), fracción o número mixto.
## «0,5», «0.5» y «1/2» valen lo mismo; cada ítem decide qué formatos acepta.

const DECIMAL := &"decimal"
const FRACTION := &"fraction"
const FORMATS: Array[StringName] = [DECIMAL, FRACTION]
## Margen para comparar decimales sin errores de redondeo.
const EPSILON := 0.000001

var value: float
var format: StringName


func _init(number: float = 0.0, written_as: StringName = DECIMAL) -> void:
	value = number
	format = written_as


## Lee lo que escribió el estudiante. Los espacios entre cifras se ignoran («1 440»).
static func parse(text: String) -> Result:
	var clean := text.strip_edges()
	if clean.is_empty():
		return Result.fail(&"number_empty", "Escribe un número.")
	if clean.contains("/"):
		return _parse_fraction(clean)
	var decimal := _without_thousands(clean).replace(",", ".")
	if not _is_decimal(decimal):
		return Result.fail(&"number_invalid", "Revisa cómo escribiste el número.")
	return Result.ok(NumberAnswer.new(decimal.to_float(), DECIMAL))


static func same(a: float, b: float, tolerance: float = 0.0) -> bool:
	return absf(a - b) <= maxf(tolerance, 0.0) + EPSILON


## Escribe un número como en los libros del Perú: espacio para los miles y coma decimal.
static func spoken(number: float) -> String:
	var negative := number < 0.0
	var text := String.num(absf(number), 6)
	if text.contains("."):
		text = text.rstrip("0").rstrip(".")
	var whole := text.get_slice(".", 0)
	var decimals := text.get_slice(".", 1) if text.contains(".") else ""
	var grouped := ""
	if whole.length() > 3:
		var count := 0
		for index in range(whole.length() - 1, -1, -1):
			grouped = whole[index] + grouped
			count += 1
			if count % 3 == 0 and index > 0:
				grouped = " " + grouped
	else:
		grouped = whole
	var result := grouped if decimals.is_empty() else "%s,%s" % [grouped, decimals]
	return "-" + result if negative else result


static func _parse_fraction(text: String) -> Result:
	var invalid := Result.fail(&"number_invalid", "Revisa cómo escribiste la fracción.")
	var rest := text.replace(" /", "/").replace("/ ", "/")
	var negative := rest.begins_with("-")
	rest = rest.trim_prefix("-").strip_edges()
	var whole := 0
	var pieces := rest.split(" ", false)
	if pieces.size() == 2:
		if not _is_digits(pieces[0]):
			return invalid
		whole = pieces[0].to_int()
		rest = pieces[1]
	elif pieces.size() != 1:
		return invalid
	var parts := rest.split("/")
	if parts.size() != 2 or not _is_digits(parts[0]) or not _is_digits(parts[1]):
		return invalid
	var denominator := parts[1].to_int()
	if denominator == 0:
		return invalid
	var number := whole + parts[0].to_int() / float(denominator)
	return Result.ok(NumberAnswer.new(-number if negative else number, FRACTION))


## Quita los espacios de los miles («1 254 300»). Devuelve "" si los grupos no son de tres cifras.
static func _without_thousands(text: String) -> String:
	if not text.contains(" "):
		return text
	var groups := text.split(" ", false)
	var first := groups[0].trim_prefix("-")
	if first.is_empty() or first.length() > 3:
		return ""
	for index in range(1, groups.size()):
		var whole := groups[index].get_slice(",", 0).get_slice(".", 0)
		if whole.length() != 3 or (index < groups.size() - 1 and whole != groups[index]):
			return ""
	return "".join(groups)


static func _is_decimal(text: String) -> bool:
	var digits := text.trim_prefix("-")
	if digits.is_empty() or digits.count(".") > 1 or digits.ends_with("."):
		return false
	for character in digits:
		if character != "." and not _is_digits(character):
			return false
	return true


static func _is_digits(text: String) -> bool:
	if text.is_empty():
		return false
	for character in text:
		if character < "0" or character > "9":
			return false
	return true
