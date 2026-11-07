# 07. Decisiones arquitectónicas

Cada decisión se documenta como un ADR (registro de decisión de arquitectura) en la carpeta [decisiones](decisiones/). Las ADR-001 a ADR-008 vienen de la v2.0 (en ese documento se numeraban ADR-01 a ADR-08).

**Estados:** *Aceptada* = vigente; *Propuesta* = pendiente de confirmar; *Modificada* = vigente con cambios de otra ADR; *Reemplazada* = ya no aplica.

| Código | Decisión | Estado | Razón principal |
| --- | --- | --- | --- |
| [ADR-001](decisiones/ADR-001-offline-first.md) | Operación offline en el aula | Aceptada | Los salones no tienen internet. |
| [ADR-002](decisiones/ADR-002-modulos-descargables.md) | Paquetes completos de contenido | Aceptada | Evita depender de la conexión de la Dirección. |
| [ADR-003](decisiones/ADR-003-persistencia-local.md) | Progreso y notas solo en la tablet | Aceptada | Privacidad y funcionamiento sin red. |
| [ADR-004](decisiones/ADR-004-nube-limitada.md) | Nube limitada, sin datos de estudiantes | Modificada por ADR-012 | Protege a los estudiantes y reduce costos. |
| [ADR-005](decisiones/ADR-005-dos-actores-en-la-tablet.md) | Dos actores en la tablet: docente y estudiante | Aceptada | Operación simple en el aula. |
| [ADR-006](decisiones/ADR-006-apk-con-capacitor.md) | APK con Capacitor | Reemplazada por ADR-009 | El producto ahora es un videojuego. |
| [ADR-007](decisiones/ADR-007-sqlite-base-local.md) | SQLite como base local | Aceptada | Durabilidad y consultas para los reportes. |
| [ADR-008](decisiones/ADR-008-configuracion-sin-datos-fijos.md) | Configuración sin datos fijos de una institución | Aceptada | Réplica en otras escuelas. |
| [ADR-009](decisiones/ADR-009-godot-como-motor.md) | Godot 4.7 con GDScript, 2D y renderizador Compatibility | Aceptada | Motor de juego libre, liviano y con exportación a Android. |
| [ADR-010](decisiones/ADR-010-clean-architecture.md) | Clean Architecture en el juego, el backend y el panel | Aceptada | Reglas fáciles de probar e independientes del motor y de la infraestructura. |
| [ADR-011](decisiones/ADR-011-panel-docente-web.md) | Panel docente web para crear retos | Aceptada | Los docentes crean ejercicios para su clase. |
| [ADR-012](decisiones/ADR-012-catalogo-publico-sin-login.md) | Catálogo público sin inicio de sesión en la tablet | Aceptada | Cliente más simple y sin credenciales en las tablets. |
| [ADR-013](decisiones/ADR-013-paquetes-solo-datos-y-pdf-a-imagenes.md) | Paquetes solo de datos y PDF convertidos a imágenes | Aceptada | Seguridad y ausencia de visor PDF en Godot. |
| [ADR-014](decisiones/ADR-014-calificacion-escala-cneb.md) | Calificación con la escala del CNEB | Aceptada | Coherencia con la evaluación de primaria en el Perú. |
| [ADR-015](decisiones/ADR-015-arte-2d-y-audio-sin-voces.md) | Arte 2D caricaturesco y audio sin voces | Aceptada | Estilo limpio, liviano y fácil de producir. |
| [ADR-016](decisiones/ADR-016-contenidos-cneb-estilo-pisa.md) | Contenidos del CNEB con estilo PISA en tres áreas | Aceptada | Aprendizajes del grado con evaluación auténtica. |
| [ADR-017](decisiones/ADR-017-stack-backend-y-panel.md) | Tecnologías del backend y del panel | Propuesta | Experiencia previa del autor y adaptadores reemplazables. |
