class_name AvatarEditorViewModel
extends RefCounted
## Editor del personaje: textos, rasgos de partida y colores de cada opción.

var title := ""
var greeting := ""
var traits: Dictionary = {}
var body_label := ""
var girl_label := ""
var boy_label := ""
var skin_label := ""
var hair_style_label := ""
var hair_color_label := ""
var top_label := ""
var surprise_label := ""
var done_label := ""
var back_label := ""
var skin_colors: Array[Color] = []
var hair_colors: Array[Color] = []
var outfit_colors: Array[Color] = []
var hair_style_names: Array[String] = []
