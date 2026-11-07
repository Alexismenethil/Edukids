# Arquitectura inicial

EduKids se ejecuta en tablets Android sin internet. La nube solo distribuye contenidos y permite a los docentes crear retos. Los estudiantes, intentos, respuestas y calificaciones permanecen en la tablet.

```mermaid
flowchart TB
    subgraph Aula["Aula sin internet"]
        E(["Estudiante"])
        D(["Docente"])
        subgraph Tablet["Tablet Android"]
            J["Juego EduKids<br/>Godot 4.7 · Clean Architecture"]
            DB[("SQLite<br/>estudiantes, intentos y calificaciones")]
            FS["Paquetes instalados<br/>JSON e imágenes"]
        end
    end
    subgraph Nube["Nube de contenidos"]
        API["API de contenidos<br/>catálogo público, retos y paquetes"]
        PG[("PostgreSQL<br/>cuentas docentes, retos y catálogo")]
        OBJ["Almacenamiento de paquetes<br/>ZIP con SHA-256"]
    end
    P["Panel docente web"]
    USB["Archivo de paquete<br/>USB o cable"]
    E --> J
    D --> J
    D -->|"crea y publica retos"| P
    P -->|"HTTPS con sesión"| API
    API --> PG
    API --> OBJ
    J -->|"consulta el catálogo<br/>solo en la Dirección"| API
    J -->|"descarga reanudable"| OBJ
    USB -->|"importación sin red"| J
    J <--> DB
    J <--> FS
```

**Regla de privacidad:** ningún dato de estudiantes sale de la tablet hacia la nube. La única salida es la exportación de reportes que hace el docente.
