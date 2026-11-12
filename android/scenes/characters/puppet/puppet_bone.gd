class_name PuppetBone
extends RefCounted
## Una pieza animable del rig: guarda su pose de reposo y junta, en cada cuadro, lo que le suman
## las capas (respiración, carrera, clips, mirada, cara y resortes).

var node: Node2D
var rest_position := Vector2.ZERO
var rest_rotation := 0.0
var rest_scale := Vector2.ONE
## Lo que se suma a la pose de reposo en este cuadro.
var position := Vector2.ZERO
var rotation := 0.0
var scale := Vector2.ONE


func _init(target: Node2D = null) -> void:
	node = target
	if node:
		rest_position = node.position
		rest_rotation = node.rotation
		rest_scale = node.scale


func reset() -> void:
	position = Vector2.ZERO
	rotation = 0.0
	scale = Vector2.ONE


## Atenúa lo acumulado hasta ahora (los clips que «silencian» un hueso).
func damp(keep: float) -> void:
	position *= keep
	rotation *= keep
	scale = Vector2.ONE.lerp(scale, keep)


func apply() -> void:
	node.position = rest_position + position
	node.rotation = rest_rotation + rotation
	node.scale = rest_scale * scale
