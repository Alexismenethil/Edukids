class_name SierraBackdrop
extends Control
## Fondo de la Sierra para las pantallas de menú: cielo, sol, nubes que pasan y los cerros en
## capas de la pantalla de inicio. Con «veil» se oscurece para que el contenido resalte.

const SKY_COLORS := [Color("#4FA8DD"), Color("#9FD8F2"), Color("#FFE9C4"), Color("#FFE2B5")]
const CLOUD_A := preload("res://assets/art/backgrounds/sierra/bg_cloud_a.svg")
const CLOUD_B := preload("res://assets/art/backgrounds/sierra/bg_cloud_b.svg")
const FAR := preload("res://assets/art/backgrounds/sierra/bg_sierra_far.svg")
const MID := preload("res://assets/art/backgrounds/sierra/bg_sierra_mid.svg")
const NEAR := preload("res://assets/art/backgrounds/sierra/bg_sierra_near.svg")

## Cuánto bajan los cerros (en píxeles del mundo) para dejar más cielo.
@export var ground_offset := 0.0
## Velo oscuro sobre el paisaje, de 0 a 1.
@export_range(0.0, 1.0) var veil := 0.0
## Muestra la capa cercana (pasto y flores).
@export var show_near := true

var world: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sky := TextureRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.42, 0.7, 1.0])
	gradient.colors = PackedColorArray(SKY_COLORS)
	var sky_texture := GradientTexture2D.new()
	sky_texture.gradient = gradient
	sky_texture.width = 4
	sky_texture.height = 256
	sky_texture.fill_to = Vector2(0, 1)
	sky.texture = sky_texture
	add_child(sky)

	world = Control.new()
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	world.offset_left = -960.0
	world.offset_right = 960.0
	world.offset_top = -960.0 + ground_offset
	world.offset_bottom = ground_offset
	add_child(world)
	_cloud(CLOUD_B, Vector2(250, 330), 0.4, 6.0, 0.85)
	_cloud(CLOUD_A, Vector2(620, 420), 0.6667, 9.0, 1.0)
	_cloud(CLOUD_B, Vector2(1520, 360), 0.6667, 13.0, 1.0)
	_cloud(CLOUD_A, Vector2(1180, 250), 0.42, 7.0, 0.9)
	_layer(FAR, 330.0, 760.0)
	_layer(MID, 580.0, 920.0)
	if show_near:
		_layer(NEAR, 760.0, 970.0)
	if veil > 0.0:
		var shade := ColorRect.new()
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.color = Color(0.16, 0.13, 0.12, veil)
		add_child(shade)


func _cloud(texture: Texture2D, at: Vector2, size: float, speed: float, alpha: float) -> void:
	var cloud := SkyDrifter.new()
	cloud.texture = texture
	cloud.position = at
	cloud.scale = Vector2.ONE * size
	cloud.speed = speed
	cloud.modulate.a = alpha
	world.add_child(cloud)


func _layer(texture: Texture2D, top: float, bottom: float) -> void:
	var layer := TextureRect.new()
	layer.texture = texture
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.position = Vector2(0, top)
	layer.size = Vector2(1920, bottom - top)
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world.add_child(layer)
