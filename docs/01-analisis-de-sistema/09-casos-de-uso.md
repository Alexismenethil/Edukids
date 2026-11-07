# 09. Casos de uso

CU-01 a CU-07 vienen de la v2.0 y se ajustaron al juego. CU-08 a CU-11 son nuevos.

| Código | Caso y actor | Precondición | Flujo principal | Alternativa | Resultado |
| --- | --- | --- | --- | --- | --- |
| CU-01 | Configurar la tablet · Docente | Aplicación instalada. | Registra institución, grado, secciones, PIN docente y código de docente; luego registra a sus estudiantes. | Si falta un dato obligatorio, no permite continuar. | Tablet lista para usarse sin conexión. |
| CU-02 | Descargar paquetes · Docente | Tablet en la red de la Dirección. | Abre el catálogo sin iniciar sesión, elige módulos o retos; la aplicación revisa el espacio, descarga, verifica el SHA-256 e instala. | Si se corta la red, la descarga se reanuda; si no hay espacio, se informa cuánto falta. | Paquetes disponibles sin conexión. |
| CU-03 | Ingresar · Estudiante | Estudiante registrado. | Elige su avatar e ingresa su PIN. | Con un PIN incorrecto se rechaza el ingreso; tras cinco fallos, se bloquea por un tiempo. | Perfil abierto en el mapa. |
| CU-04 | Aprender en una parada · Estudiante | Módulo habilitado. | Ve la explicación del guía y abre la ficha del módulo. | Si cierra la aplicación, retoma donde estaba. | Explicación registrada como vista. |
| CU-05 | Rendir el desafío final · Estudiante | Niveles de práctica completados o desafío habilitado por el docente; intentos disponibles. | Responde todas las preguntas, confirma la entrega y ve su calificación y la retroalimentación. | Sin intentos disponibles, pide autorización al docente. | Intento cerrado y calificado con AD, A, B o C. |
| CU-06 | Revisar el avance · Docente | Modo docente abierto con PIN. | Elige sección, área y módulo, y consulta estrellas, calificaciones y porcentajes por estudiante. | Puede exportar el reporte en CSV. | Desempeño revisado en la tablet. |
| CU-07 | Importar un paquete · Docente | Archivo del paquete en una USB o en la memoria. | Selecciona el archivo; la aplicación lo verifica e instala. | Si el archivo está dañado o contiene código, no se instala. | Paquete disponible sin internet. |
| CU-08 | Jugar un nivel de práctica · Estudiante | Nivel desbloqueado. | El guía presenta el nivel; el estudiante responde; el avatar avanza o Atoq se acerca; al terminar recibe estrellas y recompensas. | Si pierde todas las vidas, ve game over y puede reintentar. | Intento guardado con sus estrellas. |
| CU-09 | Crear y publicar un reto · Docente | Cuenta en el panel e internet. | Crea el reto, agrega preguntas, lo previsualiza y lo publica. | Si falta información obligatoria, el panel no permite publicar. | Paquete del reto en el catálogo con su código de docente. |
| CU-10 | Publicar un módulo oficial · Equipo de contenidos | Cuenta con rol de editor. | Carga o edita el módulo, lo valida y publica una versión. | Si la validación falla, no se publica. | Nueva versión del módulo en el catálogo. |
| CU-11 | Personalizar el avatar · Estudiante | Perfil abierto. | Elige rasgos y accesorios desbloqueados. | Un accesorio bloqueado muestra cuántas estrellas faltan. | Avatar guardado. |
