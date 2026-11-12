# Estructura del repositorio

## Vista general

```text
Edukids/
├── docs/              Documentación (Sprint 1)
├── android/           Juego en Godot 4.7 (desde el Sprint 2)
├── backend/           API de contenidos en Node.js y TypeScript (Sprint 8)
├── web/               Panel docente en React y TypeScript (Sprint 8)
├── .github/workflows/ CI del juego: verificación de capas y pruebas
├── README.md
├── CONTRIBUTING.md
├── .gitignore
├── .gitattributes
└── .editorconfig
```

Las carpetas `android/`, `backend/` y `web/` se crean en sus sprints. Cada una tendrá su propio README con instrucciones de instalación, pruebas y ejecución. Los números de capa corresponden a [Clean Architecture](../02-arquitectura-software/clean-architecture.md).

## Juego: `android/`

```text
android/
├── project.godot
├── export_presets.cfg            Ajustes de exportación (sin credenciales)
├── addons/                       Plugins con versión fijada: godot-sqlite y GdUnit4
├── src/
│   ├── domain/                   1. Dominio: sin nodos, sin archivos y sin red
│   │   ├── entities/             Institution, Section, Teacher, Student, StoryScene, ContentPackage, LevelEntry, Level, Item,
│   │   │                         Attempt, AttemptAnswer y Chapter (paradas del mapa)
│   │   ├── value_objects/        Pin, PinCredential, PersonName, TeacherCode, Avatar, AudioSettings, CnebGrade, TextAnswer,
│   │   │                         NumberAnswer, Evaluation, SessionStep, AnswerOutcome, LevelSummary, QuestionReview y
│   │   │                         SemanticVersion
│   │   ├── rules/                PinLockout, DangerMeter, StarRule, CnebGradeScale, LevelSession, TrailRule (RN-18) y
│   │   │                         PackageRules (contenido permitido, SHA-256, compatibilidad y habilitación por defecto)
│   │   ├── evaluators/           ItemEvaluator, EvaluatorRegistry y un evaluador por tipo de ítem P1
│   │   └── errors/
│   ├── application/              2. Aplicación
│   │   ├── use_cases/
│   │   │   ├── classroom/        ConfigureInstitution, UnlockTeacherMode, RegisterStudent, UpdateStudent, SetStudentActive,
│   │   │   │                     ResetStudentPin, LoginStudent, ListStudents, CustomizeAvatar, SuggestPin, SuggestAvatar
│   │   │   ├── play/             GetChapterMap, StartLevel, SubmitAnswer, RequestHint, ContinueLevel, FinishLevel,
│   │   │   │                     RegisterBundledPackages, LevelRecords y StepBuilder (prepara cada pregunta para la vista)
│   │   │   ├── packages/         InstallPackage, ListPackages, SetPackageAccess (RF-09) y ListImportFiles (RF-19);
│   │   │   │                     después FetchCatalog y DownloadPackage
│   │   │   ├── rewards/          GrantRewards (los accesorios de RF-32 amplían CustomizeAvatar)
│   │   │   ├── reports/          GetSectionReport, ExportReportCsv
│   │   │   ├── settings/         GetAudioSettings, RestoreAudioSettings, ToggleSound
│   │   │   └── story/            GetStoryScene (escenas narrativas)
│   │   ├── ports/                Clases base abstractas: repositorios, gateways, Clock, IdGenerator, RandomSource
│   │   └── dto/                  Objetos de petición y respuesta
│   ├── infrastructure/           3. Adaptadores de salida
│   │   ├── sqlite/               Repositorios y migraciones
│   │   ├── packages/             FolderPackageStore (lee paquetes de carpetas) y ZipPackageFiles (lee el ZIP, calcula
│   │   │                         los SHA-256 e instala en user://packages pasando por una carpeta temporal)
│   │   ├── network/              Cliente del catálogo y descarga por rangos
│   │   ├── security/             Hash del PIN (PBKDF2-HMAC-SHA256 con sal)
│   │   ├── memory/               Repositorios en memoria si SQLite no está disponible y sesiones de nivel en curso
│   │   ├── content/              Escenas narrativas del juego base en JSON
│   │   └── system/               Reloj, identificadores, archivos y exportación CSV
│   ├── presentation/             3. Adaptadores de entrada
│   │   ├── presenters/           Un presentador por pantalla
│   │   ├── view_models/
│   │   ├── styles/               Paleta del avatar y colores e iconos de cada área
│   │   └── play_session.gd       Quién entró y qué se vio mientras el juego está abierto
│   └── main/                     Raíz de composición y navegador
├── scenes/                       4. Vistas (escenas de Godot)
│   ├── ui/                       title/ (portada), profiles/ (perfiles y PIN), avatar/ (editor), teacher/ (configuración,
│   │                             PIN docente, estudiantes y paquetes) y components/ (teclado del PIN, quipu, carrusel,
│   │                             fondo de la Sierra)
│   ├── map/                      Mapa del capítulo, parada con sus senderos, nudo de cada nivel y ficha antes de jugar
│   ├── level/                    Nivel, vidas, medidor de peligro, quipu de avance, retroalimentación, resultados, game over,
│   │                             portada y calificación del desafío final
│   ├── mechanics/                Persecución, puente, caimán y clásica (Atoq que se asoma), con sus efectos y su cámara
│   ├── world/                    Mundo por capas con paralaje (ParallaxWorld), sombreadores de cielo, rayos, neblina,
│   │                             agua y viento, lo que flota en el aire (polen, pétalos, mariposas, pájaros), el humo
│   │                             de las chimeneas y fauna/ (llamas y ovejas que pastan: GrazingAnimal y sus rigs)
│   ├── activities/               Un componente visual por tipo de ítem, tarjetas, canastas y el panel de lectura
│   └── characters/               Avatar, Quwi, Atoq, Coco el caimán y fauna (cóndor); el rig de cada personaje se genera
├── assets/
│   ├── art/                      Personajes, fondos, mundos de las mecánicas (worlds/), interfaz e iconos
│   ├── audio/                    music/ y sfx/
│   ├── fonts/
│   └── themes/                   Tema de la interfaz
├── content/                      Escenas narrativas del juego base y módulos 0 de práctica (packages/)
├── art-src/                      Fuentes del arte (SVG maestros, rigs): characters/, fauna/ e icons/; tiene .gdignore y no
│                                 se exporta
├── tools/art/                    Herramientas del flujo de arte: rigs por piezas, fauna.py (animales del paisaje) y
│                                 generadores de mundos y de la portada (worlds/, Python; no se exporta)
├── tools/preview/                Galería de avatares y laboratorio de poses para revisar el arte (no se exporta)
├── builds/                       APK y videos generados (ignorado por Git)
└── tests/
    ├── unit/                     Dominio, casos de uso y presentadores, sin escenas
    ├── integration/              JSON, SQLite, paquetes y adaptadores del sistema
    └── architecture/             Verificación de dependencias (check_dependencies.sh)
```

