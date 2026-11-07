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

```bash
godot --path android -- --demo-data --demo-profiles
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
| `tests/unit/domain` | Medidor de peligro (RN-13), estrellas (RN-11), escala AD/A/B/C (RN-12) y escenas narrativas |
| `tests/unit/application` | Casos de uso con repositorios falsos |
| `tests/unit/presentation` | Presentadores y modelos de vista |
| `tests/integration` | Lectura de JSON, reloj, aleatoriedad e identificadores |
| `tests/architecture` | Regla de dependencias entre capas (RNF-15, CA-20) |

El CI ([`.github/workflows/android.yml`](../.github/workflows/android.yml)) ejecuta la verificación de capas y las pruebas en cada cambio dentro de `android/`. Los reportes de GdUnit4 se guardan en `reports/` (ignorado por Git).

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
│   ├── domain/          1. Reglas: aula (Pin, PinLockout, Avatar, Student…), DangerMeter, StarRule, CnebGradeScale
│   ├── application/     2. Casos de uso (aula, ajustes, historia), puertos y DTO
│   ├── infrastructure/  3. Adaptadores de salida: SQLite, memoria, hash del PIN, JSON, reloj, UUID
│   ├── presentation/    3. Presentadores, modelos de vista y paleta del avatar
│   └── main/            Raíz de composición (autoload), navegador y modo demostración
├── scenes/              4. Vistas: inicio, perfiles y PIN, editor del avatar, modo docente, personajes
├── assets/              Arte importado, fuentes y tema de la interfaz
├── content/story/       Escenas narrativas del juego base (JSON)
├── art-src/             Fuentes del arte (SVG maestros); Godot no las importa
├── tools/art/           Herramientas del flujo de arte
├── tools/preview/       Galería de avatares para revisar el arte
├── tests/               Pruebas y verificación de capas
└── addons/gdUnit4/      Pruebas (versión fijada)
```

El detalle está en la [estructura del repositorio](../docs/03-diseno-de-software/estructura-del-repositorio.md).

## Flujo de arte

| Recurso | Fuente | Cómo llega al juego |
| --- | --- | --- |
| Fondos por capas | `assets/art/backgrounds/*.svg` | Godot importa el SVG a 1,5× |
| Interfaz e iconos | `assets/art/ui/*.svg` | Godot importa el SVG a 2× |
| Personajes por piezas | `art-src/characters/<personaje>.svg` y `<personaje>.rig.json` | `tools/art/build_cutout_rig.gd` rasteriza cada pieza a 2×, arma un atlas y genera la escena del rig |
| Avatar del estudiante | `art-src/characters/avatar.svg` y `avatar.rig.json` | Igual que Quwi, pero las piezas de piel, cabello y ropa van en gris y el juego las tiñe con la paleta de `src/presentation/styles/avatar_palette.gd` |
| Letras del logotipo | Fredoka Bold (OFL) | `art-src/tools/make_logo_letters.py` genera una letra por SVG y su escena |
| Ícono de la app | `icon.svg` y `art-src/icons/` | PNG de 192 y 432 px para Android |

Reconstruir el rig de Quwi después de editar su SVG:

```bash
godot --headless --path android -s res://tools/art/build_cutout_rig.gd -- res://art-src/characters/quwi.rig.json
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

La introducción está sin música mientras se elige una nueva pista. Se conserva el sonido del cuy Quwi y el mismo efecto cuando los nudos del quipu se desprenden y regresan. El botón de sonido permite activar o silenciar el audio.

Una candidata para escuchar es «Through the Llama Passage», de Firage, una composición para videojuego inspirada en los Andes. Está disponible en [Bandcamp](https://firage.bandcamp.com/track/through-the-llama-passage) bajo CC BY 4.0, pero todavía no está incluida en el juego.

## Licencias de terceros

| Recurso | Licencia |
| --- | --- |
| Fredoka y Andika (`assets/fonts/`) | SIL Open Font License 1.1 (incluida en la carpeta) |
| GdUnit4 (`addons/gdUnit4/`) | MIT (incluida en la carpeta) |
| godot-sqlite 4.9 (`addons/godot-sqlite/`) | MIT (incluida en la carpeta) |
| Godot Engine | MIT |
