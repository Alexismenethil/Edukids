# Personajes: el motor de títeres

Todos los personajes animados (Quwi, el avatar, Atoq y Coco) son **títeres por piezas** que heredan de `Puppet` (`puppet/puppet.gd`). El personaje solo declara sus datos; el motor pone el resto.

| Lo que el motor da gratis | Cómo |
| --- | --- |
| Respira, parpadea y habla | `_breathe`, `_sway`, `PuppetFace` |
| Sigue el dedo con la mirada y gira la cabeza en 2.5D | `_look_layer`, `look_at_point` |
| Pelo, orejas, cola, chalina y bolsa con rebote | `_spring`, `_strip` |
| Se aplasta al caer y levanta polvo | gelatina del cuerpo y la marca `land` |
| Gestos de biblioteca (salto, voltereta, susto, risa, mareo…) | `PuppetMoves` |
| Emotes sobre la cabeza | `emote(&"heart")` |
| Reacciona al toque y a la caricia | `interactive = true` |
| Se entretiene solo cuando nadie lo mira | `fidgets` |

Cada cuadro la pose se arma **sumando capas** sobre la pose de reposo del rig: reposo vivo → ciclos de marcha → clips → cara → mirada → resortes. Por eso un saludo puede sonar mientras el personaje corre, respira y mira el dedo, y al terminar todo vuelve solo a su sitio.

## Crear un personaje nuevo

### 1. Dibujar el SVG por piezas

En `art-src/characters/<nombre>.svg`, cada pieza que se mueve va en un grupo de primer nivel `<g id="part_<pieza>">`. Convenciones que el motor reconoce solo:

- Variantes de **ojos**: `part_eyes_open`, `part_eyes_closed`, `part_eyes_happy`… (la que parpadea es `closed`).
- Variantes de **boca**: `part_mouth_smile`, `part_mouth_open`, `part_mouth_o`…
- **Cejas** separadas (`part_brow_l`, `part_brow_r`) para que se puedan inclinar.
- Lo que deba mecerse (cola, trenza, oreja, chalina) va en su propia pieza, con el pivote donde se une al cuerpo.

Estilo: caricatura vectorial limpia, colores planos, una sombra y una luz por objeto, contorno oscuro.

### 2. Describir el rig

En `art-src/characters/<nombre>.rig.json` se listan los nodos con su padre y su **pivote** (en coordenadas del SVG). Las variantes de ojos van como hijos de un nodo `Eyes` con nombre `Eyes<Variante>`; las bocas, de un nodo `Mouth`:

```json
{"name": "Eyes", "parent": "Body/Head", "pivot": [280, 100]},
{"name": "EyesOpen", "parent": "Body/Head/Eyes", "part": "eyes_open", "pivot": [280, 100]},
{"name": "EyesHappy", "parent": "Body/Head/Eyes", "part": "eyes_happy", "pivot": [280, 100], "visible": false}
```

### 3. Generar el atlas y la escena

Desde `android/`:

```bash
godot --headless --path . -s res://tools/art/build_cutout_rig.gd -- res://art-src/characters/<nombre>.rig.json
```

```bash
godot --headless --path . --import
```

### 4. Escribir el personaje

Un archivo `scenes/characters/<nombre>/<nombre>.gd` que hereda de `Puppet` y llena `_setup()`. Este es un personaje completo:

```gdscript
class_name LlamaCharacter
extends Puppet

const RIG := preload("res://scenes/characters/llama/llama_rig.tscn")

const EXPRESSIONS := {
	&"neutral": {"eyes": &"open", "mouth": &"smile"},
	&"happy": {"eyes": &"happy", "mouth": &"smile", "brows": 4.0},
	&"wow": {"eyes": &"open", "mouth": &"o", "brows": 12.0, "eyes_scale": 1.15},
	&"sad": {"eyes": &"open", "mouth": &"smile", "tilt": 0.3, "mouth_scale": Vector2(0.9, -0.9)},
}

const CLIPS := {
	&"spit": {"group": &"head", "tracks": {
		"head:rot": [[0.2, -0.3, "back"], [0.3, 0.2, "snap"], [0.8, 0.0, "elastic"]],
		"face": [[0.0, "wow"], [0.7, ""]],
		"cue": [[0.3, "spit"]],
	}},
}


func _setup() -> void:
	_use_rig(RIG)
	_bone_map({&"body": "Body", &"head": "Body/Head", &"ear_l": "Body/Head/EarL", &"tail": "Body/Tail"})
	body_center = Vector2(0, -120)
	emote_anchor = Vector2(90, -260)

	_breathe(&"body")
	_sway(&"head", "rot", 0.04, 1.2)
	_spring(&"ear_l", Vector2.UP, 80.0, {"limit": 0.5})
	_strip(&"tail", Vector2.ZERO, Vector2(-120, 40), 8, {"wave": 0.2})
	_spring(&"tail", Vector2(-120, 40), 126.0)

	_face_setup(^"Body/Head", EXPRESSIONS, {"talk": [&"open", &"smile"]})
	_look_layer(&"eyes", Vector2(1.0, 1.0))
	_clip_set(CLIPS)
	fidgets = [&"look_around", &"stretch"]
	tap_reactions = [&"spit", &"laugh", &"flip"]
```

