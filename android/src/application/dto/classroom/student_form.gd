class_name StudentForm
extends RefCounted
## Datos del formulario de un estudiante en el modo docente (RF-04).

## Vacío al registrar; el id del estudiante al editar.
var student_id := ""
var name := ""
var section_id := ""
## Solo al registrar o al restablecer el PIN.
var pin := ""
