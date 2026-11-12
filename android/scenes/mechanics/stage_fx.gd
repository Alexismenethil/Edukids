class_name StageFx
extends RefCounted
## Efectos de las escenas de juego: ráfagas de caricatura (ToonFx), textos que flotan y nudos
## que vuelan.

const KNOT_COLORS := [Color("#E8833A"), Color("#3B7DD8"), Color("#3FA34D"), Color("#C2185B"), Color("#F2C14E")]


## Una ráfaga de efectos: dust, sparkle, splash, crumbs, leaves o hearts (ver ToonFx).
static func burst(parent: Node, at: Vector2, kind: StringName, amount: int = 18) -> void:
	match kind:
		&"dust":
			ToonFx.puff(parent, at, clampi(amount / 3, 4, 8))
		&"splash":
			ToonFx.splash(parent, at, amount, 1.0 if amount < 30 else 1.25)
		&"crumbs":
			ToonFx.crumbs(parent, at, clampi(amount / 2, 6, 14))
		&"leaves":
			ToonFx.leaves(parent, at, amount)
		&"hearts":
			ToonFx.hearts(parent, at, clampi(amount / 2, 4, 8))
		_:
			ToonFx.sparkles(parent, at, clampi(amount / 2, 6, 16))
			ToonFx.stars(parent, at, clampi(amount / 5, 3, 8))


## Un texto que sube y se desvanece: «¡Ñam!», «¡Ñac!», «¡Hop!».
static func float_text(parent: Node, text: String, at: Vector2, color: Color, font_size: int = 30) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#3A2418"))
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
	label.position = at - Vector2(60, 20)
	label.size = Vector2(120, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 6
	label.pivot_offset = Vector2(60, 20)
	label.scale = Vector2(0.4, 0.4)
	parent.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position:y", label.position.y - 46.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(label.queue_free)


## Un nudo de colores que vuela en arco de un punto a otro.
static func fly_knot(parent: Node, from: Vector2, to: Vector2, color: Color, seconds: float = 0.6) -> Tween:
	var knot := KnotSprite.new()
	knot.color = color
	knot.position = from
	knot.z_index = 6
	parent.add_child(knot)
	var tween := knot.create_tween()
	var lift := minf(from.y, to.y) - 80.0
	tween.tween_method(func(t: float) -> void:
		var a := from.lerp(Vector2((from.x + to.x) * 0.5, lift), t)
		var b := Vector2((from.x + to.x) * 0.5, lift).lerp(to, t)
		knot.position = a.lerp(b, t)
		knot.rotation = t * TAU, 0.0, 1.0, seconds).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(knot.queue_free)
	return tween
