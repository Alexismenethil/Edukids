# Patrones de diseño

Cada patrón responde a una necesidad concreta del proyecto. No se agregan patrones sin un caso real.

| Patrón | Dónde se aplica | Beneficio |
| --- | --- | --- |
| Puertos y adaptadores | Puertos en `application/ports`; adaptadores en `infrastructure/` y `presentation/` | Base de Clean Architecture: el núcleo no depende de la tecnología |
| Repository | `StudentRepository`, `AttemptRepository`, `PackageRepository` | Aísla SQLite y PostgreSQL de las reglas |
| Strategy | Un `ItemEvaluator` por tipo de ítem | Agregar tipos de ítem sin modificar la sesión de nivel |
| Factory | `EvaluatorRegistry`; fábrica de escenas por mecánica | Centraliza la creación según el tipo o la mecánica |
| Adapter | `CatalogHttpGateway` y `UsbFileImporter` entregan paquetes por la misma interfaz | Un solo flujo de instalación para la red y la USB |
| State | `LevelSession` (en curso, alcanzado, game over, completado) y ciclo de vida del paquete | Solo se permiten transiciones válidas |
| Presenter (vista humilde) | `LevelPresenter` y `LevelView`, uno por pantalla | Las escenas no tienen lógica y los presentadores se prueban |
| Observer | Señales de Godot, solo dentro de la presentación | La escena reacciona a cambios del presentador sin acoplarse |
| Template Method | Escena base de mecánica con los pasos comunes del nivel | Persecución, puente y clásica comparten el flujo y cambian la animación |
| Composition Root | `main/composition_root.gd`, `backend/src/main` | Todas las dependencias concretas se conectan en un solo lugar |
| Null Object | `SilentAudio` para el modo sin sonido; `OfflineCatalog` cuando no hay red | Evita condicionales repetidos |

## Ejemplo: agregar un tipo de ítem

1. Crear el evaluador en `src/domain/evaluators/` e implementar `ItemEvaluator`.
2. Registrarlo en `EvaluatorRegistry`.
3. Crear su componente visual en `scenes/activities/`.
4. Documentar sus campos en el [formato de paquete](../formato-de-paquete.md).
5. Agregar sus pruebas unitarias.

`LevelSession`, los casos de uso y los repositorios no cambian.
