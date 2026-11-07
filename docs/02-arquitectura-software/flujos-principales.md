# Flujos principales

## 1. Jugar un nivel de persecución

La escena no decide nada: el caso de uso aplica las reglas del dominio y la escena solo anima el resultado.

```mermaid
sequenceDiagram
    actor E as Estudiante
    participant V as Escena del nivel
    participant P as LevelPresenter
    participant UC as Caso de uso SubmitAnswer
    participant D as LevelSession del dominio
    participant R as AttemptRepository
    E->>V: Toca una opción
    V->>P: on_answer_selected(item_id, value)
    P->>UC: execute(request)
    UC->>D: answer(item_id, value)
    D-->>UC: correcta o no, medidor, vidas y fin del nivel
    UC->>R: save_answer(...)
    UC-->>P: SubmitAnswerResponse
    P-->>V: Modelo de vista: avanzar o acercar a Atoq y reacción del guía
    V-->>E: Animación y retroalimentación
```

Al terminar, el caso de uso `FinishLevel` calcula las estrellas (RN-11), otorga las recompensas y cierra el intento. Si las vidas llegan a cero, el resultado es game over y el estudiante puede reintentar (RN-14).

## 2. Rendir el desafío final

```mermaid
sequenceDiagram
    actor E as Estudiante
    participant P as FinalChallengePresenter
    participant UC as Casos de uso del desafío
    participant R as AttemptRepository
    E->>P: Abre el desafío final
    P->>UC: StartFinalChallenge
    UC->>R: Cuenta los intentos usados
    alt Quedan intentos
        UC-->>P: Intento abierto
        loop Cada pregunta
            E->>P: Responde
            P->>UC: AnswerFinalItem
            UC->>R: Guarda la respuesta en una transacción
        end
        E->>P: Confirma la entrega
        P->>UC: SubmitFinalChallenge
        UC->>UC: Calcula el porcentaje y aplica la escala del CNEB
        UC->>R: Cierra el intento con su calificación
        UC-->>P: Calificación AD, A, B o C y retroalimentación
    else Sin intentos
        UC-->>P: Pedir autorización al docente
    end
```

## 3. Publicar un reto y llevarlo a la tablet

```mermaid
sequenceDiagram
    actor D as Docente
    participant W as Panel web
    participant A as API de contenidos
    participant S as Almacenamiento
    participant T as Tablet en modo docente
    D->>W: Crea el reto y pulsa Publicar
    W->>A: POST /v1/challenges/ID/publish
    A->>A: Valida, arma el ZIP y calcula el SHA-256
    A->>S: Guarda el paquete versionado
    A-->>W: Publicado: versión y tamaño
    Note over T: En la Dirección, con internet
    T->>A: GET /v1/catalog?grade=6&teacherCode=K7M3QX
    A-->>T: Módulos oficiales y retos del docente
    T->>S: GET del paquete con encabezado Range
    S-->>T: Partes del ZIP
    T->>T: Verifica el SHA-256 e instala
    Note over T: En el aula, sin internet
    D->>T: Habilita el reto para su sección
```

## 4. Instalar un paquete

El mismo flujo se usa para un paquete descargado y para uno importado por USB.

```mermaid
flowchart TD
    A["Paquete descargado o importado"] --> B{"¿El SHA-256 coincide?"}
    B -- No --> X["Rechazar e informar el motivo"]
    B -- Sí --> C{"¿Hay espacio suficiente?"}
    C -- No --> X
    C -- Sí --> D{"¿Solo rutas y extensiones permitidas?<br/>Sin código, sin '..' y sin rutas absolutas"}
    D -- No --> X
    D -- Sí --> E{"¿Manifiesto válido y versión<br/>de formato compatible?"}
    E -- No --> X
    E -- Sí --> F["Descomprimir en una carpeta temporal"]
    F --> G["Mover a la carpeta definitiva<br/>y registrar en SQLite"]
    G --> H["Paquete instalado;<br/>el docente lo habilita por sección"]
```
