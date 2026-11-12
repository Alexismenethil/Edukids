class_name Puppet
extends Node2D
## Motor de títeres de EduKids: la base de todos los personajes animados por piezas.
##
## Un personaje nuevo solo declara sus datos en `_setup()` (qué rig usa, cómo se llaman sus huesos,
## qué piezas tienen resorte, sus expresiones y sus clips) y recibe gratis: respiración, parpadeo,
## habla, mirada que sigue al dedo, cabeza que gira en 2.5D, pelo y colas con rebote, aplastamiento
## al caer, sombra, emotes, reacción al toque y gestos de biblioteca (PuppetMoves).
##
## Cada cuadro la pose se arma por capas, todas sumadas sobre la pose de reposo del rig:
##   1. reposo vivo (`_sway`, `_breathe`)       4. cara (PuppetFace)
##   2. ciclos de marcha (`_cycle`)             5. mirada (`look_at_point`)
##   3. clips (`play`)                          6. resortes (`_spring`)
## Como todo se suma, un saludo puede sonar mientras el personaje corre, respira y mira al dedo.
##
## El origen del títere está entre sus pies. La guía para crear un personaje está en
## scenes/characters/README.md. Solo anima: las reglas del juego viven en el dominio.

## Lo tocaron (solo si `interactive`).
signal tapped
## Lo acariciaron: el dedo pasó un rato por encima.
signal petted
## Un clip llegó a una marca `cue` (por ejemplo «step» o «land»): la escena pone el efecto.
signal cue(cue_name: StringName)

const SHADOW_COLOR := Color(0.2, 0.12, 0.05, 0.22)
const EMOTE := preload("res://scenes/characters/puppet/puppet_emote.gd")

## 1 mira a la derecha; -1 a la izquierda (el rig se voltea).
@export var facing := 1:
	set(value):
		facing = 1 if value >= 0 else -1
		if _pose:
			_apply_body()
## Respira, parpadea y se mueve solo. Desactívalo para retratos quietos.
@export var lively := true:
	set(value):
		lively = value
		set_process(value)
## Escala de la sombra en el suelo (0 la oculta).
@export var shadow_scale := 1.0
## Reacciona solo cuando lo tocan o lo acarician.
@export var interactive := false
## Sigue con la mirada el dedo que toca la pantalla.
@export var curious := true
## Pisa el suelo: al caer se aplasta y levanta polvo. Falso para los que vuelan o nadan.
@export var grounded := true

## Estiramiento y aplastamiento, desde los pies.
var squash := Vector2.ONE
## Altura sobre el suelo (unidades del títere).
var lift := 0.0
## Inclinación del cuerpo hacia adelante, en radianes.
var lean := 0.0
## Giro alrededor del centro del cuerpo (volteretas).
var spin := 0.0
## Desplazamiento del cuerpo sin mover el origen.
var shift := Vector2.ZERO
## Velocidad «de mentira» cuando corre en su sitio: el pelo y la cola se van hacia atrás.
var travel := Vector2.ZERO
## Vivacidad del reposo: 0 quieto, 1 normal, más de 1 inquieto.
var energy := 1.0
## Velocidad del reposo (un personaje dormido respira más lento).
var tempo := 1.0
var face: PuppetFace

# --- Datos del personaje (se llenan en _setup) ---
## Radio y achatado de la sombra.
var shadow_radius := 64.0
var shadow_flat := 0.2
## Zona que responde al toque, en el espacio del títere.
var hit_rect := Rect2(-100.0, -300.0, 200.0, 310.0)
## Centro del cuerpo: eje de las volteretas y origen de la mirada.
var body_center := Vector2(0.0, -150.0)
## Dónde aparecen los emotes y su tamaño.
var emote_anchor := Vector2(60.0, -320.0)
var emote_size := 1.0
## Cuánto se corren las piezas de la cara al mirar (píxeles del rig para profundidad 1).
var look_range := Vector2(8.0, 5.0)
## Cuánto gira la cabeza al mirar a los lados y arriba o abajo.
var look_turn := 0.0
var look_nod := 0.0
## A qué distancia el dedo ya hace mirar del todo.
var look_reach := 320.0
## Gestos que hace solo cuando se aburre, y cada cuántos segundos.
var fidgets: Array[StringName] = []
var fidget_wait := Vector2(5.0, 11.0)
## Reacciones al toque: se alternan en orden.
var tap_reactions: Array[StringName] = []

