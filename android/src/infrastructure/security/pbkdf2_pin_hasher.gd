class_name Pbkdf2PinHasher
extends PinHasher
## Adaptador de salida: PBKDF2-HMAC-SHA256 con sal aleatoria de 16 bytes (RNF-08).
##
## El hash guardado indica el algoritmo y las iteraciones («pbkdf2-sha256$4000$…»), así se
## pueden subir las iteraciones más adelante sin invalidar los PIN que ya están guardados.

const ALGORITHM := "pbkdf2-sha256"
const ITERATIONS := 4000
const SALT_BYTES := 16

var _crypto := Crypto.new()
var _iterations: int


func _init(iterations: int = ITERATIONS) -> void:
	_iterations = maxi(iterations, 1)


func new_salt() -> String:
	return _crypto.generate_random_bytes(SALT_BYTES).hex_encode()


func hash_pin(digits: String, salt: String) -> String:
	var derived := derive(digits.to_utf8_buffer(), salt.hex_decode(), _iterations)
	return "%s$%d$%s" % [ALGORITHM, _iterations, derived.hex_encode()]


func verify(digits: String, credential: PinCredential) -> bool:
	if credential == null or credential.is_empty():
		return false
	var parts := credential.pin_hash.split("$")
	if parts.size() != 3 or parts[0] != ALGORITHM or not parts[1].is_valid_int():
		return false
	var derived := derive(digits.to_utf8_buffer(), credential.salt.hex_decode(), parts[1].to_int())
	return _same(derived.hex_encode(), parts[2])


## PBKDF2 con un solo bloque de 32 bytes. Los XOR se hacen en enteros de 64 bits,
## porque en GDScript es mucho más rápido que byte por byte.
func derive(password: PackedByteArray, salt: PackedByteArray, iterations: int) -> PackedByteArray:
	var block := salt.duplicate()
	block.append_array(PackedByteArray([0, 0, 0, 1]))
	var u := _crypto.hmac_digest(HashingContext.HASH_SHA256, password, block)
	var t0 := u.decode_s64(0)
	var t1 := u.decode_s64(8)
	var t2 := u.decode_s64(16)
	var t3 := u.decode_s64(24)
	for i in iterations - 1:
		u = _crypto.hmac_digest(HashingContext.HASH_SHA256, password, u)
		t0 ^= u.decode_s64(0)
		t1 ^= u.decode_s64(8)
		t2 ^= u.decode_s64(16)
		t3 ^= u.decode_s64(24)
	var result := PackedByteArray()
	result.resize(32)
	result.encode_s64(0, t0)
	result.encode_s64(8, t1)
	result.encode_s64(16, t2)
	result.encode_s64(24, t3)
	return result


## Compara sin salir antes de tiempo, para no revelar cuántos caracteres coinciden.
static func _same(a: String, b: String) -> bool:
	if a.length() != b.length():
		return false
	var difference := 0
	for i in a.length():
		difference |= a.unicode_at(i) ^ b.unicode_at(i)
	return difference == 0
