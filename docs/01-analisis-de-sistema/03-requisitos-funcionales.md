# 03. Requisitos funcionales

Prioridades: **P1** = MVP; **P2** = mejora del piloto; **P3** = fase posterior. Los requisitos RF-01 a RF-21 vienen de la v2.0; se indica cuáles cambiaron. Los requisitos RF-22 a RF-45 son nuevos.

## A. Configuración e identidad

| Código | Requisito | Descripción | Prioridad | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| RF-01 | Configuración inicial | En el primer uso, el docente registra la institución, el grado, las secciones, su PIN y, si lo tiene, su código de docente. | P1 | La aplicación no muestra datos fijos de otra institución. |
| RF-02 | Cuenta docente en el panel *(modificado)* | El docente se registra e inicia sesión en el panel web para crear y publicar retos. La tablet no pide una cuenta en la nube. | P1 | Las credenciales válidas acceden; las inválidas se rechazan sin revelar información interna. |
| RF-03 | PIN docente *(modificado)* | El docente entra al modo docente con su PIN, sin internet. | P1 | En modo avión, el PIN correcto abre el modo docente y uno incorrecto no. |
| RF-04 | Registro de estudiantes | El docente registra, edita y desactiva estudiantes en la tablet. | P1 | Los cambios se guardan sin conexión y cada estudiante pertenece a una sola sección. |
| RF-05 | Ingreso del estudiante *(modificado)* | El estudiante elige su avatar, que muestra su nombre, e ingresa un PIN de cuatro dígitos. | P1 | En modo avión, solo el PIN correcto abre su perfil. |
| RF-17 | Restablecer PIN | El docente restablece el PIN de un estudiante. | P2 | El PIN anterior deja de funcionar. |

## B. Catálogo, paquetes y habilitación

| Código | Requisito | Descripción | Prioridad | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| RF-06 | Catálogo público *(modificado)* | En la Dirección, la tablet consulta sin iniciar sesión los módulos oficiales por área, grado y número, y los retos del código de docente configurado, con su tamaño y versión. | P1 | Se muestran los módulos publicados de las tres áreas y solo los retos del código configurado. |
| RF-07 | Descarga de paquete | La tablet descarga el paquete completo (módulo o reto) y verifica su integridad. | P1 | Una descarga interrumpida se reanuda y un paquete dañado no se instala. |
| RF-08 | Control de espacio | Antes de descargar, la aplicación compara el tamaño del paquete con el espacio libre. | P1 | Si el espacio no alcanza, informa cuánto falta y no inicia la descarga. |
| RF-09 | Habilitación *(modificado)* | El docente habilita o deshabilita módulos, desafíos finales y retos para cada sección. | P1 | El estudiante solo puede abrir en el mapa lo habilitado para su sección. |
| RF-19 | Importar paquete por archivo | El docente instala un módulo o un reto copiado por USB o por cable. | P2 | El paquete importado funciona igual que uno descargado. |
| RF-20 | Liberar espacio | El docente elimina el contenido de un paquete terminado. | P2 | Se libera el espacio y se conservan los resultados. |
| RF-21 | Nueva versión de paquete | Si hay una versión corregida, el docente decide si la descarga. | P3 | Los intentos anteriores conservan la versión con la que se respondieron. |

## C. Aprendizaje y juego

