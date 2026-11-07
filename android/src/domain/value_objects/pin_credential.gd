class_name PinCredential
extends RefCounted
## Hash y sal de un PIN (RNF-08). Es lo único que se guarda del PIN.

var pin_hash: String:
	get:
		return _pin_hash

var salt: String:
	get:
		return _salt

var _pin_hash: String
var _salt: String


func _init(hashed: String, pin_salt: String) -> void:
	_pin_hash = hashed
	_salt = pin_salt


func is_empty() -> bool:
	return _pin_hash.is_empty() or _salt.is_empty()
