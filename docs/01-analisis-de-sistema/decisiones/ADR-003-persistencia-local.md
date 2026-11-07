# ADR-003: Progreso y notas solo en la tablet

**Estado:** Aceptada (v2.0; vigente en v3.0).

## Contexto

El juego no debe depender de la red ni exponer datos de los estudiantes, que son menores de edad.

## Decisión

Los estudiantes, intentos, respuestas, estrellas, calificaciones y recompensas se guardan solo en la tablet. La tecnología de almacenamiento se define en [ADR-007](ADR-007-sqlite-base-local.md).

## Consecuencias

- Existe riesgo de pérdida si la tablet se daña o se restablece (riesgo R-03); por eso hay exportación de reportes en CSV.
- Los reportes se consultan por tablet.

## Verificación

Criterio CA-04 y revisión del tráfico de red (RNF-07).
