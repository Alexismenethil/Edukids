class_name TitleScreen
extends Control
## Pantalla de inicio (vista humilde): pinta la mañana en el valle de Huamanga (cordilleras
## nevadas, andenes, chacras de colores, el pueblito con su iglesia y el camino que nace en el botón
## Jugar), con llamas y ovejas que pastan, anima la entrada, reproduce los sonidos de Quwi y el quipu
## y reenvía los toques a su presentador.

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
const VALLEY := "res://assets/art/worlds/valley/"
const COVER := "res://assets/art/worlds/cover/"
const HUMMINGBIRD := preload("res://scenes/characters/hummingbird/hummingbird.tscn")
## Cómo se encuadra el paisaje dentro de World (1920 × 960, pegado abajo): las capas de la portada
## están dibujadas en unidades de pantalla de 1280 × 800, así que el punto (640, 752) queda en
## SCREEN_FOCUS (en una pantalla de 1280 × 800, el mundo coincide con la pantalla).
const FOCUS := Vector2(640.0, 752.0)
const SCREEN_FOCUS := Vector2(960.0, 912.0)
## Capas lejanas de la portada (tools/art/worlds/cover.py): nombre, profundidad, borde de arriba y
## escala de importación.
const LAYERS := [["horizon", 0.04, 190.0, 1.0], ["hills", 0.12, 400.0, 1.0], ["village", 0.3, 470.0, 1.25]]
## Chimeneas del pueblito (las imprime cover.py): de ahí sale el humo.
const CHIMNEYS: Array[Vector2] = [Vector2(366.6, 575.8), Vector2(447.9, 554.1), Vector2(491.5, 571.8),
	Vector2(795.7, 573.0), Vector2(839.5, 556.3)]
## Mata de cantuta del picaflor (a la izquierda, entre Mama Sisa y el botón Jugar).
const CANTUTA_AT := Vector2(330.0, 776.0)
const CANTUTA_SCALE := 0.8
## Bocas de las campanas de la cantuta, en unidades del SVG (las imprime tools/art/worlds/valley.py).
const CANTUTA_MOUTHS: Array[Vector2] = [Vector2(23.3, 150.5), Vector2(49.2, 124.6), Vector2(87.2, 105.5),
	Vector2(131.6, 107.7), Vector2(168.2, 120.4), Vector2(196.3, 146.7), Vector2(106.9, 135.6)]
const CANTUTA_SIZE := Vector2(220.0, 196.0)
## Dónde se detiene Mama Sisa: a la izquierda de la cantuta, sin taparla.
const SISA_STOP := 140.0
## Llamas (x, y, escala, color, mira, cría) y ovejas (x, y, mira) de la pradera.
const LLAMAS := [[404.0, 650.0, 0.44, Color("#FFF7EA"), 1, false], [352.0, 652.0, 0.27, Color("#E3B07A"), 1, true]]
const SHEEP := [[838.0, 652.0, -1], [876.0, 646.0, 1], [910.0, 655.0, -1]]

@onready var _halo: Control = $Halo
@onready var _glow: Sprite2D = $Halo/SunGlow
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
var _world: ParallaxWorld
var _actors: Node2D
var _herd: Node2D
var _sky_plane: Node2D
var _hummingbird: Hummingbird
var _sisa_watching := false
var _sisa: Puppet
var _kuntur: CondorCharacter
var _atoq: AtoqCharacter
var _gag_wait := 14.0
var _sparkle_wait := 5.0
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
	$Credits.get_label().add_theme_color_override("font_color", Color.WHITE)
	_bubble.line_started.connect(_on_line_started)
	_bubble.line_shown.connect(_on_line_shown)
	_bubble.finished.connect(_on_dialogue_finished)
	_toast.modulate.a = 0.0
	_shine.shader = SHINE_SHADER
	_build_valley()
	for i in _letters.get_child_count():
		var letter := _letters.get_child(i) as Node2D
		letter.rotation = LETTER_TILTS[i % LETTER_TILTS.size()]
		letter.material = _shine
		_letter_base.append(letter.position)
	_bring_cast()
	_play_intro()


