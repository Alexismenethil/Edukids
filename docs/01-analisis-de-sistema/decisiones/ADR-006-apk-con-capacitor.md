# ADR-006: APK con Capacitor

**Estado:** Reemplazada por [ADR-009](ADR-009-godot-como-motor.md) en v3.0.

## Decisión original (v2.0)

Construir la aplicación con React, TypeScript y Vite, y empaquetarla como APK con Capacitor, en lugar de una aplicación web progresiva.

## Motivo del reemplazo

EduKids es un videojuego educativo con personajes animados, mapa de aventura y mecánicas de juego. Un motor de videojuegos ofrece animación, escenas, partículas y audio de forma nativa, algo que con React y Capacitor exigiría mucho trabajo adicional.

Se mantienen las razones de fondo de la v2.0: instalación por APK sin internet y almacenamiento que el sistema no borra.
