class_name PuppetEase
extends RefCounted
## Curvas de aceleración de los clips: cómo se llega de una pose a la siguiente. Cada clave de un
## clip nombra la curva con la que se llega a ella (por omisión, `inout`).
##
##   linear   velocidad pareja             in       arranca despacio
##   out      frena al llegar              inout    arranca y frena suave
##   cubic    frena fuerte al llegar       snap     llega casi de golpe y se asienta
##   back     se pasa un poco y vuelve     elastic  rebota como un resorte
##   bounce   rebota contra el final       hold     espera y cambia de golpe

const BACK := 1.70158


static func apply(kind: StringName, t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	match kind:
		&"linear":
			return t
		&"in":
			return t * t
		&"out":
			return 1.0 - (1.0 - t) * (1.0 - t)
		&"cubic":
			return 1.0 - pow(1.0 - t, 3.0)
		&"snap":
			return 1.0 if t >= 1.0 else 1.0 - pow(2.0, -10.0 * t)
		&"back":
			var u := t - 1.0
			return 1.0 + (BACK + 1.0) * u * u * u + BACK * u * u
		&"elastic":
			if t <= 0.0 or t >= 1.0:
				return t
			return pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * TAU / 3.0) + 1.0
		&"bounce":
			return _bounce(t)
		&"hold":
			return 1.0 if t >= 1.0 else 0.0
		_:
			return 0.5 - 0.5 * cos(t * PI)


static func _bounce(t: float) -> float:
	const N := 7.5625
	const D := 2.75
	if t < 1.0 / D:
		return N * t * t
	if t < 2.0 / D:
		t -= 1.5 / D
		return N * t * t + 0.75
	if t < 2.5 / D:
		t -= 2.25 / D
		return N * t * t + 0.9375
	t -= 2.625 / D
	return N * t * t + 0.984375
