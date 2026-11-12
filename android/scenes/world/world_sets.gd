class_name WorldSets
extends RefCounted
## Mundos listos para usar: arman un ParallaxWorld completo en una línea, con la hora del día que
## se pida. Los usan los cortos (ShortPlayer), los menús y las mecánicas nuevas.
##
##   var place := WorldSets.build(world, &"valley", &"dusk")
##   place["actors"].add_child(personaje)      # plano de los personajes
##   personaje.position = Vector2(640, place["ground"])
##
## Mundos: valley (Sierra), jungle (Selva), coast (Costa), lagoon (laguna con muelle) y canyon
## (cañón con río). Los tres primeros corren sin fin: `REGION_WORLDS` dice cuál es el de cada
## capítulo.
## Horas: day (día), dusk (atardecer dorado) y night (noche con luna, estrellas y luciérnagas).
## Lo que devuelve: "actors" (plano de los personajes), "track" (plano del suelo, para objetos
## detrás de ellos), "ground" (altura donde pisan), "focus" (punto que mira la cámara) y "mood".
## Los mundos que corren dan además "stage": un plano quieto respecto de la cámara.

const VALLEY := "res://assets/art/worlds/valley/"
const LAGOON := "res://assets/art/worlds/lagoon/"
const CANYON := "res://assets/art/worlds/canyon/"
const JUNGLE := "res://assets/art/worlds/jungle/"
const COAST := "res://assets/art/worlds/coast/"
## Mundo de franja (para correr) de cada capítulo del juego.
const REGION_WORLDS := {&"sierra": &"valley", &"selva": &"jungle", &"costa": &"coast"}

## Cielo, luz y aire de cada hora del día.
const MOODS := {
	&"day": {
		"sky": ["#4FAEEA", "#9AD6F2", "#FFF0D6", "#FFD9AE"], "stops": [0.0, 0.45, 0.78, 1.0],
		"sun": Vector2(0.8, 395.0), "sun_radius": 44.0, "sun_color": "#FFFAE6", "glow": "#FFE6B3",
		"rays": 0.13, "rays_tint": "#FFE09E", "far": "#FFFFFF", "near": "#FFFFFF", "actors": "#FFFFFF",
		"fog": Color(1.0, 0.97, 0.9, 0.5), "clouds": "#FFFFFF", "stars": 0, "fireflies": 0, "motes": 24,
	},
	&"dusk": {
		"sky": ["#4E5FC4", "#B77FC0", "#FFA877", "#FFD58A"], "stops": [0.0, 0.42, 0.74, 1.0],
		"sun": Vector2(0.74, 520.0), "sun_radius": 58.0, "sun_color": "#FFE9A8", "glow": "#FF9A5C",
		"rays": 0.22, "rays_tint": "#FF9E5E", "far": "#E8B8C8", "near": "#FFD9B8", "actors": "#FFEBD6",
		"fog": Color(1.0, 0.8, 0.62, 0.5), "clouds": "#FFC7A8", "stars": 14, "fireflies": 10, "motes": 16,
	},
	&"night": {
		"sky": ["#141E4A", "#27397C", "#4F62B0", "#8C93D6"], "stops": [0.0, 0.4, 0.78, 1.0],
		"sun": Vector2(0.76, 250.0), "sun_radius": 36.0, "sun_color": "#F4F6FF", "glow": "#6F86E0",
		"rays": 0.0, "rays_tint": "#9FB4FF", "far": "#6A7CC4", "near": "#7C92CC", "actors": "#C9D3F2",
		"fog": Color(0.62, 0.7, 1.0, 0.35), "clouds": "#7E8FD0", "stars": 70, "fireflies": 26, "motes": 0,
	},
}


static func build(world: ParallaxWorld, place: StringName, mood: StringName = &"day", options: Dictionary = {}) -> Dictionary:
	match place:
		&"jungle":
			return jungle(world, mood, options)
		&"coast":
			return coast(world, mood, options)
		&"lagoon":
			return lagoon(world, mood, options)
		&"canyon":
			return canyon(world, mood, options)
	return valley(world, mood, options)


