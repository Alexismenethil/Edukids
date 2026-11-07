class_name SetupViewModel
extends RefCounted
## Textos del asistente de configuración inicial (RF-01).

var welcome_title := ""
var welcome_text := ""
var start_label := ""
var step_titles: Array[String] = []
var step_hints: Array[String] = []
var next_label := ""
var back_label := ""
var finish_label := ""
var done_title := ""
var done_text := ""
var done_button := ""
var default_school_year := 2026
var default_grade := 6
## Etiquetas de cada campo, por nombre del campo.
var labels: Dictionary = {}
var placeholders: Dictionary = {}
var suggested_sections: Array[String] = []
## Largo máximo de cada campo, por nombre del campo.
var max_lengths: Dictionary = {}
var grades: Array[int] = []
