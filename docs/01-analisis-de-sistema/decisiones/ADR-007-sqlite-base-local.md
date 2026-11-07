# ADR-007: SQLite como base local

**Estado:** Aceptada en v3.0 (era Propuesta en v2.0).

## Contexto

Los resultados deben resistir cierres y apagones (RNF-06), y los reportes necesitan consultas por sección, área y módulo.

## Decisión

Usar SQLite en la tablet mediante el plugin **godot-sqlite** (GDExtension con soporte para Android), con:

- modo WAL y una transacción por respuesta guardada;
- migraciones versionadas del esquema;
- acceso solo desde adaptadores de infraestructura que implementan los puertos de repositorio ([ADR-010](ADR-010-clean-architecture.md)).

## Alternativas consideradas

- **Archivos JSON en `user://`:** simples, pero con más riesgo de corrupción ante un apagado y sin consultas para los reportes. Quedan como plan de respaldo si el plugin falla.
- **Recursos de Godot (`.tres`):** no están pensados para datos transaccionales.

## Consecuencias

- Hay que fijar la versión del plugin compatible con Godot 4.7 y probarla en Android en el Sprint 2 (riesgo R-13).
- Como el dominio no conoce SQLite, cambiar de almacenamiento solo afecta a la infraestructura.

## Verificación

Criterio CA-04 y prueba de apagado forzado.
