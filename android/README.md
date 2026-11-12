# EduKids: juego para Android (Godot)

Proyecto del videojuego en **Godot 4.7.2** con GDScript, 2D y renderizador Compatibility (OpenGL ES 3.0). Sigue **Clean Architecture** ([ADR-010](../docs/01-analisis-de-sistema/decisiones/ADR-010-clean-architecture.md)): las reglas del juego viven en el dominio y no dependen de Godot, de la base de datos ni de la red.

![Pantalla de inicio en Android](../docs/05-diseno-del-juego/img/pantalla-de-inicio.jpg)

## Requisitos

| Herramienta | Versión | Para qué |
| --- | --- | --- |
| Godot | 4.7.2 estable (sin .NET) | Editor y ejecución |
| Plantillas de exportación | 4.7.2 (Android) | Generar el APK |
| Android SDK | build-tools 34 o superior | Firmar el APK |
| JDK | 17 | Herramientas de Android |
| GdUnit4 | 6.2.3 (incluido en `addons/`) | Pruebas |

En macOS: `brew install --cask godot`. Las plantillas se instalan desde el editor en **Editor → Administrar plantillas de exportación**.

## Ejecutar

1. Abre `android/project.godot` con Godot.
2. Presiona **F5**. La pantalla de inicio se ve en 1280 × 800 y se adapta a otras proporciones.

La primera vez, el botón **Docente** abre la configuración inicial: institución, secciones y PIN docente. Después, el docente registra a sus estudiantes y cada uno entra con su personaje y su PIN.

### Modo demostración

Para grabar videos o probar los recorridos sin tocar la pantalla. Solo funciona en compilaciones de depuración. Los datos de demostración se guardan en una base aparte (`user://edukids_demo.db`) que se borra en cada arranque, así nunca se mezclan con los datos reales.

| Opción | Qué hace |
| --- | --- |
| `--demo` | Pantalla de inicio: toca a Quwi, Jugar y avanza el diálogo |
| `--demo-data` | Usa un aula ficticia: «Escuela de demostración», secciones A y B, 11 estudiantes (PIN docente 2580; PIN de estudiantes 2468) |
| `--demo-empty` | Usa una base de demostración vacía, como una tablet recién instalada |
| `--demo-profiles` | Elige un perfil, escribe un PIN incorrecto y luego el correcto (con `--demo-data`) |
| `--demo-editor` | Un estudiante sin personaje lo crea (con `--demo-data`) |
| `--demo-teacher` | PIN docente, lista de estudiantes y formulario para agregar uno (con `--demo-data`) |
| `--demo-setup` | Configuración inicial completa (con `--demo-empty`) |
| `--demo-map` | Mapa de la Sierra: entra a Huamanga, abre la ficha de un nivel y lo juega (con `--demo-data`) |
| `--demo-chase` | Persecución de Atoq: saltos con vuelta, tropiezos, un nudo robado y el arco tejido |
| `--demo-caiman` | Coco, el caimán glotón: saltos por la fruta, mordiscos, un nudo perdido y el paseo en su lomo |
| `--demo-bridge` | El puente colgante: tablas que caen del cielo, viento, una caída al río con el rescate del cóndor y el arco iris |
| `--demo-classic` | Tarjetas con Quwi y Atoq que se asoma por el costado |
| `--demo-gameover` | Responde todo mal hasta perder las tres vidas |
| `--demo-final` | Desafío final: portada, respuestas guardadas y calificación con la revisión |
| `--lab` | Laboratorio de personajes: cada títere con sus gestos, caras y emotes, para tocarlo y probarlo; también abre los cortos |
| `--short=prologue` | Reproduce un corto del catálogo (`prologue`, `rope`, `selva`, `costa`); los diálogos avanzan solos |
| `--demo-chapter=selva` | Con un modo de nivel, lo abre con el mundo y el guía de ese capítulo (`selva` o `costa`) |
| `--demo-lab` | El laboratorio se recorre solo: todos los personajes con sus gestos, la carrera y un toque |

