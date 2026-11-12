# EduKids

Videojuego educativo 2D para tablets Android que refuerza **Matemática**, **Comunicación** y **Ciencia y Tecnología** en estudiantes de **6.° grado de primaria**. Los contenidos siguen el Currículo Nacional de la Educación Básica (CNEB) con el enfoque de las evaluaciones PISA, y la aventura recorre la **Sierra**, la **Selva** y la **Costa** del Perú, con Ayacucho como punto de partida. En el aula funciona **100 % sin internet**.

| Campo | Detalle |
| --- | --- |
| Proyecto | Servicio Social Universitario IS 480, Escuela Profesional de Ingeniería de Sistemas, Universidad Nacional de San Cristóbal de Huamanga |
| Institución piloto | I.E. N.° 38984-22 Alfredo Mendoza Salazar, Mollepata II, Ayacucho |
| Autor | Alexis Huamani Rivera |
| Versión de la documentación | 3.0 (noviembre de 2026) |
| Estado | Sprint 5 implementado y en revisión (mapa, mecánicas, vidas, game over y desafío final); el siguiente es el Sprint 6 de arte, animación y audio. |

## Cómo funciona

La siguiente descripción presenta la visión completa del producto; algunas funciones todavía están pendientes según el [plan de trabajo](docs/PLAN-DE-TRABAJO.md).

- **En el aula, sin internet:** cada estudiante entra con su avatar y un PIN, recorre el mapa de aventura y resuelve niveles. Cada respuesta correcta hace avanzar a su personaje y cada error acerca al zorro Atoq. Gana estrellas, insignias y cartas, y rinde el desafío final de cada módulo, que se califica con la escala AD, A, B o C.
- **El docente:** en el modo docente de la tablet registra estudiantes, habilita módulos y retos, y revisa los reportes. Desde un **panel web** crea sus propios retos con preguntas sobre temas concretos.
- **En la Dirección, con internet:** la tablet descarga, sin iniciar sesión, los módulos oficiales y los retos publicados con el código del docente. También se pueden instalar por USB.
- **Privacidad:** los datos y las notas de los estudiantes nunca salen de la tablet. La nube solo guarda cuentas docentes, retos y paquetes de contenido.

## Estructura del repositorio

```text
Edukids/
├── docs/              Documentación del proyecto
├── android/           Juego en Godot 4.7 que se exporta como APK (desde el Sprint 2)
├── backend/           (próximo) API de contenidos con Clean Architecture
├── web/               (próximo) Panel docente web
├── .github/workflows/ Integración continua del juego
├── README.md
├── CONTRIBUTING.md    Ramas, commits y estilo de código
├── .gitignore
├── .gitattributes
└── .editorconfig
```

La organización interna de `android/`, `backend/` y `web/` está definida en [estructura del repositorio](docs/03-diseno-de-software/estructura-del-repositorio.md). Para abrir, probar y exportar el juego, consulta [android/README.md](android/README.md).

## Documentación

| Sección | Contenido |
| --- | --- |
| [Plan de trabajo](docs/PLAN-DE-TRABAJO.md) | Sprints, épicas y definición de terminado |
| [Glosario](docs/GLOSARIO.md) | Términos del juego, del currículo y de la arquitectura |
| [01. Análisis del sistema](docs/01-analisis-de-sistema/README.md) | Actores, historias de usuario, requisitos, calidad, restricciones, casos de uso, riesgos, decisiones (ADR) y trazabilidad |
| [02. Arquitectura de software](docs/02-arquitectura-software/README.md) | Clean Architecture, estilo, componentes y flujos principales |
| [03. Diseño de software](docs/03-diseno-de-software/README.md) | Estructura de carpetas, modelo de datos, formato de paquete, patrones y principios |
| [04. Modelo C4](docs/04-modelo-c4/README.md) | Contexto, contenedores, componentes y código |
| [05. Diseño del juego](docs/05-diseno-del-juego/README.md) | Narrativa, personajes, capítulos, mecánicas, recompensas, pantallas, arte y audio |
| [06. Contenidos curriculares](docs/06-contenidos-curriculares/README.md) | Marco PISA y CNEB, fuentes, temarios de las tres áreas y calificación |

## Tecnologías

| Parte | Tecnología | Estado |
| --- | --- | --- |
| Juego | Godot 4.7 con GDScript, 2D y renderizador Compatibility | Aceptada ([ADR-009](docs/01-analisis-de-sistema/decisiones/ADR-009-godot-como-motor.md)) |
| Arquitectura | Clean Architecture en el juego, el backend y el panel | Aceptada ([ADR-010](docs/01-analisis-de-sistema/decisiones/ADR-010-clean-architecture.md)) |
| Datos locales | SQLite con el plugin godot-sqlite | Aceptada ([ADR-007](docs/01-analisis-de-sistema/decisiones/ADR-007-sqlite-base-local.md)) |
| Paquetes de contenido | ZIP con manifiesto JSON y SHA-256, solo datos | Aceptada ([ADR-013](docs/01-analisis-de-sistema/decisiones/ADR-013-paquetes-solo-datos-y-pdf-a-imagenes.md)) |
| Pruebas del juego | GdUnit4 6.2 y verificación de capas en GitHub Actions | En uso desde el Sprint 2 |
| Backend | Node.js, TypeScript, Fastify, Prisma, PostgreSQL y almacenamiento compatible con S3 | Propuesta ([ADR-017](docs/01-analisis-de-sistema/decisiones/ADR-017-stack-backend-y-panel.md)) |
| Panel docente | React, TypeScript y Vite | Propuesta ([ADR-017](docs/01-analisis-de-sistema/decisiones/ADR-017-stack-backend-y-panel.md)) |

## Principios

1. **Offline en el aula:** ninguna función de clase depende de internet.
2. **Privacidad por diseño:** ningún dato de estudiantes sale de la tablet.
3. **Clean Architecture:** las reglas del juego y de la evaluación no dependen de Godot, de la base de datos ni de la red.
4. **Contenido como datos:** los módulos y retos se publican sin publicar un APK nuevo.
5. **Ligero:** pensado para tablets Android de gama media.
6. **Replicable:** cualquier escuela configura sus datos sin cambiar el código.

## Historial de versiones

| Versión | Fecha | Cambio principal |
| --- | --- | --- |
| 1.0 | 09/10/2026 | Aplicación con sincronización a un servidor central. |
| 2.0 | 10/10/2026 | Modelo 100 % offline con módulos descargables y revisión del avance en cada tablet. |
| 3.0 | 06/11/2026 | Videojuego en Godot, Clean Architecture, tres áreas con enfoque PISA, panel docente y catálogo público. |
| 3.1 | 06/11/2026 | Sprint 2: proyecto base del juego con Clean Architecture, pruebas, CI, identidad visual, pantalla de inicio y APK de prueba. |

## Contribuir

Revisa [CONTRIBUTING.md](CONTRIBUTING.md) antes de crear una rama o un commit.

## Licencia

Por definir con la universidad y la institución educativa.