var _pose: Node2D
var _rig: Node2D
var _time := 0.0
var _bones: Dictionary = {}
var _bone_list: Array[PuppetBone] = []
var _sways: Array = []
var _cycles: Dictionary = {}
var _clips: Dictionary = {}
var _playing: Array[PuppetPlayback] = []
var _springs: Array[PuppetSpring] = []
var _strips: Dictionary = {}
var _look_layers: Array = []
var _params: Dictionary = {}
var _started := false

# Lo que suman las capas al cuerpo en este cuadro.
var _b_lift := 0.0
var _b_lean := 0.0
var _b_spin := 0.0
var _b_squash := Vector2.ONE
var _b_shift := Vector2.ZERO
var _b_look := Vector2.ZERO

var _look := Vector2.ZERO
var _look_goal := Vector2.ZERO
var _look_point := Vector2.ZERO
var _look_mode := 0
var _look_left := 0.0
var _attention := Vector2.ZERO
var _attention_left := 0.0
var _glance := Vector2.ZERO
var _glance_wait := 3.0
var _glance_left := 0.0
var _fidget_in := 6.0
var _tap := 0
var _press_at := Vector2.INF
var _press_ms := 0
var _stroke := 0.0
var _pet_wait := 0.0
var _hop: Tween
var _jelly := 0.0
var _jelly_speed := 0.0
var _last_height := 0.0
var _height_speed := 0.0
var _drawn_height := -1.0
var _cycle_travel := Vector2.ZERO
var _tap_ms := 0


func _ready() -> void:
	_pose = Node2D.new()
	_pose.name = "Pose"
	add_child(_pose)
	_setup()
	if face:
		face.bind(_bones.get(&"eyes"), _bones.get(&"mouth"), _bones.get(&"brow_l"), _bones.get(&"brow_r"),
			_bones.get(&"brows"))
	_time = randf() * TAU
	_fidget_in = randf_range(fidget_wait.x, fidget_wait.y)
	_glance_wait = randf_range(1.5, 4.0)
	_started = true
	set_process(lively)
	refresh()


## Cada personaje declara aquí su rig, huesos, resortes, cara y clips.
func _setup() -> void:
	pass


## Movimiento por código que no cabe en datos (se suma antes de los clips).
func _animate(_delta: float) -> void:
	pass


## Después de aplicar la pose: piezas dibujadas por código que dependen de ella.
func _after_pose(_delta: float) -> void:
	pass


## Un clip disparó una marca. Por omisión solo avisa con la señal `cue`.
func _on_cue(cue_name: StringName) -> void:
	cue.emit(cue_name)


# --- Declaración del personaje -----------------------------------------------------------------

## Instancia el rig generado por tools/art/build_cutout_rig.gd.
func _use_rig(scene: PackedScene) -> Node2D:
	_rig = scene.instantiate()
	_pose.add_child(_rig)
	return _rig


## Da nombre a las piezas que se animan: {&"head": "Torso/Head", ...}.
func _bone_map(map: Dictionary) -> void:
	for bone_name: StringName in map:
		_add_bone(bone_name, _rig.get_node(map[bone_name]) as Node2D)


func _add_bone(bone_name: StringName, node: Node2D) -> PuppetBone:
	if node == null:
		push_warning("%s: no existe la pieza del hueso «%s»." % [name, bone_name])
		return null
	var bone := PuppetBone.new(node)
	_bones[bone_name] = bone
	_bone_list.append(bone)
	return bone


## Vaivén continuo de un hueso: `channel` es rot, x, y, sx o sy.
func _sway(bone_name: StringName, channel: String, amplitude: float, speed: float, phase: float = 0.0) -> void:
	var bone: PuppetBone = _bones.get(bone_name)
	if bone:
		_sways.append([bone, channel, amplitude, speed, phase])


