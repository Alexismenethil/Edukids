class_name TeacherPanelViewModel
extends RefCounted
## Encabezado y pestañas del modo docente.

var title := ""
var subtitle := ""
var exit_label := ""
## Cada pestaña: {"id": String, "label": String, "enabled": bool, "soon": String}.
var tabs: Array[Dictionary] = []
var add_label := ""
var empty_message := ""
var sections: Array[SectionTabViewModel] = []
var auto_lock_seconds := 300
