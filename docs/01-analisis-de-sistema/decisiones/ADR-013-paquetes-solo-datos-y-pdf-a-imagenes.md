# ADR-013: Paquetes solo de datos y PDF convertidos a imágenes

**Estado:** Aceptada (v3.0, 06/11/2026).

## Contexto

Godot no incluye un visor de PDF. Además, el contenido descargado (incluido el que crean los docentes) debe ser seguro y fácil de producir sin programar.

## Decisión

- Un paquete es un ZIP con `manifest.json`, archivos JSON de niveles e ítems, imágenes (WebP o PNG) y, si hace falta, audio (OGG).
- Un paquete **nunca** contiene código ni recursos ejecutables de Godot (`.gd`, `.tscn`, `.tres`, `.pck`, `.so`, `.dex` ni similares).
- Las mecánicas y los minijuegos viven en la aplicación; el paquete solo los configura.
- Los PDF se convierten en imágenes (una por página) al publicar el paquete.
- El instalador valida el SHA-256, las extensiones permitidas, las rutas (sin `..` ni rutas absolutas), los tamaños y la versión del formato.

## Alternativas consideradas

- **Paquetes de recursos de Godot (`.pck`) con escenas:** permitirían ejecutar código descargado y exigirían Godot para crear contenido.
- **Plugin de Android para mostrar PDF:** requiere código nativo y más mantenimiento.

## Consecuencias

- Un minijuego nuevo requiere una versión nueva de la aplicación; el contenido nuevo, no.
- Las imágenes pesan más que el PDF original, así que se comprimen en WebP.

## Verificación

Criterios CA-03 y CA-17. Especificación en [formato de paquete](../../03-diseno-de-software/formato-de-paquete.md).