func _process(delta: float) -> void:
	_time += delta
	# La cámara respira despacio: cada capa del valle se mueve a su ritmo (paralaje).
	_world.cam_x = 22.0 * sin(_time * 0.16)
	_glow.scale = Vector2.ONE * (3.4 + 0.12 * sin(_time * 0.9))
	if not _letters_alive:
		return
	_update_cover_life(delta)
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
	_world.screen_focus = SCREEN_FOCUS + Vector2(0.0, 130.0)
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
	# La cámara empieza cerca del valle y se abre mientras cae el título.
	var world: Control = $World
	world.pivot_offset = Vector2(960.0, 760.0)
	world.scale = Vector2(1.12, 1.12)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(world, "scale", Vector2.ONE, 2.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Sounds.play.bind(&"title", 1.0, -4.0)).set_delay(0.35)
	tween.tween_callback(Sounds.play.bind(&"card", 1.0, -7.0)).set_delay(1.15)
	tween.tween_callback(Sounds.play.bind(&"sparkle", 1.0, -9.0)).set_delay(1.5)
	tween.tween_callback(Sounds.play.bind(&"pop", 0.85, -5.0)).set_delay(2.6)
	tween.tween_callback(_kuntur_pass.bind(true)).set_delay(0.3)
	tween.tween_callback(_sisa_enters).set_delay(1.7)
	tween.tween_callback(_logo_flourish).set_delay(2.9)
	tween.tween_property(_world, "screen_focus", SCREEN_FOCUS, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_halo, "modulate:a", 1.0, 1.4).set_delay(0.2)
	for i in _letters.get_child_count():
		var letter := _letters.get_child(i) as Node2D
		var delay := 0.5 + i * 0.08
		tween.tween_property(letter, "position:y", _letter_base[i].y, 0.6).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_callback(_letter_lands.bind(letter, i)).set_delay(delay + 0.4)
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


# --- Portada viva ------------------------------------------------------------------------------

## El valle de Huamanga en la mañana, de lo lejano a lo cercano: nubes y bandadas, dos cordilleras
## nevadas, Kuntur a lo lejos, lomas con andenes y chacras, el pueblito con su iglesia y el humo de
## las chimeneas, neblina, la pradera con el camino y las pircas, llamas y ovejas, los personajes y
## el pasto del primer plano que se mece. La luz del sol y sus rayos quedan detrás del logo (Halo).
func _build_valley() -> void:
	var holder: Control = $World
	_world = ParallaxWorld.new()
	_world.name = "Cover"
	_world.view_size = Vector2(1920.0, 960.0)
	_world.focus = FOCUS
	_world.screen_focus = SCREEN_FOCUS
	holder.add_child(_world)
	holder.move_child(_world, 0)
	var clouds: Array[Texture2D] = []
	for i in 4:
		clouds.append(load(VALLEY + "cloud_%d.svg" % i))
	_world.add_clouds(clouds, [
		{"x": 40.0, "y": 236.0, "texture": 0, "speed": 6.0, "scale": 0.75, "depth": 0.03},
		{"x": 760.0, "y": 180.0, "texture": 1, "speed": 9.0, "scale": 0.7, "depth": 0.03},
		{"x": 1420.0, "y": 262.0, "texture": 2, "speed": 5.0, "scale": 0.8, "depth": 0.03},
		{"x": 2100.0, "y": 206.0, "texture": 3, "speed": 11.0, "scale": 0.75, "depth": 0.03},
		{"x": 2700.0, "y": 300.0, "texture": 1, "speed": 7.0, "scale": 0.55, "alpha": 0.9, "depth": 0.03},
	])
	var birds := BirdFlock.new()
	birds.world = _world
	_world.add_child(birds)
	for layer: Array in LAYERS:
		_world.add_layer(load(COVER + "cover_%s.svg" % layer[0]), layer[1], layer[2], layer[3], false, -400.0)
		if layer[0] == "horizon":
			_sky_plane = _world.add_plane(0.08)
	var smoke := _world.add_plane(0.3)
	for chimney in CHIMNEYS:
		var puff := ChimneySmoke.new()
		puff.position = chimney
		smoke.add_child(puff)
	_world.add_fog(592.0, 648.0, 0.4, Color(1.0, 0.97, 0.9, 0.2))
	_world.add_layer(load(COVER + "cover_land.svg"), 0.8, 380.0, 1.25, false, -400.0)
	_herd = _world.add_plane(0.8)
	_actors = _world.add_plane(0.8)
	var front := _world.add_layer(load(COVER + "cover_front.svg"), 1.1, 700.0, 1.5, false, -400.0)
	_world.sway(front, 5.0, 1.4)
	_world.add_child(AmbientField.new().setup(_world, AmbientField.Kind.MOTES, 26, 0.9, Vector2(320.0, 780.0)))
	_world.add_child(AmbientField.new().setup(_world, AmbientField.Kind.PETALS, 7, 1.0, Vector2(300.0, 800.0),
		PackedColorArray([Color("#FF8FB3"), Color("#FFD23F"), Color("#FFFFFF")])))
	_world.add_child(AmbientField.new().setup(_world, AmbientField.Kind.BUTTERFLIES, 4, 0.8, Vector2(560.0, 760.0),
		PackedColorArray([Color("#FF8A3C"), Color("#FFD23F"), Color("#B58CFF")])))
	_bring_herd()
	_world.refresh()


