# ADR-016: Contenidos del CNEB con estilo PISA en tres áreas

**Estado:** Aceptada (v3.0, 06/11/2026). Los temarios están sujetos a validación docente.

## Contexto

El proyecto busca preparar a los estudiantes de 6.° grado con el enfoque de las evaluaciones PISA, que mide lectura, matemática y ciencias. La v2.0 solo tenía Matemática y Comunicación.

## Decisión

- Tres áreas: **Matemática**, **Comunicación** y **Ciencia y Tecnología**, con 9 módulos cada una.
- El **nivel** lo fija el CNEB para el ciclo V; el **estilo** de las preguntas sigue los marcos de PISA (unidades con estímulo real, procesos y contextos).
- Los temas se contrastaron con los libros de 6.° grado de Perú, Chile y El Salvador.
- Cada ítem lleva metadatos de competencia del CNEB, categoría o proceso PISA y dificultad.

El detalle está en [contenidos curriculares](../../06-contenidos-curriculares/README.md).

## Consecuencias

- Se producen 27 módulos en total; el MVP incluye el módulo 1 de cada área.
- Los reportes pueden agruparse por competencia gracias a los metadatos.
- Los contenidos sensibles necesitan validación docente (riesgo R-11).
