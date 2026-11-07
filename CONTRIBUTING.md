# Cómo contribuir

## Ramas

Se usa un flujo simple basado en `main`:

| Rama | Uso |
| --- | --- |
| `main` | Versión estable. Solo recibe cambios mediante pull request. |
| `docs/<tema>` | Cambios de documentación. Ejemplo: `docs/temario-ciencia`. |
| `feat/<tema>` | Funciones nuevas. Ejemplo: `feat/mecanica-persecucion`. |
| `fix/<tema>` | Correcciones. |
| `chore/<tema>` | Configuración, dependencias o mantenimiento. |

Las ramas duran poco: se integran en cuanto la tarea está terminada y revisada.

## Commits

Formato [Conventional Commits](https://www.conventionalcommits.org/es/), en español y en modo imperativo:

```text
<tipo>(<ámbito opcional>): <descripción>
```

Tipos: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `style` y `chore`.

```text
docs(contenidos): agrega temario de Ciencia y Tecnología
feat(juego): agrega la mecánica de persecución
fix(paquetes): rechaza rutas fuera del paquete
```

## Versiones

- La aplicación usa versionado semántico (`MAJOR.MINOR.PATCH`) con etiquetas `vX.Y.Z`.
- Cada paquete de contenido tiene su propia versión (ver [formato de paquete](docs/03-diseno-de-software/formato-de-paquete.md)).
- La versión de la documentación figura en el README.

## Documentación

- Markdown en español; diagramas en Mermaid dentro del mismo archivo.
- Conservar los códigos (RF, RNF, RN, HU, CU, CA, ADR, R) y actualizar la [matriz de trazabilidad](docs/01-analisis-de-sistema/11-matriz-de-trazabilidad.md) al agregar o cambiar un requisito.
- Marcar lo que falta validar con `[POR CONFIRMAR: ...]`.
- Registrar cada decisión de arquitectura nueva como ADR en [decisiones](docs/01-analisis-de-sistema/decisiones/).

## Código

### Reglas comunes

- Identificadores de código en inglés; textos que ve el usuario en español.
- Respetar [Clean Architecture](docs/02-arquitectura-software/clean-architecture.md): el dominio y los casos de uso no dependen de las capas externas.
- Cada regla del dominio y cada caso de uso tienen pruebas unitarias.
- Sin secretos en el repositorio: usar `.env` (ignorado por Git) y documentar las variables en `.env.example`.

### GDScript (`android/`)

- Seguir la guía de estilo oficial de GDScript: tabulaciones; `snake_case` para archivos, funciones y variables; `PascalCase` para `class_name`; `CONSTANT_CASE` para constantes.
- Tipado estático en variables, parámetros y retornos.
- Las escenas no acceden a la base de datos, a los archivos ni a la red: usan su presentador.
- Las pruebas usan GdUnit4 y se nombran `<clase>_test.gd`. Los comandos para ejecutarlas y para verificar las capas están en [android/README.md](android/README.md#pruebas).
- La escena del rig de un personaje se genera con `tools/art/build_cutout_rig.gd`; no se edita a mano.

### TypeScript (`backend/` y `web/`)

- `strict` activado en `tsconfig`, con ESLint y Prettier.
- Validación de entradas con Zod en la capa de interfaces.

## Pull requests

- [ ] La rama sigue la convención y el título usa el formato de commit.
- [ ] Las pruebas pasan y el cambio tiene pruebas nuevas.
- [ ] Se respeta la regla de dependencias de Clean Architecture.
- [ ] Se actualizó la documentación y la trazabilidad si cambió un requisito.
- [ ] No se agregan secretos, credenciales ni datos personales.

## Archivos grandes

El arte y el audio se guardan optimizados (ver [guía de arte y audio](docs/05-diseno-del-juego/08-guia-de-arte-y-audio.md)). Si el repositorio crece demasiado, se evaluará Git LFS para los archivos binarios.
