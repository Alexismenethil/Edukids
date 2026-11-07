class_name ProfileCardViewModel
extends RefCounted
## Tarjeta de un estudiante en la pantalla de perfiles: su avatar y su nombre en dos líneas.

var id := ""
var name := ""
var first_line := ""
var second_line := ""
var look: AvatarLookViewModel
var has_avatar := false
var locked := false
