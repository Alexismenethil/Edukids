# 07. Tipos de ítems y calificación

## Unidades al estilo PISA

Una **unidad** presenta un estímulo real y luego varias preguntas:

- **Estímulo:** un texto, una tabla, un gráfico, una infografía, un mapa o una situación ilustrada, ambientada en la parada del juego.
- **Preguntas:** de 3 a 5, con dificultad creciente y procesos distintos (por ejemplo: localizar, luego inferir y por último evaluar).
- **Contexto:** personal (la casa, la escuela), comunitario (la feria, la chacra), científico (un experimento) o global (el clima, el mar).

## Tipos de ítem

Los nombres en inglés son los identificadores que usa el [formato de paquete](../03-diseno-de-software/formato-de-paquete.md).

| Tipo | Identificador | Cómo responde el estudiante | Cómo se corrige | Prioridad |
| --- | --- | --- | --- | --- |
| Opción múltiple | `multiple_choice` | Toca una opción | Una sola opción correcta | P1 |
| Selección múltiple | `multi_select` | Marca varias opciones | Debe marcar exactamente las correctas | P1 |
| Verdadero o falso | `true_false` | Elige V o F (o Sí o No) en cada afirmación | Cada afirmación por separado | P1 |
| Ordenar | `ordering` | Arrastra elementos a su posición | Secuencia exacta | P1 |
| Emparejar | `matching` | Une elementos de dos columnas | Todos los pares correctos | P1 |
| Clasificar | `classification` | Arrastra elementos a grupos o canastas | Cada elemento en su grupo | P1 |
| Completar | `fill_blank` | Elige o escribe la palabra que falta | Cada espacio; texto normalizado | P1 |
| Respuesta numérica | `numeric` | Escribe un número con el teclado del juego | Valor exacto o con tolerancia; acepta formatos equivalentes definidos (0,5 y 1/2) | P1 |
| Respuesta breve | `short_text` | Escribe una o dos palabras | Lista de respuestas aceptadas, sin distinguir mayúsculas ni tildes | P2 |
| Tocar en la imagen | `hotspot` | Toca una zona del dibujo, mapa o gráfico | Zona correcta | P2 |
| ¿Tiene sentido? | `sentence_check` | Decide rápido si una oración tiene sentido | Sí o No (fluidez lectora) | P2 |
| Unidad de lectura | `reading_unit` | Lee el estímulo y responde sus preguntas | Cada pregunta según su tipo | P1 |
| Simulación | `simulation` | Manipula una balanza, un circuito o un termómetro | Reglas propias de la simulación | P3 |

## Metadatos obligatorios de cada ítem

| Campo | Ejemplo |
| --- | --- |
| Área y módulo | `math`, `MAT-03` |
| Competencia y capacidad del CNEB | Resuelve problemas de cantidad · Usa estrategias y procedimientos |
| Categoría o competencia PISA | `quantity` |
| Proceso PISA | `employ` |
| Dificultad | 1, 2 o 3 |
| Tiempo estimado | 60 segundos |
| Retroalimentación | Explicación de la respuesta correcta y de los errores frecuentes |
| Pista | Opcional |

## Cómo escribir la retroalimentación

- Explica **por qué**, no solo "correcto" o "incorrecto".
- Usa un tono amable y frases cortas: como máximo dos líneas.
- Para cada distractor importante, escribe una retroalimentación que corrija el error que lo hace atractivo.
- La pista orienta sin dar la respuesta.

## Control de calidad antes de publicar

- [ ] El ítem corresponde a un contenido del temario y tiene todos sus metadatos.
- [ ] Hay una sola respuesta defendible (o el conjunto exacto en selección múltiple).
- [ ] Los distractores son errores reales de los estudiantes, no opciones absurdas.
- [ ] El texto se entiende sin ayuda oral y usa vocabulario de 6.° grado.
- [ ] Los datos son ficticios o tienen fuente citada.
- [ ] El contexto respeta la cultura que representa y no usa estereotipos.
- [ ] No contiene nombres ni datos personales de estudiantes reales.
- [ ] Un docente de 6.° grado lo revisó y aprobó.

## Calificación

### Niveles de práctica: estrellas

Las estrellas miden el desempeño en la práctica y no son una nota (reglas RN-11 y RN-13 en [requisitos funcionales](../01-analisis-de-sistema/03-requisitos-funcionales.md)):

| Estrellas | Condición |
| --- | --- |
| ★ | Completar el nivel. |
| ★★ | 70 % o más de aciertos al primer intento y sin pistas. |
| ★★★ | 90 % o más de aciertos al primer intento, sin pistas y sin perder vidas. |

### Desafío final: escala del CNEB

El desafío final se califica con la escala de logro del CNEB. Los rangos por defecto se basan en el porcentaje de aciertos y el docente puede ajustarlos (regla RN-12):

| Calificación | Significado | Rango por defecto |
| --- | --- | --- |
| **AD** | Logro destacado: supera lo esperado en la competencia. | 90 % a 100 % |
| **A** | Logro esperado: demuestra lo esperado en la competencia. | 70 % a 89 % |
| **B** | En proceso: está cerca de lo esperado y necesita acompañamiento. | 55 % a 69 % |
| **C** | En inicio: muestra un progreso mínimo y necesita más apoyo. | 0 % a 54 % |

La calificación del juego es **referencial**: ayuda al docente, pero la calificación oficial la decide el docente con todas sus evidencias.

### Composición del desafío final

- De 12 a 15 ítems que cubren todos los contenidos del módulo.
- Dificultad aproximada: 30 % básica, 50 % intermedia y 20 % avanzada.
- Al menos una unidad con estímulo (lectura, tabla, gráfico o experimento).
- Sin vidas ni medidor de peligro; la retroalimentación se muestra al terminar.
