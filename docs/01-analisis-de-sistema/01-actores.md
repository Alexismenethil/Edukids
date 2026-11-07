# 01. Actores del sistema

EduKids tiene dos partes que usan personas distintas:

- **Juego en la tablet:** lo usan el estudiante y el docente (modo docente). Se mantiene la decisión de la v2.0 de tener solo dos actores en la tablet ([ADR-005](decisiones/ADR-005-dos-actores-en-la-tablet.md)).
- **Panel docente web:** lo usan el docente y el equipo de contenidos.

| Actor | Dónde actúa | Responsabilidad principal | Acceso |
| --- | --- | --- | --- |
| Estudiante | Tablet | Jugar los niveles, leer las fichas, rendir los desafíos finales y personalizar su avatar. | Su perfil y un PIN de 4 dígitos; solo ve su propio avance. |
| Docente | Tablet (modo docente) | Configurar la tablet, registrar estudiantes, descargar o importar paquetes, habilitarlos, configurar la evaluación y revisar los reportes. | PIN docente, sin conexión. |
| Docente | Panel web | Crear, previsualizar y publicar retos con su código de docente. | Cuenta con correo y contraseña. |
| Equipo de contenidos | Panel web | Producir, versionar y publicar los módulos oficiales. | Cuenta con rol de editor. |

## Permisos en la tablet

| Acción | Estudiante | Docente |
| --- | --- | --- |
| Configurar la tablet y la institución | No | Sí |
| Registrar, editar y desactivar estudiantes | No | Sí |
| Descargar o importar paquetes (módulos y retos) | No | Sí |
| Habilitar módulos, desafíos finales y retos por sección | No | Sí |
| Configurar la escala AD/A/B/C, los intentos y la pausa | No | Sí |
| Jugar niveles y leer fichas | Sí | Solo vista previa, sin registrar resultados |
| Rendir desafíos finales | Sí | No |
| Personalizar su avatar | Sí | No |
| Consultar su propio avance | Sí | Sí |
| Consultar el reporte de la sección | No | Sí |
| Autorizar un nuevo intento y restablecer el PIN | No | Sí |
| Exportar reportes | No | Sí |

## Permisos en el panel web

| Acción | Docente | Equipo de contenidos |
| --- | --- | --- |
| Crear, editar y previsualizar retos | Sí | Sí |
| Publicar retos con su código de docente | Sí | Sí |
| Exportar un paquete para USB | Sí | Sí |
| Publicar y versionar módulos oficiales | No | Sí |

La nube no guarda datos de estudiantes, así que nadie puede consultarlos desde el panel (regla RN-08).
