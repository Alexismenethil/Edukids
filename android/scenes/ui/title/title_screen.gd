class_name TitleScreen
extends Control
## Pantalla de inicio (vista humilde): pinta el amanecer en la Sierra, anima la entrada,
## reproduce los sonidos de Quwi y el quipu, y reenvía los toques a su presentador.

signal play_requested
signal teacher_requested
signal diagnostics_requested

## Hacia dónde vuelan los nudos del quipu: la Sierra, la Selva y la Costa.
const KNOT_TARGETS: Array[Vector2] = [Vector2(-900.0, 560.0), Vector2(-80.0, 760.0), Vector2(900.0, 520.0)]
const LETTER_TILTS: Array[float] = [-0.06, 0.04, -0.03, 0.05, -0.05, 0.03, -0.04]
const BUBBLE_OFFSET := Vector2(-64.0, -112.0)
const SHINE_EVERY := 6.5
const SHINE_SHADER := preload("res://assets/shaders/logo_shine.gdshader")
const SOUND_ON_ICON := preload("res://assets/art/ui/ui_icon_sound_on.svg")
const SOUND_OFF_ICON := preload("res://assets/art/ui/ui_icon_sound_off.svg")
const RETURN_SOUND := preload("res://assets/audio/sfx/sfx_knots_return.ogg")

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
@onready var _confetti: CPUParticles2D = $Confetti
@onready var _teacher: Button = $TeacherButton
@onready var _sound: Button = $SoundButton
@onready var _version: Label = $VersionLabel
@onready var _bubble: SpeechBubble = $SpeechBubble
@onready var _toast: PanelContainer = $Toast
@onready var _toast_label: Label = $Toast/ToastLabel
@onready var _sfx: SfxPlayer = $Sfx

var _presenter: TitlePresenter
var _time := 0.0
var _letters_alive := false
var _in_dialogue := false
var _pulse: Tween
var _toast_tween: Tween
var _shine := ShaderMaterial.new()
var _shine_wait := 1.2
var _version_taps: Array[int] = []
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
		_show_sound(view_model.sound)
	_play.pressed.connect(_on_play_pressed)
	_teacher.pressed.connect(_on_teacher_pressed)
	_sound.pressed.connect(_on_sound_pressed)
	_version.gui_input.connect(_on_version_input)
	_bubble.line_started.connect(_on_line_started)
	_bubble.line_shown.connect(_on_line_shown)
	_bubble.finished.connect(_on_dialogue_finished)
	_toast.modulate.a = 0.0
	_shine.shader = SHINE_SHADER
	for layer in [_far, _mid, _near]:
		_layer_base.append(layer.position)
	for i in _letters.get_child_count():
		var letter := _letters.get_child(i) as Node2D
		letter.rotation = LETTER_TILTS[i % LETTER_TILTS.size()]
		letter.material = _shine
		_letter_base.append(letter.position)
	_play_intro()


func _process(delta: float) -> void:
	_time += delta
	# Parallax suave: cada capa respira a su ritmo.
	_far.position.x = _layer_base[0].x + 6.0 * sin(_time * 0.17)
	_mid.position.x = _layer_base[1].x + 11.0 * sin(_time * 0.17)
	_near.position.x = _layer_base[2].x + 16.0 * sin(_time * 0.17)
	_glow.scale = Vector2.ONE * (3.4 + 0.12 * sin(_time * 0.9))
	if not _letters_alive:
		return
	for i in _letters.get_child_count():
		var letter := _letters.get_child(i) as Node2D
		letter.position.y = _letter_base[i].y + 4.0 * sin(_time * 2.2 + i * 0.65)
		letter.rotation = LETTER_TILTS[i] + 0.02 * sin(_time * 1.6 + i)
	_shine_wait -= delta
	if _shine_wait <= 0.0:
		_shine_wait = SHINE_EVERY
		_sweep_shine()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _quwi.visible and _quwi.contains_point(event.global_position):
			_on_quwi_tapped()
			accept_event()


## Equivale a tocar Jugar (lo usa también el modo demostración).
func press_play() -> void:
	_on_play_pressed()


## Equivale a tocar el globo de diálogo.
func advance_dialogue() -> void:
	_bubble.advance()


