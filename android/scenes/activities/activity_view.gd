@abstract class_name ActivityView
extends Control
## Base de las actividades: una por tipo de ítem. Cada una arma su interacción con los datos
## del paso, entrega la respuesta con el formato del motor y marca lo que salió bien o mal.

## La respuesta cambió (puede estar completa o no).
signal changed

var step: StepViewModel
var locked := false


func setup(step_model: StepViewModel) -> void:
	step = step_model


func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build()
	for child in get_children():
		if child is Control:
			(child as Control).minimum_size_changed.connect(update_minimum_size)
	update_minimum_size()


## El alto mínimo es el de su contenido, para que la tarjeta pueda desplazarse si no cabe.
func _get_minimum_size() -> Vector2:
	var minimum := Vector2.ZERO
	for child in get_children():
		if child is Control and (child as Control).visible:
			minimum = minimum.max((child as Control).get_combined_minimum_size())
	return Vector2(0.0, minimum.y)


## Arma la actividad (se llama al entrar al árbol).
@abstract func build() -> void


## La respuesta con el formato del motor: texto, lista o diccionario.
@abstract func answer() -> Variant


@abstract func is_complete() -> bool


## Marca cada parte respondida: id → true si está bien.
@abstract func show_result(parts: Dictionary) -> void


## Pone una respuesta como si la hubiera dado el estudiante (modo demostración).
@abstract func apply_answer(value: Variant) -> void


func lock() -> void:
	locked = true


## Ubica el contenido de la actividad centrado en el espacio libre de la tarjeta.
static func center(container: Control) -> void:
	container.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	container.grow_vertical = Control.GROW_DIRECTION_BOTH


## true si la actividad comparte la tarjeta con el texto de una lectura (columna angosta).
func compact() -> bool:
	return step != null and not step.unit.is_empty()


func accent() -> Color:
	return step.area.deep if step and step.area else ActivityStyle.PRIMARY