## Valle del Qhapaq Ñan (Sierra): cerros nevados, lomas, chacras y el camino inca. Se repite sin
## fin, así que sirve para correr. Opciones: road (camino), front (primer plano).
static func valley(world: ParallaxWorld, mood: StringName = &"day", options: Dictionary = {}) -> Dictionary:
	return _strip(world, VALLEY + "valley", mood, options, {"meadow": "#6DBE58", "deep": "#2F7740",
		"fog": true})


## Selva del valle del Apurímac: cerros de bosque entre la neblina, palmeras, lianas y un sendero
## de tierra. Corre sin fin, como el valle.
static func jungle(world: ParallaxWorld, mood: StringName = &"day", options: Dictionary = {}) -> Dictionary:
	var place := _strip(world, JUNGLE + "jungle", mood, options, {"meadow": "#3FA35E", "deep": "#1C6038",
		"fog": true, "fog_color": Color(0.93, 0.9, 1.0, 0.62), "fog_band": Vector2(520.0, 640.0)})
	world.add_child(AmbientField.new().setup(world, AmbientField.Kind.BUTTERFLIES, 6, 1.0, Vector2(380.0, 600.0),
		PackedColorArray([Color("#FF8A3C"), Color("#5AC8F2"), Color("#FFD23F")])))
	return place


## Costa: el mar con islotes guaneros y caballitos de totora, dunas con huarangos y arena firme.
## Corre sin fin, como el valle.
static func coast(world: ParallaxWorld, mood: StringName = &"day", options: Dictionary = {}) -> Dictionary:
	return _strip(world, COAST + "coast", mood, options, {"meadow": "#EACB82", "deep": "#B88A4A", "fog": false,
		"petals": false})


## Mundo de franja que se repite: cinco capas con las mismas medidas (far, mid, near, ground,
## front) y el plano de los personajes entre el suelo y el primer plano.
static func _strip(world: ParallaxWorld, prefix: String, mood: StringName, options: Dictionary, look: Dictionary) -> Dictionary:
	var air: Dictionary = MOODS.get(mood, MOODS[&"day"])
	_sky(world, air, -300.0, 600.0)
	_tint(world.add_layer(load(prefix + "_far.svg"), 0.1, 250.0, 1.0), air["far"])
	_rays(world, air)
	_tint(world.add_layer(load(prefix + "_mid.svg"), 0.3, 410.0, 1.25), air["far"])
	if look.get("fog", true):
		var band: Vector2 = look.get("fog_band", Vector2(560.0, 640.0))
		var fog_color: Color = look.get("fog_color", air["fog"])
		if mood != &"day":
			fog_color = Color((air["fog"] as Color), fog_color.a)
		_tint(world.add_fog(band.x, band.y, 0.45, fog_color), "#FFFFFF")
	_tint(world.add_layer(load(prefix + "_near.svg"), 0.6, 300.0, 1.5), air["near"])
	if options.get("road", true):
		_tint(world.add_layer(load(prefix + "_ground.svg"), 1.0, 596.0, 2.0), air["near"])
	else:
		_tint(world.add_fill(640.0, 4000.0, Color(str(look["meadow"]))), air["near"])
	var track := world.add_plane(1.0)
	var actors := world.add_plane(1.0)
	# Un plano quieto respecto de la cámara, para quien corre en su sitio mientras el mundo pasa.
	var stage := world.add_stage()
	actors.modulate = Color(air["actors"])
	track.modulate = Color(air["actors"])
	stage.modulate = Color(air["actors"])
	if options.get("front", true):
		var front := world.add_layer(load(prefix + "_front.svg"), 1.35, 650.0, 1.5)
		world.sway(front, 5.0, 1.4)
		_tint(front, air["near"])
	_tint(world.add_fill(814.0, 4000.0, Color(str(look["deep"]))), air["near"])
	_air(world, air, Vector2(300.0, 700.0), look.get("petals", true))
	return {"actors": actors, "track": track, "stage": stage, "ground": 652.0, "focus": Vector2(640.0, 652.0), "mood": mood}


