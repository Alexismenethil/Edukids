# Componentes arquitectónicos

Componentes de cada aplicación, con la capa de Clean Architecture donde vive su lógica principal. La lista de casos de uso y puertos de cada componente está en el [diseño interno de módulos](../03-diseno-de-software/diseno-interno/diseno-interno-de-modulos.md).

## Juego (`android/`)

| Componente | Capas principales | Responsabilidad | Requisitos |
| --- | --- | --- | --- |
| Configuración | Aplicación y dominio | Institución, grado, secciones, código de docente y ajustes de evaluación | RF-01, RF-30 |
| Identidad local | Dominio, aplicación e infraestructura | PIN del docente y de los estudiantes, bloqueo tras fallos y modo docente | RF-03, RF-05, RF-17 |
| Gestión de estudiantes | Aplicación | Alta, edición, desactivación y sección | RF-04 |
| Catálogo y descargas | Aplicación e infraestructura | Consultar el catálogo público por código de docente y descargar por rangos | RF-06, RF-07, RF-08, RF-45 |
| Gestor de paquetes | Dominio e infraestructura | Validar el manifiesto, verificar SHA-256, instalar, importar por USB, liberar espacio y manejar versiones | RF-07, RF-19, RF-20, RF-21 |
| Habilitación | Aplicación | Habilitar módulos, desafíos finales y retos por sección | RF-09 |
| Contenidos | Aplicación e infraestructura | Explicación del guía y fichas de lectura | RF-10, RF-11 |
| Motor de actividades | Dominio | Un evaluador por tipo de ítem, retroalimentación y pistas | RF-12, RF-28 |
| Sesión de nivel | Dominio y aplicación | Medidor de peligro, vidas, game over, repetición de errores y estrellas | RF-23 a RF-27, RF-29 |
| Desafío final | Dominio y aplicación | Intentos, cierre y calificación con la escala del CNEB | RF-13, RF-16 |
| Progreso y recompensas | Dominio y aplicación | Estrellas acumuladas, insignias, cartas, accesorios y quipu | RF-14, RF-31 a RF-35 |
| Reportes | Aplicación e infraestructura | Consultas por sección, área y módulo, y exportación CSV | RF-15, RF-18 |
| Persistencia local | Infraestructura | Repositorios SQLite y migraciones | RNF-06 |
| Presentación | Adaptadores de entrada | Presentadores y modelos de vista de cada pantalla | — |
| Vistas y experiencia | Frameworks | Escenas, mapa, mecánicas, personajes, audio y pausa | RF-22, RF-26, RF-36, RF-37 |
| Composición | `main/` | Raíz de composición y navegador | RNF-15 |

## Backend (`backend/`)

| Componente | Capas principales | Responsabilidad | Requisitos |
| --- | --- | --- | --- |
| Catálogo público | Interfaces y aplicación | Listar módulos oficiales y retos por código de docente | RF-06, RF-45 |
| Descargas | Interfaces e infraestructura | Entregar los paquetes con soporte de descargas por rangos | RF-07, RF-45 |
| Cuentas docentes | Dominio, aplicación e infraestructura | Registro, inicio de sesión y código de docente | RF-02 |
| Retos | Dominio y aplicación | Crear, editar y validar retos | RF-39 |
| Publicación y empaquetado | Aplicación e infraestructura | Generar el ZIP, el manifiesto y el SHA-256, y versionar | RF-41, RF-44 |
| Módulos oficiales | Aplicación | Publicar y versionar módulos (rol de editor) | RF-44 |
| Persistencia y almacenamiento | Infraestructura | PostgreSQL con Prisma y almacenamiento de objetos | — |

## Panel docente (`web/`)

| Componente | Capas principales | Responsabilidad | Requisitos |
| --- | --- | --- | --- |
| Sesión | Aplicación e infraestructura | Inicio de sesión del docente | RF-02 |
| Editor de retos | Interfaz y dominio | Plantillas, preguntas, imágenes, retroalimentación y validación | RF-39 |
| Vista previa | Interfaz y dominio | Probar el reto con las mismas reglas de corrección del juego | RF-40 |
| Conversión de PDF | Infraestructura | Convertir páginas a imágenes con pdf.js | RF-42 |
| Publicación y exportación | Aplicación | Publicar el reto y descargar su paquete | RF-41, RF-43 |
