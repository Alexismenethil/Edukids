class_name PuppetClip
extends RefCounted
## Un gesto escrito como datos: pistas con claves en el tiempo. Los valores son **desplazamientos
## desde la pose de reposo**, así los clips se suman entre sí y con la respiración, y al terminar
## el personaje vuelve solo a su sitio.
##
## Ejemplo (saludo con la mano):
##   {
##     "group": &"arms",
##     "mute": [&"arm_r"],
##     "tracks": {
##       "arm_r:rot": [[0.22, -2.5, "back"], [0.38, -2.1], [0.54, -2.6], [0.9, 0.0, "back"]],
##       "face": [[0.0, "happy"], [0.9, ""]],
##       "cue": [[0.2, "squeak"]],
##     },
##   }
##
## Pistas: `hueso:rot`, `hueso:pos`, `hueso:x`, `hueso:y`, `hueso:scale`, `hueso:sx`, `hueso:sy`;
## del cuerpo entero `lift`, `lean`, `spin`, `squash`, `shift`, `look`; parámetros propios del
## personaje `param:nombre`; y las pistas de eventos `face`, `cue` y `emote`.
## Cada clave es `[tiempo, valor]` o `[tiempo, valor, curva]` (ver PuppetEase).

enum Channel { ROT, POS, X, Y, SCALE, SX, SY, LIFT, LEAN, SPIN, SQUASH, SHIFT, LOOK, PARAM }

const BODY_CHANNELS := {
	"lift": Channel.LIFT, "lean": Channel.LEAN, "spin": Channel.SPIN, "squash": Channel.SQUASH,
	"shift": Channel.SHIFT, "look": Channel.LOOK,
}
const BONE_CHANNELS := {
	"rot": Channel.ROT, "pos": Channel.POS, "x": Channel.X, "y": Channel.Y, "scale": Channel.SCALE,
	"sx": Channel.SX, "sy": Channel.SY,
}
const EVENT_TRACKS: Array[String] = ["face", "cue", "emote"]

var name: StringName
var length := 0.0
var loop := false
## Al empezar un clip se apaga el que estaba sonando en su mismo grupo.
var group: StringName = &"gesture"
var fade_in := 0.0
var fade_out := 0.14
## Huesos cuya respiración y ciclo de carrera se apagan mientras dura el clip.
var mute: Array[StringName] = []
var tracks: Array[Track] = []
## Eventos ordenados por tiempo: [tiempo, pista, valor].
var events: Array = []


static func from_dict(clip_name: StringName, data: Dictionary) -> PuppetClip:
	var clip := PuppetClip.new()
	clip.name = clip_name
	clip.loop = data.get("loop", false)
	clip.group = data.get("group", &"gesture")
	clip.fade_in = data.get("fade_in", 0.0)
	clip.fade_out = data.get("fade_out", 0.14)
	for bone: StringName in data.get("mute", []):
		clip.mute.append(bone)
	var source: Dictionary = data.get("tracks", {})
	for key: String in source:
		var keys: Array = source[key]
		if key in EVENT_TRACKS:
			for event: Array in keys:
				clip.events.append([float(event[0]), key, event[1]])
				clip.length = maxf(clip.length, float(event[0]))
			continue
		var track := Track.new()
		if BODY_CHANNELS.has(key):
			track.channel = BODY_CHANNELS[key]
		elif key.begins_with("param:"):
			track.channel = Channel.PARAM
			track.target = StringName(key.get_slice(":", 1))
		else:
			track.target = StringName(key.get_slice(":", 0))
			var channel := key.get_slice(":", 1)
			if not BONE_CHANNELS.has(channel):
				push_warning("Clip %s: pista desconocida «%s»." % [clip_name, key])
				continue
			track.channel = BONE_CHANNELS[channel]
		track.vector = track.channel in [Channel.POS, Channel.SCALE, Channel.SQUASH, Channel.SHIFT, Channel.LOOK]
		track.multiply = track.channel in [Channel.SCALE, Channel.SQUASH, Channel.SX, Channel.SY]
		for entry: Array in keys:
			track.times.append(float(entry[0]))
			track.values.append(_value(entry[1], track.vector))
			track.eases.append(StringName(entry[2]) if entry.size() > 2 else &"inout")
		if track.times.is_empty():
			continue
		clip.length = maxf(clip.length, track.times[track.times.size() - 1])
		clip.tracks.append(track)
	clip.events.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	clip.length = maxf(float(data.get("length", 0.0)), clip.length)
	return clip


static func _value(raw: Variant, vector: bool) -> Variant:
	if not vector:
		return float(raw)
	if raw is Vector2:
		return raw
	if raw is Array:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2(float(raw), float(raw))


## Una pista: un canal de un hueso (o del cuerpo) con sus claves.
class Track:
	extends RefCounted

	var target: StringName
	var channel := Channel.ROT
	var vector := false
	## Las escalas se multiplican (reposo = 1); el resto se suma (reposo = 0).
	var multiply := false
	var times := PackedFloat32Array()
	var values: Array = []
	var eases: Array[StringName] = []

	func rest() -> Variant:
		if vector:
			return Vector2.ONE if multiply else Vector2.ZERO
		return 1.0 if multiply else 0.0

	## Valor de la pista en el instante `time`. Antes de la primera clave parte del reposo.
	func sample(time: float) -> Variant:
		var count := times.size()
		if time >= times[count - 1]:
			return values[count - 1]
		var next := 0
		while next < count and times[next] <= time:
			next += 1
		var t0 := 0.0
		var from: Variant = rest()
		if next > 0:
			t0 = times[next - 1]
			from = values[next - 1]
		var span := times[next] - t0
		var u := PuppetEase.apply(eases[next], (time - t0) / span if span > 0.0001 else 1.0)
		if vector:
			return (from as Vector2).lerp(values[next], u)
		return lerpf(from, values[next], u)
