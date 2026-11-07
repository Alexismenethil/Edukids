# ADR-014: Calificación con la escala del CNEB

**Estado:** Aceptada (v3.0, 06/11/2026). Los rangos por defecto están por confirmar con los docentes.

## Contexto

En primaria, el CNEB califica con la escala AD, A, B y C. La v2.0 dejaba pendiente la nota aprobatoria.

## Decisión

- El **desafío final** se califica con AD, A, B o C a partir del porcentaje de aciertos, con rangos configurables por el docente. Por defecto: AD de 90 % a 100 %, A de 70 % a 89 %, B de 55 % a 69 % y C de 0 % a 54 % (regla RN-12).
- Los **niveles de práctica** no tienen nota: otorgan estrellas (regla RN-11).
- La calificación del juego es **referencial**; la calificación oficial la decide el docente.

## Consecuencias

- La regla de calificación vive en el dominio (`CnebGradeScale`) y se prueba de forma unitaria.
- Un cambio de rangos solo afecta a los intentos nuevos (RF-30).

## Verificación

Criterio CA-14.
