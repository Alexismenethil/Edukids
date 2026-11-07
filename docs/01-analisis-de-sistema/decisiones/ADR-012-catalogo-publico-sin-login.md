# ADR-012: Catálogo público sin inicio de sesión en la tablet

**Estado:** Aceptada (v3.0, 06/11/2026). Modifica [ADR-004](ADR-004-nube-limitada.md) y el RF-02 de la v2.0.

## Contexto

En la v2.0 el docente debía iniciar sesión en la tablet para descargar módulos. Sin embargo, los módulos están pensados para compartirse con cualquier escuela, y el inicio de sesión agrega trabajo en el cliente, credenciales en las tablets y cuentas que alguien debe mantener (riesgo R-05). A la vez, los retos de un docente deben llegar a sus tablets y no a todas.

## Decisión

- El catálogo es **público y de solo lectura**; las tablets no inician sesión.
- En la configuración inicial, la tablet guarda el **código de docente**: 6 caracteres públicos, sin letras ni números que se confundan (sin 0, O, 1 ni I).
- El catálogo devuelve los módulos oficiales y los retos publicados con ese código.
- Las cuentas docentes existen solo en el panel web.

## Consecuencias

- **Positivas:** cliente más simple, sin credenciales en las tablets y réplica más fácil.
- **Negativas:** quien conozca el código puede descargar los retos de ese docente. Por eso los retos no pueden incluir datos personales de estudiantes (regla RN-19) y la API limita la cantidad de peticiones.

## Verificación

Criterio CA-16.
