class_name Carousel
extends Control
## Fila horizontal que se arrastra con el dedo, con inercia y rebote en los extremos.
## Un toque sin arrastre avisa qué elemento se tocó (los elementos no reciben el toque).

signal item_tapped(index: int)
signal scrolled(at_start: bool, at_end: bool)

const TAP_SLOP := 14.0
const FRICTION := 5.5

var content := HBoxContainer.new()
var separation := 28:
	set(value):
		separation = value
		content.add_theme_constant_override("separation", value)

var _scroll := 0.0
var _velocity := 0.0
var _pressing := false
var _dragged := false
var _press_x := 0.0
var _last_x := 0.0
var _last_time := 0
var _target := NAN


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	content.add_theme_constant_override("separation", separation)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	resized.connect(_layout)
	content.resized.connect(_layout)


func clear() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	_scroll = 0.0
	_velocity = 0.0
	_layout()


func add_item(item: Control) -> void:
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(item)


func items() -> Array[Node]:
	return content.get_children()


func max_scroll() -> float:
	return maxf(content.size.x - size.x, 0.0)


## Avanza o retrocede casi una pantalla.
func page(direction: int) -> void:
	_target = clampf(_scroll + direction * size.x * 0.8, 0.0, max_scroll())
	_velocity = 0.0


func _gui_input(event: InputEvent) -> void:
	var pressed_event := event as InputEventMouseButton
	if pressed_event and pressed_event.button_index == MOUSE_BUTTON_LEFT:
		if pressed_event.pressed:
			_pressing = true
			_dragged = false
			_press_x = pressed_event.position.x
			_last_x = _press_x
			_last_time = Time.get_ticks_msec()
			_velocity = 0.0
			_target = NAN
		elif _pressing:
			_pressing = false
			if not _dragged:
				_tap(pressed_event.position)
		accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion and _pressing:
		if absf(motion.position.x - _press_x) > TAP_SLOP:
			_dragged = true
		if _dragged:
			var dx := motion.position.x - _last_x
			var now := Time.get_ticks_msec()
			var dt := maxf((now - _last_time) / 1000.0, 0.001)
			_velocity = lerpf(_velocity, -dx / dt, 0.4)
			_scroll -= dx * (0.45 if _scroll < 0.0 or _scroll > max_scroll() else 1.0)
			_last_x = motion.position.x
			_last_time = now
			_apply()
		accept_event()
	elif event is InputEventPanGesture:
		_scroll += (event as InputEventPanGesture).delta.x * 18.0
		_scroll = clampf(_scroll, 0.0, max_scroll())
		_apply()
		accept_event()


func _process(delta: float) -> void:
	if _pressing:
		return
	if not is_nan(_target):
		_scroll = lerpf(_scroll, _target, 1.0 - exp(-delta * 9.0))
		if absf(_scroll - _target) < 0.5:
			_scroll = _target
			_target = NAN
		_apply()
		return
	var limit := max_scroll()
	if _scroll < 0.0 or _scroll > limit:
		_scroll = lerpf(_scroll, clampf(_scroll, 0.0, limit), 1.0 - exp(-delta * 12.0))
		_velocity = 0.0
		_apply()
	elif absf(_velocity) > 4.0:
		_scroll += _velocity * delta
		_velocity *= exp(-FRICTION * delta)
		_apply()


func _tap(at: Vector2) -> void:
	for i in content.get_child_count():
		var item := content.get_child(i) as Control
		if item and item.visible and item.get_rect().has_point(at - content.position):
			item_tapped.emit(i)
			return


func _layout() -> void:
	content.size = content.get_combined_minimum_size()
	content.position.y = (size.y - content.size.y) * 0.5
	_apply()


func _apply() -> void:
	var limit := max_scroll()
	if limit <= 0.0:
		content.position.x = (size.x - content.size.x) * 0.5
	else:
		content.position.x = -_scroll
	scrolled.emit(_scroll <= 1.0, _scroll >= limit - 1.0)
