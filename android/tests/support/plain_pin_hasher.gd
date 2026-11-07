class_name PlainPinHasher
extends PinHasher
## Doble de prueba del hash del PIN: rápido y legible. Solo para pruebas.

var _salts := 0


func new_salt() -> String:
	_salts += 1
	return "salt-%d" % _salts


func hash_pin(digits: String, salt: String) -> String:
	return "plain$%s$%s" % [salt, digits]


func verify(digits: String, credential: PinCredential) -> bool:
	return credential != null and credential.pin_hash == hash_pin(digits, credential.salt)
