# Modelo de datos

Los nombres de tablas y columnas están en inglés, como el código. El contenido de los niveles (preguntas, textos e imágenes) no se copia a la base de datos: queda en los archivos del paquete instalado, y la base guarda un índice de niveles y los resultados.

## Tablet (SQLite)

```mermaid
erDiagram
    INSTITUTION ||--o{ SECTION : "tiene"
    SECTION ||--o{ STUDENT : "agrupa"
    STUDENT ||--o{ ATTEMPT : "realiza"
    ATTEMPT ||--o{ ANSWER : "contiene"
    PACKAGE ||--o{ LEVEL : "define"
    LEVEL ||--o{ ATTEMPT : "registra"
    PACKAGE ||--o{ PACKAGE_SECTION : "se habilita en"
    SECTION ||--o{ PACKAGE_SECTION : "recibe"
    STUDENT ||--o{ REWARD : "gana"
    STUDENT ||--o{ RESOURCE_VIEW : "registra"
    INSTITUTION {
        text id PK
        text name
        text modular_code
        int grade
        int school_year
        text teacher_code
    }
    SECTION {
        text id PK
        text name
        int active
    }
    STUDENT {
        text id PK
        text section_id FK
        text name
        text code
        text pin_hash
        text pin_salt
        text avatar_json
        int failed_attempts
        text locked_until
        int active
    }
    PACKAGE {
        text id PK
        text kind
        text area
        int grade
        int number
        text chapter
        text title
        text version
        int size_bytes
        text sha256
        text status
        text install_path
        text installed_at
    }
    PACKAGE_SECTION {
        text package_id FK
        text section_id FK
        int enabled
        int final_enabled
    }
    LEVEL {
        text id PK
        text package_id FK
        text kind
        text mechanic
        int position
        text title
        int estimated_minutes
    }
    ATTEMPT {
        text id PK
        text student_id FK
        text level_id FK
        text package_version
        text kind
        text status
        text started_at
        text finished_at
        int correct_count
        int total_count
        real percent
        int stars
        text cneb_grade
        int lives_lost
        int hints_used
    }
    ANSWER {
        text id PK
        text attempt_id FK
        text item_id
        text value_json
        int is_correct
        int first_try
        int with_hint
        int time_ms
        text answered_at
    }
    REWARD {
        text student_id FK
        text kind
        text reward_id
        text earned_at
    }
    RESOURCE_VIEW {
        text student_id FK
        text resource_id
        text viewed_at
    }
```

Tablas adicionales: `teacher` (nombre, `pin_hash`, `pin_salt`, intentos fallidos y bloqueo), `setting` (clave y valor para la escala AD/A/B/C, los intentos, la pausa y el volumen) y `schema_migration` (versión del esquema).

### Valores permitidos

| Columna | Valores |
| --- | --- |
| `package.kind` | `module`, `challenge` |
| `package.area` | `math`, `language`, `science` |
| `package.chapter` | `sierra`, `selva`, `costa` |
| `package.status` | `installed`, `archived` |
| `level.kind` | `short`, `regular`, `final` |
| `level.mechanic` | `chase`, `bridge`, `classic` |
| `attempt.kind` | `practice`, `final` |
| `attempt.status` | `in_progress`, `completed`, `game_over`, `closed` |
| `attempt.cneb_grade` | `AD`, `A`, `B`, `C` (solo desafío final) |
| `reward.kind` | `badge`, `card`, `accessory` |

### Reglas de almacenamiento

- Cada respuesta se guarda en su propia transacción, con SQLite en modo WAL (RNF-06).
- Los identificadores de intentos y respuestas son UUID generados en la tablet.
- Las fechas se guardan en formato ISO 8601.
- El PIN se guarda como hash con sal; nunca en texto claro (RNF-08). El hash usa PBKDF2-HMAC-SHA256 y guarda el algoritmo y las iteraciones (`pbkdf2-sha256$4000$…`), así se pueden subir las iteraciones sin invalidar los PIN guardados. La sal son 16 bytes aleatorios en hexadecimal.
- `failed_attempts` y `locked_until` llevan el bloqueo temporal: con 5 fallos seguidos, el acceso se bloquea 5 minutos.
- `student.avatar_json` guarda los índices de los catálogos del avatar: `{"body": "girl", "skin": 2, "hair_style": 3, "hair_color": 0, "top_color": 1, "bottom_color": 4}`. Un `{}` significa que el estudiante todavía no creó su personaje. Los colores no se guardan: los decide la paleta del juego.
- Un estudiante con resultados se desactiva, no se elimina (RN-07).
- `level.id` identifica el nivel en toda la tablet como `paquete/nivel` (por ejemplo, `mod-math-6-00/L01`); así un intento siempre apunta a un nivel registrado. Los paquetes que vienen con el juego se registran al iniciar, con `install_path` en `res://content/packages/…`.
- `attempt.total_count` cuenta las preguntas del nivel (cada pregunta de una unidad de lectura por separado); `correct_count`, las acertadas al primer intento; `percent`, su porcentaje; y `stars`, las estrellas según RN-11. Un intento `in_progress` con respuestas se retoma al volver a abrir el nivel.
- `answer.value_json` guarda la respuesta tal como la dio el estudiante: el id de la opción (`"b"`), una lista de ids (selección múltiple y ordenar), un objeto (verdadero o falso, emparejar, clasificar y completar) o el texto escrito (respuesta numérica, por ejemplo `"0,5"`). `first_try` es 0 en el repaso de una pregunta fallada y `with_hint` indica si se vio la pista.

## Nube (PostgreSQL)

La nube **no tiene tablas de estudiantes, intentos ni calificaciones** (RN-08).

```mermaid
erDiagram
    TEACHER_ACCOUNT ||--o{ CHALLENGE : "crea"
    CHALLENGE ||--|{ CHALLENGE_ITEM : "contiene"
    CHALLENGE ||--o{ PACKAGE : "se publica como"
    TEACHER_ACCOUNT {
        uuid id PK
        text email
        text name
        text institution_name
        text password_hash
        text teacher_code
        text role
        text status
        timestamp created_at
    }
    CHALLENGE {
        uuid id PK
        uuid teacher_id FK
        text title
        text area
        text chapter
        text mechanic
        text status
        text current_version
        timestamp updated_at
    }
    CHALLENGE_ITEM {
        uuid id PK
        uuid challenge_id FK
        int position
        text type
        jsonb content
    }
    PACKAGE {
        uuid id PK
        text kind
        text area
        int grade
        int number
        text chapter
        text title
        text version
        bigint size_bytes
        text sha256
        text storage_key
        text teacher_code
        text format_version
        text min_app_version
        text status
        timestamp published_at
    }
```

| Columna | Valores |
| --- | --- |
| `teacher_account.role` | `teacher`, `editor` |
| `challenge.status` | `draft`, `published`, `archived` |
| `package.kind` | `module` (oficial, sin `teacher_code`), `challenge` (con `teacher_code`) |
| `package.status` | `published`, `withdrawn` |