Los modos de nivel se usan con `--demo-data` y juegan el primer nivel que tenga esa mecánica; con `--demo-area=language` o `--demo-area=science` se elige el área. En la base de demostración se completan solos los niveles anteriores del módulo, para que el elegido esté abierto.

```bash
godot --path android -- --demo-data --demo-profiles
```

En un emulador o en la tablet, el lanzador de Android no pasa argumentos: en una compilación de depuración se escriben en `user://demo_args.txt` y se vuelve a abrir la app (para volver al juego normal, se borra el archivo):

```bash
adb shell "run-as pe.edu.unsch.edukids sh -c 'echo --demo-data --demo-chase > /data/user/0/pe.edu.unsch.edukids/files/demo_args.txt'"
```

Grabar un video con el Movie Maker de Godot:

```bash
godot --path android --write-movie builds/demo.avi --fixed-fps 30 --quit-after 450 -- --demo-data --demo-profiles
```

## Pruebas

Desde `android/`:

```bash
godot --headless --path . --import
```

```bash
godot --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests -c
```

```bash
bash tests/architecture/check_dependencies.sh
```

| Carpeta | Qué prueba |
| --- | --- |
| `tests/unit/domain` | Medidor de peligro (RN-13), vidas y game over (RN-14), estrellas (RN-11), escala AD/A/B/C (RN-12), orden de los niveles (RN-18), escenas narrativas, PIN, avatar, evaluadores de cada tipo de ítem, respuestas escritas y numéricas, la sesión del nivel y el desafío final |
| `tests/unit/application` | Casos de uso con repositorios falsos: aula, mapa del capítulo, niveles cerrados, respuestas, pistas, game over, desafío final con intentos y continuar un nivel |
| `tests/unit/presentation` | Presentadores y modelos de vista: mapa, parada, nivel, vidas, game over y calificación |
| `tests/unit/scenes` | Motor de títeres (curvas, clips, reproducción, resortes y gestos) y revisión de datos: elenco, clips y caras de cada personaje, mundos de cada región y guiones de los cortos |
| `tests/integration` | JSON, paquetes incluidos y sus senderos, SQLite (aula, intentos, respuestas, game over, calificaciones y la migración 002), hash del PIN, reloj, aleatoriedad e identificadores |
| `tests/architecture` | Regla de dependencias entre capas (RNF-15, CA-20) |

El CI ([`.github/workflows/android.yml`](../.github/workflows/android.yml)) ejecuta la verificación de capas y las pruebas en cada cambio dentro de `android/`. Los reportes de GdUnit4 se guardan en `reports/` (ignorado por Git).

## Mapa y mecánicas

Después de entrar con su PIN, el estudiante llega al **mapa de la Sierra**: el Qhapaq Ñan une Huamanga, Quinua, Pampa Galeras y Vilcashuamán. Las paradas sin contenido muestran un candado. En **Huamanga** hay un sendero por área (una cuerda del quipu) con un nudo por nivel: los niveles de cada módulo se abren en orden y el desafío final se abre al completarlos (RN-18).

| Mecánica | Escena (`scenes/mechanics/`) | Mundo | Qué pasa con cada respuesta |
| --- | --- | --- | --- |
| Persecución (`chase`) | `ChaseStage` | Valle del Qhapaq Ñan, corre sin fin | El avatar acelera y salta una piedra con una vuelta; con un error tropieza y Atoq se acerca riendo. En 0, Atoq se lanza y se lleva un nudo. Al final, el avatar cruza el arco tejido |
| Puente (`bridge`) | `BridgeStage` | Cañón con río y cascada | Cada acierto hace caer un tramo de tablas desde el cielo; con un error sopla el viento y el puente se sacude. En 0, el avatar cae al río y un cóndor lo rescata. Al final cruza y sale un arco iris |
| Caimán (`caiman`) | `CaimanStage` | Laguna con muelle, totoras y nenúfares | Cada acierto lanza una fruta y Coco salta fuera del agua para atraparla; con un error se acerca, salpica y muerde el aire. En 0, salta hasta el muelle y se lleva un nudo. Al final, lleva al avatar en su lomo a la otra orilla |
| Clásica (`classic`) | `ClassicStage` | Valle de los menús | Atoq se asoma por el borde de la tarjeta según el medidor |

