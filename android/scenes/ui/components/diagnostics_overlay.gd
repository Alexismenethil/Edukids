class_name DiagnosticsOverlay
extends PanelContainer
## Panel de medición para probar el APK en la tablet real (Sprint 2): dispositivo, memoria,
## cuadros por segundo, arranque y almacenamiento. Se abre con tres toques sobre la versión.

const WINDOW_SECONDS := 5.0
const MB := 1048576.0

@onready var _text: Label = $Box/Text
@onready var _close: Button = $Box/CloseButton

var _info := DiagnosticsViewModel.new()
var _samples: Array[Vector2] = []
var _clock := 0.0
var _refresh := 0.0


func _ready() -> void:
	visible = false
	_close.pressed.connect(hide)


func toggle(info: DiagnosticsViewModel) -> void:
	_info = info
	visible = not visible
	_samples.clear()
	_refresh = 0.0


func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	if delta > 0.0:
		_samples.append(Vector2(_clock, 1.0 / delta))
	while not _samples.is_empty() and _clock - _samples[0].x > WINDOW_SECONDS:
		_samples.pop_front()
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = 0.5
		_text.text = report()


## Texto del reporte, listo para una captura de pantalla.
func report() -> String:
	var memory := OS.get_memory_info()
	var screen := DisplayServer.screen_get_size()
	var view := get_viewport().get_visible_rect().size
	var lines: PackedStringArray = [
		"EduKids %s" % _info.version,
		"Dispositivo: %s" % OS.get_model_name(),
		"Sistema: %s %s · %s" % [OS.get_name(), OS.get_version(), Engine.get_architecture_name()],
		"Procesador: %s (%d núcleos)" % [OS.get_processor_name(), OS.get_processor_count()],
		"GPU: %s · %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version()],
		"Pantalla: %d × %d px · %d ppp · vista %d × %d" % [screen.x, screen.y, DisplayServer.screen_get_dpi(), view.x, view.y],
		"RAM del dispositivo: %s · disponible %s" % [_megabytes(memory.get("physical", -1)), _megabytes(memory.get("available", -1))],
		"Memoria del motor: %.0f MB · pico %.0f MB" % [OS.get_static_memory_usage() / MB, OS.get_static_memory_peak_usage() / MB],
		"Memoria de video: %.0f MB" % (Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / MB),
		"Cuadros por segundo: %d · promedio %.0f · mínimo %.0f (últimos %d s)" % [Engine.get_frames_per_second(), _average_fps(), _minimum_fps(), WINDOW_SECONDS],
		"Tiempo de proceso por cuadro: %.1f ms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0),
		"Llamadas de dibujo: %d" % Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"Arranque hasta la pantalla de inicio: %.2f s" % (_info.startup_ms / 1000.0),
		"Almacenamiento: %s" % _info.storage,
	]
	return "\n".join(lines)


func _average_fps() -> float:
	if _samples.is_empty():
		return 0.0
	var total := 0.0
	for sample in _samples:
		total += sample.y
	return total / _samples.size()


func _minimum_fps() -> float:
	var lowest := INF
	for sample in _samples:
		lowest = minf(lowest, sample.y)
	return 0.0 if lowest == INF else lowest


static func _megabytes(bytes: int) -> String:
	return "?" if bytes < 0 else "%.0f MB" % (bytes / MB)
