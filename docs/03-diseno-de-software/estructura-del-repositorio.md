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
│   │   ├── entities/             Institution, Section, Teacher, Student, StoryScene; después Package, Level, Item, Attempt, Answer
│   │   ├── value_objects/        Pin, PinCredential, PersonName, TeacherCode, Avatar, AudioSettings, CnebGrade
│   │   ├── rules/                PinLockout, DangerMeter, StarRule, CnebGradeScale; después LevelSession y UnlockRule
│   │   ├── evaluators/           Un evaluador por tipo de ítem
│   │   └── errors/
│   ├── application/              2. Aplicación
│   │   ├── use_cases/
│   │   │   ├── classroom/        ConfigureInstitution, UnlockTeacherMode, RegisterStudent, UpdateStudent, SetStudentActive,
│   │   │   │                     ResetStudentPin, LoginStudent, ListStudents, CustomizeAvatar, SuggestPin, SuggestAvatar
│   │   │   ├── play/             StartLevel, SubmitAnswer, RequestHint, FinishLevel
│   │   │   ├── final_challenge/  StartFinalChallenge, AnswerFinalItem, SubmitFinalChallenge
│   │   │   ├── packages/         FetchCatalog, DownloadPackage, InstallPackage, ImportPackageFile, ReleasePackage
│   │   │   ├── rewards/          GrantRewards (los accesorios de RF-32 amplían CustomizeAvatar)
│   │   │   ├── reports/          GetSectionReport, ExportReportCsv
│   │   │   ├── settings/         GetAudioSettings, RestoreAudioSettings, ToggleSound
│   │   │   └── story/            GetStoryScene (escenas narrativas)
│   │   ├── ports/                Clases base abstractas: repositorios, gateways, Clock, IdGenerator, RandomSource
│   │   └── dto/                  Objetos de petición y respuesta
│   ├── infrastructure/           3. Adaptadores de salida
│   │   ├── sqlite/               Repositorios y migraciones
│   │   ├── packages/             Lectura de ZIP, validación e instalación
│   │   ├── network/              Cliente del catálogo y descarga por rangos
│   │   ├── security/             Hash del PIN (PBKDF2-HMAC-SHA256 con sal)
│   │   ├── memory/               Repositorios en memoria si SQLite no está disponible
│   │   ├── content/              Escenas narrativas del juego base en JSON
│   │   └── system/               Reloj, identificadores, archivos y exportación CSV
│   ├── presentation/             3. Adaptadores de entrada
│   │   ├── presenters/           Un presentador por pantalla
│   │   ├── view_models/
│   │   ├── styles/               Paleta del avatar (los colores de cada índice)
│   │   └── play_session.gd       Quién entró y qué se vio mientras el juego está abierto
│   └── main/                     Raíz de composición y navegador
├── scenes/                       4. Vistas (escenas de Godot)
│   ├── ui/                       title/, profiles/ (perfiles y PIN), avatar/ (editor), student/, teacher/ (configuración,
│   │                             PIN docente y estudiantes) y components/ (teclado del PIN, quipu, carrusel, fondo de la Sierra)
│   ├── map/                      Mapa general y mapas de capítulo
│   ├── level/                    Nivel, HUD, resultados y game over
│   ├── mechanics/                Persecución, puente y clásica
│   ├── activities/               Un componente visual por tipo de ítem
│   └── characters/               Avatar, guías, Atoq, Mama Sisa y fauna (cóndor); el rig de cada personaje se genera
├── assets/
│   ├── art/                      Personajes, fondos, interfaz e iconos
│   ├── audio/                    music/ y sfx/
│   ├── fonts/
│   └── themes/                   Tema de la interfaz
├── content/                      Escenas narrativas del juego base y paquete de demostración
├── art-src/                      Fuentes del arte (SVG maestros, rigs); tiene .gdignore y no se exporta
├── tools/art/                    Herramientas del flujo de arte (generar rigs por piezas)
├── tools/preview/                Galería de avatares para revisar el arte (no se exporta)
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