## Respiración: el hueso se ensancha y se estira apenas.
func _breathe(bone_name: StringName, amount: float = 0.012, speed: float = 2.3) -> void:
	_sway(bone_name, "sy", amount, speed)
	_sway(bone_name, "sx", -amount * 0.5, speed)


## Resorte para una pieza que cuelga o sobresale. `axis` es hacia dónde apunta la pieza desde su
## pivote (en su propio espacio) y `length` su largo. Opciones: stiffness, damping, drag, limit,
## gain, origin.
func _spring(bone_name: StringName, axis: Vector2, length: float, options: Dictionary = {}) -> PuppetSpring:
	if not _bones.has(bone_name):
		return null
	var spring := PuppetSpring.new()
	spring.bone = bone_name
	spring.axis = axis.normalized()
	spring.length = length
	spring.stiffness = options.get("stiffness", spring.stiffness)
	spring.damping = options.get("damping", spring.damping)
	spring.drag = options.get("drag", spring.drag)
	spring.limit = options.get("limit", spring.limit)
	spring.gain = options.get("gain", spring.gain)
	spring.origin = options.get("origin", Vector2.ZERO)
	_springs.append(spring)
	return spring


## Convierte la pieza de un hueso en una tira flexible (cola, trenza, chalina) que se curva de la
## raíz a la punta. Opciones: wave (amplitud de la onda), speed, wavelength, curl (cuánto la
## dobla su resorte) y bend (curva fija).
func _strip(bone_name: StringName, root: Vector2, tip: Vector2, pieces: int = 8, options: Dictionary = {}) -> BendStrip:
	var bone: PuppetBone = _bones.get(bone_name)
	if bone == null or not bone.node is Sprite2D:
		return null
	var strip := BendStrip.from_sprite(bone.node as Sprite2D, root, tip, pieces)
	bone.node = strip
	_strips[bone_name] = {"strip": strip, "wave": options.get("wave", 0.0), "speed": options.get("speed", 2.0),
		"wavelength": options.get("wavelength", 1.0), "curl": options.get("curl", 1.0), "bend": options.get("bend", 0.0)}
	return strip


## Arma la cara con las piezas que cuelgan de `head_path` y sus expresiones.
func _face_setup(head_path: NodePath, expressions: Dictionary, options: Dictionary = {}) -> PuppetFace:
	face = PuppetFace.new()
	var head := _rig.get_node(head_path)
	face.discover(head)
	for expression: StringName in expressions:
		face.expressions[expression] = expressions[expression]
	if options.has("talk"):
		face.talk_shapes.assign(options["talk"])
	if options.has("blinkable"):
		face.blinkable.assign(options["blinkable"])
	face.blink_eyes = options.get("blink_eyes", face.blink_eyes)
	if not _bones.has(&"eyes") and head.has_node("Eyes"):
		_add_bone(&"eyes", head.get_node("Eyes"))
	if not _bones.has(&"mouth") and head.has_node("Mouth"):
		_add_bone(&"mouth", head.get_node("Mouth"))
	return face


## Una pieza que se corre al mirar: profundidad 1 es la cara; menos, lo que está más atrás;
## negativa, lo que queda del otro lado de la cabeza (orejas, pelo de atrás).
func _look_layer(bone_name: StringName, depth: Vector2) -> void:
	var bone: PuppetBone = _bones.get(bone_name)
	if bone:
		_look_layers.append([bone, depth])


## Registra los clips propios del personaje (ver PuppetClip).
func _clip_set(clips: Dictionary) -> void:
	for clip_name: StringName in clips:
		_clips[clip_name] = PuppetClip.from_dict(clip_name, clips[clip_name])


