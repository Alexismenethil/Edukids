class_name LaunchArgs
extends RefCounted
## Argumentos de arranque: los de la línea de comandos y, solo en compilaciones de depuración, los
## de `user://demo_args.txt`. Así se puede abrir el modo demostración en un emulador o en la tablet,
## donde el lanzador de Android no pasa argumentos. Por ejemplo:
##   adb shell run-as pe.edu.unsch.edukids sh -c 'echo "--demo-data --demo-chase" > files/demo_args.txt'
## Para volver al juego normal se borra el archivo (o se reinstala la app).

const FILE := "user://demo_args.txt"

static var _args: PackedStringArray
static var _loaded := false


static func all() -> PackedStringArray:
	if _loaded:
		return _args
	_loaded = true
	_args = OS.get_cmdline_user_args()
	if _args.is_empty() and OS.is_debug_build() and FileAccess.file_exists(FILE):
		for part in FileAccess.get_file_as_string(FILE).replace("\n", " ").split(" ", false):
			if not part.strip_edges().is_empty():
				_args.append(part.strip_edges())
	return _args