| Código | Requisito | Descripción | Prioridad | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| RF-10 | Explicación del guía *(antes Teoría)* | El guía del capítulo presenta la teoría del módulo con diálogos breves e ilustraciones. | P1 | Se muestra completa en modo avión y queda registrada como vista. |
| RF-11 | Fichas de lectura *(antes Visor de PDF)* | El estudiante abre las fichas del módulo, cuyas páginas son imágenes, con zoom y desplazamiento. | P1 | Las fichas se abren en modo avión sin aplicaciones externas. |
| RF-12 | Niveles de práctica *(antes Ejercicios)* | El estudiante resuelve niveles con los tipos de ítem P1 (ver [tipos de ítems](../06-contenidos-curriculares/07-tipos-de-items-y-calificacion.md)). | P1 | Cada respuesta muestra si es correcta, su explicación y la reacción del guía. |
| RF-22 | Mapa de aventura | El estudiante recorre un mapa por capítulos con paradas y un sendero por área; lo no habilitado aparece con candado. | P1 | Desde el mapa se llega a cualquier nivel habilitado en máximo tres toques. |
| RF-23 | Mecánicas de nivel | Los niveles usan las mecánicas de persecución, puente o clásica, todas con el medidor de peligro (RN-13). | P1 | Un acierto hace avanzar al avatar y un error acerca a Atoq, según RN-13. |
| RF-24 | Vidas y game over | Cada nivel de práctica inicia con tres vidas; sin vidas aparece la pantalla de game over con la opción de reintentar. | P1 | El reintento crea un intento nuevo y conserva el anterior. |
| RF-25 | Estrellas | Cada nivel de práctica otorga de una a tres estrellas según RN-11. | P1 | Las estrellas coinciden con los aciertos guardados. |
| RF-26 | Guía por capítulo | Quwi (Sierra), Tunki (Selva) y Humbi (Costa) presentan los niveles, dan pistas y reaccionan a cada respuesta. | P1 | Tras dos errores seguidos, el guía ofrece una pista. |
| RF-27 | Niveles cortos y regulares | Hay niveles cortos (3 a 5 min) y regulares (8 a 12 min). | P1 | Cada nivel declara su tipo y su duración estimada en el paquete. |
| RF-28 | Unidades de lectura | Una unidad presenta un estímulo y varias preguntas; el texto sigue disponible mientras se responde. | P1 | Desde cualquier pregunta de la unidad se puede volver al texto. |
| RF-29 | Repetición de errores | Una pregunta fallada vuelve una vez al final del nivel. | P2 | La segunda respuesta se registra, pero no cuenta para las estrellas. |

## D. Evaluación y reportes

| Código | Requisito | Descripción | Prioridad | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| RF-13 | Desafío final *(antes Examen)* | El estudiante rinde el desafío final con intentos limitados, sin vidas ni medidor de peligro, y recibe su calificación y la retroalimentación al terminar. | P1 | Al confirmar, el intento se cierra, se califica con AD, A, B o C y no se puede modificar. |
| RF-14 | Puntaje y progreso | El sistema calcula aciertos, porcentaje, estrellas, tiempo e intentos, y guarda el avance automáticamente. | P1 | Al reabrir la aplicación, el estudiante continúa desde el último avance guardado. |
| RF-15 | Reporte docente | El docente consulta en la tablet el avance, las estrellas, la calificación y el porcentaje por estudiante, área y módulo. | P1 | El reporte coincide con los intentos guardados. |
| RF-16 | Nuevo intento del desafío final | El docente autoriza un intento adicional a un estudiante. | P2 | El nuevo intento se registra por separado y conserva el anterior. |
| RF-18 | Exportar reporte *(modificado)* | El docente exporta el reporte en CSV a la memoria o a una USB. La exportación en PDF queda para una fase posterior. | P2 | El archivo incluye estudiante, sección, área, módulo, estrellas, calificación, porcentaje y fecha, y no incluye el PIN. |
| RF-30 | Configurar la evaluación | El docente ajusta los rangos de AD, A, B y C y el número de intentos del desafío final. | P2 | Los cambios solo se aplican a los intentos nuevos. |

## E. Recompensas y experiencia

| Código | Requisito | Descripción | Prioridad | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| RF-31 | Avatar | El estudiante elige y personaliza su avatar: niño o niña, tono de piel, peinado y colores. | P1 | El avatar se guarda en su perfil. |
| RF-32 | Accesorios | Los accesorios del avatar se desbloquean al acumular estrellas. | P2 | Un accesorio queda disponible al alcanzar su umbral de estrellas. |
| RF-33 | Insignias | El estudiante gana insignias al cumplir logros. | P2 | Cada insignia se otorga una sola vez al cumplir su condición. |
| RF-34 | Álbum de cartas | El estudiante colecciona cartas de animales, plantas, lugares y costumbres, cada una con un dato breve. | P2 | La carta obtenida aparece en el álbum con su dato. |
| RF-35 | Quipu de progreso | Cada desafío final completado agrega al quipu una cuerda del color del área. | P2 | El quipu refleja los desafíos completados. |
| RF-36 | Música y efectos | El juego tiene música por capítulo y efectos de sonido, sin voces, con volumen ajustable. | P1 | La música y los efectos se pueden silenciar por separado. |
| RF-37 | Recordatorio de pausa | El juego sugiere una pausa activa cada cierto tiempo (por defecto, 40 minutos); el docente lo configura. | P2 | El aviso aparece al terminar el nivel en curso, nunca a mitad de una pregunta. |
| RF-38 | Ranking de sección | Ranking opcional, desactivado por defecto. [POR CONFIRMAR: si se incluye] | P3 | Solo se muestra si el docente lo activa. |

