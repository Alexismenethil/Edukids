class_name SemanticVersion
extends RefCounted
## Versión semántica MAYOR.MENOR.PARCHE de un paquete o de la aplicación («1.2.0»).

var major := 0
var minor := 0
var patch := 0


## Lee «1.2.3» (o «1.2», con parche 0). Falla si no son números.
static func parse(text: String) -> Result:
	var parts := text.strip_edges().split(".")
	if parts.size() < 2 or parts.size() > 3:
		return Result.fail(&"version_invalid", "«%s» no es una versión válida (debe ser como 1.0.0)." % text)
	for part in parts:
		if part.is_empty() or not part.is_valid_int() or int(part) < 0:
			return Result.fail(&"version_invalid", "«%s» no es una versión válida (debe ser como 1.0.0)." % text)
	var version := SemanticVersion.new()
	version.major = int(parts[0])
	version.minor = int(parts[1])
	version.patch = int(parts[2]) if parts.size() == 3 else 0
	return Result.ok(version)


## -1 si esta versión es anterior a `other`, 0 si es la misma y 1 si es posterior.
func compare(other: SemanticVersion) -> int:
	for pair in [[major, other.major], [minor, other.minor], [patch, other.patch]]:
		if pair[0] != pair[1]:
			return -1 if pair[0] < pair[1] else 1
	return 0


func _to_string() -> String:
	return "%d.%d.%d" % [major, minor, patch]
