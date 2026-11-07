# ADR-009: Godot 4.7 como motor del juego

**Estado:** Aceptada (v3.0, 06/11/2026). Reemplaza a [ADR-006](ADR-006-apk-con-capacitor.md).

## Contexto

EduKids es un videojuego educativo con personajes animados, mapa por capítulos y mecánicas como la persecución. Debe funcionar sin internet en tablets Android de gama media, instalarse como APK y poder desarrollarse con software libre.

## Decisión

- Motor **Godot 4.7** (rama estable vigente). La versión exacta del parche, por ejemplo 4.7.2, se fija al crear el proyecto y todo el equipo usa la misma.
- Lenguaje **GDScript** con tipado estático.
- Juego **2D**, con el renderizador **Compatibility** (OpenGL ES 3.0), que es el más compatible con tablets de gama media.
- Orientación horizontal y resolución base de 1280 × 800, con escalado `canvas_items` y relación de aspecto `expand`.
- Exportación para `arm64-v8a`; se agrega `armeabi-v7a` solo si alguna tablet es de 32 bits.

## Alternativas consideradas

| Alternativa | Motivo para descartarla |
| --- | --- |
| React y Capacitor (v2.0) | Poca capacidad para animación y escenas de juego. |
| Unity | Motor más pesado para 2D sencillo, APK más grande y condiciones de licencia que hay que revisar. |
| Flutter con Flame | Herramientas de animación y edición de escenas menos completas para este tipo de juego. |
| Godot con C# | Agrega el entorno de .NET y aumenta el tamaño del APK sin un beneficio claro para el proyecto. |

## Consecuencias

- **Positivas:** motor libre con licencia MIT y sin regalías; editor de escenas, `AnimationPlayer`, `Skeleton2D`, partículas y audio integrados; exportación directa a APK; buen rendimiento en 2D.
- **Negativas:** Godot no trae visor de PDF ([ADR-013](ADR-013-paquetes-solo-datos-y-pdf-a-imagenes.md)); SQLite requiere un plugin ([ADR-007](ADR-007-sqlite-base-local.md)); GDScript no tiene interfaces formales, por lo que los puertos se definen como clases base abstractas (`@abstract`, disponible desde Godot 4.5) y se respetan con convenciones y verificación automática ([ADR-010](ADR-010-clean-architecture.md)).

## Verificación

En el Sprint 2 se exporta un APK de prueba y se mide en la tablet real: fps, memoria, tiempo de carga y tamaño (criterio CA-19).