## Un ciclo de marcha: pistas periódicas que avanzan con la velocidad.
##   {"stride": 0.42, "gain": Vector2(0.5, 1.3), "travel": 300.0,
##    "tracks": [["leg_fl:rot", 0.62], ["lift", 9.0, 0.0, &"abs"], ...]}
## Cada pista es [canal, amplitud, desfase, forma, multiplicador, base]; las formas son sin, cos,
## abs (|sin|) y half (solo la mitad positiva). Los canales del cuerpo: lift, lean, squash_x,
## squash_y, shift_x y shift_y.
func _cycle(cycle_name: StringName, data: Dictionary) -> void:
	var tracks: Array = []
	for raw: Array in data.get("tracks", []):
		var key: String = raw[0]
		var bone: PuppetBone = null
		var channel := key
		if key.contains(":"):
			bone = _bones.get(StringName(key.get_slice(":", 0)))
			channel = key.get_slice(":", 1)
			if bone == null:
				continue
		tracks.append({"bone": bone, "channel": channel, "amp": float(raw[1]),
			"offset": float(raw[2]) if raw.size() > 2 else 0.0,
			"shape": StringName(raw[3]) if raw.size() > 3 else &"sin",
			"mul": float(raw[4]) if raw.size() > 4 else 1.0,
			"bias": float(raw[5]) if raw.size() > 5 else 0.0})
	_cycles[cycle_name] = {"stride": float(data.get("stride", 0.4)), "gain": data.get("gain", Vector2(0.5, 1.4)),
		"rate": data.get("rate", Vector2(0.5, 2.2)), "travel": float(data.get("travel", 0.0)),
		"tracks": tracks, "phase": 0.0, "speed": 0.0, "weight": 0.0}


# --- Uso desde las escenas ---------------------------------------------------------------------

## Toca un clip del personaje o de la biblioteca (PuppetMoves). Opciones: speed, amount, loop.
func play(clip_name: StringName, options: Dictionary = {}) -> PuppetPlayback:
	var clip: PuppetClip = _clips.get(clip_name)
	if clip == null:
		clip = PuppetMoves.get_clip(clip_name)
	if clip == null:
		push_warning("%s: no existe el clip «%s»." % [name, clip_name])
		var missing := PuppetPlayback.new()
		missing.done = true
		return missing
	for other in _playing:
		if other.clip.group == clip.group:
			other.stop(0.12)
	var playback := PuppetPlayback.new(clip)
	playback.speed = options.get("speed", 1.0)
	playback.amount = options.get("amount", 1.0)
	playback.loop = options.get("loop", clip.loop)
	_playing.append(playback)
	_fidget_in = randf_range(fidget_wait.x, fidget_wait.y)
	return playback


## Corta un clip por su nombre o todos los de un grupo.
func stop_clip(name_or_group: StringName, fade: float = 0.14) -> void:
	for playback in _playing:
		if playback.clip.name == name_or_group or playback.clip.group == name_or_group:
			playback.stop(fade)


func is_playing(name_or_group: StringName) -> bool:
	for playback in _playing:
		if not playback.done and (playback.clip.name == name_or_group or playback.clip.group == name_or_group):
			return true
	return false


func has_clip(clip_name: StringName) -> bool:
	return _clips.has(clip_name) or PuppetMoves.get_clip(clip_name) != null


## Un clip propio del personaje por su nombre (null si no lo tiene).
func own_clip(clip_name: StringName) -> PuppetClip:
	return _clips.get(clip_name)


func has_bone(bone_name: StringName) -> bool:
	return _bones.has(bone_name)


## Clips propios del personaje, en el orden en que se declararon.
func own_clips() -> Array[StringName]:
	var list: Array[StringName] = []
	list.assign(_clips.keys())
	return list


## Expresiones que tiene la cara del personaje.
func expressions() -> Array[StringName]:
	var list: Array[StringName] = []
	if face:
		list.assign(face.expressions.keys())
	return list


## Velocidad de un ciclo de marcha: 0 lo detiene.
func set_cycle(cycle_name: StringName, speed: float) -> void:
	if _cycles.has(cycle_name):
		_cycles[cycle_name]["speed"] = speed


## Cambia el estado de ánimo de base (una expresión del personaje).
func set_expression(expression: StringName) -> void:
	if face:
		face.mood = expression


## Pone una expresión por unos segundos.
func express(expression: StringName, seconds: float = 1.0) -> void:
	if face:
		face.express(expression, seconds)


## Mueve la boca como si hablara.
func talk(active: bool) -> void:
	if face:
		face.talking = active


