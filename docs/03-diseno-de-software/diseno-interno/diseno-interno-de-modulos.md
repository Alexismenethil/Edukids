# Diseño interno de módulos

Componentes del juego con sus casos de uso, sus puertos y las reglas del dominio que usan. Los nombres están en inglés, como en el código.

## Componentes del juego

| Componente | Casos de uso | Reglas del dominio | Puertos |
| --- | --- | --- | --- |
| Aula e identidad | `ConfigureInstitution`, `GetClassroom`, `UnlockTeacherMode`, `RegisterStudent`, `UpdateStudent`, `SetStudentActive`, `ResetStudentPin`, `LoginStudent`, `ListStudents`, `GetStudentProfile`, `CustomizeAvatar`, `SuggestPin`, `SuggestAvatar` | `Pin`, `PinLockout` (bloqueo tras 5 fallos), `PersonName`, `TeacherCode`, `Avatar` | `InstitutionRepository`, `StudentRepository`, `PinHasher`, `Clock`, `IdGenerator`, `RandomSource` |
| Paquetes | `FetchCatalog`, `DownloadPackage`, `InstallPackage`, `ImportPackageFile`, `ReleasePackage`, `EnablePackage` | Validación del manifiesto y del contenido | `CatalogGateway`, `PackageDownloader`, `PackageArchive`, `PackageRepository`, `FileImporter` |
| Contenidos | `GetStopContent`, `OpenTheory`, `OpenReading` | `UnlockRule` (RN-18) | `PackageStore`, `ProgressRepository` |
| Juego | `ListLevels`, `StartLevel`, `SubmitAnswer`, `RequestHint`, `ContinueLevel`, `FinishLevel`, `RegisterBundledPackages` | `LevelSession`, `EvaluatorRegistry` y un evaluador por tipo, `StarRule`; desde el Sprint 5, `DangerMeter` | `PackageStore`, `PackageRepository`, `AttemptRepository`, `LevelSessionStore`, `Clock`, `IdGenerator`, `RandomSource` |
| Desafío final | `StartFinalChallenge`, `AnswerFinalItem`, `SubmitFinalChallenge`, `AuthorizeExtraAttempt` | `FinalChallenge`, `CnebGradeScale`, límite de intentos | `AttemptRepository`, `SettingsRepository`, `Clock` |
| Recompensas | `GrantRewards`, `GetCollection` (los accesorios de RF-32 amplían `CustomizeAvatar`) | Umbrales de accesorios, condiciones de insignias | `RewardRepository`, `StudentRepository` |
| Reportes | `GetSectionReport`, `ExportReportCsv` | Agregados por estudiante, área y módulo | `AttemptRepository`, `ReportExporter` |
| Ajustes | `UpdateEvaluationSettings`, `UpdateAudioSettings` | Rangos válidos de la escala | `SettingsRepository` |

## Sesión de nivel

`LevelSession` es la entidad que aplica las reglas de un nivel de práctica (RN-11, RN-13 y RN-14). No conoce animaciones: devuelve un resultado que el presentador traduce para la escena.

```mermaid
stateDiagram-v2
    [*] --> EnCurso: StartLevel
    EnCurso --> EnCurso: acierto o error
    EnCurso --> Alcanzado: el medidor llega a 0
    Alcanzado --> EnCurso: quedan vidas y el medidor vuelve a 2
    Alcanzado --> GameOver: no quedan vidas
    EnCurso --> Completado: se respondió el último ítem
    GameOver --> [*]: reintentar crea un intento nuevo
    Completado --> [*]: FinishLevel calcula las estrellas
```

Resultado de cada respuesta (`AnswerOutcome`): si fue correcta, la retroalimentación, si la pregunta volverá al final, si el guía ofrece una pista para la siguiente, la solución cuando ya no queda otra oportunidad y si el nivel terminó. Con las mecánicas del Sprint 5 se suman el valor del medidor, las vidas restantes y si Atoq alcanzó al avatar.

