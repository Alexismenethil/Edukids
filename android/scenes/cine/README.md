# Cine: escenarios, mundos y cortos

Todo lo que hace que el juego se vea como una película vive aquí y en `scenes/world/`, y lo comparten las mecánicas de juego y los cortos.

| Pieza | Qué hace |
| --- | --- |
| `CineStage` (`cine_stage.gd`) | Escenario base: un mundo por capas con cámara y herramientas de dirección |
| `WorldSets` (`scenes/world/world_sets.gd`) | Mundos listos (valle, laguna, cañón) a tres horas del día |
| `ShortPlayer` (`short_player.gd`) | Reproduce un corto: pone a los personajes y ejecuta el guion paso a paso |
| `ShortScript` (`short_script.gd`) | Base de cada guion |
| `Shorts` (`shorts/shorts.gd`) | Catálogo de cortos del juego |
| `ShortLint` (`short_lint.gd`) | Revisa un guion sin reproducirlo (lo usan las pruebas) |
| `Cast` (`scenes/characters/cast.gd`) | Elenco: crea cualquier personaje por su identificador |

## Herramientas de dirección

Las tiene cualquier escena que herede de `CineStage` (todas las mecánicas y los cortos):

| Llamada | Efecto |
| --- | --- |
| `frame(Shot.ACTION)`, `close_on(punto)`, `shoot(punto, zoom)` | Encuadres: acción, primer plano y cámara libre |
| `shake(8.0)` | Sacudida |
| `punch(0.06)` | Golpe de zoom: la cámara se acerca un instante |
| `hit_stop(0.08)` | Pausa de impacto: el mundo se congela un momento |
| `flash(color)` | Destello suave (un solo pulso, nunca parpadeos) |
| `cinema(true)` | Barras de cine para los momentos grandes |
| `light(color)` | Luz del mundo: fría en el peligro, dorada en la victoria |
| `watch(personaje)` | Polvo automático cuando el personaje cae o pisa fuerte |

## Mundos

```gdscript
var place := WorldSets.build(world, &"valley", &"dusk")
place["actors"].add_child(personaje)
personaje.position = Vector2(640, place["ground"])
```

| Mundo | Qué es |
| --- | --- |
| `valley` | Sierra: valle del Qhapaq Ñan; se repite sin fin, sirve para correr |
| `jungle` | Selva: cerros de bosque entre la neblina, palmeras, lianas y sendero de tierra; corre sin fin |
| `coast` | Costa: mar con islotes guaneros y caballitos de totora, dunas y arena firme; corre sin fin |
| `lagoon` | Laguna con muelle, totoras y nenúfares |
| `canyon` | Cañón con río y cascada |

| Hora | Cómo se ve |
| --- | --- |
| `day` | Día despejado con polen y pétalos |
| `dusk` | Atardecer dorado y violeta, primeras estrellas y luciérnagas |
| `night` | Noche azul con luna, estrellas que titilan y luciérnagas |

`WorldSets.fiesta(plano, suelo)` cuelga banderines tejidos y faroles entre postes.

Los tres mundos que corren comparten medidas y capas (`far`, `mid`, `near`, `ground`, `front`), así una mecánica escrita para uno funciona en los otros. `WorldSets.REGION_WORLDS` dice cuál es el de cada capítulo y `Cast.guide_of(capítulo)` da su guía. Las capas se pintan con `tools/art/worlds/` (`valley.py`, `jungle.py`, `coast.py`).

## Escribir un corto

Un corto es una clase pequeña que hereda de `ShortScript`: dice en qué mundo ocurre, a qué hora, y devuelve la lista de pasos.

```gdscript
class_name ShortGreeting
extends ShortScript


func id() -> StringName:
	return &"greeting"


func place() -> StringName:
	return &"lagoon"


func mood() -> StringName:
	return &"dusk"


func beats() -> Array:
	return [
		{"cinema": true},
		{"cast": &"quwi", "at": [200]},
		{"cast": &"coco", "at": [900, 668], "behind": true},
		{"enter": &"quwi", "from": "left", "to": [260], "hops": 3},
		{"look": &"quwi", "at": &"coco"},
		{"shot": "close", "on": &"coco"},
		{"play": &"coco", "clip": &"yawn"},
		{"say": &"quwi", "text": "¡Buenas tardes, Coco!", "mood": &"joy"},
		{"fx": &"splash", "on": &"coco", "offset": [120, 0]},
		{"shot": "wide", "time": 1.2},
		{"cinema": false},
	]
```

Después se agrega al catálogo en `shorts/shorts.gd` y se prueba (solo en compilaciones de depuración):