## F. Panel docente y nube

| Código | Requisito | Descripción | Prioridad | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| RF-39 | Crear retos | El docente crea un reto: elige capítulo, área y mecánica, y redacta preguntas con imágenes, retroalimentación y pistas. | P1 | El panel no guarda un reto sin respuesta correcta o sin retroalimentación. |
| RF-40 | Vista previa del reto | El docente prueba el reto en el navegador antes de publicarlo. | P2 | La vista previa aplica las mismas reglas de corrección que el juego. |
| RF-41 | Publicar reto | Al publicar, el backend genera un paquete versionado (ZIP, manifiesto y SHA-256) asociado al código del docente. | P1 | El reto aparece en el catálogo de las tablets configuradas con ese código. |
| RF-42 | Fichas PDF en el panel | El panel convierte cada página de un PDF a imagen al publicar. | P2 | Las páginas se leen con claridad en la tablet. |
| RF-43 | Exportar paquete para USB | El panel descarga el paquete de un reto o módulo como archivo. | P2 | El archivo se puede importar con RF-19. |
| RF-44 | Publicar módulos oficiales | El equipo de contenidos publica y versiona los módulos de las tres áreas. | P1 | El catálogo muestra la última versión y conserva las anteriores. |
| RF-45 | API de catálogo y descargas | La API pública es de solo lectura y permite descargas por rangos. | P1 | Una descarga se reanuda desde el último byte recibido. |

## Reglas de negocio

| Código | Regla |
| --- | --- |
| RN-01 | Un estudiante solo puede abrir los módulos, desafíos finales y retos habilitados para su sección. |
| RN-02 | Los estudiantes avanzan módulo por módulo; el docente decide cuándo habilitar el siguiente. |
| RN-03 | Los niveles de práctica permiten reintentos ilimitados; el desafío final tiene intentos limitados (por defecto, 2). |
| RN-04 | Un intento cerrado del desafío final no se modifica; un nuevo intento genera otro registro. |
| RN-05 | Cada intento conserva la versión del paquete con la que se respondió. |
| RN-06 | Solo el docente registra estudiantes, habilita paquetes, configura la evaluación y consulta los reportes. |
| RN-07 | Un estudiante con resultados no se elimina; se desactiva. |
| RN-08 | La nube no almacena datos personales ni resultados de estudiantes; solo cuentas docentes, retos y paquetes. |
| RN-09 | Al liberar el espacio de un paquete se conservan sus resultados. |
| RN-10 | El desafío final no usa vidas, medidor de peligro ni game over: se responde completo y se califica. |
| RN-11 | Estrellas. Un **acierto válido** es una pregunta respondida bien al primer intento y sin pista. ★ = completar el nivel; ★★ = aciertos válidos ≥ 70 %; ★★★ = aciertos válidos ≥ 90 % y sin perder vidas. |
| RN-12 | Escala por defecto del desafío final: AD de 90 % a 100 %, A de 70 % a 89 %, B de 55 % a 69 % y C de 0 % a 54 %. El docente puede ajustarla. La calificación es referencial. |
| RN-13 | Medidor de peligro: empieza en 2; cada acierto suma 1 (máximo 4) y cada error resta 1. En 0, Atoq alcanza al avatar, se pierde una vida y el medidor vuelve a 2. Estos valores se pueden configurar por nivel en el paquete. |
| RN-14 | Cada nivel de práctica empieza con 3 vidas; con 0 vidas termina en game over y se puede reintentar de inmediato. |
| RN-15 | Un reto solo aparece en las tablets configuradas con el código de su docente y habilitado para la sección. |
| RN-16 | Los paquetes solo contienen datos y medios (JSON, imágenes y audio); nunca código ejecutable. |
| RN-17 | En las unidades de lectura el texto siempre está disponible y no hay límite de tiempo; el tiempo se registra solo para los reportes. |
| RN-18 | Dentro de un módulo, los niveles se desbloquean en orden; el desafío final se abre al completar los niveles de práctica o cuando el docente lo habilita. |
| RN-19 | Los retos no deben incluir nombres ni datos personales de estudiantes; el panel lo advierte antes de publicar. |
