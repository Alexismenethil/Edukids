class_name SpeechBubble
extends Control
## Globo de diálogo de los guías. El origen del nodo es la punta de la colita:
## el globo crece hacia arriba y a la izquierda desde ahí.
## Escribe el texto letra por letra; un toque completa la línea y otro avanza.

signal line_started(index: int, line: DialogueLineViewModel)
signal line_shown(index: int)
signal finished

const CHARS_PER_SECOND := 36.0
const FILL := Color("#FFF8EC")
const OUTLINE := Color("#5A2E16")

## Con true, el globo crece hacia la derecha de la punta (guía a la izquierda de la pantalla).
@export var flipped := false
## Con true, el globo queda arriba de la punta (sobre la cabeza de quien habla) y la colita baja
## hacia ella; así no tapa a los personajes de al lado.
@export var above := false

@onready var _panel: PanelContainer = $Panel
@onready var _text: Label = $Panel/Box/Text
@onready var _next: Button = $Panel/Box/Footer/NextButton
@onready var _skip: Button = $Panel/Box/Footer/SkipButton
@onready var _name_tag: PanelContainer = $NameTag
@onready var _name: Label = $NameTag/NameLabel

var _dialogue: DialogueViewModel
var _index := -1
var _typing: Tween
var _tail_a := Vector2.ZERO
var _tail_b := Vector2.ZERO


func _ready() -> void:
	visible = false
	_next.pressed.connect(advance)
	_skip.pressed.connect(close)
	_panel.gui_input.connect(_on_panel_input)
	_panel.resized.connect(_layout)


func is_open() -> bool:
	return visible and _dialogue != null


func play(dialogue: DialogueViewModel) -> void:
	_dialogue = dialogue
	_skip.text = dialogue.skip_label
	_skip.visible = not dialogue.skip_label.is_empty()
	visible = true
	scale = Vector2(0.3, 0.3)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_show_line(0)


## Completa la línea que se está escribiendo o pasa a la siguiente.
func advance() -> void:
	if _dialogue == null:
		return
	if _typing and _typing.is_running():
		_typing.kill()
		_text.visible_ratio = 1.0
		line_shown.emit(_index)
		return
	if _index + 1 < _dialogue.lines.size():
		_show_line(_index + 1)
	else:
		close()


func close() -> void:
	if _dialogue == null:
		return
	_dialogue = null
	if _typing:
		_typing.kill()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(func() -> void:
		visible = false
		finished.emit())


func _show_line(index: int) -> void:
	_index = index
	var line := _dialogue.lines[index]
	var is_last := index == _dialogue.lines.size() - 1
	_name.text = line.speaker_name
	_text.text = line.text
	_text.visible_characters = 0
	_next.text = _dialogue.close_label if is_last else _dialogue.next_label
	_layout.call_deferred()
	line_started.emit(index, line)
	_typing = create_tween()
	_typing.tween_method(_reveal, 0, line.text.length(), maxf(0.4, line.text.length() / CHARS_PER_SECOND))
	_typing.tween_callback(func() -> void: line_shown.emit(index))
	if index > 0:
		var bounce := create_tween()
		bounce.tween_property(_panel, "scale", Vector2(1.03, 0.97), 0.08)
		bounce.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Muestra las letras hasta la posición indicada.
func _reveal(count: int) -> void:
	_text.visible_characters = count


## El panel queda a la izquierda de la punta y la colita sale de su borde derecho
## (o al revés, si `flipped`).
func _layout() -> void:
	var size_now := _panel.get_combined_minimum_size()
	_panel.size = size_now
	if above:
		var left := -74.0 if flipped else -size_now.x + 74.0
		_panel.position = Vector2(left, -size_now.y - 34.0)
		_panel.pivot_offset = Vector2(-left, size_now.y + 34.0)
		_name_tag.position = _panel.position + Vector2(28.0, -24.0)
		_tail_a = Vector2(-18.0, -39.0)
		_tail_b = Vector2(20.0, -39.0)
		return
	if flipped:
		_panel.position = Vector2(46.0, -size_now.y * 0.6)
		_panel.pivot_offset = Vector2(0.0, size_now.y * 0.6)
	else:
		_panel.position = Vector2(-size_now.x - 46.0, -size_now.y * 0.6)
		_panel.pivot_offset = Vector2(size_now.x, size_now.y * 0.6)
	_name_tag.position = _panel.position + Vector2(28.0, -24.0)
	var edge := _panel.position.x + 5.0 if flipped else _panel.position.x + size_now.x - 5.0
	_tail_a = Vector2(edge, -34.0)
	_tail_b = Vector2(edge, 6.0)


func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		accept_event()


## La colita se dibuja encima del panel para tapar su borde.
func draw_tail(canvas: CanvasItem) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([_tail_a, _tail_b, Vector2.ZERO]), FILL)
	canvas.draw_line(_tail_a, Vector2.ZERO, OUTLINE, 5.0, true)
	canvas.draw_line(_tail_b, Vector2.ZERO, OUTLINE, 5.0, true)