Con eso ya respira, parpadea, mira el dedo, mueve la oreja y la cola, y entiende `play(&"spit")`, `play(&"flip")`, `express(&"wow", 1.0)`, `emote(&"heart")`, `hop()` y `talk(true)`.

### 5. Probarlo en el laboratorio

Agrega el personaje a `CAST` en `lab/character_lab.gd` y ábrelo (solo en compilaciones de depuración):

```bash
godot --path . -- --lab
```

El laboratorio muestra un botón por cada gesto, cara y emote, y deja correr, hablar, voltear y tocar al personaje. Con `--demo-lab` recorre a todos solo (útil para grabar).

## Referencia rápida

### Clips

Un clip es un diccionario con pistas de claves `[tiempo, valor, curva]`. Los valores son **desplazamientos desde el reposo**, así se suman entre sí.

| Pista | Qué mueve |
| --- | --- |
| `hueso:rot`, `hueso:x`, `hueso:y`, `hueso:pos` | Giro (radianes) y posición (píxeles del rig) |
| `hueso:scale`, `hueso:sx`, `hueso:sy` | Escala (reposo = 1) |
| `lift`, `lean`, `spin`, `squash`, `shift` | El cuerpo entero: altura, inclinación, voltereta, aplastamiento y desplazamiento |
| `look` | La mirada: `[1, 0]` a la derecha, `[0, -1]` arriba |
| `param:nombre` | Un valor propio del personaje (lo lee con `param(&"nombre")`) |
| `face` | Pone una expresión (`""` la quita) |
| `cue` | Emite la señal `cue` (la escena pone el efecto) |
| `emote` | Saca un emote |

Curvas (`PuppetEase`): `linear`, `in`, `out`, `inout` (por omisión), `cubic`, `snap`, `back`, `elastic`, `bounce`, `hold`.

Opciones del clip: `group` (un clip nuevo apaga al que suena en su grupo), `mute` (huesos cuya respiración y carrera se apagan mientras dura; `&"body"` apaga el rebote del cuerpo), `loop`, `fade_in`, `fade_out` y `length`.

### Expresiones

Vocabulario común que usan los gestos de biblioteca: `neutral`, `happy`, `joy`, `laugh`, `wow`, `think`, `worry`, `sad`, `ouch`, `dizzy`, `proud`, `determined`, `sleepy`. Si a un personaje le falta alguna, conserva la cara que tenía.

Campos: `eyes`, `mouth`, `brows` (sube las cejas), `tilt` (positivo: preocupado; negativo: decidido), `eyes_scale`, `mouth_scale` (negativa voltea la boca), `show` / `hide` (extras como el rubor) y `blink`.

### Ciclos de marcha

`_cycle(&"run", {...})` define pistas periódicas (`sin`, `cos`, `abs`, `half`) que avanzan con `set_cycle(&"run", velocidad)`. El campo `travel` es la velocidad «de mentira» con la que el pelo y la cola se van hacia atrás cuando el personaje corre en su sitio. Cada pisada emite la marca `step`.

### Efectos

Los efectos de caricatura están en `scenes/fx/toon_fx.gd` (`ToonFx.puff`, `stars`, `sparkles`, `impact`, `ring`, `splash`, `hearts`, `leaves`, `confetti`). En las escenas de juego, `MechanicStage.watch(personaje)` pone solo el polvo de los aterrizajes y pisotones.
