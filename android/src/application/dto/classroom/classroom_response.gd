class_name ClassroomResponse
extends RefCounted
## Estado del aula en la tablet: si ya se configuró, la institución y sus secciones activas.

var configured := false
var institution_name := ""
var modular_code := ""
var grade := 6
var school_year := 0
var teacher_name := ""
var teacher_code := ""
## Secciones activas: cada una es {"id": String, "name": String}.
var sections: Array[Dictionary] = []
