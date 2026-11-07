class_name DemoClassroom
extends RefCounted
## Aula ficticia para el modo demostración (godot -- --demo-data, solo en compilaciones de
## depuración). Se guarda en una base aparte; nunca aparece en una instalación normal (ADR-008).
## Se registra con los mismos casos de uso que usa el docente.

const TEACHER_PIN := "2580"
const STUDENT_PIN := "2468"
## Nombre, sección y rasgos del avatar ({} si todavía no creó su personaje).
const STUDENTS := [
	["Wayra Quispe", "A", {"body": "boy", "skin": 2, "hair_style": 1, "hair_color": 0, "top_color": 2, "bottom_color": 7}],
	["Killa Huamán", "A", {"body": "girl", "skin": 3, "hair_style": 3, "hair_color": 0, "top_color": 0, "bottom_color": 6}],
	["Inti Ccori", "A", {"body": "boy", "skin": 4, "hair_style": 2, "hair_color": 1, "top_color": 1, "bottom_color": 3}],
	["Sumaq Rojas", "A", {"body": "girl", "skin": 1, "hair_style": 4, "hair_color": 2, "top_color": 4, "bottom_color": 7}],
	["Kusi Mamani", "A", {}],
	["Amaru Soto", "A", {"body": "boy", "skin": 5, "hair_style": 0, "hair_color": 0, "top_color": 3, "bottom_color": 7}],
	["Ñusta Tito", "A", {"body": "girl", "skin": 2, "hair_style": 5, "hair_color": 1, "top_color": 6, "bottom_color": 2}],
	["Yuri Paucar", "A", {"body": "girl", "skin": 0, "hair_style": 3, "hair_color": 4, "top_color": 5, "bottom_color": 0}],
	["Pacha Llamoca", "A", {}],
	["Rumi Condori", "B", {"body": "boy", "skin": 3, "hair_style": 2, "hair_color": 0, "top_color": 7, "bottom_color": 1}],
	["Illa Yupanqui", "B", {"body": "girl", "skin": 4, "hair_style": 4, "hair_color": 0, "top_color": 2, "bottom_color": 6}],
]


static func seed(institutions: InstitutionRepository, students: StudentRepository, hasher: PinHasher, ids: IdGenerator) -> void:
	var request := SetupRequest.new()
	request.institution_name = "Escuela de demostración"
	request.grade = 6
	request.school_year = 2026
	request.section_names = PackedStringArray(["A", "B"])
	request.teacher_name = "Docente de prueba"
	request.teacher_pin = TEACHER_PIN
	request.teacher_pin_confirmation = TEACHER_PIN
	if not ConfigureInstitution.new(institutions, hasher, ids).execute(request).ok:
		return
	var section_ids := {}
	for section in GetClassroom.new(institutions).execute().sections:
		section_ids[section["name"]] = section["id"]
	var register := RegisterStudent.new(institutions, students, hasher, ids)
	var customize := CustomizeAvatar.new(students)
	for entry: Array in STUDENTS:
		var form := StudentForm.new()
		form.name = entry[0]
		form.section_id = section_ids.get(entry[1], "")
		form.pin = STUDENT_PIN
		var created := register.execute(form)
		if created.ok and not (entry[2] as Dictionary).is_empty():
			customize.execute(created.id, entry[2])


## Respuesta correcta de una pregunta, con el mismo formato que entregan las vistas.
static func solution_of(question: Item) -> Variant:
	var spec := question.spec
	match question.type:
		ItemType.MULTIPLE_CHOICE:
			return spec["correct"]
		ItemType.MULTI_SELECT:
			return spec["correct"].duplicate()
		ItemType.TRUE_FALSE:
			var answer := {}
			for statement: Dictionary in spec["statements"]:
				answer[statement["id"]] = statement["answer"]
			return answer
		ItemType.ORDERING:
			return spec["correct_order"].duplicate()
		ItemType.MATCHING:
			return spec["pairs"].duplicate()
		ItemType.CLASSIFICATION:
			var groups := {}
			for element: Dictionary in spec["elements"]:
				groups[element["id"]] = element["group"]
			return groups
		ItemType.FILL_BLANK:
			var words := {}
			for blank: Dictionary in spec["blanks"]:
				words[blank["id"]] = blank["accepted"][0]
			return words
		ItemType.NUMERIC:
			return NumberAnswer.spoken(spec["answer"]).replace(" ", "")
	return null


## Una respuesta equivocada creíble, para mostrar la retroalimentación en la demostración.
static func wrong_answer(solution: Variant) -> Variant:
	if solution is String and NumberAnswer.parse(solution).is_ok():
		if solution.length() >= 2 and solution[0] != solution[1]:
			return solution[1] + solution[0] + solution.substr(2)
		return solution + "0"
	if solution is Array and solution.size() > 1:
		var swapped: Array = solution.duplicate()
		var first: Variant = swapped[0]
		swapped[0] = swapped[1]
		swapped[1] = first
		return swapped
	if solution is Dictionary and not solution.is_empty():
		var changed: Dictionary = solution.duplicate()
		var key: Variant = changed.keys()[0]
		if changed[key] is bool:
			changed[key] = not changed[key]
		return changed
	return solution


## Tiempo para que la demostración termine de marcar su respuesta.
static func answer_seconds(value: Variant) -> float:
	if value is Array or value is Dictionary:
		return 1.0 + 0.7 * value.size()
	return 1.0 + 0.3 * str(value).length()
