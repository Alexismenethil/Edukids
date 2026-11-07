# ADR-010: Clean Architecture en el juego, el backend y el panel

**Estado:** Aceptada (v3.0, 06/11/2026).

## Contexto

Las reglas más importantes de EduKids (corrección de respuestas, medidor de peligro, vidas, estrellas, intentos y escala AD/A/B/C) deben ser correctas, fáciles de probar y estables en el tiempo. En cambio, la infraestructura puede cambiar: SQLite o archivos, descarga o USB, un proveedor de nube u otro. Además, el autor del proyecto exige Clean Architecture.

## Decisión

Aplicar Clean Architecture en las tres partes del código (`android/`, `backend/` y `web/`):

1. **Dominio:** entidades, objetos de valor y reglas del negocio y del juego. No depende de nada externo.
2. **Aplicación:** casos de uso y **puertos** (interfaces) para todo lo que el caso de uso necesita del exterior.
3. **Adaptadores:** de entrada (presentadores, controladores HTTP) y de salida (repositorios, gateways de red, empaquetado).
4. **Frameworks y controladores:** Godot y sus escenas, plugins, Fastify, Prisma, React y el almacenamiento.

**Regla de dependencias:** el código solo depende de capas más internas. Las implementaciones concretas se conectan en una **raíz de composición** por aplicación. Los datos cruzan las fronteras como objetos simples de petición y respuesta.

El detalle está en [Clean Architecture](../../02-arquitectura-software/clean-architecture.md) y la estructura de carpetas en [estructura del repositorio](../../03-diseno-de-software/estructura-del-repositorio.md).

## Consecuencias

- **Positivas:** las reglas se prueban sin abrir el motor ni la base de datos; la infraestructura se puede cambiar; cada archivo tiene un lugar claro.
- **Negativas:** más archivos y clases pequeñas; en GDScript la regla no la impone el compilador, por lo que se verifica con un script en CI y en las revisiones de código.

## Verificación

Requisito RNF-15 y criterio CA-20.