## Equivale a tocar a Quwi.
func tap_quwi() -> void:
	_on_quwi_tapped()


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
	for button: Control in [_teacher, _sound, _version]:
		button.modulate.a = 0.0
	_quwi.visible = false

	var tween := create_tween().set_parallel(true)
	for i in 3:
		var layer: TextureRect = [_far, _mid, _near][i]
		tween.tween_property(layer, "position:y", _layer_base[i].y, 1.3 + i * 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_halo, "modulate:a", 1.0, 1.4).set_delay(0.2)
	for i in _letters.get_child_count():
		var letter := _letters.get_child(i) as Node2D
		var delay := 0.5 + i * 0.08
		tween.tween_property(letter, "position:y", _letter_base[i].y, 0.6).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_ribbon, "scale:x", 1.0, 0.5).set_delay(1.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_subtitle, "modulate:a", 1.0, 0.35).set_delay(1.45)
	tween.tween_property(_quipu, "reveal", 1.0, 1.0).set_delay(1.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_quwi_enters).set_delay(1.1)
	tween.tween_property(_play, "scale", Vector2.ONE, 0.55).set_delay(2.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for button: Control in [_teacher, _sound, _version]:
		tween.tween_property(button, "modulate:a", 1.0, 0.4).set_delay(2.8)
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


## Un destello diagonal recorre las letras de izquierda a derecha.
func _sweep_shine() -> void:
	var first := _letters.get_child(0) as Node2D
	var last := _letters.get_child(_letters.get_child_count() - 1) as Node2D
	var start := first.global_position.x - first.global_position.y * 0.4 - 140.0
	var finish := last.global_position.x - last.global_position.y * 0.4 + 140.0
	var tween := create_tween()
	tween.tween_method(func(x: float) -> void: _shine.set_shader_parameter("shine_x", x), start, finish, 0.9).set_trans(Tween.TRANS_SINE)


func _on_play_pressed() -> void:
	if _in_dialogue or _presenter == null:
		return
	_in_dialogue = true
	if _pulse:
		_pulse.kill()
	_confetti.global_position = _play.global_position + _play.size * 0.5
	_confetti.restart()
	_play.pivot_offset = _play.size * 0.5
	var tween := create_tween()
	tween.tween_property(_play, "scale", Vector2(1.15, 0.88), 0.08)
	tween.tween_property(_play, "scale", Vector2.ZERO, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_quwi.hop()
	# Quwi cuenta su adelanto solo la primera vez; después, Jugar lleva directo a los perfiles.
	if not _presenter.should_tell_teaser():
		var go := create_tween()
		go.tween_interval(0.5)
		go.tween_callback(func() -> void:
			_restore_play()
			play_requested.emit())
		return
	# El confeti y el salto de Quwi se lucen antes de que aparezca el globo.
	var dialogue := _presenter.prologue_teaser()
	var later := create_tween()
	later.tween_interval(0.55)
	later.tween_callback(func() -> void:
		_bubble.position = _quwi.global_position - global_position + BUBBLE_OFFSET
		_bubble.play(dialogue))


func _on_quwi_tapped() -> void:
	if _in_dialogue:
		_quwi.squeak()
		_quwi.hop(22.0)
		return
	_quwi.react_to_tap()
	var later := create_tween()
	later.tween_interval(1.6)
	later.tween_callback(func() -> void:
		if not _in_dialogue:
			_quwi.set_mood(&"joy"))


func _on_line_started(_index: int, line: DialogueLineViewModel) -> void:
	_quwi.set_mood(line.mood)
	_quwi.talk(true)
	match line.cue:
		&"knots_scatter":
			_sfx.play(RETURN_SOUND)
			_quipu.scatter_knots(KNOT_TARGETS)
		&"knots_return":
			_sfx.play(RETURN_SOUND)
			_quipu.return_knots()


func _on_line_shown(_index: int) -> void:
	_quwi.talk(false)


func _on_dialogue_finished() -> void:
	_quwi.talk(false)
	_quwi.celebrate()
	_quwi.squeak()
	if _quipu.has_loose_knots():
		_sfx.play(RETURN_SOUND)
		_quipu.return_knots()
	_presenter.mark_teaser_told()
	var tween := create_tween()
	tween.tween_interval(1.1)
	tween.tween_callback(func() -> void:
		_restore_play()
		play_requested.emit())


## Vuelve a mostrar el botón Jugar (por ejemplo, si la tablet aún no está configurada).
func _restore_play() -> void:
	var tween := create_tween()
	tween.tween_property(_play, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_in_dialogue = false
		_start_pulse())


## La tablet todavía no está configurada: Quwi lo avisa.
func show_not_configured() -> void:
	_quwi.react_to_tap()
	_show_toast(_presenter.not_configured_notice())


func _on_teacher_pressed() -> void:
	teacher_requested.emit()


func _on_sound_pressed() -> void:
	if _presenter == null:
		return
	var sound := _presenter.toggle_sound()
	_show_sound(sound)
	if not sound.notice.is_empty():
		_show_toast(sound.notice)


func _show_sound(sound: SoundToggleViewModel) -> void:
	_sound.text = sound.label
	_sound.icon = SOUND_ON_ICON if sound.sound_on else SOUND_OFF_ICON


## Tres toques seguidos sobre la versión abren el panel de medición.
func _on_version_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var now := Time.get_ticks_msec()
	_version_taps.append(now)
	_version_taps = _version_taps.filter(func(tap: int) -> bool: return now - tap < 1200)
	if _version_taps.size() >= 3:
		_version_taps.clear()
		diagnostics_requested.emit()


func _show_toast(message: String) -> void:
	_toast_label.text = message
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
