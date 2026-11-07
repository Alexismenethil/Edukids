# Plan de trabajo

El proyecto avanza por sprints, cada uno con un entregable que se puede verificar. Las fechas se fijan al iniciar cada sprint.

## Sprints

| Sprint | Objetivo | Entregable | Épicas |
| --- | --- | --- | --- |
| 1 | Documentación v3.0 | Este repositorio: análisis, arquitectura, diseño, C4, diseño del juego y temarios | — |
| 2 | Base técnica del juego | Proyecto Godot en `android/` con estructura Clean, raíz de composición, SQLite, pruebas y verificación de dependencias en CI; APK de prueba medido en la tablet real | E1 |
| 3 | Aula e identidad | Configuración inicial, secciones, estudiantes, PIN docente y de estudiante, perfiles y avatar base | E2 |
| 4 | Motor de actividades | Tipos de ítem P1, evaluadores, retroalimentación, pistas y guardado de intentos | E3 |
| 5 | Mecánicas de juego | Mapa, persecución, puente, mecánica clásica, medidor de peligro, vidas, game over, estrellas y desafío final con escala CNEB | E4 |
| 6 | Arte, animación y audio del MVP | Avatar, Quwi, Atoq, Mama Sisa, parada Huamanga, mapas, interfaz, música y efectos, con optimización | E5 |
| 7 | Paquetes | Formato v1, instalación verificada, importación por USB, cliente del catálogo y descarga reanudable | E6 |
| 8 | Backend y panel docente | API con catálogo público y cuentas docentes; panel para crear, previsualizar y publicar retos | E7, E8 |
| 9 | Contenido del MVP | MAT-01, COM-01 y CYT-01 producidos y validados por docentes | E9 |
| 10 | Reportes y piloto | Reportes y exportación CSV; pruebas con estudiantes; correcciones y guía de réplica | E10, E11 |

## Épicas

| Código | Épica | Resultado | Depende de |
| --- | --- | --- | --- |
| E1 | Base técnica | Proyecto Godot con Clean Architecture, CI y APK de prueba | — |
| E2 | Aula e identidad | Configuración, estudiantes, PIN, perfiles y habilitación de paquetes | E1 |
| E3 | Motor de actividades | Ítems P1 evaluados, con retroalimentación y guardados | E1 |
| E4 | Mecánicas de juego | Mapa, niveles, persecución, vidas, estrellas y desafío final | E3 |
| E5 | Arte y audio | Recursos del MVP integrados y optimizados | E4 |
| E6 | Paquetes | Instalación, importación por USB, catálogo y descargas | E3 |
| E7 | Backend | API de contenidos y generación de paquetes | E6 (formato de paquete) |
| E8 | Panel docente | Crear, previsualizar y publicar retos | E7 |
| E9 | Contenidos | Módulo 1 de las tres áreas | E6 |
| E10 | Reportes | Reporte docente y exportación | E2, E4 |
| E11 | Piloto y réplica | Evidencias del piloto y guía para otras escuelas | E1 a E10 |

## Definición de terminado

Una tarea está terminada cuando:

- cumple sus criterios de aceptación y está enlazada a sus requisitos;
- tiene pruebas automáticas (dominio y casos de uso) que pasan en CI;
- respeta la regla de dependencias de Clean Architecture;
- funciona en modo avión en la tablet de referencia, si es una función de aula;
- está documentada (README, ADR o `docs/`) y revisada en un pull request.

El MVP está terminado cuando:

- los requisitos P1 están implementados y trazados a sus pruebas;
- MAT-01, COM-01 y CYT-01 están validados por los docentes;
- un estudiante completa un módulo entero en modo avión y su calificación aparece en el reporte;
- un reto creado en el panel llega a la tablet por descarga y por USB;
- la descarga se probó con la conexión real de la Dirección;
- la aplicación se instaló y configuró con los datos de una segunda institución de prueba;
- no hay defectos críticos abiertos en el ingreso, el guardado o la calificación.

## Pendientes antes del Sprint 2

- [ ] Ficha técnica de la tablet: modelo, versión de Android, RAM, almacenamiento libre y GPU.
- [ ] Número de tablets y si serán individuales o compartidas.
- [ ] Velocidad de la conexión de la Dirección.
- [ ] Validación de los temarios con los docentes de 6.° grado.
- [ ] Guía del capítulo Costa y decisión sobre el ranking de sección.
- [ ] Hosting del backend y responsable del catálogo después del proyecto.
