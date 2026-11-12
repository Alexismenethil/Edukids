class_name LevelEntry
extends RefCounted
## Un nivel tal como lo describe el manifiesto del paquete: tipo, mecánica, archivo y reglas.

const SHORT := &"short"
const REGULAR := &"regular"
const FINAL := &"final"
const KINDS: Array[StringName] = [SHORT, REGULAR, FINAL]
const CHASE := &"chase"
const BRIDGE := &"bridge"
## Darle de comer al caimán Coco: cada acierto es una fruta para él; cada error lo pone gruñón.
const CAIMAN := &"caiman"
const CLASSIC := &"classic"
const MECHANICS: Array[StringName] = [CHASE, BRIDGE, CAIMAN, CLASSIC]
const DEFAULT_LIVES := 3
const MAX_LIVES := 5
## Intentos del desafío final, si el manifiesto no dice otra cosa.
const DEFAULT_FINAL_ATTEMPTS := 2

var id := ""
var kind: StringName = SHORT
var mechanic: StringName = CLASSIC
var file := ""
var position := 0
var estimated_minutes := 0
var lives := DEFAULT_LIVES
var danger_start := DangerMeter.DEFAULT_START
var danger_max := DangerMeter.DEFAULT_MAX
var timer_seconds := 0
## Solo en el desafío final: intentos que tiene cada estudiante.
var max_attempts := DEFAULT_FINAL_ATTEMPTS


static func parse(raw: Variant, position_in_package: int) -> Result:
	if typeof(raw) != TYPE_DICTIONARY:
		return Result.fail(&"manifest_invalid", "Cada nivel del manifiesto debe ser un objeto.")
	var entry := LevelEntry.new()
	entry.id = str(raw.get("id", "")).strip_edges()
	entry.kind = StringName(str(raw.get("kind", "")))
	entry.mechanic = StringName(str(raw.get("mechanic", "")))
	entry.file = str(raw.get("file", "")).strip_edges()
	entry.position = position_in_package
	if entry.id.is_empty():
		return Result.fail(&"manifest_invalid", "Hay un nivel sin «id».")
	if not KINDS.has(entry.kind) or not MECHANICS.has(entry.mechanic):
		return Result.fail(&"manifest_invalid", "El nivel %s tiene un tipo o una mecánica desconocidos." % entry.id)
	if not is_safe_path(entry.file) or not entry.file.ends_with(".json"):
		return Result.fail(&"manifest_invalid", "El archivo del nivel %s no es válido." % entry.id)
	entry.estimated_minutes = int(raw.get("estimated_minutes", 0))
	entry.lives = int(raw.get("lives", DEFAULT_LIVES))
	var danger: Variant = raw.get("danger", {})
	if typeof(danger) == TYPE_DICTIONARY:
		entry.danger_start = int(danger.get("start", DangerMeter.DEFAULT_START))
		entry.danger_max = int(danger.get("max", DangerMeter.DEFAULT_MAX))
	entry.timer_seconds = int(raw.get("timer_seconds", 0))
	entry.max_attempts = int(raw.get("max_attempts", DEFAULT_FINAL_ATTEMPTS))
	if entry.kind == FINAL and entry.mechanic != CLASSIC:
		return Result.fail(&"manifest_invalid", "El desafío final %s debe usar la mecánica clásica (RN-10)." % entry.id)
	if entry.lives < 1 or entry.lives > MAX_LIVES:
		return Result.fail(&"manifest_invalid", "El nivel %s debe tener entre 1 y %d vidas." % [entry.id, MAX_LIVES])
	if not DangerMeter.create(entry.danger_start, entry.danger_max).is_ok():
		return Result.fail(&"manifest_invalid", "El medidor de peligro del nivel %s no es válido." % entry.id)
	if entry.max_attempts < 1:
		return Result.fail(&"manifest_invalid", "El desafío final %s necesita al menos un intento." % entry.id)
	return Result.ok(entry)


func is_final() -> bool:
	return kind == FINAL


## Rutas del paquete: relativas, en minúsculas, sin «..» ni rutas absolutas (formato v1).
static func is_safe_path(path: String) -> bool:
	return not path.is_empty() and path == path.to_lower() and not path.begins_with("/") \
		and not path.contains("..") and not path.contains("\\") and not path.contains(":")
