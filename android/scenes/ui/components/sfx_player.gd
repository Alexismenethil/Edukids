class_name SfxPlayer
extends Node
## Reproduce efectos cortos en el bus SFX, con varias voces para que no se corten entre sí.

@export var voices := 6

var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in voices:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_players.append(player)


func _exit_tree() -> void:
	for player in _players:
		player.stop()


func play(stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null or _players.is_empty():
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()