```bash
godot --path . -- --short=greeting
```

Con `--short=` los diálogos avanzan solos (sirve para grabar). También se puede abrir desde el laboratorio (`--lab`, sección «Cortos»).

### Pasos

Los pasos corren uno tras otro. Con `"join": true` el paso no espera: el siguiente empieza a la vez.

| Paso | Qué hace |
| --- | --- |
| `{"cast": &"quwi", "at": [300]}` | Pone un personaje. Sin `y`, pisa el suelo. Opciones: `as` (otro nombre), `facing`, `scale`, `hidden`, `behind` |
| `{"enter": &"quwi", "from": "left", "to": [420], "hops": 3}` | Entra desde un borde, a saltitos o con `"run": true` |
| `{"move": &"atoq", "to": [700], "time": 1.2, "run": true}` | Va hasta un punto |
| `{"exit": &"atoq", "to": "right", "run": true}` | Sale de la pantalla |
| `{"play": &"quwi", "clip": &"wave"}` | Un gesto propio o de la biblioteca |
| `{"face": &"quwi", "is": &"wow", "time": 1.5}` | Una expresión (sin `time` se queda puesta) |
| `{"emote": &"atoq", "kind": &"alert"}` | Un emote sobre la cabeza |
| `{"look": &"quwi", "at": &"atoq"}` | Mira a un personaje o a un punto `[x, y]`; con `null` deja de mirar |
| `{"turn": &"atoq", "facing": -1}` | Se voltea |
| `{"hop": &"quwi", "height": 40}` | Un saltito |
| `{"say": &"quwi", "text": "…", "mood": &"joy"}` | Globo de diálogo sobre su cabeza; espera el toque |
| `{"shot": "close", "on": &"quwi"}` | Cámara: `wide`, `action`, `close` o `free` (con `zoom` y `time`) |
| `{"fx": &"stars", "on": &"quwi", "offset": [0, -120]}` | Efecto: `puff`, `stars`, `sparkles`, `impact`, `ring`, `splash`, `hearts`, `leaves`, `streaks`, `confetti` |
| `{"shake": 8.0}`, `{"punch": 0.06}`, `{"hit_stop": 0.08}`, `{"flash": "#FFFFFF"}` | Golpes de cámara |
| `{"cinema": true}`, `{"light": "#FFE8C8", "time": 1.0}` | Barras de cine y luz |
| `{"title": "…", "subtitle": "…"}` | Cartel centrado |
| `{"sound": &"squeak"}` | Un sonido del juego (`squeak` o `knots`) |
| `{"wait": 0.8}` | Pausa |
| `{"together": [paso, paso]}` | Varios pasos a la vez; sigue cuando todos terminan |
| `{"call": "mi_accion", "time": 0.7}` | Llama a un método del guion (para utilería y acciones a medida) |

### Reglas de la narrativa

- Máximo **4 globos** por corto, de una o dos líneas (las pruebas lo verifican).
- Siempre se puede saltar; los cortos no tienen voces: todo se cuenta con gestos, emotes y cámara.
- El avatar del estudiante se pide con `{"cast": &"avatar"}` y sale con su propio aspecto.

### Acciones a medida y utilería

Un guion puede definir métodos y llamarlos con `call`. `player` da acceso al reproductor: `player.actor(&"sisa")`, `player.actors` (plano de los personajes), `player.track`, `player.ground_y` y `params` (datos que pasa quien abre el corto). `setup()` corre después de armar el mundo y sirve para el decorado.

`props/quipu_prop.gd` es el quipu de los saberes: se mece, sigue a un personaje (`hold`) y suelta sus nudos (`knot_points`).

## Cortos del juego

| Corto | Cuándo se ve | Qué pasa |
| --- | --- | --- |
| `prologue` | Al crear el personaje por primera vez y desde el botón «Historia» del mapa | Fiesta en Huamanga al atardecer: Mama Sisa muestra el quipu, Atoq lo jala y los nudos vuelan |
| `rope` | Al superar un desafío final (AD, A o B) | De noche, el avatar entrega el nudo y la cuerda vuelve al quipu; Kuntur cruza el cielo |
| `selva` | Listo para la llegada al capítulo 2 (por ahora, desde el laboratorio o `--short=selva`) | Tunki recibe al avatar con su baile y Quwi le pasa la posta |
| `costa` | Listo para la llegada al capítulo 3 (por ahora, desde el laboratorio o `--short=costa`) | Al atardecer, Humbi llega deslizándose de panza y Tunki se despide |
