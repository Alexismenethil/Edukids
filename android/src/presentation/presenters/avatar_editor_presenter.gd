class_name AvatarEditorPresenter
extends RefCounted
## Presentador de «¡Crea tu personaje!» (RF-31 y CU-11).

var _get_profile: GetStudentProfile
var _customize: CustomizeAvatar
var _suggest: SuggestAvatar
var _session: PlaySession


func _init(get_profile: GetStudentProfile, customize: CustomizeAvatar, suggest: SuggestAvatar, session: PlaySession) -> void:
	_get_profile = get_profile
	_customize = customize
	_suggest = suggest
	_session = session


func editor() -> AvatarEditorViewModel:
	var view_model := AvatarEditorViewModel.new()
	var profile := _get_profile.execute(_session.student_id)
	var is_new := profile == null or profile.avatar.is_empty()
	view_model.title = "¡Crea tu personaje!" if is_new else "Cambia tu personaje"
	var first_name := ClassroomMessages.split_name(profile.name)[0] if profile else ""
	view_model.greeting = "Así te verás en la aventura, %s." % first_name if first_name else "Así te verás en la aventura."
	view_model.traits = _suggest.execute() if is_new else profile.avatar.duplicate()
	view_model.body_label = "Soy"
	view_model.girl_label = "Niña"
	view_model.boy_label = "Niño"
	view_model.skin_label = "Piel"
	view_model.hair_style_label = "Peinado"
	view_model.hair_color_label = "Cabello"
	view_model.top_label = "Chompa"
	view_model.surprise_label = "Sorpréndeme"
	view_model.done_label = "¡Listo!"
	view_model.back_label = "Volver"
	view_model.skin_colors = AvatarPalette.SKIN
	view_model.hair_colors = AvatarPalette.HAIR
	view_model.outfit_colors = AvatarPalette.OUTFIT
	view_model.hair_style_names = AvatarPalette.HAIR_STYLE_NAMES
	return view_model


func look(traits: Dictionary) -> AvatarLookViewModel:
	return AvatarPalette.look_for(traits)


func bottom_label(traits: Dictionary) -> String:
	return "Falda" if str(traits.get("body", "")) == "girl" else "Pantalón"


## Un personaje al azar, del mismo tipo de cuerpo que el actual.
func surprise(traits: Dictionary) -> Dictionary:
	return _suggest.execute(StringName(str(traits.get("body", ""))))


func save(traits: Dictionary) -> FormFeedbackViewModel:
	var feedback := FormFeedbackViewModel.new()
	var saved := _customize.execute(_session.student_id, traits)
	feedback.ok = saved.is_ok()
	if not feedback.ok:
		feedback.errors["general"] = "No se pudo guardar tu personaje. Inténtalo otra vez."
	return feedback
