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

## Avance del Sprint 2

| Entregable | Estado |
| --- | --- |
| Proyecto Godot 4.7.2 en `android/` con la estructura Clean | Hecho |
| Raíz de composición (autoload) y navegador que inyecta presentadores | Hecho |
| Dominio base con pruebas: medidor de peligro (RN-13), estrellas (RN-11), escala AD/A/B/C (RN-12), escenas narrativas y `Result` | Hecho |
| Puertos `Clock`, `IdGenerator` y `RandomSource` con sus adaptadores del sistema | Hecho |
| GdUnit4 con 50 pruebas, verificación de dependencias y CI en GitHub Actions | Hecho |
| Identidad visual: tema de la interfaz, logotipo, Quwi por piezas, Sierra en capas y pantalla de inicio animada | Hecho (primera versión; se pule en cada sprint) |
| APK de prueba firmado en modo depuración, probado en un emulador Android 17 | Hecho (59 MB, 110 MB de memoria) |
| Base local SQLite (godot-sqlite 4.9, SQLite 3.51) con migraciones, modo WAL y pruebas; probada en Android arm64 | Hecho |
| Primer uso de SQLite: ajustes de sonido (RF-36) que persisten al reiniciar | Hecho |
| Pulido visual (picaflor, destello del logo, reacciones de Quwi) | Hecho |
| Audio de la introducción | Pendiente elegir música; se conservan los sonidos de Quwi y de los nudos al desprenderse y regresar |
| Panel de medición oculto (tres toques sobre la versión) | Hecho |
| Medición del APK en la tablet real del piloto | Pendiente: requiere la tablet. godot-sqlite no trae binario para Android de 32 bits (armeabi-v7a): si la tablet es de 32 bits, el juego funciona sin guardar y hay que compilar el plugin |

## Avance del Sprint 3

| Entregable | Estado |
| --- | --- |
| Configuración inicial (RF-01, CU-01): asistente de tres pasos (institución, secciones y acceso), con validación por campo y un quipu que marca el avance | Hecho |
| PIN docente (RF-03) de 4 a 6 números, sin series fáciles, con bloqueo de 5 minutos tras 5 fallos (RNF-08) | Hecho |
| Modo docente: estudiantes por sección; registrar, editar, cambiar de sección, desactivar y reactivar (RF-04, RN-06, RN-07) | Hecho |
| Restablecer el PIN de un estudiante (RF-17) y PIN sugerido al azar | Hecho |
| El modo docente se cierra solo tras 5 minutos sin uso | Hecho |
| Ingreso del estudiante (RF-05, CU-03): perfiles por sección con su personaje y PIN de 4 números que se ata como nudos de un quipu; bloqueo tras 5 fallos | Hecho |
| Avatar base (RF-31): niña o niño, 6 tonos de piel, 6 peinados, 5 colores de cabello y 8 de ropa; editor «¡Crea tu personaje!» con «Sorpréndeme» | Hecho |
| PIN guardado con PBKDF2-HMAC-SHA256 y sal aleatoria; nunca en texto claro | Hecho |
| Repositorios SQLite de institución, secciones, docente y estudiantes, con respaldo en memoria | Hecho |
| Modo demostración con aula ficticia en una base aparte, para grabar y probar | Hecho |
| Pruebas: 151 (70 nuevas) y verificación de dependencias | Hecho |
| Prueba en Android (emulador de tablet 2560 × 1600): teclado en pantalla, validación, PIN docente y de estudiante, avatar y datos que siguen ahí al cerrar la app | Hecho; falta repetirla en la tablet real del piloto |
| Habilitación de paquetes por sección (RF-09) | Pasa al Sprint 7, cuando existan paquetes |

## Avance del Sprint 4

| Entregable | Estado |
| --- | --- |
| Tipos de ítem P1 con su evaluador: opción múltiple, selección múltiple, verdadero o falso, ordenar, emparejar, clasificar, completar, respuesta numérica y unidad de lectura (RF-12) | Hecho |
| Respuestas escritas sin distinguir mayúsculas ni tildes; números con coma o punto, fracciones y números mixtos equivalentes (0,5 = 1/2) | Hecho |
| Sesión del nivel: retroalimentación por opción, pregunta fallada que vuelve una vez al final (RF-29), pista que no suma acierto válido (RN-11) y pista ofrecida por el guía tras dos errores seguidos (RF-26) | Hecho |
| Unidades de lectura con el texto, la tabla o la imagen siempre a la vista (RF-28, RN-17) | Hecho |
| Guardado de intentos: cada respuesta en el momento (RNF-06), cierre con aciertos, porcentaje, pistas y estrellas (RF-14, RF-25); el nivel continúa donde se quedó al reabrir la aplicación | Hecho |
| Lectura y validación del manifiesto y de los niveles del formato de paquete v1 | Hecho (la instalación de paquetes descargados queda para el Sprint 7) |
| Módulos 0 de práctica de las tres áreas, con contenido original ambientado en Ayacucho y los 9 tipos de ítem | Hecho; falta la revisión de los docentes de 6.° grado |
| Pantalla del nivel con la mecánica clásica, quipu de avance, retroalimentación, pistas de Quwi y resultados con estrellas; los niveles aparecen en el inicio del estudiante | Hecho |
| Pruebas: 228 (77 nuevas) y verificación de dependencias | Hecho |
| Prueba en Android (emulador de tablet 2560 × 1600): tocar opciones, teclado del juego, arrastrar tarjetas, tender cuerdas, llenar canastas y continuar el nivel después de cerrar la aplicación | Hecho; falta repetirla en la tablet real del piloto |
| Tipos P2 (respuesta breve, tocar en la imagen y ¿tiene sentido?) | Pendientes: el registro de evaluadores ya permite agregarlos sin tocar la sesión |
| Vidas, medidor de peligro, Atoq y game over (RN-13, RN-14) | Sprint 5, con las mecánicas |

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

- [ ] Ficha técnica de la tablet: modelo, versión de Android, RAM, almacenamiento libre y GPU (necesaria para cerrar el Sprint 2).
- [ ] Número de tablets y si serán individuales o compartidas.
- [ ] Velocidad de la conexión de la Dirección.
- [ ] Validación de los temarios con los docentes de 6.° grado.
- [ ] Guía del capítulo Costa y decisión sobre el ranking de sección.
- [ ] Hosting del backend y responsable del catálogo después del proyecto.
