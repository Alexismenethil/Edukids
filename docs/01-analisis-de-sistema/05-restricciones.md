# 05. Restricciones, supuestos y pendientes

## Restricciones

| Restricción | Tratamiento |
| --- | --- |
| Solo la Dirección tiene internet; los salones de 6.° A y 6.° B no tienen conexión. | Juego 100 % offline; descargas en la Dirección o por USB. |
| Las tablets son Android con RAM de gama media. | 2D, renderizador Compatibility, presupuesto de rendimiento y paquetes livianos. |
| Las tablets se usan una vez por semana, durante 2 horas. | Niveles cortos y regulares, pausas y módulos de unas 2 horas. |
| No habrá voces ni narración; solo música y efectos. | Textos breves, iconos y diálogos en globos. |
| La arquitectura debe ser Clean Architecture. | Capas y regla de dependencias en el juego, el backend y el panel ([ADR-010](decisiones/ADR-010-clean-architecture.md)). |
| Los contenidos deben seguir el CNEB con el enfoque PISA. | Temarios en [06. Contenidos curriculares](../06-contenidos-curriculares/README.md). |
| Los libros oficiales de referencia tienen derechos reservados. | Solo se usan para identificar temas; todo el contenido es original. |
| El desarrollo lo realiza una sola persona. | Prioridades P1, P2 y P3, MVP acotado y documentación al día. |

## Supuestos

| Supuesto | Cómo se valida |
| --- | --- |
| Las tablets tienen GPU con OpenGL ES 3.0 y espacio para al menos dos módulos por área. | Ficha técnica y APK de prueba en el Sprint 2. |
| La conexión de la Dirección permite descargar un módulo en un tiempo razonable. | Medición con un paquete de prueba. |
| Los docentes pueden usar el panel web desde una computadora o un celular con internet. | Consulta con los docentes antes del Sprint 8. |
| Los docentes de 6.° grado validan los temarios y los ítems. | Acuerdo con la Dirección. |

## Decisiones pendientes

- [POR CONFIRMAR: modelo, versión de Android, RAM, almacenamiento libre y GPU de las tablets]
- [POR CONFIRMAR: número de tablets y si serán individuales o compartidas]
- [POR CONFIRMAR: rangos de AD, A, B y C y número de intentos del desafío final con los docentes]
- [POR CONFIRMAR: guía del capítulo Costa (propuesta: Humbi, el pingüino de Humboldt)]
- [POR CONFIRMAR: inclusión del ranking de sección]
- [POR CONFIRMAR: proveedor de hosting y responsable del catálogo y de las cuentas docentes después del proyecto]
- [POR CONFIRMAR: licencia del proyecto]
- [POR CONFIRMAR: autorización institucional para el tratamiento de datos de estudiantes y de evidencias fotográficas]
- [POR CONFIRMAR: redacción de los contenidos sensibles (pubertad y prevención de drogas) con los docentes]

## Fuera de alcance

- Sincronización de resultados con un servidor o un panel central de notas.
- Rol de administrador dentro de la tablet.
- Videoconferencias, mensajería, chat o red social escolar.
- Matrícula, notas oficiales e integración con SIAGIE.
- Generación de contenido con inteligencia artificial dentro de la aplicación.
- Publicación en Google Play y versión para iOS.
- Voces, narración o doblaje.
- Modo multijugador en línea.
- Producción de los 27 módulos completos dentro del MVP.
