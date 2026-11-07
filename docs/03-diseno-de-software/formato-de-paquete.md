# Formato de paquete v1

Contrato entre el panel, el backend y el juego ([ADR-002](../01-analisis-de-sistema/decisiones/ADR-002-modulos-descargables.md) y [ADR-013](../01-analisis-de-sistema/decisiones/ADR-013-paquetes-solo-datos-y-pdf-a-imagenes.md)). Un paquete es un ZIP con datos y medios; **nunca contiene código**. Las claves de los archivos JSON están en inglés; los textos que ve el estudiante, en español.

## Nombre del archivo

| Tipo | Patrón | Ejemplo |
| --- | --- | --- |
| Módulo oficial | `mod-<área>-<grado>-<número>-<versión>.zip` | `mod-math-6-01-1.0.0.zip` |
| Reto de docente | `chl-<código de docente>-<número>-<versión>.zip` | `chl-K7M3QX-0007-1.0.0.zip` |

## Estructura

```text
mod-math-6-01-1.0.0.zip
├── manifest.json            Descripción del paquete (obligatorio)
├── checksums.sha256         SHA-256 de cada archivo (obligatorio)
├── credits.txt              Créditos y licencias de imágenes (opcional)
├── theory/
│   └── dialogues.json       Explicación del guía
├── levels/
│   ├── L01.json             Un archivo por nivel
│   └── FINAL.json           Desafío final (solo en módulos)
├── readings/
│   └── ficha-01/
│       └── p001.webp        Páginas de las fichas
└── images/                  Ilustraciones de ítems y tarjetas
```

## Reglas de contenido

- **Extensiones permitidas:** `.json`, `.webp`, `.png`, `.ogg`, `.sha256` y `.txt`.
- **Prohibido:** cualquier otra extensión, en especial `.gd`, `.tscn`, `.tres`, `.pck`, `.so`, `.dex`, `.apk`, `.js` y `.html`.
- **Rutas:** relativas, en minúsculas, sin `..`, sin rutas absolutas y sin enlaces simbólicos.
- **Tamaño:** 50 MB como objetivo y 100 MB como máximo por paquete; imágenes de hasta 2048 × 2048 px.
- **Codificación:** UTF-8.

## `manifest.json`

| Campo | Tipo | Obligatorio | Descripción |
| --- | --- | --- | --- |
| `format_version` | texto | Sí | Versión de este formato: `"1.0"`. |
| `id` | texto | Sí | Identificador estable sin versión, por ejemplo `mod-math-6-01`. |
| `kind` | texto | Sí | `module` o `challenge`. |
| `title` | texto | Sí | Título visible. |
| `area` | texto | Sí | `math`, `language` o `science`. |
| `grade` | número | Sí | Grado (6). |
| `number` | número | Solo módulos | Número del módulo, de 1 a 9. |
| `chapter` | texto | Sí | `sierra`, `selva` o `costa`. |
| `stop` | texto | Solo módulos | Parada del mapa, por ejemplo `huamanga`. |
| `version` | texto | Sí | Versión semántica del contenido. |
| `min_app_version` | texto | Sí | Versión mínima de la aplicación que lo puede abrir. |
| `author` | objeto | Sí | `type`: `official` o `teacher`; `teacher_code` si es un reto. |
| `created_at` | texto | Sí | Fecha en ISO 8601. |
| `competencies` | lista | Sí | Competencias del CNEB que trabaja. |
| `theory` | texto | No | Ruta de la explicación del guía. |
| `readings` | lista | No | Fichas: `id`, `title` y `pages` (rutas de imágenes). |
| `levels` | lista | Sí | Niveles: `id`, `kind` (`short`, `regular` o `final`), `mechanic` (`chase`, `bridge` o `classic`), `file`, `estimated_minutes`, `lives` y `danger` (`start` y `max`), además de `timer_seconds` si el nivel tiene tiempo. |

