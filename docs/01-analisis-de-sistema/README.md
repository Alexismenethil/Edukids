# 01. Análisis del sistema

Requisitos y decisiones de EduKids, versión 3.0. Parte del documento *Requerimientos y arquitectura del aplicativo EduKids*, versión 2.0 (10/10/2026), y lo actualiza para el videojuego en Godot. Se conservan los códigos de la v2.0 y se agregan los nuevos a continuación.

## Documentos

| Documento | Contenido |
| --- | --- |
| [01. Actores](01-actores.md) | Quién usa el sistema y con qué permisos |
| [02. Historias de usuario](02-historias-de-usuario.md) | HU-01 a HU-22 |
| [03. Requisitos funcionales](03-requisitos-funcionales.md) | RF-01 a RF-45 y reglas de negocio RN-01 a RN-19 |
| [04. Atributos de calidad](04-atributos-de-calidad.md) | Requisitos no funcionales RNF-01 a RNF-18 |
| [05. Restricciones](05-restricciones.md) | Restricciones, supuestos, pendientes y fuera de alcance |
| [06. Drivers arquitectónicos](06-drivers-arquitectonicos.md) | DA-01 a DA-10 |
| [07. Decisiones arquitectónicas](07-decisiones-arquitectonicas.md) | Índice de ADR-001 a ADR-017 |
| [08. Escenarios de calidad y aceptación](08-escenarios-atributos-calidad.md) | Criterios CA-01 a CA-20 |
| [09. Casos de uso](09-casos-de-uso.md) | CU-01 a CU-11 |
| [10. Riesgos](10-riesgos.md) | R-01 a R-16 |
| [11. Matriz de trazabilidad](11-matriz-de-trazabilidad.md) | Relación entre requisitos, historias, casos, pruebas y épicas |

## Cambios respecto de la v2.0

| Tema | v2.0 | v3.0 |
| --- | --- | --- |
| Producto | Aplicación con teoría, PDF, ejercicios y examen | Videojuego 2D con mapa, mecánicas, guías y recompensas, con la misma estructura de módulo |
| Tecnología | React, TypeScript, Vite y Capacitor | Godot 4.7 con GDScript ([ADR-009](decisiones/ADR-009-godot-como-motor.md)) |
| Arquitectura | Monolito modular sugerido | Clean Architecture obligatoria en el juego, el backend y el panel ([ADR-010](decisiones/ADR-010-clean-architecture.md)) |
| Áreas | Matemática y Comunicación | Matemática, Comunicación y Ciencia y Tecnología ([ADR-016](decisiones/ADR-016-contenidos-cneb-estilo-pisa.md)) |
| Contenidos | Por definir con los docentes | Temarios del CNEB con estilo PISA, contrastados con Perú, Chile y El Salvador |
| Acceso a la nube desde la tablet | Cuenta docente para descargar | Catálogo público sin inicio de sesión, filtrado por código de docente ([ADR-012](decisiones/ADR-012-catalogo-publico-sin-login.md)) |
| Creación de contenido | Equipo de contenidos, fuera de la aplicación | Además, panel web para que el docente cree retos ([ADR-011](decisiones/ADR-011-panel-docente-web.md)) |
| Examen | Nota sin escala definida | Desafío final con escala AD, A, B y C ([ADR-014](decisiones/ADR-014-calificacion-escala-cneb.md)) |
| PDF | Visor PDF.js | Páginas convertidas a imágenes al empaquetar ([ADR-013](decisiones/ADR-013-paquetes-solo-datos-y-pdf-a-imagenes.md)) |
| Plazo | Malla de 12 semanas | Sprints, sin fecha fija |

**Se mantiene de la v2.0:** operación offline en el aula, ingreso con PIN, módulos descargables o por USB, reportes en cada tablet, ningún dato de estudiantes en la nube, instalación por APK sin tienda de aplicaciones y réplica en otras escuelas.
