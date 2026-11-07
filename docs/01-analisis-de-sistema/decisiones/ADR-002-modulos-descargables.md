# ADR-002: Paquetes completos de contenido

**Estado:** Aceptada (v2.0; ampliada en v3.0 a los retos del docente).

## Contexto

Las descargas solo son posibles en la Dirección. Conviene llevar las tablets allí pocas veces.

## Decisión

Cada módulo oficial y cada reto de docente se distribuyen como un paquete completo y versionado, que se descarga una sola vez o se importa por USB, con verificación de integridad. El formato se define en [formato de paquete](../../03-diseno-de-software/formato-de-paquete.md).

## Consecuencias

- La aplicación gestiona el espacio disponible, las descargas interrumpidas y las versiones.
- Un mismo formato sirve para módulos oficiales y para retos.

## Verificación

Criterios CA-02, CA-03 y CA-08.
