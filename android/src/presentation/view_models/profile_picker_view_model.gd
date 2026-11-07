class_name ProfilePickerViewModel
extends RefCounted
## Textos y secciones de la pantalla «¿Quién va a jugar hoy?».

var title := ""
var hint := ""
var back_label := ""
var empty_message := ""
var pin_prompt := ""
var not_me_label := ""
var sections: Array[SectionTabViewModel] = []
## Sección que se muestra al abrir.
var selected_section_id := ""
