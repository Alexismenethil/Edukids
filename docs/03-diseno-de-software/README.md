# 03. Diseño de software

Diseño interno de EduKids v3.0. Las decisiones de fondo están en los [ADR](../01-analisis-de-sistema/07-decisiones-arquitectonicas.md); aquí se concretan carpetas, datos, contratos y patrones.

| Documento | Contenido |
| --- | --- |
| [Estructura del repositorio](estructura-del-repositorio.md) | Carpetas de `android/`, `backend/` y `web/` según Clean Architecture, y convenciones de nombres |
| [Modelo de datos](modelo-de-datos.md) | Tablas de la tablet (SQLite) y de la nube (PostgreSQL) |
| [Formato de paquete](formato-de-paquete.md) | Contrato v1 de los módulos y retos: estructura, manifiesto, ítems y validación |
| [Diseño interno de módulos](diseno-interno/diseno-interno-de-modulos.md) | Casos de uso, puertos y estados por componente |
| [Patrones de diseño](diseno-interno/patrones-de-diseno.md) | Patrones que se usan y dónde |
| [Principios de diseño](diseno-interno/principios-de-diseno.md) | SOLID y principios propios del juego |

El diseño se valida con código y pruebas a partir del Sprint 2. Los cambios importantes se registran como ADR.
