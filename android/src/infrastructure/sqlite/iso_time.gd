class_name IsoTime
extends RefCounted
## Conversión entre milisegundos Unix y fechas ISO 8601 en UTC («2026-11-07T15:30:00Z»),
## el formato de las fechas en la base de datos.


## Devuelve null para 0, así la columna queda en NULL.
static func from_unix_ms(milliseconds: int) -> Variant:
	if milliseconds <= 0:
		return null
	return Time.get_datetime_string_from_unix_time(int(milliseconds / 1000.0)) + "Z"


static func to_unix_ms(value: Variant) -> int:
	if value == null or str(value).is_empty():
		return 0
	return Time.get_unix_time_from_datetime_string(str(value).trim_suffix("Z")) * 1000