## Laguna con muelle, totoras y nenúfares. El muelle está a la izquierda (x de 0 a 330).
static func lagoon(world: ParallaxWorld, mood: StringName = &"day", _options: Dictionary = {}) -> Dictionary:
	var air: Dictionary = MOODS.get(mood, MOODS[&"day"])
	_sky(world, air, -320.0, 560.0)
	_tint(world.add_layer(load(VALLEY + "valley_far.svg"), 0.08, 200.0, 1.0), air["far"])
	_rays(world, air)
	_tint(world.add_layer(load(LAGOON + "lagoon_far.svg"), 0.25, 360.0, 1.0, false, -700.0), air["far"])
	_tint(world.add_layer(load(LAGOON + "lagoon_mid.svg"), 0.5, 340.0, 1.2, false, -700.0), air["near"])
	_tint(world.add_water(572.0, 1600.0, 0.9, 14.0, Color("#8FDCEB"), Color("#3A9CC8")), air["near"])
	var swimmers := world.add_plane(1.0)
	swimmers.modulate = Color(air["actors"])
	var front := world.add_water(650.0, 1600.0, 1.0, 14.0, Color("#78CFE4"), Color("#3A9CC8"))
	(front.material as ShaderMaterial).set_shader_parameter("opacity", 0.84)
	(front.material as ShaderMaterial).set_shader_parameter("depth_span", 260.0)
	_tint(front, air["near"])
	var floating := world.add_plane(1.0)
	floating.modulate = Color(air["near"])
	for spot in [Vector2(820, 700), Vector2(1080, 676), Vector2(560, 742), Vector2(1260, 760)]:
		var lily := Sprite2D.new()
		lily.texture = load(LAGOON + "prop_lily.svg")
		lily.scale = Vector2.ONE * 0.5
		lily.position = spot
		floating.add_child(lily)
	_tint(world.add_layer(load(LAGOON + "lagoon_near.svg"), 1.0, 360.0, 1.4, false, -700.0), air["near"])
	_tint(world.add_fill(900.0, 4000.0, Color("#3A9CC8")), air["near"])
	var actors := world.add_plane(1.0)
	actors.modulate = Color(air["actors"])
	_air(world, air, Vector2(280.0, 640.0))
	return {"actors": actors, "track": swimmers, "ground": 592.0, "water": 668.0, "focus": Vector2(520.0, 600.0), "mood": mood}


## Cañón con río y cascada. Las dos orillas están en x = 330 y x = 1050, a la altura 560.
static func canyon(world: ParallaxWorld, mood: StringName = &"day", _options: Dictionary = {}) -> Dictionary:
	var air: Dictionary = MOODS.get(mood, MOODS[&"day"])
	_sky(world, air, -300.0, 560.0)
	_tint(world.add_layer(load(VALLEY + "valley_far.svg"), 0.08, 170.0, 1.0), air["far"])
	_rays(world, air)
	_tint(world.add_layer(load(CANYON + "canyon_far.svg"), 0.25, 420.0, 0.9, false, -700.0), air["far"])
	_tint(world.add_layer(load(CANYON + "canyon_mid.svg"), 0.55, 320.0, 1.1, false, -700.0), air["near"])
	_tint(world.add_water(900.0, 1500.0, 0.8, 70.0), air["near"])
	_tint(world.add_fog(700.0, 800.0, 0.8, Color(1.0, 0.98, 0.94, 0.55)), air["near"])
	_tint(world.add_layer(load(CANYON + "canyon_near.svg"), 1.0, 200.0, 1.4, false, -700.0), air["near"])
	_tint(world.add_fill(1012.0, 4000.0, Color("#8E5238")), air["near"])
	var track := world.add_plane(1.0)
	var actors := world.add_plane(1.0)
	actors.modulate = Color(air["actors"])
	track.modulate = Color(air["actors"])
	_air(world, air, Vector2(250.0, 760.0))
	return {"actors": actors, "track": track, "ground": 560.0, "focus": Vector2(690.0, 560.0), "mood": mood}


