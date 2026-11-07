# ADR-005: Dos actores en la tablet

**Estado:** Aceptada (v2.0; vigente en v3.0).

## Contexto

En el aula conviene una operación simple, sin cuentas de administración.

## Decisión

En la tablet solo hay dos actores: el **docente**, que entra al modo docente con su PIN, y el **estudiante**, que entra con su avatar y su PIN. No existe un rol de administrador.

En v3.0 se agrega el panel web, que es otra aplicación: allí actúan el docente y el equipo de contenidos ([ADR-011](ADR-011-panel-docente-web.md)).

## Consecuencias

- El docente es responsable de configurar la tablet y de habilitar los paquetes.
- El equipo de contenidos no usa la tablet; publica desde el panel.

## Verificación

Matriz de permisos en [actores](../01-actores.md).
