class_name PuppetSpring
extends RefCounted
## Movimiento secundario de una pieza que cuelga o sobresale (pelo, orejas, cola, chalina, bolsa):
## la punta de la pieza es una masa unida con un resorte a su sitio ideal. Cuando el personaje se
## mueve, salta o gira, la punta llega tarde y se pasa un poco: la pieza se queda atrás, rebota y
## se asienta sola, sin animarla a mano.
##
## Todo se calcula en el espacio del padre del títere, así no depende de la cámara ni del zoom.

## Hueso que mueve.
var bone: StringName
## Hacia dónde apunta la pieza en reposo, en el espacio de su nodo padre.
var axis := Vector2.DOWN
## Largo de la pieza en píxeles del rig.
var length := 60.0
## Fuerza con la que vuelve a su sitio (más alto, más nervioso).
var stiffness := 170.0
## Freno (más alto, se asienta antes).
var damping := 9.0
## Cuánto la dobla el viento de la carrera (segundos de retraso).
var drag := 0.03
## Giro máximo, en radianes.
var limit := 0.7
## Multiplica el giro final (negativo lo invierte).
var gain := 1.0
## Dónde nace la pieza, en su propio espacio (el pivote, salvo en las tiras flexibles).
var origin := Vector2.ZERO
## Giro que resulta, en radianes (ya en el espacio local del hueso).
var angle := 0.0

var _tip := Vector2.ZERO
var _velocity := Vector2.ZERO
var _started := false


## Deja la pieza quieta en su sitio (después de un teletransporte).
func settle() -> void:
	_started = false
	angle = 0.0


## Avanza la simulación. `pivot` es la articulación e `ideal` es donde estaría la punta si la pieza
## fuera rígida, los dos en el espacio del padre del títere. `wind` empuja la punta (píxeles por
## segundo) y `mirrored` indica si el personaje está volteado.
func step(pivot: Vector2, ideal: Vector2, wind: Vector2, mirrored: bool, delta: float) -> float:
	var reach := pivot.distance_to(ideal)
	if reach < 0.001:
		return 0.0
	var target := ideal + wind * drag
	if not _started or _tip.distance_to(target) > reach * 5.0:
		_started = true
		_tip = target
		_velocity = Vector2.ZERO
	# Dos pasos por cuadro: estable también a 30 cuadros por segundo.
	var step_time := minf(delta, 0.05) * 0.5
	for i in 2:
		_velocity += ((target - _tip) * stiffness - _velocity * damping) * step_time
		_tip += _velocity * step_time
	var rest_direction := ideal - pivot
	var direction := _tip - pivot
	if direction.length_squared() < 0.0001:
		return angle
	var turned := rest_direction.angle_to(direction)
	if absf(turned) > limit:
		# Al llegar al tope la punta no se sigue alejando: evita latigazos al soltarse.
		turned = clampf(turned, -limit, limit)
		_tip = pivot + rest_direction.rotated(turned).normalized() * direction.length()
		_velocity *= 0.6
	angle = turned * gain * (-1.0 if mirrored else 1.0)
	return angle