## Llamas (una mamá con su manta tejida y su cría que la sigue) y ovejitas que pastan en la pradera.
func _bring_herd() -> void:
	var mother: GrazingAnimal
	for spec: Array in LLAMAS:
		var llama := GrazingAnimal.new()
		llama.kind = GrazingAnimal.Kind.LLAMA
		llama.position = Vector2(spec[0], spec[1])
		llama.scale = Vector2.ONE * float(spec[2])
		llama.fleece = spec[3]
		llama.facing = spec[4]
		llama.young = spec[5]
		llama.roam = 20.0
		if llama.young:
			llama.follow = mother
		_herd.add_child(llama)
		if llama.young:
			llama.get_node("LlamaRig/Body/Blanket").visible = false
		else:
			mother = llama
	for spec: Array in SHEEP:
		var sheep := GrazingAnimal.new()
		sheep.kind = GrazingAnimal.Kind.SHEEP
		sheep.position = Vector2(spec[0], spec[1])
		sheep.scale = Vector2.ONE * 0.34
		sheep.facing = spec[2]
		sheep.roam = 26.0
		_herd.add_child(sheep)


## La mata de cantuta del picaflor: queda sola, entre Mama Sisa y el botón Jugar, para que nadie
## tape al picaflor mientras toma el néctar.
func _plant_cantuta() -> void:
	var bush := Sprite2D.new()
	bush.name = "Cantuta"
	bush.texture = load(VALLEY + "prop_cantuta.svg")
	bush.centered = false
	bush.offset = -Vector2(CANTUTA_SIZE.x, CANTUTA_SIZE.y * 2.0)
	bush.scale = Vector2.ONE * 0.5 * CANTUTA_SCALE
	bush.position = CANTUTA_AT
	_actors.add_child(bush)
	var flowers: Array[Vector2] = []
	for mouth in CANTUTA_MOUTHS:
		flowers.append(CANTUTA_AT + (mouth - Vector2(CANTUTA_SIZE.x * 0.5, CANTUTA_SIZE.y)) * CANTUTA_SCALE)
	_hummingbird = HUMMINGBIRD.instantiate()
	_hummingbird.flowers = flowers
	_hummingbird.outside = Vector2(-160.0, 480.0)
	_hummingbird.scale = Vector2.ONE * 0.6


## Suma a la portada a Mama Sisa, a Kuntur volando sobre los cerros, a Atoq (que se asoma de vez
## en cuando) y al picaflor de la cantuta. Entran con la animación de inicio y después hacen su vida.
## Todos pisan el plano del camino, así se mueven con él cuando la cámara respira.
func _bring_cast() -> void:
	_kuntur = Cast.create(&"condor") as CondorCharacter
	_kuntur.scale = Vector2.ONE * 0.3
	_kuntur.position = Vector2(1880.0, 160.0)
	_kuntur.curious = false
	_sky_plane.add_child(_kuntur)
	_plant_cantuta()
	_quwi.reparent(_actors, false)
	_quwi.position = Vector2(1016.0, 744.0)
	_sisa = Cast.create(&"sisa")
	_sisa.scale = Vector2.ONE * 0.62
	_sisa.position = Vector2(-170.0, 764.0)
	_sisa.interactive = true
	_actors.add_child(_sisa)
	_actors.move_child(_sisa, _quwi.get_index())
	_atoq = Cast.create(&"atoq") as AtoqCharacter
	_atoq.scale = Vector2.ONE * 0.8
	_atoq.facing = -1
	_atoq.position = Vector2(1460.0, 758.0)
	_atoq.interactive = true
	_actors.add_child(_atoq)
	_actors.move_child(_atoq, _quwi.get_index())
	_actors.add_child(_hummingbird)


