class_name SetupPresenter
extends RefCounted
## Presentador del asistente de configuración inicial (RF-01 y CU-01).

const STEP_FIELDS := [
	["institution_name", "modular_code", "grade", "school_year"],
	["sections"],
	["teacher_name", "teacher_pin", "teacher_pin_confirmation", "teacher_code"],
]

var _configure: ConfigureInstitution
var _clock: Clock


func _init(configure: ConfigureInstitution, clock: Clock) -> void:
	_configure = configure
	_clock = clock


func screen() -> SetupViewModel:
	var view_model := SetupViewModel.new()
	view_model.welcome_title = "¡Hola, profe!"
	view_model.welcome_text = "Preparemos esta tablet para tu aula. Toma un par de minutos y funciona sin internet."
	view_model.start_label = "Empezar"
	view_model.step_titles = ["Tu institución", "Tus secciones", "Tu acceso", "¡Todo listo!"]
	view_model.step_hints = [
		"Estos datos solo se guardan en esta tablet.",
		"Agrega las secciones que usarán esta tablet. Cada estudiante pertenece a una.",
		"Con tu PIN entrarás al modo docente. Nadie más debe conocerlo.",
		"",
	]
	view_model.next_label = "Siguiente"
	view_model.back_label = "Atrás"
	view_model.finish_label = "Guardar"
	view_model.done_title = "¡Todo listo!"
	view_model.done_text = "La tablet ya está configurada. Ahora registra a tus estudiantes: cada uno tendrá su perfil y su PIN."
	view_model.done_button = "Registrar estudiantes"
	view_model.default_school_year = Time.get_datetime_dict_from_unix_time(int(_clock.now_unix_ms() / 1000.0))["year"]
	view_model.default_grade = 6
	view_model.labels = {
		"institution_name": "Nombre de la institución",
		"modular_code": "Código modular (opcional)",
		"grade": "Grado",
		"school_year": "Año escolar",
		"sections": "Secciones",
		"section_new": "Otra sección",
		"teacher_name": "Tu nombre",
		"teacher_pin": "PIN docente (4 a 6 números)",
		"teacher_pin_confirmation": "Repite tu PIN",
		"teacher_code": "Código de docente del panel web (opcional)",
	}
	view_model.placeholders = {
		"institution_name": "Por ejemplo: I.E. N.° 00000",
		"modular_code": "7 números",
		"section_new": "Escribe y toca Agregar",
		"teacher_name": "Nombre y apellido",
		"teacher_pin": "••••",
		"teacher_pin_confirmation": "••••",
		"teacher_code": "6 caracteres",
	}
	view_model.suggested_sections = ["A", "B", "C", "D"]
	view_model.max_lengths = {
		"institution_name": Institution.NAME_MAX_LENGTH,
		"modular_code": Institution.MODULAR_CODE_LENGTH,
		"school_year": 4,
		"section_new": Section.MAX_LENGTH,
		"teacher_name": PersonName.MAX_LENGTH,
		"teacher_pin": Pin.TEACHER_MAX_LENGTH,
		"teacher_pin_confirmation": Pin.TEACHER_MAX_LENGTH,
		"teacher_code": TeacherCode.LENGTH + 2,
	}
	for grade in range(Institution.MIN_GRADE, Institution.MAX_GRADE + 1):
		view_model.grades.append(grade)
	return view_model


## Errores del paso indicado (0, 1 o 2), como {campo: mensaje}.
func validate_step(step: int, data: Dictionary) -> Dictionary:
	var errors := _configure.validate(_request(data))
	var messages := {}
	if step < 0 or step >= STEP_FIELDS.size():
		return messages
	for field: String in STEP_FIELDS[step]:
		if errors.has(field):
			messages[field] = ClassroomMessages.text_for(errors[field], field)
	return messages


func submit(data: Dictionary) -> FormFeedbackViewModel:
	var response := _configure.execute(_request(data))
	var feedback := FormFeedbackViewModel.new()
	feedback.ok = response.ok
	feedback.errors = ClassroomMessages.field_messages(response.errors)
	return feedback


## Primer paso con errores, para volver a él si algo falló al guardar.
func first_step_with_errors(errors: Dictionary) -> int:
	for step in STEP_FIELDS.size():
		for field: String in STEP_FIELDS[step]:
			if errors.has(field):
				return step
	return STEP_FIELDS.size() - 1


static func _request(data: Dictionary) -> SetupRequest:
	var request := SetupRequest.new()
	request.institution_name = str(data.get("institution_name", ""))
	request.modular_code = str(data.get("modular_code", ""))
	request.grade = int(data.get("grade", 6))
	request.school_year = int(data.get("school_year", 0))
	request.section_names = PackedStringArray(data.get("sections", []))
	request.teacher_name = str(data.get("teacher_name", ""))
	request.teacher_pin = str(data.get("teacher_pin", ""))
	request.teacher_pin_confirmation = str(data.get("teacher_pin_confirmation", ""))
	request.teacher_code = str(data.get("teacher_code", ""))
	return request