## Salto con anticipación; el aterrizaje aplasta solo.
func hop(height: float = 34.0, seconds: float = 0.42) -> void:
	if _hop:
		_hop.kill()
	_hop = create_tween()
	_hop.tween_property(self, "squash", Vector2(1.12, 0.86), 0.08)
	_hop.tween_property(self, "squash", Vector2(0.93, 1.09), 0.1)
	_hop.parallel().tween_property(self, "lift", height, seconds * 0.54).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop.tween_property(self, "lift", 0.0, seconds * 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_hop.parallel().tween_property(self, "squash", Vector2.ONE, seconds * 0.46)


## Saca un emote sobre la cabeza: heart, alert, question, note, idea, zzz, sweat, anger, dizzy
## o sparkle.
func emote(kind: StringName, seconds: float = 1.4) -> void:
	var bubble: PuppetEmote = EMOTE.new()
	bubble.kind = kind
	bubble.life = seconds
	bubble.size = emote_size
	bubble.position = Vector2(emote_anchor.x * facing, emote_anchor.y - lift)
	if kind != &"zzz" and kind != &"sweat":
		Sounds.play(&"pop", randf_range(0.95, 1.1), -9.0)
	if kind == &"dizzy" or kind == &"sparkle":
		bubble.position.x = 0.0
	add_child(bubble)


## Mira hacia un punto de la pantalla (coordenadas globales). Con `seconds` = 0 mira hasta
## que se llame a `look_reset`.
func look_at_point(global_point: Vector2, seconds: float = 0.0) -> void:
	_look_mode = 1
	_look_point = global_point
	_look_left = seconds if seconds > 0.0 else INF
	if face and _look_goal.distance_to(_gaze_to(to_local(global_point))) > 0.9:
		face.blink()


## Mira en una dirección: (1, 0) a la derecha de la pantalla, (0, -1) arriba.
func look_toward(direction: Vector2, seconds: float = 0.0) -> void:
	_look_mode = 2
	_look_point = direction.limit_length(1.0)
	_look_left = seconds if seconds > 0.0 else INF


func look_reset() -> void:
	_look_mode = 0


## ¿El punto (en coordenadas globales) toca al personaje?
func contains_point(global_point: Vector2) -> bool:
	return hit_rect.has_point(to_local(global_point))


## Reacción al toque: toca la siguiente de `tap_reactions`.
func react_to_tap() -> void:
	if tap_reactions.is_empty():
		hop(26.0)
	else:
		play(tap_reactions[_tap % tap_reactions.size()])
	_tap += 1


## Reacción a la caricia.
func react_to_petting() -> void:
	emote(&"heart")
	express(&"happy", 1.4)


## Valor de un parámetro animado por los clips (`param:nombre`).
func param(param_name: StringName) -> float:
	return _params.get(param_name, 0.0)


func get_bone(bone_name: StringName) -> PuppetBone:
	return _bones.get(bone_name)


## Deja quietos los resortes (después de mover al personaje de golpe).
func settle() -> void:
	for spring in _springs:
		spring.settle()


## Altura total sobre el suelo, con lo que suman los clips.
func height() -> float:
	return lift + _b_lift


## Recalcula la pose una vez (también con `lively` apagado).
func refresh() -> void:
	if _started:
		_step(0.0)


# --- Cada cuadro -------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _started:
		_step(minf(delta, 0.05))


func _step(delta: float) -> void:
	_time += delta * tempo
	for item in _bone_list:
		item.reset()
	_b_lift = 0.0
	_b_lean = 0.0
	_b_spin = 0.0
	_b_squash = Vector2.ONE
	_b_shift = Vector2.ZERO
	_b_look = Vector2.ZERO
	for key: StringName in _params:
		_params[key] = 0.0
	_pose_sways()
	_pose_cycles(delta)
	_animate(delta)
	var clip_face := _pose_clips(delta)
	if face:
		face.update(delta, clip_face)
	_pose_look(delta)
	_update_jelly(delta)
	_apply_body()
	for item in _bone_list:
		item.apply()
	_pose_springs(delta)
	_after_pose(delta)
	_update_fidgets(delta)
	_pet_wait = maxf(0.0, _pet_wait - delta)
	var total := height()
	if absf(total - _drawn_height) > 0.5:
		_drawn_height = total
		queue_redraw()


func _pose_sways() -> void:
	if energy <= 0.0:
		return
	for entry: Array in _sways:
		var item: PuppetBone = entry[0]
		var value: float = entry[2] * energy * sin(_time * entry[3] + entry[4])
		match entry[1]:
			"rot":
				item.rotation += value
			"x":
				item.position.x += value
			"y":
				item.position.y += value
			"sx":
				item.scale.x += value
			"sy":
				item.scale.y += value


func _pose_cycles(delta: float) -> void:
	var moving := Vector2.ZERO
	for cycle: Dictionary in _cycles.values():
		var speed: float = cycle["speed"]
		var active := speed > 0.05
		cycle["weight"] = move_toward(cycle["weight"], 1.0 if active else 0.0, delta * 7.0)
		var weight: float = cycle["weight"]
		if weight <= 0.001:
			continue
		var rate: Vector2 = cycle["rate"]
		var gain: Vector2 = cycle["gain"]
		var before: float = cycle["phase"]
		cycle["phase"] += delta * TAU / float(cycle["stride"]) * clampf(speed, rate.x, rate.y)
		var phase: float = cycle["phase"]
		# Cada medio ciclo un pie toca el suelo.
		if grounded and weight > 0.6 and floorf(phase / PI) != floorf(before / PI) and height() < 14.0:
			_on_cue(&"step")
		var strength := weight * clampf(speed, gain.x, gain.y)
		moving.x += float(cycle["travel"]) * speed * weight * facing * absf(scale.x)
		for track: Dictionary in cycle["tracks"]:
			var angle: float = phase * track["mul"] + track["offset"]
			var wave := sin(angle)
			match track["shape"]:
				&"cos":
					wave = cos(angle)
				&"abs":
					wave = absf(wave)
				&"half":
					wave = maxf(0.0, wave)
			var value: float = (track["bias"] + track["amp"] * wave) * strength
			var item: PuppetBone = track["bone"]
			match track["channel"]:
				"rot":
					item.rotation += value
				"x":
					item.position.x += value
				"y":
					item.position.y += value
				"sx":
					item.scale.x += value
				"sy":
					item.scale.y += value
				"lift":
					_b_lift += value
				"lean":
					_b_lean += value
				"squash_x":
					_b_squash.x += value
				"squash_y":
					_b_squash.y += value
				"shift_x":
					_b_shift.x += value
				"shift_y":
					_b_shift.y += value
	_cycle_travel = moving


## Suma los clips que suenan. Devuelve la expresión que pide el clip más reciente.
func _pose_clips(delta: float) -> StringName:
	var clip_face: StringName = &""
	if _playing.is_empty():
		return clip_face
	var fired: Array = []
	for playback in _playing:
		fired.append_array(playback.advance(delta))
	# Los clips apagan primero lo que venía de la respiración y la carrera en sus huesos.
	for playback in _playing:
		if playback.done:
			continue
		for muted in playback.clip.mute:
			var keep := 1.0 - clampf(playback.weight, 0.0, 1.0)
			if muted == &"body":
				_b_lift *= keep
				_b_lean *= keep
				_b_shift *= keep
				_b_squash = Vector2.ONE.lerp(_b_squash, keep)
			elif _bones.has(muted):
				(_bones[muted] as PuppetBone).damp(keep)
	for playback in _playing:
		if playback.done:
			continue
		var weight := playback.weight * playback.amount
		if playback.face != &"":
			clip_face = playback.face
		for track in playback.clip.tracks:
			var value: Variant = track.sample(playback.time)
			match track.channel:
				PuppetClip.Channel.LIFT:
					_b_lift += value * weight
				PuppetClip.Channel.LEAN:
					_b_lean += value * weight
				PuppetClip.Channel.SPIN:
					_b_spin += value * weight
				PuppetClip.Channel.SQUASH:
					_b_squash *= Vector2.ONE.lerp(value, weight)
				PuppetClip.Channel.SHIFT:
					_b_shift += value * weight
				PuppetClip.Channel.LOOK:
					_b_look += value * weight
				PuppetClip.Channel.PARAM:
					_params[track.target] = _params.get(track.target, 0.0) + value * weight
				_:
					var item: PuppetBone = _bones.get(track.target)
					if item == null:
						continue
					match track.channel:
						PuppetClip.Channel.ROT:
							item.rotation += value * weight
						PuppetClip.Channel.POS:
							item.position += value * weight
						PuppetClip.Channel.X:
							item.position.x += value * weight
						PuppetClip.Channel.Y:
							item.position.y += value * weight
						PuppetClip.Channel.SCALE:
							item.scale *= Vector2.ONE.lerp(value, weight)
						PuppetClip.Channel.SX:
							item.scale.x *= lerpf(1.0, value, weight)
						PuppetClip.Channel.SY:
							item.scale.y *= lerpf(1.0, value, weight)
	_playing = _playing.filter(func(playback: PuppetPlayback) -> bool: return not playback.done)
	for event: Array in fired:
		if event[0] == "emote":
			emote(StringName(event[1]))
		else:
			_on_cue(StringName(event[1]))
	return clip_face


func _pose_look(delta: float) -> void:
	if _look_left != INF:
		_look_left -= delta
		if _look_left <= 0.0 and _look_mode != 0:
			_look_mode = 0
	_attention_left = maxf(0.0, _attention_left - delta)
	var goal := Vector2.ZERO
	if _look_mode == 1:
		goal = _gaze_to(to_local(_look_point))
	elif _look_mode == 2:
		goal = _look_point
	elif curious and _attention_left > 0.0:
		goal = _gaze_to(_attention)
	else:
		# Sin nada que mirar, echa vistazos al azar de vez en cuando.
		if _glance_left > 0.0:
			_glance_left -= delta
			goal = _glance
		else:
			_glance_wait -= delta
			if _glance_wait <= 0.0 and energy > 0.0:
				_glance_wait = randf_range(2.5, 6.5)
				_glance_left = randf_range(0.6, 1.5)
				_glance = Vector2(randf_range(-0.8, 0.8), randf_range(-0.35, 0.25))
	_look_goal = goal
	_look = _look.lerp(goal, minf(1.0, delta * 9.0)) if delta > 0.0 else goal
	var gaze := (_look + _b_look).limit_length(1.3)
	if gaze.length_squared() < 0.00001:
		return
	# Con el rig volteado, la derecha de la pantalla es su izquierda.
	var local := Vector2(gaze.x * facing, gaze.y)
	for layer: Array in _look_layers:
		var item: PuppetBone = layer[0]
		var depth: Vector2 = layer[1]
		item.position += Vector2(local.x * look_range.x * depth.x, local.y * look_range.y * depth.y)
	var head: PuppetBone = _bones.get(&"head")
	if head:
		head.rotation += local.x * look_turn + local.y * look_nod


## Dirección de la mirada (de -1 a 1 en cada eje) hacia un punto del espacio del títere.
func _gaze_to(local_point: Vector2) -> Vector2:
	var origin := body_center + Vector2(0.0, body_center.y * 0.5)
	return ((local_point - origin) / look_reach).limit_length(1.0)


## Gelatina del cuerpo: al caer se aplasta y rebota sola.
func _update_jelly(delta: float) -> void:
	if delta <= 0.0:
		return
	var total := height()
	var speed := (total - _last_height) / delta
	if grounded and _last_height > 1.0 and total <= 1.0 and _height_speed < -60.0:
		_jelly_speed += minf(-_height_speed * 0.0036, 3.2)
		_on_cue(&"land")
	_height_speed = speed
	_last_height = total
	_jelly_speed += (-_jelly * 300.0 - _jelly_speed * 15.0) * delta
	_jelly = clampf(_jelly + _jelly_speed * delta, -0.3, 0.3)


func _apply_body() -> void:
	var size := squash * _b_squash * Vector2(1.0 + _jelly * 0.55, 1.0 - _jelly)
	_pose.scale = Vector2(size.x * facing, size.y)
	var tilt := (lean + _b_lean) * facing
	var turn := (spin + _b_spin) * facing
	_pose.rotation = tilt + turn
	var feet := Vector2(shift.x + _b_shift.x * facing, shift.y + _b_shift.y - height())
	_pose.position = feet + body_center - body_center.rotated(turn)


func _pose_springs(delta: float) -> void:
	if _springs.is_empty() and _strips.is_empty():
		return
	var wind := -(travel + _cycle_travel)
	var angles := {}
	if delta > 0.0:
		for spring in _springs:
			var item: PuppetBone = _bones[spring.bone]
			var parent := item.node.get_parent() as Node2D
			if parent == null:
				continue
			var space := transform * parent.get_relative_transform_to_parent(self) * item.node.transform
			var angle := spring.step(space * spring.origin, space * (spring.origin + spring.axis * spring.length), wind,
				space.determinant() < 0.0, delta)
			if _strips.has(spring.bone):
				angles[spring.bone] = angle
			else:
				item.node.rotation += angle
	for strip_name: StringName in _strips:
		var entry: Dictionary = _strips[strip_name]
		var curl: float = entry["bend"] + float(angles.get(strip_name, 0.0)) * entry["curl"]
		(entry["strip"] as BendStrip).wave(curl, entry["wave"] * energy, _time * entry["speed"], entry["wavelength"])


func _update_fidgets(delta: float) -> void:
	if fidgets.is_empty() or delta <= 0.0:
		return
	if not _playing.is_empty() or _cycle_travel != Vector2.ZERO or height() > 1.0:
		return
	_fidget_in -= delta
	if _fidget_in <= 0.0:
		play(fidgets[randi() % fidgets.size()])


func _draw() -> void:
	if shadow_scale <= 0.0:
		return
	var shrink := 1.0 - clampf(height() / (shadow_radius * 3.2), 0.0, 0.65)
	var radius := Vector2(shadow_radius, shadow_radius * shadow_flat) * shadow_scale * shrink
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, Color(SHADOW_COLOR, SHADOW_COLOR.a * shrink))


