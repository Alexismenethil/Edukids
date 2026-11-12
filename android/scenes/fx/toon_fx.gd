class_name ToonFx
extends RefCounted
## Efectos de caricatura listos para usar en cualquier escena: se llaman con el nodo donde deben
## aparecer y el punto, y se borran solos. Todos son formas vectoriales (ToonBurst).
##
##   ToonFx.puff(actors, pies)            polvo al despegar, caer o frenar
##   ToonFx.stars(actors, punto)          estrellas que saltan (acierto, premio)
##   ToonFx.sparkles(actors, punto)       brillitos que titilan
##   ToonFx.impact(actors, punto)         destello de golpe con rayas
##   ToonFx.ring(actors, punto)           onda que se abre
##   ToonFx.splash(actors, punto)         salpicadura de agua con ondas
##   ToonFx.hearts / leaves / crumbs      corazones, hojas al viento, migas
##   ToonFx.confetti(capa, ancho)         papel picado que cae por toda la pantalla

const TEXTILE := [Color("#E8833A"), Color("#3B7DD8"), Color("#3FA34D"), Color("#C2185B"), Color("#F2C14E"),
	Color("#22AEB2"), Color("#8A63D2")]
const DUST := Color("#EAD9BC")
const GOLD := Color("#F2C14E")
const OUTLINE := Color("#3A2418")


static func _burst(parent: Node, at: Vector2) -> ToonBurst:
	var burst := ToonBurst.new()
	burst.position = at
	parent.add_child(burst)
	return burst


## Nubecitas de polvo que se abren a los lados. `push` las empuja (por ejemplo, hacia atrás).
static func puff(parent: Node, at: Vector2, amount: int = 6, size: float = 15.0, push: Vector2 = Vector2.ZERO,
		color: Color = DUST) -> void:
	var burst := _burst(parent, at)
	for i in amount:
		var side := -1.0 if i % 2 == 0 else 1.0
		var spread := randf_range(0.35, 1.0)
		burst.add({"shape": ToonBurst.Shape.PUFF, "pos": Vector2(side * randf_range(2.0, 14.0), randf_range(-6.0, 2.0)),
			"vel": Vector2(side * spread * 120.0, -randf_range(20.0, 70.0)) + push, "gravity": -40.0, "drag": 3.2,
			"life": randf_range(0.45, 0.75), "size": size * randf_range(0.55, 1.0), "grow": 0.9,
			"color": Color(color, 0.92), "fade": 0.35, "delay": i * 0.012})


## Estrellas doradas que saltan con giro.
static func stars(parent: Node, at: Vector2, amount: int = 8, size: float = 13.0, color: Color = GOLD) -> void:
	Sounds.play(&"star", randf_range(0.96, 1.06), -6.0)
	var burst := _burst(parent, at)
	for i in amount:
		var angle := -PI * 0.5 + randf_range(-1.25, 1.25)
		burst.add({"shape": ToonBurst.Shape.STAR, "pos": Vector2.ZERO,
			"vel": Vector2.from_angle(angle) * randf_range(190.0, 380.0), "gravity": 620.0, "drag": 0.8,
			"life": randf_range(0.7, 1.05), "size": size * randf_range(0.6, 1.1), "color": color,
			"outline": Color(OUTLINE, 0.85), "spin": randf_range(-7.0, 7.0), "turn": randf() * TAU, "fade": 0.7})


## Brillitos de cuatro puntas que titilan alrededor de un punto.
static func sparkles(parent: Node, at: Vector2, amount: int = 10, radius: float = 70.0,
		color: Color = Color("#FFF3B0")) -> void:
	var burst := _burst(parent, at)
	for i in amount:
		var offset := Vector2.from_angle(randf() * TAU) * radius * sqrt(randf())
		burst.add({"shape": ToonBurst.Shape.SPARK, "pos": offset, "vel": offset.normalized() * 30.0 + Vector2(0, -22.0),
			"life": randf_range(0.45, 0.8), "size": randf_range(9.0, 18.0), "color": color, "delay": randf() * 0.35,
			"fade": 1.0})


## Destello de golpe: estrella de puntas, rayas hacia afuera y estrellitas.
static func impact(parent: Node, at: Vector2, size: float = 46.0, color: Color = Color("#FFD75E")) -> void:
	Sounds.play(&"impact", 1.0, -3.0)
	var burst := _burst(parent, at)
	burst.add({"shape": ToonBurst.Shape.POW, "pos": Vector2.ZERO, "life": 0.34, "size": size, "color": color,
		"outline": Color(OUTLINE, 0.9), "turn": randf() * TAU, "fade": 0.55})
	for i in 8:
		burst.add({"shape": ToonBurst.Shape.STREAK, "pos": Vector2.ZERO, "life": 0.3, "size": size * 1.5,
			"color": Color(1, 1, 1, 0.95), "turn": TAU * i / 8.0 + randf_range(-0.12, 0.12), "width": 5.0, "fade": 0.3})


