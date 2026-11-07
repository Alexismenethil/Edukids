# C4 Nivel 2: Contenedores

```mermaid
flowchart TB
    E(["Estudiante<br/>[Persona]"])
    D(["Docente<br/>[Persona]"])
    C(["Equipo de contenidos<br/>[Persona]"])
    subgraph Tablet["Tablet Android en el aula"]
        G["Juego EduKids<br/>[Godot 4.7, GDScript]<br/>Mapa, niveles, desafíos,<br/>modo docente y reportes"]
        L[("Base local<br/>[SQLite]<br/>Estudiantes, intentos,<br/>respuestas y recompensas")]
        F["Paquetes instalados<br/>[Sistema de archivos]<br/>Manifiestos, niveles e imágenes"]
    end
    subgraph Nube["Servicios web"]
        W["Panel docente<br/>[React, TypeScript]<br/>Crear, previsualizar<br/>y publicar retos"]
        A["API de contenidos<br/>[Node.js, TypeScript, Fastify]<br/>Catálogo público, cuentas docentes<br/>y generación de paquetes"]
        P[("Base de datos<br/>[PostgreSQL]<br/>Cuentas docentes,<br/>retos y catálogo")]
        O["Almacenamiento de objetos<br/>[Compatible con S3]<br/>Paquetes ZIP versionados"]
    end
    E -->|"Juega"| G
    D -->|"Modo docente con PIN"| G
    D -->|"HTTPS"| W
    C -->|"HTTPS"| W
    W -->|"JSON sobre HTTPS con token"| A
    A -->|"Prisma"| P
    A -->|"Guarda paquetes"| O
    G -->|"Consulta el catálogo sin login<br/>JSON sobre HTTPS, en la Dirección"| A
    G -->|"Descarga por rangos HTTPS"| O
    G <-->|"Lee y escribe"| L
    G <-->|"Instala y lee"| F
```

| Contenedor | Tecnología | Responsabilidad | Estado |
| --- | --- | --- | --- |
| Juego EduKids | Godot 4.7, GDScript | Toda la experiencia del estudiante y del docente en el aula | Aceptada (ADR-009) |
| Base local | SQLite con godot-sqlite | Datos y resultados de los estudiantes | Aceptada (ADR-007) |
| Paquetes instalados | Archivos en el almacenamiento interno de la aplicación | Contenido de módulos y retos | Aceptada (ADR-013) |
| Panel docente | React, TypeScript y Vite | Crear y publicar retos; publicar módulos (editor) | Propuesta (ADR-017) |
| API de contenidos | Node.js, TypeScript y Fastify | Catálogo, cuentas docentes y empaquetado | Propuesta (ADR-017) |
| Base de datos | PostgreSQL | Cuentas docentes, retos y catálogo | Propuesta (ADR-017) |
| Almacenamiento de objetos | Compatible con S3 | Paquetes ZIP con descargas por rangos | Propuesta (ADR-017) |

**Reglas:** la tablet solo se conecta a la nube en la Dirección y nunca envía datos de estudiantes. Si la nube no está disponible, los paquetes se instalan por USB.