# --- Dedo --------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not lively or not is_visible_in_tree():
		return
	var pressed := false
	var released := false
	var moved := false
	if event is InputEventScreenTouch:
		pressed = event.pressed
		released = not event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		released = not event.pressed
	elif event is InputEventScreenDrag:
		moved = true
	elif event is InputEventMouseMotion:
		moved = event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0
	if not (pressed or released or moved):
		return
	var local: Vector2 = make_input_local(event).position
	if curious and not released:
		if _attention_left <= 0.0 and face:
			face.blink()
		_attention = local
		_attention_left = 2.4
	if not interactive:
		return
	if pressed:
		if hit_rect.has_point(local) and not _covered_at(event.position):
			_press_at = local
			_press_ms = Time.get_ticks_msec()
			_stroke = 0.0
			get_viewport().set_input_as_handled()
	elif moved and _press_at != Vector2.INF and hit_rect.has_point(local):
		_stroke += (event.relative as Vector2).length()
		if _stroke > 260.0 and _pet_wait <= 0.0:
			_stroke = 0.0
			_pet_wait = 1.6
			react_to_petting()
			petted.emit()
	elif released and _press_at != Vector2.INF:
		var quick := Time.get_ticks_msec() - _press_ms < 600 and _press_at.distance_to(local) < 40.0
		_press_at = Vector2.INF
		get_viewport().set_input_as_handled()
		# En Android el mismo toque llega también como clic: cuenta una sola vez.
		if quick and _pet_wait < 1.2 and Time.get_ticks_msec() - _tap_ms > 220:
			_tap_ms = Time.get_ticks_msec()
			react_to_tap()
			tapped.emit()


## ¿Hay un control (botón, tarjeta, diálogo) dibujado encima del personaje en ese punto? Se
## revisa todo lo que viene después en el árbol: lo que se dibuja más arriba.
func _covered_at(screen_point: Vector2) -> bool:
	var node: Node = self
	while node and node != get_viewport():
		var parent := node.get_parent()
		if parent == null:
			break
		for index in range(node.get_index() + 1, parent.get_child_count()):
			if _blocks(parent.get_child(index), screen_point):
				return true
		node = parent
	return false


func _blocks(node: Node, screen_point: Vector2) -> bool:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return false
	if node is Control:
		var control := node as Control
		if control.mouse_filter != Control.MOUSE_FILTER_IGNORE and control.get_global_rect().has_point(screen_point):
			return true
	for child in node.get_children():
		if _blocks(child, screen_point):
			return true
	return false
