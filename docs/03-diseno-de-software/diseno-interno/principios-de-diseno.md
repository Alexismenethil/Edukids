# Principios de diseño

## SOLID

- **S, responsabilidad única:** cada clase tiene una razón para cambiar. La sesión de nivel aplica reglas, el repositorio guarda y la escena muestra.
- **O, abierto y cerrado:** se agregan tipos de ítem, mecánicas o fuentes de paquetes con clases nuevas, sin modificar las existentes.
- **L, sustitución de Liskov:** cualquier evaluador o repositorio respeta el contrato de su puerto; por ejemplo, todo `ItemEvaluator` devuelve el mismo tipo de resultado.
- **I, segregación de interfaces:** los puertos son pequeños; un caso de uso que solo lee intentos no depende de métodos de escritura.
- **D, inversión de dependencias:** los casos de uso dependen de puertos, no de SQLite, HTTP ni Godot.

## Principios de Clean Architecture

- La regla de dependencias apunta siempre hacia el dominio.
- Las fronteras entre capas se cruzan con objetos simples de petición y respuesta.
- El framework es un detalle: Godot, Fastify o React se pueden actualizar sin reescribir las reglas.
- La base de datos es un detalle: SQLite, PostgreSQL o archivos quedan detrás de repositorios.

## Principios propios del juego

- **Contenido como datos:** niveles, ítems, textos e imágenes vienen del paquete; el código solo interpreta el formato.
- **Reglas deterministas:** el reloj, los identificadores y la aleatoriedad se inyectan, para que cada regla se pruebe con resultados repetibles.
- **Animación separada de las reglas:** la escena anima lo que decidió el dominio; nunca decide si una respuesta es correcta.
- **Guardado inmediato:** cada respuesta confirmada se guarda en el momento; el juego no depende de cerrar bien la aplicación.
- **Rendimiento medido:** cada escena respeta el presupuesto de memoria, fps y tamaño (RNF-02, RNF-05 y RNF-13).
- **Errores amables:** un fallo técnico muestra un mensaje claro al docente y nunca hace perder el progreso del estudiante.

## Calidad

- Bajo acoplamiento, alta cohesión y nombres que explican su propósito.
- Sin optimizaciones prematuras: primero se mide en la tablet real.
- El diseño se valida con código y pruebas desde el Sprint 2; los cambios importantes se registran como ADR.
