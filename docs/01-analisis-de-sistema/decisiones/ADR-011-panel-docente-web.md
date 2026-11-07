# ADR-011: Panel docente web para crear retos

**Estado:** Aceptada (v3.0, 06/11/2026).

## Contexto

Los docentes deben poder crear ejercicios y niveles para un tema concreto de su clase, y esos retos deben llegar a las tablets de sus estudiantes. El aula no tiene internet, pero la Dirección sí.

## Decisión

Construir un **panel docente web**, usable desde una computadora o un celular:

1. El docente crea un reto a partir de plantillas: capítulo, área, mecánica, tipos de ítem, preguntas, imágenes, retroalimentación y pistas.
2. Lo previsualiza y lo publica.
3. El backend valida el reto y genera un paquete con el mismo formato de los módulos oficiales ([ADR-013](ADR-013-paquetes-solo-datos-y-pdf-a-imagenes.md)), asociado a su código de docente.
4. En la Dirección, la tablet descarga el reto desde el catálogo público ([ADR-012](ADR-012-catalogo-publico-sin-login.md)) o lo importa desde una USB.

El equipo de contenidos usa el mismo panel, con rol de editor, para publicar los módulos oficiales.

## Alternativas consideradas

- **Editor dentro de la tablet:** funcionaría sin internet, pero escribir en una tablet es más lento y habría que copiar el reto a cada tablet. Queda como opción futura (P3) con el mismo formato de paquete.
- **Solo contenido del equipo del proyecto:** no cumple el pedido de que el docente cree sus propios retos.

## Consecuencias

- Hacen falta un backend, cuentas docentes y conexión para crear retos (riesgo R-15).
- Las reglas de corrección del panel y del juego deben coincidir; por eso el formato del paquete es un contrato versionado.

## Verificación

Criterio CA-16 y caso de uso CU-09.