```json
{
  "format_version": "1.0",
  "id": "mod-math-6-01",
  "kind": "module",
  "title": "Números grandes en el mercado de Huamanga",
  "area": "math",
  "grade": 6,
  "number": 1,
  "chapter": "sierra",
  "stop": "huamanga",
  "version": "1.0.0",
  "min_app_version": "1.0.0",
  "author": { "type": "official" },
  "created_at": "2026-11-06T00:00:00Z",
  "competencies": ["MAT.CANTIDAD"],
  "theory": "theory/dialogues.json",
  "readings": [
    {
      "id": "ficha-01",
      "title": "Ventas de la feria",
      "pages": ["readings/ficha-01/p001.webp", "readings/ficha-01/p002.webp"]
    }
  ],
  "levels": [
    {
      "id": "L01",
      "kind": "short",
      "mechanic": "chase",
      "file": "levels/L01.json",
      "estimated_minutes": 4,
      "lives": 3,
      "danger": { "start": 2, "max": 4 }
    },
    {
      "id": "FINAL",
      "kind": "final",
      "mechanic": "classic",
      "file": "levels/FINAL.json",
      "estimated_minutes": 20
    }
  ]
}
```

## Archivo de nivel

Cada nivel tiene un saludo del guía y una lista de ítems. Todos los ítems comparten estos campos:

| Campo | Obligatorio | Descripción |
| --- | --- | --- |
| `id` | Sí | Identificador único dentro del paquete. |
| `type` | Sí | Tipo de ítem (ver la tabla siguiente). |
| `prompt` | Sí | Enunciado. |
| `image` | No | Ruta de una imagen del paquete. |
| `feedback` | Sí | `correct` e `incorrect`; cada opción puede tener su propio `feedback`. |
| `hint` | No | Pista que orienta sin dar la respuesta. |
| `metadata` | Sí | `competency`, `capacity`, `pisa` (`category` y `process`), `difficulty` (1 a 3) y `estimated_seconds`. |

| `type` | Campos propios |
| --- | --- |
| `multiple_choice` | `options`: `id`, `text`, `image` opcional y `correct: true` en una sola opción |
| `multi_select` | `options`, con `correct: true` en cada opción correcta |
| `true_false` | `statements`: `id`, `text` y `answer` (`true` o `false`) |
| `ordering` | `elements` (`id` y `text`) y `correct_order` (lista de `id`) |
| `matching` | `left` (2 a 6), `right` (puede tener uno o dos distractores) y `pairs`: cada par como lista `["izquierda", "derecha"]` u objeto `{"left": …, "right": …}`; cada elemento de la izquierda va con uno distinto de la derecha |
| `classification` | `groups` (`id` y `label`) y `elements` (`id`, `text` y `group`) |
| `fill_blank` | `text` con marcadores `{{1}}`, `{{2}}` (hasta 5) y `blanks`: `id`, `accepted` (respuestas válidas, obligatorio) y `options` si se elige de una lista; las opciones de todos los espacios forman un solo banco de palabras. Sin `options`, el espacio se escribe |
| `numeric` | `answer`, `tolerance` (por defecto 0), `unit` opcional y `accepted_formats` (`decimal`, `fraction`; por defecto solo `decimal`). Se acepta coma o punto decimal; con `fraction`, también fracciones y números mixtos. `S/` se escribe antes del número; las demás unidades, después |
| `short_text` | `accepted`: lista de respuestas válidas |
| `hotspot` | `image` y `zones` (`id`, rectángulo `x`, `y`, `w`, `h` y `correct`) |
| `sentence_check` | `sentence` y `makes_sense` |
| `reading_unit` | `stimulus` e `items` (1 a 8 ítems de los tipos anteriores, sin otra unidad dentro). El estímulo tiene `type` y `title`; si es `text`, `content` es una lista de párrafos (o un texto con párrafos separados por una línea en blanco); si es `table`, `content` tiene `columns` y `rows`, y puede llevar `note`; si es `image`, `file` es la ruta de la imagen |

