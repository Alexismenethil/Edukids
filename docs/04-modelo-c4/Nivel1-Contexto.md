# C4 Nivel 1: Contexto

```mermaid
flowchart TB
    E(["Estudiante<br/>[Persona]<br/>6.° grado de primaria"])
    D(["Docente<br/>[Persona]"])
    C(["Equipo de contenidos<br/>[Persona]"])
    S["EduKids<br/>[Sistema de software]<br/>Juego educativo offline en tablets,<br/>panel docente y nube de contenidos"]
    E -->|"Juega niveles y desafíos sin internet"| S
    D -->|"Gestiona su aula en la tablet<br/>y crea retos en el panel web"| S
    C -->|"Publica los módulos oficiales"| S
```

| Elemento | Descripción |
| --- | --- |
| Estudiante | Juega en la tablet con su avatar y su PIN. Solo ve su propio avance. |
| Docente | En la tablet configura el aula, habilita paquetes y revisa reportes. En el panel web crea y publica retos. |
| Equipo de contenidos | Produce y publica los módulos oficiales de las tres áreas desde el panel. |
| EduKids | Juego para Android que funciona sin internet en el aula, más la API y el panel que distribuyen y crean contenidos. |

**Límite de privacidad:** los resultados de los estudiantes no salen de la tablet. EduKids no se integra con sistemas externos como SIAGIE (fuera de alcance).