## Backend: `backend/`

```text
backend/
├── src/
│   ├── domain/                   1. Teacher, TeacherCode, Challenge, ChallengeItem, Package y reglas del formato
│   ├── application/              2. Aplicación
│   │   ├── use_cases/            ListCatalog, GetPackageDownload, RegisterTeacher, Login,
│   │   │                         CreateChallenge, PublishChallenge, PublishOfficialModule
│   │   └── ports/                Repositorios, PackageStorage, PackageBuilder, PasswordHasher, TokenService, Clock
│   ├── infrastructure/           3. Prisma, almacenamiento S3, ZIP y SHA-256, hash de contraseñas y tokens
│   ├── interfaces/http/          3. Rutas de Fastify, esquemas Zod y presentadores
│   └── main/                     Raíz de composición y servidor
├── prisma/                       Esquema y migraciones
├── tests/                        unit/ e integration/
├── .env.example
└── package.json
```

## Panel docente: `web/`

```text
web/
├── src/
│   ├── domain/                   Modelo del reto y validaciones
│   ├── application/              Casos de uso del panel
│   ├── infrastructure/           Cliente de la API y pdf.js
│   └── ui/                       Páginas y componentes React
├── tests/
├── .env.example
└── package.json
```

## Convenciones de nombres

| Elemento | Convención | Ejemplo |
| --- | --- | --- |
| Archivos GDScript | `snake_case` | `submit_answer.gd` |
| Clases GDScript | `PascalCase` con `class_name` | `SubmitAnswer` |
| Escenas | `snake_case` | `level_chase.tscn` |
| Archivos TypeScript | `kebab-case` | `publish-challenge.ts` |
| Recursos de arte | `tipo_nombre_variante` | `char_quwi_idle.png`, `bg_sierra_huamanga_l1.webp` |
| Paquetes | Ver [formato de paquete](formato-de-paquete.md) | `mod-math-6-01-1.0.0.zip` |
