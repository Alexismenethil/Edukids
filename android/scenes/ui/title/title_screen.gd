class_name TitleScreen
extends Control
## Pantalla de inicio (vista humilde): pinta el amanecer en la Sierra, anima la entrada
## y reenvía los toques a su presentador. No conoce casos de uso ni datos.

signal play_requested
signal teacher_requested

## Hacia dónde vuelan los nudos del quipu: la Sierra, la Selva y la Costa.
const KNOT_TARGETS: Array[Vector2] = [Vector2(-900.0, 560.0), Vector2(-80.0, 760.0), Vector2(900.0, 520.0)]
const LETTER_TILTS: Array[float] = [-0.06, 0.04, -0.03, 0.05, -0.05, 0.03, -0.04]
const BUBBLE_OFFSET := Vector2(-64.0, -112.0)

@onready var _halo: Control = $Halo
@onready var _glow: Sprite2D = $Halo/SunGlow
@onready var _far: TextureRect = $World/FarLayer
@onready var _mid: TextureRect = $World/MidLayer
@onready var _near: TextureRect = $World/NearLayer
@onready var _quwi: QuwiCharacter = $World/Quwi
@onready var _letters: Node2D = $Logo/LogoWord
@onready var _ribbon: TextureRect = $Logo/Ribbon
@onready var _subtitle: Label = $Logo/Subtitle
@onready var _quipu: QuipuCords = $Logo/Quipu
@onready var _play: Button = $PlayButton
@onready var _teacher: Button = $TeacherButton
@onready var _version: Label = $VersionLabel
@onready var _bubble: SpeechBubble = $SpeechBubble
@onready var _toast: PanelContainer = $Toast
@onready var _toast_label: Label = $Toast/ToastLabel

var _presenter: TitlePresenter
var _time := 0.0
var _letters_alive := false
var _in_dialogue := false
var _pulse: Tween
var _toast_tween: Tween
var _layer_base: Array[Vector2] = []
var _letter_base: Array[Vector2] = []


## El navegador inyecta el presentador antes de mostrar la pantalla.
func setup(presenter: TitlePresenter) -> void:
	_presenter = presenter


func _ready() -> void:
	if _presenter:
		var view_model := _presenter.title()
		_subtitle.text = view_model.subtitle
		_play.text = view_model.play_label
		_teacher.text = view_model.teacher_label
		_version.text = view_model.version_label
	_play.pressed.connect(_on_play_pressed)
	_teacher.pressed.connect(_on_teacher_pressed)
	_bubble.line_started.connect(_on_line_started)
	_bubble.line_shown.connect(_on_line_shown)
	_bubble.finished.connect(_on_dialogue_finished)
	_toast.modulate.a = 0.0
	for layer in [_far, _mid, _near]:
		_layer_base.append(layer.position)
	for i in _letters.get_child_count():
		var letter := _letters.get_child(i) as Node2D
		letter.rotation = LETTER_TILTS[i % LETTER_TILTS.size()]
		_letter_base.append(letter.position)
	_play_intro()


func _process(delta: float) -> void:
	_time += delta
	# Parallax suave: cada capa respira a su ritmo.
	_far.position.x = _layer_base[0].x + 6.0 * sin(_time * 0.17)
	_mid.position.x = _layer_base[1].x + 11.0 * sin(_time * 0.17)
	_near.position.x = _layer_base[2].x + 16.0 * sin(_time * 0.17)
	_glow.scale = Vector2.ONE * (3.4 + 0.12 * sin(_time * 0.9))
	if _letters_alive:
		for i in _letters.get_child_count():
			var letter := _letters.get_child(i) as Node2D
			letter.position.y = _letter_base[i].y + 4.0 * sin(_time * 2.2 + i * 0.65)
			letter.rotation = LETTER_TILTS[i] + 0.02 * sin(_time * 1.6 + i)


func _play_intro() -> void:
	for i in 3:
		var layer: TextureRect = [_far, _mid, _near][i]
		layer.position.y = _layer_base[i].y + [40.0, 80.0, 120.0][i]
	_halo.modulate.a = 0.0
	for letter in _letters.get_children():
		(letter as Node2D).position.y -= 460.0
	_ribbon.pivot_offset = _ribbon.size * 0.5
	_ribbon.scale = Vector2(0.0, 1.0)
	_subtitle.modulate.a = 0.0
	_quipu.reveal = 0.0
	_play.scale = Vector2.ZERO
	_teacher.modulate.a = 0.0
	_version.modulate.a = 0.0
	_quwi.visible = false

	var tween := create_tween().set_parallel(true)
	for i in 3:
		var layer: TextureRect = [_far, _mid, _near][i]
		tween.tween_property(layer, "position:y", _layer_base[i].y, 1.3 + i * 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_halo, "modulate:a", 1.0, 1.4).set_delay(0.2)
	for i in _letters.get_child_count():
		var letter := _letters.get_child(i) as Node2D
		tween.tween_property(letter, "position:y", _letter_base[i].y, 0.6).set_delay(0.5 + i * 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_ribbon, "scale:x", 1.0, 0.5).set_delay(1.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_subtitle, "modulate:a", 1.0, 0.35).set_delay(1.45)
	tween.tween_property(_quipu, "reveal", 1.0, 1.0).set_delay(1.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_quwi_enters).set_delay(1.1)
	tween.tween_property(_play, "scale", Vector2.ONE, 0.55).set_delay(2.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_teacher, "modulate:a", 1.0, 0.4).set_delay(2.8)
	tween.tween_property(_version, "modulate:a", 1.0, 0.4).set_delay(2.8)
	tween.chain().tween_callback(func() -> void:
		_letters_alive = true
		_start_pulse())


func _quwi_enters() -> void:
	_quwi.visible = true
	_quwi.enter_from(460.0)


func _start_pulse() -> void:
	_play.pivot_offset = _play.size * 0.5
	if _pulse:
		_pulse.kill()
	_pulse = create_tween().set_loops()
	_pulse.tween_property(_play, "scale", Vector2(1.05, 1.05), 0.7).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(_play, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)


## Equivale a tocar Jugar (lo usa también el modo demostración).
func press_play() -> void:
	_on_play_pressed()


## Equivale a tocar el globo de diálogo.
func advance_dialogue() -> void:
	_bubble.advance()


func _on_play_pressed() -> void:
	if _in_dialogue or _presenter == null:
		return
	_in_dialogue = true
	if _pulse:
		_pulse.kill()
	_play.pivot_offset = _play.size * 0.5
	var tween := create_tween()
	tween.tween_property(_play, "scale", Vector2(1.15, 0.88), 0.08)
	tween.tween_property(_play, "scale", Vector2.ZERO, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_quwi.hop()
	_bubble.position = _quwi.global_position - global_position + BUBBLE_OFFSET
	_bubble.play(_presenter.prologue_teaser())


func _on_line_started(_index: int, line: DialogueLineViewModel) -> void:
	_quwi.set_mood(line.mood)
	_quwi.talk(true)
	match line.cue:
		&"knots_scatter":
			_quipu.scatter_knots(KNOT_TARGETS)
		&"knots_return":
			_quipu.return_knots()


func _on_line_shown(_index: int) -> void:
	_quwi.talk(false)


func _on_dialogue_finished() -> void:
	_quwi.talk(false)
	_quwi.celebrate()
	if _quipu.has_loose_knots():
		_quipu.return_knots()
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(_play, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_in_dialogue = false
		_start_pulse())
	play_requested.emit()


func _on_teacher_pressed() -> void:
	teacher_requested.emit()
	if _presenter == null:
		return
	_toast_label.text = _presenter.teacher_notice()
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