## Fiesta del pueblo: cuerdas de banderines tejidos y faroles entre postes, en el plano que se
## indique (normalmente "track", detrás de los personajes).
static func fiesta(plane: Node2D, ground: float, from_x: float = 80.0, to_x: float = 1200.0, lanterns: bool = true) -> Node2D:
	var garlands := _Garlands.new()
	garlands.ground = ground
	garlands.from_x = from_x
	garlands.to_x = to_x
	garlands.lanterns = lanterns
	plane.add_child(garlands)
	return garlands


static func _sky(world: ParallaxWorld, air: Dictionary, top: float, bottom: float) -> void:
	var colors := PackedColorArray()
	for hex: String in air["sky"]:
		colors.append(Color(hex))
	var sky := world.add_sky(colors, PackedFloat32Array(air["stops"]), top, bottom, air["sun"], air["sun_radius"])
	var material := sky.material as ShaderMaterial
	material.set_shader_parameter("sun_color", Color(air["sun_color"]))
	material.set_shader_parameter("glow_color", Color(air["glow"]))
	if int(air["stars"]) > 0:
		var stars := _Stars.new()
		stars.world = world
		stars.count = air["stars"]
		world.add_child(stars)
	var clouds: Array[Texture2D] = []
	for i in 4:
		clouds.append(load(VALLEY + "cloud_%d.svg" % i))
	var before := world.get_child_count()
	world.add_clouds(clouds, [
		{"x": 100.0, "y": 140.0, "texture": 0, "speed": 7.0},
		{"x": 820.0, "y": 80.0, "texture": 1, "speed": 10.0, "scale": 0.9},
		{"x": 1450.0, "y": 200.0, "texture": 2, "speed": 6.0},
		{"x": 2200.0, "y": 120.0, "texture": 3, "speed": 12.0},
		{"x": 2800.0, "y": 230.0, "texture": 1, "speed": 8.0, "scale": 0.75, "alpha": 0.9},
	])
	for index in range(before, world.get_child_count()):
		var cloud := world.get_child(index) as CanvasItem
		cloud.modulate = Color(Color(air["clouds"]), cloud.modulate.a)
	if int(air["stars"]) < 40:
		var birds := BirdFlock.new()
		birds.world = world
		world.add_child(birds)


static func _rays(world: ParallaxWorld, air: Dictionary) -> void:
	if float(air["rays"]) <= 0.0:
		return
	var rays := world.add_rays(air["sun"], air["rays"])
	(rays.material as ShaderMaterial).set_shader_parameter("tint", Color(air["rays_tint"]))


static func _air(world: ParallaxWorld, air: Dictionary, band: Vector2, petals: bool = true) -> void:
	if int(air["motes"]) > 0:
		world.add_child(AmbientField.new().setup(world, AmbientField.Kind.MOTES, air["motes"], 0.9, band))
	if int(air["fireflies"]) > 0:
		world.add_child(AmbientField.new().setup(world, AmbientField.Kind.MOTES, air["fireflies"], 1.0,
			Vector2(band.x + 160.0, band.y), PackedColorArray([Color("#E9FF8A"), Color("#FFF2A0")])))
	if petals and int(air["stars"]) < 40:
		world.add_child(AmbientField.new().setup(world, AmbientField.Kind.PETALS, 5, 1.1, Vector2(band.x - 60.0, band.y + 40.0),
			PackedColorArray([Color("#FF8FB3"), Color("#FFD23F"), Color("#FFFFFF")])))


static func _tint(item: CanvasItem, color: Variant) -> void:
	item.modulate = Color(color) if color is String else color