## Onda que se abre (aterrizajes fuertes, premios). `flat` la achata como un charco.
static func ring(parent: Node, at: Vector2, size: float = 30.0, color: Color = Color(1, 1, 1, 0.9), flat: float = 1.0,
		grow: float = 2.4, life: float = 0.42) -> void:
	_burst(parent, at).add({"shape": ToonBurst.Shape.RING, "pos": Vector2.ZERO, "life": life, "size": size, "grow": grow,
		"color": color, "width": 9.0, "flat": flat, "fade": 0.3})


## Rayas de velocidad que salen de un punto.
static func streaks(parent: Node, at: Vector2, amount: int = 10, size: float = 90.0, color: Color = Color(1, 1, 1, 0.9)) -> void:
	var burst := _burst(parent, at)
	for i in amount:
		burst.add({"shape": ToonBurst.Shape.STREAK, "pos": Vector2.ZERO, "life": randf_range(0.25, 0.4), "size": size,
			"color": color, "turn": TAU * i / amount + randf_range(-0.15, 0.15), "width": 6.0, "fade": 0.3})


## Salpicadura: gotas que saltan y ondas en la superficie.
static func splash(parent: Node, at: Vector2, amount: int = 14, power: float = 1.0) -> void:
	Sounds.play(&"splash", randf_range(0.92, 1.08), -4.0 if amount >= 20 else -9.0)
	var burst := _burst(parent, at)
	for i in amount:
		var angle := -PI * 0.5 + randf_range(-0.75, 0.75)
		burst.add({"shape": ToonBurst.Shape.DROP, "pos": Vector2(randf_range(-18.0, 18.0), 0.0),
			"vel": Vector2.from_angle(angle) * randf_range(200.0, 430.0) * power, "gravity": 820.0,
			"life": randf_range(0.6, 0.95), "size": randf_range(4.0, 8.5), "color": Color("#D8F3FB") if i % 3 else Color("#8FD6EE"),
			"fade": 0.75})
	for i in 2:
		burst.add({"shape": ToonBurst.Shape.RING, "pos": Vector2.ZERO, "life": 0.7, "size": 22.0 * power, "grow": 3.0,
			"color": Color(1, 1, 1, 0.75), "width": 6.0, "flat": 0.28, "delay": i * 0.16, "fade": 0.2})


static func hearts(parent: Node, at: Vector2, amount: int = 5) -> void:
	var burst := _burst(parent, at)
	for i in amount:
		burst.add({"shape": ToonBurst.Shape.HEART, "pos": Vector2(randf_range(-30.0, 30.0), 0.0),
			"vel": Vector2(randf_range(-40.0, 40.0), -randf_range(70.0, 130.0)), "gravity": -30.0, "drag": 0.6,
			"life": randf_range(0.9, 1.3), "size": randf_range(10.0, 17.0), "color": Color("#F0566E") if i % 2 else Color("#F48FA0"),
			"delay": i * 0.09, "fade": 0.6})


## Hojas que se lleva el viento hacia `wind`.
static func leaves(parent: Node, at: Vector2, amount: int = 16, wind: Vector2 = Vector2(340.0, -40.0)) -> void:
	var burst := _burst(parent, at)
	var colors := [Color("#7FC35C"), Color("#B5D84E"), Color("#F2C14E")]
	for i in amount:
		burst.add({"shape": ToonBurst.Shape.LEAF, "pos": Vector2(randf_range(-40.0, 40.0), randf_range(-60.0, 60.0)),
			"vel": wind * randf_range(0.7, 1.25) + Vector2(0, randf_range(-60.0, 60.0)), "gravity": 60.0,
			"life": randf_range(1.1, 1.7), "size": randf_range(8.0, 14.0), "color": colors[i % colors.size()],
			"spin": randf_range(-6.0, 6.0), "turn": randf() * TAU, "delay": randf() * 0.4, "fade": 0.7})


static func crumbs(parent: Node, at: Vector2, amount: int = 10, color: Color = GOLD) -> void:
	var burst := _burst(parent, at)
	for i in amount:
		burst.add({"shape": ToonBurst.Shape.CHUNK, "pos": Vector2.ZERO,
			"vel": Vector2.from_angle(-PI * 0.5 + randf_range(-1.3, 1.3)) * randf_range(90.0, 210.0), "gravity": 560.0,
			"life": randf_range(0.45, 0.7), "size": randf_range(4.0, 8.0), "color": color, "spin": randf_range(-9.0, 9.0),
			"fade": 0.6})


## Papel picado con los colores del tejido: cae desde arriba a todo lo ancho.
static func confetti(parent: Node, width: float, amount: int = 70, top: float = -30.0) -> ToonBurst:
	Sounds.play(&"sparkle", 1.0, -5.0)
	var burst := _burst(parent, Vector2.ZERO)
	burst.z_index = 8
	for i in amount:
		burst.add({"shape": ToonBurst.Shape.PAPER, "pos": Vector2(randf() * width, top - randf() * 120.0),
			"vel": Vector2(randf_range(-50.0, 50.0), randf_range(140.0, 260.0)), "gravity": 70.0, "drag": 0.5,
			"life": randf_range(2.6, 3.8), "size": randf_range(7.0, 12.0), "color": TEXTILE[i % TEXTILE.size()],
			"spin": randf_range(-4.0, 4.0), "turn": randf() * TAU, "delay": randf() * 1.1, "fade": 0.85})
	return burst
