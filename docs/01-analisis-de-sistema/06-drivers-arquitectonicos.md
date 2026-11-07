# 06. Drivers arquitectónicos

Los drivers son las condiciones que más influyen en la arquitectura. DA-01 a DA-03, DA-06 y DA-07 vienen de la v2.0. El driver de la v2.0 "Entrega en 12 semanas" se retiró porque el plazo ya no es fijo.

| Código | Driver | Prioridad | Implicación |
| --- | --- | --- | --- |
| DA-01 | Aula sin internet | Alta | Toda la experiencia de estudiante y docente funciona sin conexión. |
| DA-02 | Paquetes descargables y verificados | Alta | Descarga reanudable, verificación SHA-256, control de espacio e importación por USB. |
| DA-03 | Datos solo en la tablet | Alta | Almacenamiento local durable y protegido; la nube no recibe datos de estudiantes. |
| DA-04 | Experiencia de juego inmersiva para niños | Alta | Motor de juego 2D, animación fluida, interfaz limpia y caricaturesca. |
| DA-05 | Tablets de gama media | Alta | Presupuesto de rendimiento, memoria y tamaño; renderizador Compatibility. |
| DA-06 | Replicabilidad | Media | Ningún dato de una institución fijo en el código; catálogo público y paquetes por USB. |
| DA-07 | Contenido independiente del APK | Alta | Módulos y retos como paquetes de datos que se publican sin actualizar la aplicación. |
| DA-08 | Clean Architecture y mantenibilidad | Alta | Reglas del juego y de la evaluación aisladas, fáciles de probar y sin dependencia del motor. |
| DA-09 | Contenido creado por docentes | Alta | Panel web, backend que genera paquetes y catálogo filtrado por código de docente. |
| DA-10 | Alineación curricular CNEB y PISA | Alta | Metadatos curriculares en cada ítem y reportes por competencia. |
