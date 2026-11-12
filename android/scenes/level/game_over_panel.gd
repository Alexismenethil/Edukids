class_name GameOverPanel
extends Control
## Game over (RN-14): Atoq (o Coco) se queda con los nudos entre risas, sin regañar.
## Un mensaje de ánimo y dos botones: «Reintentar» y «Volver a la parada».

signal replay_requested
signal continue_requested

var _result: LevelResultViewModel
var _card: PanelContainer
var _character: Node2D


func _init(result: LevelResultViewModel = null) -> void:
	_result = result


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.color = Color(0.16, 0.13, 0.12, 0.5)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	_card = PanelContainer.new()
	_card.theme_type_variation = &"CardPanel"
	add_child(_card)
	var row := Ui.hbox(28)
	_card.add_child(row)
	var stage := _CharacterDisc.new()
	stage.custom_minimum_size = Vector2(300, 300)
	stage.caiman = _result.mechanic == &"caiman"
	row.add_child(stage)
	var column := Ui.vbox(14)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.custom_minimum_size.x = 440
	row.add_child(column)
	var heading := Ui.label(_result.heading, &"TitleLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 440)
	heading.add_theme_font_size_override("font_size", 38)
	column.add_child(heading)
	column.add_child(ActivityStyle.label(_result.game_over_message, 24, ActivityStyle.INK, true, 440))
	for line in _result.lines:
		column.add_child(ActivityStyle.label(line, 22, ActivityStyle.MUTED, true, 440))
	if not _result.warning.is_empty():
		column.add_child(Ui.label(_result.warning, &"ErrorLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 440))
	var replay := Ui.button(_result.replay_label, "replay")
	replay.pressed.connect(func() -> void: replay_requested.emit())
	var back := Ui.button(_result.continue_label, "back", &"SoftButton")
	back.pressed.connect(func() -> void: continue_requested.emit())
	column.add_child(Ui.spacer())
	column.add_child(Ui.hbox(16, [replay, back]))
	_layout.call_deferred()
	resized.connect(_layout)
	Ui.pop_in(_card, 0.05)


func _layout() -> void:
	_card.reset_size()
	var card_size := _card.get_combined_minimum_size()
	_card.size = card_size
	_card.position = (size - card_size) * 0.5
	_card.pivot_offset = card_size * 0.5


func press_replay() -> void:
	replay_requested.emit()


func press_continue() -> void:
	continue_requested.emit()


## Un círculo de cielo con el personaje que se quedó con los nudos.
class _CharacterDisc:
	extends Control
	var caiman := false
	var _time := 0.0
	var _character: Node2D

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if caiman:
			var coco := CaimanCharacter.new()
			coco.scale = Vector2.ONE * 0.62
			coco.position = Vector2(170, 205)
			_character = coco
			add_child(coco)
			coco.set_mood(&"happy")
		else:
			var atoq := AtoqCharacter.new()
			atoq.scale = Vector2.ONE * 0.78
			atoq.position = Vector2(132, 246)
			atoq.shadow_scale = 0.8
			_character = atoq
			add_child(atoq)
			atoq.laugh(999.0)

	func _process(delta: float) -> void:
		_time += delta
		if caiman and _character and fmod(_time, 1.8) < delta:
			(_character as CaimanCharacter).chomp(0.9)
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		draw_circle(center, 148.0, Color("#5A2E16"))
		draw_circle(center, 143.0, Color("#BDE6F5"))
		# Suelo (o río) recortado dentro del círculo: la parte de abajo, desde una cuerda.
		var ground := PackedVector2Array()
		var start := asin(40.0 / 143.0)
		for i in 33:
			var angle := start + (PI - 2.0 * start) * i / 32.0
			ground.append(center + Vector2.from_angle(angle) * 143.0)
		draw_colored_polygon(ground, Color("#93B04B") if not caiman else Color("#4C9CBF"))
		for i in 6:
			var angle := _time * 0.8 + TAU * i / 6.0
			var at := center + Vector2(cos(angle) * 112.0, sin(angle) * 40.0 - 96.0)
			draw_circle(at, 10.0, StageFx.KNOT_COLORS[i % StageFx.KNOT_COLORS.size()])
			draw_arc(at, 5.0, -0.6, 2.4, 8, Color(1, 1, 1, 0.6), 2.0, true)
