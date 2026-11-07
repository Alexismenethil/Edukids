class_name Toast
extends PanelContainer
## Aviso breve que aparece abajo y se va solo. Los avisos son de una línea.

const BOTTOM_GAP := 36.0

var _label := Label.new()
var _tween: Tween


func _ready() -> void:
	theme_type_variation = &"ToastPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.theme_type_variation = &"ToastLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	modulate.a = 0.0
	visible = false


## Mientras se ve, se ajusta a su texto y queda centrado abajo.
func _process(_delta: float) -> void:
	if not visible:
		return
	size = get_combined_minimum_size()
	var view := get_viewport_rect().size
	position = Vector2((view.x - size.x) * 0.5, view.y - size.y - BOTTOM_GAP)


func show_message(text: String, seconds: float = 2.8) -> void:
	_label.text = text
	visible = true
	_process(0.0)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	_tween.tween_interval(seconds)
	_tween.tween_property(self, "modulate:a", 0.0, 0.35)
	_tween.tween_callback(hide)
