class_name ShortScript
extends RefCounted
## Guion de un corto: en qué mundo ocurre, a qué hora del día y la lista de pasos. Cada corto es
## una clase pequeña que hereda de esta; así puede sumar decorado (`setup`) y acciones propias que
## los pasos llaman con `{"call": "nombre"}`. La guía completa está en scenes/cine/README.md.
##
## Un paso es un diccionario con un verbo. Los pasos corren uno tras otro; con `"join": true` el
## paso no espera y el siguiente empieza a la vez.
##
##   {"cast": &"quwi", "at": [300]}                           pone un personaje (sin "y": en el suelo)
##   {"enter": &"quwi", "from": "left", "to": [420], "hops": 3}   entra saltando (o "run": true)
##   {"move": &"atoq", "to": [700], "time": 1.2, "run": true}     camina o corre hasta un punto
##   {"exit": &"atoq", "to": "right", "run": true}                sale de la pantalla
##   {"play": &"quwi", "clip": &"wave"}                           un gesto del personaje o de biblioteca
##   {"face": &"quwi", "is": &"wow", "time": 1.5}                 una expresión (sin tiempo: se queda)
##   {"emote": &"atoq", "kind": &"alert"}                         un emote
##   {"look": &"quwi", "at": &"atoq"}                             mira a otro personaje o a un punto
##   {"turn": &"atoq", "facing": -1}                              se voltea
##   {"hop": &"quwi", "height": 40}                               un saltito
##   {"say": &"quwi", "text": "¡Hola!", "mood": &"joy"}           globo de diálogo (espera el toque)
##   {"shot": "close", "on": &"quwi"}                             cámara: wide, action o close
##   {"shot": "free", "on": [640, 500], "zoom": 1.2, "time": 1.0} cámara libre
##   {"fx": &"stars", "on": &"quwi", "offset": [0, -120]}         efecto (ver ToonFx)
##   {"shake": 8.0}  {"punch": 0.06}  {"flash": "#FFFFFF"}  {"hit_stop": 0.08}
##   {"cinema": true}  {"light": "#FFE8C8", "time": 1.0}
##   {"title": "El quipu de los saberes", "subtitle": "Prólogo"}  cartel
##   {"sound": &"squeak"}  {"wait": 0.8}  {"call": "scatter_knots"}
##   {"together": [paso, paso, ...]}                              varios pasos a la vez

## El reproductor que está pasando el corto (para las acciones propias).
var player: ShortPlayer
## Datos que cambian de una vez a otra (un texto, un color), que pasa quien abre el corto.
var params: Dictionary = {}


## Identificador del corto.
func id() -> StringName:
	return &""


## Mundo donde ocurre: valley, lagoon o canyon (ver WorldSets).
func place() -> StringName:
	return &"valley"


## Hora del día: day, dusk o night.
func mood() -> StringName:
	return &"day"


## Decorado propio, después de armar el mundo (`player.place` tiene sus planos).
func setup() -> void:
	pass


## Los pasos del corto, en orden.
func beats() -> Array:
	return []
