class_name Student
extends RefCounted
## Estudiante registrado por el docente (RF-04). Entra con su avatar y su PIN (RF-05).
## Nunca se elimina: se desactiva y conserva sus resultados (RN-07).

var id: String
var section_id: String
var name: String
## Código opcional que usa la institución; "" si no tiene.
var code: String
var credential: PinCredential
## Null mientras el estudiante no crea su personaje (RF-31).
var avatar: Avatar
var lockout: PinLockout
var active: bool


func _init(student_id: String, student_section_id: String, student_name: String, pin_credential: PinCredential) -> void:
	id = student_id
	section_id = student_section_id
	name = student_name
	code = ""
	credential = pin_credential
	avatar = null
	lockout = PinLockout.new()
	active = true


func has_avatar() -> bool:
	return avatar != null