## Estrellas que titilan, fijas en el cielo.
class _Stars:
	extends Node2D

	var world: ParallaxWorld
	var count := 60
	var _stars: Array[Vector3] = []
	var _time := 0.0

	func _ready() -> void:
		var random := RandomNumberGenerator.new()
		random.seed = 7
		for i in count:
			_stars.append(Vector3(random.randf(), random.randf() * 0.55, random.randf()))

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var view := world.visible_rect()
		for star in _stars:
			var at := view.position + Vector2(star.x * view.size.x, star.y * view.size.y)
			var twinkle := 0.45 + 0.55 * absf(sin(_time * (0.6 + star.z) + star.z * 20.0))
			var size := (2.0 + star.z * 5.0) * (0.7 + 0.3 * twinkle) / world.zoom
			var color := Color(1.0, 0.98, 0.9, twinkle * (1.0 - star.y * 1.2))
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -size), at + Vector2(size * 0.3, -size * 0.3),
				at + Vector2(size, 0), at + Vector2(size * 0.3, size * 0.3), at + Vector2(0, size),
				at + Vector2(-size * 0.3, size * 0.3), at + Vector2(-size, 0), at + Vector2(-size * 0.3, -size * 0.3)]), color)


## Banderines y faroles de fiesta que se mecen con el viento.
class _Garlands:
	extends Node2D

	const COLORS := [Color("#E8833A"), Color("#3B7DD8"), Color("#3FA34D"), Color("#C2185B"), Color("#F2C14E"), Color("#22AEB2")]
	const POLE := Color("#8A5A3A")
	const POLE_DARK := Color("#5A2E16")
	const CORD := Color("#5A2E16")

	var ground := 650.0
	var from_x := 80.0
	var to_x := 1200.0
	var lanterns := true
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var spans := maxi(1, int(round((to_x - from_x) / 380.0)))
		var step := (to_x - from_x) / spans
		var top := ground - 300.0
		for pole in spans + 1:
			var x := from_x + pole * step
			draw_line(Vector2(x, ground + 4.0), Vector2(x, top - 8.0), POLE_DARK, 13.0, true)
			draw_line(Vector2(x, ground + 2.0), Vector2(x, top - 6.0), POLE, 8.0, true)
			draw_circle(Vector2(x, top - 10.0), 9.0, Color("#F2C14E"), true, -1.0, true)
		for span in spans:
			var a := Vector2(from_x + span * step, top)
			var b := Vector2(a.x + step, top)
			var cord := PackedVector2Array()
			for i in 25:
				var t := i / 24.0
				var sag := 4.0 * t * (1.0 - t) * (46.0 + 4.0 * sin(_time * 1.3 + span))
				cord.append(a.lerp(b, t) + Vector2(0, sag))
			draw_polyline(cord, CORD, 3.0, true)
			for i in range(1, 24, 2):
				var at := cord[i]
				var swing := 0.16 * sin(_time * 2.1 + i * 0.7 + span * 1.9)
				var flag := PackedVector2Array([at + Vector2(-13, 0), at + Vector2(13, 0), at + Vector2(0, 30).rotated(swing)])
				draw_colored_polygon(flag, COLORS[(i / 2 + span) % COLORS.size()])
			if lanterns:
				var middle := cord[12]
				var sway := 0.1 * sin(_time * 1.2 + span * 2.3)
				var lantern := middle + Vector2(0, 44).rotated(sway)
				draw_line(middle, lantern + Vector2(0, -16).rotated(sway), CORD, 2.5, true)
				var glow := 0.75 + 0.25 * sin(_time * 3.1 + span * 1.7)
				draw_circle(lantern, 52.0, Color(1.0, 0.82, 0.4, 0.1 * glow), true, -1.0, true)
				draw_circle(lantern, 30.0, Color(1.0, 0.85, 0.45, 0.18 * glow), true, -1.0, true)
				draw_circle(lantern, 17.0, Color("#C2185B"), true, -1.0, true)
				draw_circle(lantern, 13.5, Color("#FFD36B"), true, -1.0, true)
				draw_circle(lantern + Vector2(-4, -4), 4.5, Color(1, 1, 1, 0.7), true, -1.0, true)
