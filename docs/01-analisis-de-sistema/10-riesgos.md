# 10. Riesgos y mitigaciones

R-01 a R-08 vienen de la v2.0 (actualizados). R-09 a R-16 son nuevos.

| Código | Riesgo | Impacto | Mitigación |
| --- | --- | --- | --- |
| R-01 | Las tablets no cumplen los requisitos de Godot (OpenGL ES 3.0 o versión de Android) o tienen poco espacio. | Alto | Ficha técnica antes del Sprint 2, APK de prueba en la tablet real, renderizador Compatibility y paquetes livianos. |
| R-02 | La conexión de la Dirección es lenta. | Alto | Descarga reanudable, paquetes livianos e importación por USB. |
| R-03 | Los resultados solo están en la tablet y pueden perderse por daño, robo o restablecimiento. | Alto | Exportación CSV periódica, registro de notas del docente y cuidado de las tablets. |
| R-04 | La producción de los 27 módulos excede la capacidad del proyecto. | Alto | MVP con el módulo 1 de cada área, plantillas de niveles y panel para producir contenido. |
| R-05 | Nadie mantiene la nube después del proyecto. | Medio | Plan gratuito, responsable designado, tablets sin cuentas en la nube e importación por USB. |
| R-06 | Un estudiante entra al perfil de otro. | Medio | PIN individual, bloqueo tras intentos fallidos y supervisión del docente. |
| R-07 | Se usa material con derechos de autor (fichas, imágenes o textos de los libros). | Medio | Solo material propio o con licencia abierta; los libros oficiales sirven solo como referencia. |
| R-08 | El alcance crece durante el desarrollo. | Alto | Prioridades P1, P2 y P3, y aprobación de cada cambio. |
| R-09 | La producción de arte y animación toma más tiempo del previsto. | Alto | Estilo modular, animación por piezas, recursos reutilizables entre paradas y MVP con pocos personajes. |
| R-10 | El rendimiento es bajo en tablets de gama media. | Alto | Presupuesto de rendimiento, atlas y compresión de texturas, y pruebas tempranas en la tablet real. |
| R-11 | Los contenidos sensibles (pubertad y prevención de drogas) generan rechazo. | Medio | Redacción con los docentes y lineamientos de Educación Sexual Integral. |
| R-12 | La representación cultural es inadecuada o estereotipada. | Medio | Guía de representación, revisión con docentes y, cuando sea posible, con la comunidad. |
| R-13 | Los plugins (godot-sqlite y GdUnit4) no son compatibles con la versión de Godot. | Medio | Fijar versiones, probarlas en el Sprint 2 y mantener la persistencia detrás de un puerto para poder cambiarla. |
| R-14 | Android restringe la lectura de archivos desde una USB. | Medio | Usar el selector de archivos del sistema y validarlo en el Sprint 7 con la tablet real. |
| R-15 | Los docentes no tienen tiempo o conexión para usar el panel. | Medio | Plantillas rápidas, uso desde el celular y retos de ejemplo. |
| R-16 | Una sola persona concentra el conocimiento del proyecto. | Medio | Documentación al día, ADR, pruebas automáticas y convenciones claras. |