**Mundo a pantalla completa.** Cada mecánica arma su mundo con `ParallaxWorld` (`scenes/world/`): capas
con paralaje, cielo con sol, rayos de luz, neblina, agua con corriente, pasto que se mece, polen,
pétalos, mariposas y pájaros. La cámara tiene tres encuadres: mientras se responde, la franja de arriba
de la tarjeta (`QUESTION`); al responder, la tarjeta baja y la cámara abre a toda la pantalla para la
reacción (`ACTION`); y un primer plano para los momentos fuertes, como cuando se pierde una vida
(`CLOSE`). La tarjeta vuelve con la explicación. Los menús y el mapa usan el mismo valle
(`SierraBackdrop`).

**Personajes con vida.** Quwi, el avatar, Atoq y Coco son títeres del mismo motor (`scenes/characters/puppet/`,
guía en [`scenes/characters/README.md`](scenes/characters/README.md)): la pose se arma por capas (reposo,
carrera, clips, cara, mirada y resortes), así que respiran, parpadean, siguen el dedo con la mirada, giran la
cabeza, y el pelo, las orejas, las colas y la chalina rebotan solos. Tienen expresiones con nombre, emotes
sobre la cabeza, gestos de biblioteca y reaccionan cuando los tocan o los acarician. Un personaje nuevo se
declara con datos y se prueba en el laboratorio (`--lab`).

**Regiones.** Cada capítulo tiene su mundo que corre sin fin y su guía (`WorldSets.REGION_WORLDS`,
`Cast.GUIDES` y `RegionStyle`): el valle con Quwi en la Sierra, la selva del Apurímac con Tunki y la costa con
Humbi. La persecución y la pantalla del nivel los eligen solos según el capítulo del nivel. Los tres mundos
tienen día, atardecer y noche.

**Cortos.** Las escenas de la historia se escriben como una lista de pasos y las reproduce `ShortPlayer`
(guía en [`scenes/cine/README.md`](scenes/cine/README.md)): el prólogo se ve al crear el personaje y desde el
botón «Historia» del mapa; al superar un desafío final, Mama Sisa recibe la cuerda; y cada región tiene su
corto de llegada. El elenco (`scenes/characters/cast.gd`) suma a Mama Sisa, Kuntur (el cóndor que rescata al
avatar en el puente), Tunki y Humbi.

**Dirección de cine.** `MechanicStage` da a cada mecánica una pausa de impacto (`hit_stop`), un golpe de zoom
(`punch`), un destello suave (`flash`), barras de cine para los momentos grandes (`cinema`) y cambios de luz
(`light`: fría cuando el peligro alcanza al avatar, dorada en la victoria). Los efectos son formas vectoriales
(`scenes/fx/`: polvo, estrellas, brillitos, salpicaduras, anillos, golpes y papel picado).

Todas usan la misma regla del dominio: el medidor de peligro y las vidas (RN-13 y RN-14). Sin vidas, el nivel termina en game over y se puede reintentar. El desafío final no tiene medidor, vidas ni pistas: guarda cada respuesta sin decir si está bien y al entregar muestra la calificación AD, A, B o C, la cuerda recuperada y la explicación de cada pregunta.

## Motor de actividades

Los niveles se leen de paquetes con el [formato v1](../docs/03-diseno-de-software/formato-de-paquete.md). El juego trae en `content/packages/` los módulos 0 de calentamiento, los retos adicionales de práctica y un borrador del módulo 1 de cada área, con niveles de persecución, puente y caimán y un desafío final de 12 preguntas. Son contenidos de prueba pendientes de revisión docente; los módulos oficiales se validan en el Sprint 9. Los paquetes anteriores no se modificaron, para conservar sus intentos en curso.

Las preguntas, su orden y sus números son los mismos para todos los estudiantes. Se mezclan algunos elementos de las actividades de ordenar, emparejar, clasificar y completar; por ahora no se generan ejercicios ni valores distintos por estudiante.