## Cada letra cae con un «pop» un poco más agudo que el anterior y rebota al llegar.
func _letter_lands(letter: Node2D, index: int) -> void:
	Sounds.play(&"pop", 0.82 + index * 0.07, -11.0)
	var rest: Vector2 = letter.get_meta(&"rest_scale", letter.scale)
	letter.set_meta(&"rest_scale", rest)
	letter.scale = rest * Vector2(1.14, 0.84)
	letter.create_tween().tween_property(letter, "scale", rest, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Mama Sisa llega caminando desde la izquierda y saluda.
func _sisa_enters() -> void:
	_sisa.set_cycle(&"walk", 1.0)
	var tween := create_tween()
	tween.tween_property(_sisa, "position:x", SISA_STOP, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_sisa.set_cycle(&"walk", 0.0)
		_sisa.play(&"wave"))


## Kuntur cruza el cielo; en la entrada pasa cerca, grande, y después planea a lo lejos.
func _kuntur_pass(close: bool) -> void:
	if _kuntur == null:
		return
	_kuntur.scale = Vector2.ONE * (0.46 if close else 0.24)
	_kuntur.flap = 1.1 if close else 0.5
	_kuntur.position = Vector2(1460.0, 150.0 if close else randf_range(230.0, 330.0))
	_kuntur.look_toward(Vector2(-1.0, 0.2))
	if close:
		Sounds.play(&"whoosh", 0.8, -10.0)
	var tween := create_tween()
	tween.tween_property(_kuntur, "position", Vector2(-200.0, 90.0 if close else _kuntur.position.y - 40.0), 5.0 if close else 16.0)


## Brillos sobre el logo cuando termina la entrada.
func _logo_flourish() -> void:
	var center := _letters.global_position - global_position + Vector2(0.0, 50.0)
	ToonFx.sparkles(self, center, 18, 300.0)
	ToonFx.stars(self, center + Vector2(0.0, 40.0), 8, 14.0)
	_quwi.celebrate()


## Vida de la portada: brillitos en el logo, Kuntur que vuelve a pasar y Atoq que se asoma, se
## burla y sale corriendo.
func _update_cover_life(delta: float) -> void:
	_watch_hummingbird(delta)
	_sparkle_wait -= delta
	if _sparkle_wait <= 0.0:
		_sparkle_wait = randf_range(4.0, 7.0)
		var letter := _letters.get_child(randi() % _letters.get_child_count()) as Node2D
		ToonFx.sparkles(self, letter.global_position - global_position + Vector2(0.0, 20.0), 5, 60.0)
	if _in_dialogue:
		return
	_gag_wait -= delta
	if _gag_wait > 0.0:
		return
	_gag_wait = randf_range(16.0, 24.0)
	if randf() < 0.5:
		_kuntur_pass(false)
		return
	_atoq.facing = -1
	_atoq.speed = 0.9
	var tween := create_tween()
	tween.tween_property(_atoq, "position:x", 1240.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_atoq.speed = 0.0
		_atoq.play(&"sneak")
		_quwi.look_toward(Vector2(1.0, 0.0), 2.4)
		_quwi.emote(&"alert"))
	tween.tween_interval(1.7)
	tween.tween_callback(func() -> void:
		_atoq.laugh(0.9)
		_quwi.set_mood(&"surprise"))
	tween.tween_interval(1.0)
	tween.tween_callback(func() -> void:
		_atoq.facing = 1
		_atoq.speed = 1.8
		_quwi.set_mood(&"joy"))
	tween.tween_property(_atoq, "position:x", 1460.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: _atoq.speed = 0.0)


## Mama Sisa sigue con la mirada al picaflor mientras visita la cantuta.
func _watch_hummingbird(_delta: float) -> void:
	if _sisa == null or _hummingbird == null:
		return
	var near := _hummingbird.visible and _hummingbird.position.x > 200.0
	if near:
		_sisa.look_at_point(_hummingbird.global_position, 0.4)
		if not _sisa_watching:
			_sisa_watching = true
			_sisa.emote(&"heart", 1.2)
	elif _sisa_watching:
		_sisa_watching = false
		_sisa.look_reset()
