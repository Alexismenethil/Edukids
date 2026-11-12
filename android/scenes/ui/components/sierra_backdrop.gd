class_name SierraBackdrop
extends Control
## Fondo de la Sierra para las pantallas de menú: el valle del Qhapaq Ñan con su cielo, el sol,
## nubes que pasan, pajaritos, polen que flota y el pasto que se mece con el viento. Usa las mismas
## capas que la persecución, así todo el juego se ve como un solo mundo. Con «veil» se oscurece
## para que el contenido resalte.

const WORLD := "res://assets/art/worlds/valley/"

## Cuánto bajan los cerros (en píxeles) para dejar más cielo.
@export var ground_offset := 0.0
## Velo oscuro sobre el paisaje, de 0 a 1.
@export_range(0.0, 1.0) var veil := 0.0
## Muestra el primer plano (pasto y flores que se mecen).
@export var show_near := true
## Muestra el camino inca empedrado (el mapa dibuja su propio camino).
@export var show_road := true
## El valle se desliza despacio (unidades por segundo).
@export var drift := 0.0

var world: ParallaxWorld


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	world = ParallaxWorld.new()
	add_child(world)
	world.add_sky(PackedColorArray([Color("#4FAEEA"), Color("#9AD6F2"), Color("#FFF0D6"), Color("#FFD9AE")]),
		PackedFloat32Array([0.0, 0.45, 0.78, 1.0]), -300.0, 600.0, Vector2(0.8, 395.0), 44.0)
	var clouds: Array[Texture2D] = []
	for i in 4:
		clouds.append(load(WORLD + "cloud_%d.svg" % i))
	world.add_clouds(clouds, [
		{"x": 100.0, "y": 140.0, "texture": 0, "speed": 7.0},
		{"x": 820.0, "y": 80.0, "texture": 1, "speed": 10.0, "scale": 0.9},
		{"x": 1450.0, "y": 200.0, "texture": 2, "speed": 6.0},
		{"x": 2200.0, "y": 120.0, "texture": 3, "speed": 12.0},
		{"x": 2800.0, "y": 230.0, "texture": 1, "speed": 8.0, "scale": 0.75, "alpha": 0.9},
	])
	var birds := BirdFlock.new()
	birds.world = world
	world.add_child(birds)
	world.add_layer(load(WORLD + "valley_far.svg"), 0.1, 250.0, 1.0)
	world.add_rays(Vector2(0.8, 395.0), 0.12)
	world.add_layer(load(WORLD + "valley_mid.svg"), 0.3, 410.0, 1.25)
	world.add_fog(560.0, 640.0, 0.45, Color(1.0, 0.97, 0.9, 0.5))
	world.add_layer(load(WORLD + "valley_near.svg"), 0.6, 300.0, 1.5)
	if show_road:
		world.add_layer(load(WORLD + "valley_ground.svg"), 1.0, 596.0, 2.0)
	else:
		var meadow := world.add_fill(640.0, 4000.0, Color("#6DBE58"))
		meadow.material = null
	if show_near:
		var front := world.add_layer(load(WORLD + "valley_front.svg"), 1.35, 650.0, 1.5)
		world.sway(front, 5.0, 1.4)
	world.add_fill(814.0, 4000.0, Color("#2F7740"))
	world.add_child(AmbientField.new().setup(world, AmbientField.Kind.MOTES, 22, 0.9, Vector2(300, 700)))
	world.add_child(AmbientField.new().setup(world, AmbientField.Kind.PETALS, 5, 1.1, Vector2(220, 760),
		PackedColorArray([Color("#FF8FB3"), Color("#FFD23F"), Color("#FFFFFF")])))
	if veil > 0.0:
		var shade := ColorRect.new()
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.color = Color(0.16, 0.13, 0.12, veil)
		add_child(shade)
	resized.connect(_frame)
	_frame()


## Encuadre fijo: el valle llena la pantalla y baja con `ground_offset`.
func _frame() -> void:
	var view := size if size.x > 64.0 else Vector2(1280, 800)
	world.view_size = view
	world.zoom = 1.0
	world.focus = Vector2(640, 400)
	world.screen_focus = Vector2(view.x * 0.5, view.y * 0.5 + ground_offset)
	world.refresh()


func _process(delta: float) -> void:
	if drift != 0.0 and world:
		world.cam_x += drift * delta
