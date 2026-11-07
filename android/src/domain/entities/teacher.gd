class_name Teacher
extends RefCounted
## Docente de la tablet (ADR-005): entra al modo docente con su PIN, sin conexión (RF-03).

var id: String
var name: String
var credential: PinCredential
var lockout: PinLockout


func _init(teacher_id: String, teacher_name: String, pin_credential: PinCredential, pin_lockout: PinLockout = PinLockout.new()) -> void:
	id = teacher_id
	name = teacher_name
	credential = pin_credential
	lockout = pin_lockout
