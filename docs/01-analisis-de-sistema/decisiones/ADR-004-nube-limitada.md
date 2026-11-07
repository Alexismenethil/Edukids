# ADR-004: Nube limitada, sin datos de estudiantes

**Estado:** Modificada por [ADR-012](ADR-012-catalogo-publico-sin-login.md) en v3.0.

## Contexto

Se busca proteger los datos de los estudiantes y reducir costos de operación.

## Decisión (v3.0)

La nube solo guarda:

- cuentas docentes, que se usan únicamente en el panel web;
- retos creados por los docentes;
- paquetes de módulos y retos, y su catálogo.

Nunca guarda nombres, intentos ni calificaciones de estudiantes (regla RN-08).

**Cambio respecto de la v2.0:** las tablets ya no inician sesión con la cuenta docente; consultan un catálogo público (ADR-012).

## Consecuencias

- Hace falta un responsable de mantener el catálogo y las cuentas después del proyecto (riesgo R-05).
- Si la nube no está disponible, las escuelas pueden usar la importación por USB (RNF-18).

## Verificación

Revisión del modelo de datos de la nube y del tráfico de red.
