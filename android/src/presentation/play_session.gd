class_name PlaySession
extends RefCounted
## Estado de la sesión mientras el juego está abierto: quién entró y qué se vio.
## No se guarda: al cerrar la aplicación, se vuelve a elegir perfil.

## Estudiante que entró con su PIN; vacío si nadie.
var student_id := ""
## Última sección elegida en la pantalla de perfiles.
var section_id := ""
## Quwi ya contó su adelanto de la historia en esta sesión.
var teaser_told := false


func log_out() -> void:
	student_id = ""