Reglas que aplica hoy la sesión (Sprint 4):

- Las preguntas de una unidad de lectura se presentan una por una, con el estímulo a la vista.
- Una respuesta incompleta no cuenta: la pregunta sigue abierta.
- Una pregunta fallada vuelve una sola vez al final del nivel (RF-29); la segunda respuesta se guarda, pero no suma estrellas.
- Una pista no quita nada, pero esa pregunta deja de contar como acierto válido (RN-11).
- Tras dos errores seguidos, el guía ofrece la pista de la siguiente pregunta, si la tiene (RF-26).
- Si la aplicación se cierra, `StartLevel` rehace la sesión con las respuestas guardadas y el nivel continúa donde se quedó (RF-14). Si el paquete cambió de versión, empieza un intento nuevo (RN-05).

## Ciclo de vida de un paquete

```mermaid
stateDiagram-v2
    [*] --> Disponible: aparece en el catálogo o en una USB
    Disponible --> Descargando
    Descargando --> Descargando: se reanuda tras un corte
    Descargando --> Instalado: la verificación es correcta
    Descargando --> Rechazado: SHA-256 o contenido inválido
    Instalado --> Habilitado: el docente lo habilita para una sección
    Habilitado --> Instalado: el docente lo deshabilita
    Instalado --> Archivado: se libera el espacio
    Archivado --> [*]
```

Al archivar un paquete se borran sus archivos, pero se conservan sus intentos y resultados (RN-09).

## Motor de actividades

Cada tipo de ítem tiene un evaluador que implementa la misma interfaz (`ItemEvaluator`): valida los campos propios del tipo (`parse_spec`), corrige una respuesta (`evaluate`) y describe la solución (`solution_text`). `EvaluatorRegistry` elige el evaluador según el campo `type` del ítem. Agregar un tipo nuevo significa crear un evaluador, registrarlo, preparar sus datos de pantalla en `StepBuilder` y crear su componente visual en `scenes/activities/`, sin tocar `LevelSession`. Los evaluadores de prioridad P2 (`ShortTextEvaluator`, `HotspotEvaluator` y `SentenceCheckEvaluator`) todavía no están implementados.

| Evaluador | Tipo de ítem | Regla |
| --- | --- | --- |
| `MultipleChoiceEvaluator` | `multiple_choice` | La opción elegida es la correcta |
| `MultiSelectEvaluator` | `multi_select` | El conjunto elegido es exactamente el correcto |
| `TrueFalseEvaluator` | `true_false` | Todas las afirmaciones bien respondidas |
| `OrderingEvaluator` | `ordering` | Secuencia idéntica |
| `MatchingEvaluator` | `matching` | Todos los pares correctos |
| `ClassificationEvaluator` | `classification` | Cada elemento en su grupo |
| `FillBlankEvaluator` | `fill_blank` | Cada espacio, con texto normalizado |
| `NumericEvaluator` | `numeric` | Valor dentro de la tolerancia y en un formato aceptado |
| `ShortTextEvaluator` | `short_text` | Coincide con una respuesta aceptada, sin distinguir mayúsculas ni tildes |
| `HotspotEvaluator` | `hotspot` | El toque cae en la zona correcta |
| `SentenceCheckEvaluator` | `sentence_check` | Sí o No coincide |
| `ReadingUnitEvaluator` | `reading_unit` | Evalúa cada ítem interno con su evaluador |

## Pruebas por capa

| Capa | Qué se prueba | Herramienta |
| --- | --- | --- |
| Dominio | Reglas: evaluadores, medidor, vidas, estrellas, escala CNEB y desbloqueo | GdUnit4, sin escenas |
| Aplicación | Casos de uso con puertos simulados (mocks) | GdUnit4 |
| Infraestructura | Repositorios SQLite, instalación de paquetes válidos y alterados | GdUnit4 con base temporal |
| Arquitectura | Regla de dependencias | Script en CI |
| Interfaz | Recorridos principales en la tablet real | Pruebas manuales guiadas |