| Tipo de ítem | Evaluador (dominio) | Actividad (vista) |
| --- | --- | --- |
| `multiple_choice`, `multi_select` | `MultipleChoiceEvaluator`, `MultiSelectEvaluator` | `ChoiceActivity`: tarjetas con letra o casilla |
| `true_false` | `TrueFalseEvaluator` | `TrueFalseActivity`: Verdadero o Falso en cada afirmación |
| `ordering` | `OrderingEvaluator` | `OrderingActivity`: arrastrar, o tocar dos tarjetas para intercambiarlas |
| `matching` | `MatchingEvaluator` | `MatchingActivity`: cuerdas tejidas entre dos columnas |
| `classification` | `ClassificationEvaluator` | `ClassificationActivity`: canastas tejidas |
| `fill_blank` | `FillBlankEvaluator` | `FillBlankActivity`: espacios en el texto y banco de palabras |
| `numeric` | `NumericEvaluator` | `NumericActivity`: pizarra y teclado del juego |
| `reading_unit` | `ReadingUnitEvaluator` | `ReadingPanel` a la izquierda y cada pregunta a la derecha |

Para agregar un tipo de ítem:

1. Crea su evaluador en `src/domain/evaluators/` (hereda de `ItemEvaluator`) y regístralo en `EvaluatorRegistry.standard()`.
2. Prepara sus datos de pantalla en `StepBuilder` (`src/application/use_cases/play/`), sin incluir la respuesta correcta.
3. Crea su actividad en `scenes/activities/` (hereda de `ActivityView`) y agrégala a `ActivityFactory`.
4. Escribe sus pruebas en `tests/unit/domain/evaluators_test.gd`.

## Exportar el APK de prueba

```bash
godot --headless --path android --export-debug "Android" builds/edukids-debug.apk
```

```bash
adb install -r android/builds/edukids-debug.apk
```

- El editor crea su propio keystore de depuración la primera vez que se abre. Ningún keystore va al repositorio.
- Para una versión de publicación se usan las variables `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` y `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`.
- `builds/` está ignorada por Git.

## Organización

```text
android/
├── src/
│   ├── domain/          1. Reglas: aula (Pin, PinLockout, Avatar, Student…), LevelSession, DangerMeter, StarRule,
│   │                       CnebGradeScale, TrailRule y los evaluadores de cada tipo de ítem
│   ├── application/     2. Casos de uso (aula, ajustes, historia), puertos y DTO
│   ├── infrastructure/  3. Adaptadores de salida: SQLite, memoria, hash del PIN, JSON, reloj, UUID
│   ├── presentation/    3. Presentadores, modelos de vista y paleta del avatar
│   └── main/            Raíz de composición (autoload), navegador y modo demostración
├── scenes/              4. Vistas: inicio, perfiles y PIN, editor del avatar, mapa y paradas, nivel y mecánicas,
│                           mundos con paralaje, actividades, modo docente y personajes (avatar, Quwi, Atoq y Coco)
├── assets/              Arte importado, fuentes y tema de la interfaz
├── content/story/       Escenas narrativas del juego base (JSON)
├── content/packages/    Paquetes de la parada de Huamanga que vienen con el juego
├── art-src/             Fuentes del arte (SVG maestros); Godot no las importa
├── tools/art/           Herramientas del flujo de arte (rigs por piezas y generadores de mundos)
├── tools/preview/       Galería de avatares para revisar el arte
├── tests/               Pruebas y verificación de capas
└── addons/gdUnit4/      Pruebas (versión fijada)
```

El detalle está en la [estructura del repositorio](../docs/03-diseno-de-software/estructura-del-repositorio.md).

## Flujo de arte

