class_name Sounds
extends RefCounted
## Efectos de sonido del juego, por nombre: `Sounds.play(&"correct")`. Son sonidos cortos y suaves,
## afinados con la música (ver tools/audio/make_sfx.py). Suenan en el bus SFX, así respetan el
## botón de sonido. Un mismo efecto no se repite más de una vez cada 60 ms, para que varias
## ráfagas a la vez no lo amontonen.
##
## Interfaz: tap, check, card, hint, pop, title.
## Respuestas: correct, wrong, streak, life, win, lose.
## Acción: hop, whoosh, land, impact, splash, chomp, plank, star, sparkle.

const FOLDER := "res://assets/audio/sfx/sfx_%s.wav"
const VOICES := 8
const NAMES: Array[StringName] = [&"tap", &"check", &"card", &"hint", &"pop", &"title", &"correct", &"wrong", &"streak",
	&"life", &"win", &"lose", &"hop", &"whoosh", &"land", &"impact", &"splash", &"chomp", &"plank", &"star", &"sparkle"]

static var _players: Array[AudioStreamPlayer] = []
static var _streams: Dictionary = {}
static var _last: Dictionary = {}
static var _next := 0


static func play(sound: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(sound, -1000)) < 60:
		return
	var stream := _stream(sound)
	if stream == null:
		return
	_last[sound] = now
	if _players.is_empty() or not is_instance_valid(_players[0]):
		_players.clear()
		var bank := Node.new()
		bank.name = "SoundBank"
		tree.root.add_child.call_deferred(bank)
		for i in VOICES:
			var voice := AudioStreamPlayer.new()
			voice.bus = &"SFX"
			bank.add_child(voice)
			_players.append(voice)
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	if player.is_inside_tree():
		player.play()
	else:
		player.play.call_deferred()


static func has(sound: StringName) -> bool:
	return _stream(sound) != null


static func _stream(sound: StringName) -> AudioStream:
	if _streams.has(sound):
		return _streams[sound]
	var path := FOLDER % sound
	var stream: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_streams[sound] = stream
	return stream