```json
{
  "id": "L01",
  "title": "Cálculo en la feria",
  "guide_intro": [
    "¡Rimaykullayki! Hoy contaremos lo que se vende en la feria.",
    "Cada respuesta correcta te aleja de Atoq. ¡Vamos!"
  ],
  "items": [
    {
      "id": "MAT01-L01-01",
      "type": "multiple_choice",
      "prompt": "¿Cuál es el valor de la cifra 5 en 1 254 300?",
      "options": [
        { "id": "a", "text": "5 000", "feedback": "Fíjate en la posición: el 5 está en las decenas de millar." },
        { "id": "b", "text": "50 000", "correct": true },
        { "id": "c", "text": "500", "feedback": "El 5 está más a la izquierda, en las decenas de millar." },
        { "id": "d", "text": "500 000", "feedback": "Ese sería su valor si estuviera en las centenas de millar." }
      ],
      "feedback": {
        "correct": "¡Bien! El 5 está en las decenas de millar: vale 50 000.",
        "incorrect": "Ubica cada cifra en el tablero de valor posicional."
      },
      "hint": "Escribe el número en un tablero de valor posicional.",
      "metadata": {
        "competency": "MAT.CANTIDAD",
        "capacity": "Comunica su comprensión sobre los números y las operaciones",
        "pisa": { "category": "quantity", "process": "employ" },
        "difficulty": 1,
        "estimated_seconds": 45
      }
    },
    {
      "id": "MAT01-L01-02",
      "type": "numeric",
      "prompt": "Rosa vendió 3 retablos a S/ 480 cada uno. ¿Cuántos soles recibió?",
      "answer": 1440,
      "tolerance": 0,
      "unit": "S/",
      "accepted_formats": ["decimal"],
      "feedback": {
        "correct": "¡Exacto! 3 × 480 = 1 440.",
        "incorrect": "Multiplica la cantidad de retablos por el precio de cada uno."
      },
      "metadata": {
        "competency": "MAT.CANTIDAD",
        "capacity": "Usa estrategias y procedimientos de estimación y cálculo",
        "pisa": { "category": "quantity", "process": "employ" },
        "difficulty": 1,
        "estimated_seconds": 60
      }
    }
  ]
}
```

## Cómo se juega cada ítem

- Las preguntas de una unidad de lectura se presentan una por una, con el estímulo a la vista; cada una cuenta como una pregunta del nivel.
- Las respuestas escritas se comparan sin mayúsculas, sin tildes y sin signos de puntuación.
- Las opciones de `ordering`, `matching` (columna derecha), `classification` y el banco de palabras se desordenan al mostrarse; la secuencia de `ordering` nunca aparece ya resuelta.
- El `feedback` propio de una opción, afirmación o distractor se muestra cuando el estudiante elige esa parte; si no tiene, se usa el `incorrect` del ítem.

## Códigos de competencia

| Área | Códigos |
| --- | --- |
| Matemática | `MAT.CANTIDAD`, `MAT.REGULARIDAD`, `MAT.FORMA`, `MAT.DATOS` |
| Comunicación | `COM.LEE`, `COM.ESCRIBE`, `COM.ORAL` |
| Ciencia y Tecnología | `CYT.INDAGA`, `CYT.EXPLICA`, `CYT.DISENA` |

Valores de `pisa.category` y `pisa.process`:

- **Matemática:** categorías `quantity`, `change_relationships`, `space_shape`, `uncertainty_data`; procesos `formulate`, `employ`, `interpret`, `reason`.
- **Lectura:** procesos `locate`, `understand`, `evaluate_reflect`.
- **Ciencias:** competencias `explain`, `design_interpret`, `research_decide`.

## Paquetes incluidos en el juego

El juego trae tres módulos de práctica en `android/content/packages/`, con el mismo formato: `mod-math-6-00`, `mod-language-6-00` y `mod-science-6-00` (número 0, «calentamiento»). Cada uno tiene un nivel de 8 preguntas que usa los tipos de ítem P1 y se registra en la base local al iniciar el juego. No llevan `checksums.sha256` porque viajan dentro del APK firmado. Su contenido es original y debe revisarlo un docente de 6.° grado antes del piloto.

## Integridad y validación

1. El catálogo publica el SHA-256 del ZIP; la tablet lo compara al terminar la descarga.
2. `checksums.sha256` lista el SHA-256 de cada archivo; la tablet lo verifica después de descomprimir, también en la importación por USB.
3. El instalador aplica las reglas de contenido y valida el manifiesto antes de mover los archivos a su carpeta definitiva (ver [flujo de instalación](../02-arquitectura-software/flujos-principales.md)).
4. Fase posterior (P3): firma digital de los paquetes oficiales.

## Versionado

- `format_version` cambia cuando cambia este documento. La aplicación rechaza paquetes con una versión mayor de formato que no conoce.
- `version` sigue el versionado semántico del contenido: PATCH para corregir textos, MINOR para agregar ítems o niveles y MAJOR para cambios de estructura.
- Cada intento guarda la versión del paquete con la que se respondió (RN-05).