| Recurso | Fuente | Cómo llega al juego |
| --- | --- | --- |
| Fondos por capas | `assets/art/backgrounds/*.svg` | Godot importa el SVG a 1,5× |
| Mundos de las mecánicas | `tools/art/worlds/*.py` → `assets/art/worlds/<mundo>/*.svg` | Los scripts escriben capas SVG limpias (valle, cañón y laguna); Godot importa cada capa a su escala, con mipmaps. Ver `tools/art/worlds/README.md` |
| Interfaz e iconos | `assets/art/ui/*.svg` | Godot importa el SVG a 2× |
| Personajes por piezas | `art-src/characters/<personaje>.svg` y `<personaje>.rig.json` | `tools/art/build_cutout_rig.gd` rasteriza cada pieza a 2×, arma un atlas y genera la escena del rig |
| Avatar del estudiante | `art-src/characters/avatar.svg` y `avatar.rig.json` | Igual que Quwi, pero las piezas de piel, cabello y ropa van en gris y el juego las tiñe con la paleta de `src/presentation/styles/avatar_palette.gd` |
| Letras del logotipo | Fredoka Bold (OFL) | `art-src/tools/make_logo_letters.py` genera una letra por SVG y su escena |
| Ícono de la app | `icon.svg` y `art-src/icons/` | PNG de 192 y 432 px para Android |

Reconstruir el rig de un personaje después de editar su SVG (`quwi`, `atoq` o `caiman`):

```bash
godot --headless --path android -s res://tools/art/build_cutout_rig.gd -- res://art-src/characters/atoq.rig.json
```

Reconstruir el avatar y revisar todas sus combinaciones en una captura:

```bash
godot --headless --path android -s res://tools/art/build_cutout_rig.gd -- res://art-src/characters/avatar.rig.json
godot --path android res://tools/preview/avatar_gallery.tscn -- /tmp/avatares.png
```

En el SVG del avatar, `#EDEDED` es el color base, `#FFFFFF` la luz, `#C9C9C9` y `#AEAEAE` las sombras y `#595959` el contorno: al teñir, el contorno queda del color de la sombra de cada pieza, como pide la guía de arte. Los ojos, la boca, los zapatos, la franja tejida, las medias y los lazos tienen color propio y no se tiñen.

Regenerar las letras del logotipo (requiere `pip install fonttools`):

```bash
python3 android/art-src/tools/make_logo_letters.py
```

Cada grupo `part_*` del SVG maestro es una pieza; el archivo `.rig.json` define la jerarquía y el pivote de cada una. La escena del rig se genera y no se edita a mano; la animación vive en el script del personaje.

## Mediciones del Sprint 2

| Medida | Resultado | Meta |
| --- | --- | --- |
| Tamaño del APK de depuración (arm64-v8a y armeabi-v7a) | 59 MB | 150 MB o menos (RNF) |
| Memoria en el emulador Android 17 (PSS) | 110 MB | 400 MB o menos (RNF) |
| CPU por cuadro de la pantalla de inicio (Mac, Movie Maker) | 1,7 ms | Cuadros de 33 ms para 30 fps |
| Atlas de Quwi | 1024 × 624 px, 17 piezas | 2048 × 2048 px o menos |

Falta medir en la tablet real del piloto: arranque, fps y memoria.

## Panel de medición

En la pantalla de inicio, tres toques seguidos sobre el texto de la versión abren un panel con el modelo, Android, la arquitectura, la GPU, la memoria, los cuadros por segundo, el tiempo de arranque y el estado de SQLite. Una captura de ese panel en la tablet real cierra la medición del Sprint 2. También se abre con `godot --path android -- --diagnostics`.

## Audio de la versión actual

El juego incluye como música de fondo de prueba «Through the Llama Passage», de Firage, una composición para videojuego inspirada en los Andes. Se conserva el sonido del cuy Quwi y el mismo efecto cuando los nudos del quipu se desprenden y regresan. El botón de sonido permite activar o silenciar el audio.

## Licencias de terceros

| Recurso | Licencia |
| --- | --- |
| [«Through the Llama Passage», de Firage](https://firage.bandcamp.com/track/through-the-llama-passage) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); audio sin modificar. También en los créditos del juego. |
| Fredoka y Andika (`assets/fonts/`) | SIL Open Font License 1.1 (incluida en la carpeta) |
| GdUnit4 (`addons/gdUnit4/`) | MIT (incluida en la carpeta) |
| godot-sqlite 4.9 (`addons/godot-sqlite/`) | MIT (incluida en la carpeta) |
| Godot Engine | MIT |
