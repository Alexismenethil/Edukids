# Enfoque arquitectónico

## Principios

- **Offline primero:** las funciones de clase no requieren internet (ADR-001).
- **Privacidad por diseño:** la información de los estudiantes vive solo en la tablet (ADR-003 y ADR-004).
- **Clean Architecture:** las reglas del juego y de la evaluación están en el dominio y no dependen del motor, la base de datos ni la red (ADR-010).
- **Contenido como datos:** los módulos y retos son paquetes de datos versionados; nunca contienen código (ADR-013).
- **Ligereza:** presupuesto de rendimiento, memoria y tamaño para tablets de gama media (ADR-009).
- **Portabilidad:** la institución, el grado, las secciones y el código de docente se configuran en cada tablet (ADR-008).
- **Reglas deterministas:** el reloj y la aleatoriedad se inyectan como puertos para que las reglas se puedan probar.

## Límites de conectividad

| Operación | ¿Necesita internet? |
| --- | --- |
| Consultar el catálogo público | Sí, en la Dirección, sin iniciar sesión |
| Descargar un paquete | Sí, en la Dirección; alternativa: archivo por USB |
| Crear y publicar retos en el panel | Sí, desde cualquier lugar con conexión |
| Configurar la tablet, registrar estudiantes e ingresar con PIN | No |
| Explicaciones, fichas, niveles y desafíos finales | No |
| Recompensas, avatar y álbum | No |
| Reportes y exportación CSV | No |

## Cambios respecto de la v2.0

- La tablet ya no inicia sesión en la nube: el catálogo es público y se filtra por código de docente (ADR-012).
- Se agrega el panel docente web y la API genera los paquetes de los retos (ADR-011).
- El "monolito modular" sugerido en la v2.0 se concreta como Clean Architecture con puertos y adaptadores.
