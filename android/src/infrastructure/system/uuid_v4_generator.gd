class_name UuidV4Generator
extends IdGenerator
## Adaptador de salida: identificadores UUID versión 4 con bytes criptográficamente aleatorios.

var _crypto := Crypto.new()


func next_id() -> String:
	var bytes := _crypto.generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0F) | 0x40
	bytes[8] = (bytes[8] & 0x3F) | 0x80
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12),
	]
