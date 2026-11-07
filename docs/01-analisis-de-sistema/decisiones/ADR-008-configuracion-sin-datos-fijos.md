# ADR-008: Configuración sin datos fijos de una institución

**Estado:** Aceptada (v2.0; vigente en v3.0).

## Contexto

EduKids debe poder replicarse en otras escuelas sin cambiar el código.

## Decisión

El nombre de la institución, el código modular, el grado, las secciones, el PIN docente y el código de docente se definen en la configuración inicial de cada tablet. Nada de eso queda escrito en el código ni en los paquetes oficiales.

## Consecuencias

- La configuración inicial es obligatoria antes del primer uso.
- Los paquetes oficiales sirven para cualquier escuela.

## Verificación

Criterio CA-09: instalación con los datos de una segunda institución.
