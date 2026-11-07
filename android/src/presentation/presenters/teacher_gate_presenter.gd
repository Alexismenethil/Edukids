class_name TeacherGatePresenter
extends RefCounted
## Presentador del PIN docente (RF-03): entra sin internet y se bloquea tras 5 fallos.

var _unlock: UnlockTeacherMode


func _init(unlock: UnlockTeacherMode) -> void:
	_unlock = unlock


func screen() -> TeacherGateViewModel:
	var view_model := TeacherGateViewModel.new()
	view_model.title = "Modo docente"
	view_model.prompt = "Escribe tu PIN docente"
	view_model.hint = "Aquí registras a tus estudiantes y, pronto, habilitarás módulos y verás reportes."
	view_model.back_label = "Volver"
	view_model.pin_min_length = Pin.TEACHER_MIN_LENGTH
	view_model.pin_max_length = Pin.TEACHER_MAX_LENGTH
	return view_model


func unlock(pin: String) -> PinFeedbackViewModel:
	var response := _unlock.execute(pin)
	var feedback := PinFeedbackViewModel.new()
	feedback.ok = response.ok
	feedback.name = response.name
	if response.ok:
		return feedback
	if response.error == PinCheckResponse.LOCKED:
		feedback.locked = true
		feedback.locked_seconds = response.locked_seconds
		feedback.title = "Acceso bloqueado"
		feedback.message = locked_message(response.locked_seconds)
	else:
		feedback.title = "PIN incorrecto"
		feedback.message = "Te quedan %d intentos antes de un bloqueo de 5 minutos." % response.attempts_left \
			if response.attempts_left != 1 else "Te queda 1 intento antes de un bloqueo de 5 minutos."
	return feedback


func locked_message(seconds: int) -> String:
	return "Por seguridad, espera %s para volver a intentarlo." % ClassroomMessages.clock_text(seconds)
