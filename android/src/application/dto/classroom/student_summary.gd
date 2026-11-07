class_name StudentSummary
extends RefCounted
## Datos de un estudiante para listas y perfiles. Nunca incluye el PIN ni su hash.

var id := ""
var name := ""
var section_id := ""
## Rasgos del avatar; vacío si todavía no creó su personaje.
var avatar: Dictionary = {}
var active := true
var locked := false
var locked_seconds := 0


static func from_student(student: Student, now_ms: int) -> StudentSummary:
	var summary := StudentSummary.new()
	summary.id = student.id
	summary.name = student.name
	summary.section_id = student.section_id
	summary.avatar = student.avatar.to_dict() if student.has_avatar() else {}
	summary.active = student.active
	summary.locked = student.lockout.is_locked(now_ms)
	summary.locked_seconds = ceili(student.lockout.remaining_ms(now_ms) / 1000.0)
	return summary
