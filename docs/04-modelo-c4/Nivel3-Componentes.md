# C4 Nivel 3: Componentes

Los componentes se agrupan por capas de [Clean Architecture](../02-arquitectura-software/clean-architecture.md). Las flechas punteadas indican que un adaptador implementa un puerto.

## Juego EduKids

```mermaid
flowchart TB
    subgraph PRES["Vistas y adaptadores de entrada"]
        V["Escenas<br/>mapa, nivel, desafío,<br/>perfiles y modo docente"]
        PR["Presentadores"]
        NAV["Navegador"]
    end
    subgraph APP["Aplicación: casos de uso"]
        AULA["Aula e identidad"]
        JUEGO["Juego"]
        DES["Desafío final"]
        PAQ["Paquetes"]
        REC["Recompensas"]
        REP["Reportes"]
        PORTS["Puertos"]
    end
    subgraph DOM["Dominio"]
        SES["LevelSession<br/>y DangerMeter"]
        EVA["Evaluadores de ítems"]
        CAL["StarRule<br/>y CnebGradeScale"]
        VAL["Validación de paquetes"]
    end
    subgraph INF["Adaptadores de salida"]
        SQL["Repositorios SQLite"]
        ZIP["Instalador de paquetes<br/>ZIP y SHA-256"]
        NET["Cliente del catálogo<br/>y descarga por rangos"]
        SYS["Hash de PIN, reloj<br/>y exportación CSV"]
    end
    DB[("SQLite")]
    FS["Paquetes instalados"]
    API["API de contenidos"]
    NAV --> V
    V --> PR
    PR --> AULA & JUEGO & DES & PAQ & REC & REP
    JUEGO --> SES & EVA & CAL
    DES --> EVA & CAL
    PAQ --> VAL
    AULA & JUEGO & DES & PAQ & REC & REP --> PORTS
    SQL -.->|"implementa"| PORTS
    ZIP -.->|"implementa"| PORTS
    NET -.->|"implementa"| PORTS
    SYS -.->|"implementa"| PORTS
    SQL --> DB
    ZIP --> FS
    NET -->|"HTTPS"| API
```

## API de contenidos

```mermaid
flowchart TB
    subgraph HTTP["Adaptadores de entrada: Fastify y Zod"]
        RC["Rutas del catálogo<br/>públicas"]
        RA["Rutas de autenticación"]
        RR["Rutas de retos<br/>rol docente"]
        RM["Rutas de módulos<br/>rol editor"]
    end
    subgraph APP["Aplicación: casos de uso"]
        LC["ListCatalog<br/>GetPackageDownload"]
        AU["RegisterTeacher<br/>Login"]
        CH["CreateChallenge<br/>PublishChallenge"]
        OM["PublishOfficialModule"]
        PORTS["Puertos"]
    end
    subgraph DOM["Dominio"]
        ENT["TeacherAccount, TeacherCode,<br/>Challenge y Package"]
        RULES["Reglas del formato de paquete"]
    end
    subgraph INF["Adaptadores de salida"]
        PRI["Repositorios Prisma"]
        STO["Almacenamiento S3"]
        BLD["Empaquetador<br/>ZIP y SHA-256"]
        SEC["Hash de contraseñas<br/>y tokens"]
    end
    PG[("PostgreSQL")]
    OBJ["Almacenamiento de objetos"]
    RC --> LC
    RA --> AU
    RR --> CH
    RM --> OM
    LC & AU & CH & OM --> ENT
    CH & OM --> RULES
    LC & AU & CH & OM --> PORTS
    PRI -.->|"implementa"| PORTS
    STO -.->|"implementa"| PORTS
    BLD -.->|"implementa"| PORTS
    SEC -.->|"implementa"| PORTS
    PRI --> PG
    STO --> OBJ
```

El panel docente sigue la misma organización con menos piezas (dominio del reto, casos de uso del panel, cliente de la API y componentes React); se detalla en [Clean Architecture](../02-arquitectura-software/clean-architecture.md).
