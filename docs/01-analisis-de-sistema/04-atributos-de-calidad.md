# 04. Atributos de calidad y requisitos no funcionales

Los valores numéricos son objetivos que se validan con la tablet real en el Sprint 2. RNF-01 a RNF-12 vienen de la v2.0 (algunos actualizados) y RNF-13 a RNF-18 son nuevos.

| Código | Atributo | Requisito | Verificación |
| --- | --- | --- | --- |
| RNF-01 | Operación offline | Todas las funciones de estudiante y docente, salvo el catálogo y la descarga, funcionan sin internet. | Módulo completo recorrido en modo avión. |
| RNF-02 | Rendimiento *(actualizado)* | 60 fps como objetivo y nunca menos de 30 fps; un nivel carga en 3 s o menos; las pantallas de menú, en 2 s o menos; la reacción a un toque empieza en menos de 100 ms. | Monitor de rendimiento de Godot en la tablet de referencia. |
| RNF-03 | Usabilidad infantil *(actualizado)* | Botones de al menos 56 dp (recomendado 64 dp), textos cortos, iconos acompañados de texto y como máximo tres toques para llegar a un nivel. | Prueba guiada con estudiantes y docentes. |
| RNF-04 | Compatibilidad *(actualizado)* | Funciona en las tablets de la institución: GPU con OpenGL ES 3.0 y la versión de Android que exija la versión fijada de Godot. | Matriz de pruebas en dispositivos reales. |
| RNF-05 | Tamaño *(actualizado)* | APK de 150 MB o menos; cada paquete de módulo de 50 MB o menos como objetivo y nunca más de 100 MB; descarga reanudable. | Medición de los paquetes generados y de la descarga en la Dirección. |
| RNF-06 | Durabilidad de datos | Cada respuesta se guarda en una transacción en el momento; los datos resisten cierres, reinicios y falta de batería. | Apagado forzado durante un nivel y un desafío final sin perder respuestas confirmadas. |
| RNF-07 | Privacidad | Los datos de los estudiantes no salen de la tablet, salvo la exportación que hace el docente. | Revisión del tráfico de red y del modelo de datos de la nube. |
| RNF-08 | Seguridad *(actualizado)* | PIN guardado con hash y sal, con bloqueo temporal tras 5 intentos fallidos; HTTPS en el catálogo y las descargas; verificación SHA-256; paquetes sin código; en el panel, contraseñas con hash robusto, sesión con token de vida corta y límite de intentos de inicio de sesión. | Revisión de código y pruebas con paquetes alterados. |
| RNF-09 | Portabilidad | Ningún dato de una institución queda fijo en el código; todo se define en la configuración. | Instalación de prueba con datos de otra escuela. |
| RNF-10 | Mantenibilidad del contenido *(actualizado)* | Los módulos y retos se crean sin programar, con el panel y el formato de paquete documentado. | Crear un reto en el panel y un módulo siguiendo la guía de formato. |
| RNF-11 | Accesibilidad *(actualizado)* | Contraste WCAG AA; ninguna información se transmite solo con color; tipografía legible; tamaño de texto ajustable (P2). | Lista de verificación de accesibilidad del MVP. |
| RNF-12 | Trazabilidad | Cada requisito P1 se relaciona con una historia, un caso de uso, una prueba y una evidencia. | Matriz de trazabilidad completa antes del piloto. |
| RNF-13 | Memoria | El juego usa 400 MB de memoria o menos durante un nivel en la tablet de referencia. | Monitor de memoria de Godot y de Android. |
| RNF-14 | Batería y temperatura | Una sesión de 2 horas no agota una tablet con la carga completa ni la calienta en exceso (objetivo: 40 % de batería o menos). [POR CONFIRMAR con la tablet real] | Prueba de una sesión completa. |
| RNF-15 | Clean Architecture | En el juego, el dominio y la aplicación no dependen de Godot (nodos, escenas, archivos o red) ni de la infraestructura. En el backend, no dependen de Fastify, Prisma ni del almacenamiento. | Verificación automática de dependencias en CI y revisión de cada pull request. |
| RNF-16 | Testabilidad | Cobertura de pruebas de 80 % o más en el dominio y los casos de uso; las pruebas corren sin interfaz gráfica. | Reporte de cobertura en CI. |
| RNF-17 | Calidad del contenido | Cada ítem tiene metadatos completos y un docente lo aprueba antes de publicarlo. | Lista de control de calidad del ítem. |
| RNF-18 | Continuidad sin nube | Si el catálogo no responde, la escuela puede instalar paquetes por USB. | Prueba de importación con la nube apagada. |
