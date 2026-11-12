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
| Audio de la introducción | Música de prueba de Firage incluida; se conservan los sonidos de Quwi y de los nudos al desprenderse y regresar |
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
| Retos adicionales de práctica: fracciones y probabilidad, comprensión lectora e interpretación de datos | Primera versión; falta la revisión de los docentes de 6.° grado |
| Pantalla del nivel con la mecánica clásica, quipu de avance, retroalimentación, pistas de Quwi y resultados con estrellas; los niveles aparecen en el inicio del estudiante | Hecho |
| Pruebas: 228 (77 nuevas) y verificación de dependencias | Hecho |
| Prueba en Android (emulador de tablet 2560 × 1600): tocar opciones, teclado del juego, arrastrar tarjetas, tender cuerdas, llenar canastas y continuar el nivel después de cerrar la aplicación | Hecho; falta repetirla en la tablet real del piloto |
| Tipos P2 (respuesta breve, tocar en la imagen y ¿tiene sentido?) | Pendientes: el registro de evaluadores ya permite agregarlos sin tocar la sesión |
| Vidas, medidor de peligro, Atoq y game over (RN-13, RN-14) | Hecho en el Sprint 5 |

## Avance del Sprint 5

| Entregable | Estado |
| --- | --- |
| Mapa del capítulo de la Sierra: Huamanga, Quinua, Pampa Galeras y Vilcashuamán unidas por el Qhapaq Ñan; las paradas sin contenido muestran un candado (RN-01). Es el nuevo inicio del estudiante | Hecho |
| Parada de Huamanga con un sendero por área (una cuerda del quipu con un nudo por nivel), estrellas por sendero y ficha del nivel antes de jugar; un nivel se abre en tres toques desde el mapa (RF-22) | Hecho |
| Orden de los niveles de cada módulo y desafío final que se abre al completar la práctica (RN-18) | Hecho; abrirlo antes desde el modo docente queda para el Sprint 7 |
| Medidor de peligro y vidas en todos los niveles de práctica, con game over y reintento (RN-13 y RN-14); perder una vida impide la tercera estrella (RN-11) | Hecho |
| Escenas a pantalla completa: cada mecánica tiene su mundo por capas con paralaje (valle, cañón y laguna), cielo con sol, rayos de luz, neblina, agua con corriente, pasto que se mece, polen, pájaros y cóndores; la cámara encuadra la franja de arriba de la tarjeta mientras se responde y abre a toda la pantalla para cada reacción | Hecho |
| Persecución: el valle corre sin fin; con cada acierto el avatar acelera y salta una piedra con una vuelta; con cada error tropieza y Atoq se acerca riendo; si lo alcanza, se lanza y se lleva un nudo; al final, el arco tejido | Hecho |
| Puente colgante: con cada acierto cae un tramo de tablas desde el cielo; con cada error sopla el viento y el puente se sacude; al perder una vida, el avatar cae al río y un cóndor lo rescata; al final, el cruce con un arco iris | Hecho |
| Coco, el caimán glotón (mecánica nueva): con cada acierto el avatar lanza una fruta de la feria y Coco salta fuera de la laguna para atraparla; con cada error salpica y muerde el aire; en 0, salta hasta el muelle y se lleva un nudo; al final, lleva al avatar en su lomo a la otra orilla | Hecho |
| Mecánica clásica con Atoq que se asoma por el costado según el medidor | Hecho |
| Desafío final (RN-10, RN-12 y RF-30): portada con el intento, respuestas guardadas sin corrección, calificación AD, A, B o C con porcentaje, cuerda del quipu (con nudo dorado en AD y A) y revisión de cada pregunta; 2 intentos por defecto | Hecho; ajustar la escala y dar intentos extra desde el modo docente queda pendiente |
| Personajes por piezas: Atoq y Coco, con rig generado desde su SVG; el avatar trota con las rodillas arriba, salta con una vuelta, tropieza y se asusta | Primera versión; el pulido de animación es del Sprint 6 |
| Menús y mapa con el mismo valle de las escenas (nubes, pájaros, polen y pasto que se mece) | Hecho |
| Borrador del módulo 1 de las tres áreas: 12 niveles y 95 preguntas, más retadores y variados (problemas de varios pasos, proporciones, datos, inferencias, hechos y opiniones, cadenas alimentarias, cambios de la materia y diseño de experimentos) | Primera versión; falta la revisión de los docentes de 6.° grado |
| Esquema SQLite v2: la tabla `level` acepta la mecánica `caiman` sin perder los intentos guardados | Hecho |
| Pruebas: 251 y verificación de dependencias | Hecho |
| Mama Sisa entregando la cuerda, insignias, cartas del álbum y accesorios | Sprint 6 (arte) y prioridad P2 |

## Avance del Sprint 6

| Entregable | Estado |
| --- | --- |
| Motor de títeres (`Puppet`): pose por capas, clips con curvas, ciclos de marcha, resortes, tiras flexibles, cara con expresiones, mirada 2.5D, emotes, toque y caricia, gestos de biblioteca | Hecho |
| Quwi, el avatar, Atoq y Coco pasados al motor, con caras nuevas (ojos apretados, de estrella, de asombro, de enojo y de mareo; bocas nuevas; cejas separadas) y la cola de caballo y las trenzas como piezas que se mecen | Hecho |
| Laboratorio de personajes (`--lab`) y guía para crear un personaje | Hecho |
| Dirección de cine en las mecánicas: pausa de impacto, golpe de zoom, destello, barras de cine, luz fría o dorada y cámara que respira | Hecho |
| Efectos vectoriales (`ToonFx`): polvo, estrellas, brillitos, golpes, anillos, salpicaduras, hojas, corazones y papel picado | Hecho |
| Pruebas: 293 y verificación de dependencias | Hecho |
| Mama Sisa entregando la cuerda, insignias, cartas del álbum y accesorios | Pendiente (arte) y prioridad P2 |
| Medición del rendimiento en la tablet real | Pendiente |

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
