# Glosario

## Juego

| Término | Definición |
| --- | --- |
| Capítulo | Región del mapa de aventura: Sierra, Selva o Costa. |
| Parada | Lugar de un capítulo (por ejemplo, Huamanga) que reúne el módulo del mismo número de las tres áreas. |
| Módulo | Paquete oficial de un área y un número (1 a 9) con explicación, niveles, ficha y desafío final. |
| Nivel | Partida corta (3 a 5 min) o regular (8 a 12 min) con varias preguntas. |
| Reto | Nivel creado por un docente en el panel web y descargado en las tablets. |
| Desafío final | Evaluación de un módulo; equivale al examen de la v2.0 y se califica con AD, A, B o C. |
| Ficha | Material de lectura del módulo; equivale al PDF de la v2.0 y se muestra como imágenes. |
| Explicación del guía | Teoría del módulo presentada por el guía con diálogos e ilustraciones. |
| Mecánica | Forma de jugar un nivel: persecución, puente o clásica. |
| Medidor de peligro | Regla común de las mecánicas: sube con los aciertos y baja con los errores; en cero se pierde una vida. |
| Vidas | Oportunidades de un nivel de práctica (3). Sin vidas, el nivel termina en game over y se puede reintentar. |
| Estrellas | Resultado de un nivel de práctica (1 a 3). No son una nota. |
| Guía | Personaje que explica, da pistas y reacciona: Quwi (Sierra), Tunki (Selva) y Humbi (Costa). |
| Atoq | Zorro andino travieso que persigue al avatar en los niveles. |
| Quipu de los saberes | Hilo narrativo: cada desafío final recupera una cuerda del quipu de Mama Sisa. |
| Escuelita | Lugar de cada capítulo donde aparecen los retos del docente. |

## Currículo y evaluación

| Término | Definición |
| --- | --- |
| CNEB | Currículo Nacional de la Educación Básica del Perú. |
| Competencia | Lo que el estudiante debe saber hacer en un área (por ejemplo, *Resuelve problemas de cantidad*). |
| Capacidad | Parte de una competencia (por ejemplo, *Usa estrategias y procedimientos*). |
| Ciclo V | 5.° y 6.° grado de primaria en el CNEB. |
| AD, A, B, C | Escala de calificación del CNEB: logro destacado, logro esperado, en proceso y en inicio. |
| PISA | Evaluación internacional de la OCDE para estudiantes de 15 años; EduKids adapta su enfoque a 6.° grado. |
| Unidad (estilo PISA) | Estímulo real (texto, tabla, gráfico) con varias preguntas de dificultad creciente. |
| Ítem | Pregunta individual de un nivel o de un desafío. |

## Sistema y arquitectura

| Término | Definición |
| --- | --- |
| Paquete | Archivo ZIP con un manifiesto JSON, niveles e imágenes. Puede ser un módulo o un reto. Nunca contiene código. |
| Manifiesto | Archivo `manifest.json` que describe el contenido y la versión de un paquete. |
| Catálogo | Lista pública de paquetes disponibles para descargar. |
| Código de docente | Código público de 6 caracteres que asocia los retos de un docente con sus tablets. |
| Modo docente | Parte de la aplicación de la tablet protegida con el PIN del docente. |
| Panel docente | Aplicación web donde el docente crea y publica retos. |
| Clean Architecture | Arquitectura por capas concéntricas en la que las dependencias apuntan hacia el dominio. |
| Entidad | Objeto del dominio con reglas propias (por ejemplo, un intento). |
| Caso de uso | Acción del sistema que coordina entidades y puertos (por ejemplo, responder una pregunta). |
| Puerto | Interfaz que define el dominio o la aplicación y que implementa una capa externa. |
| Adaptador | Implementación de un puerto (por ejemplo, el repositorio SQLite). |
| Raíz de composición | Único lugar donde se crean y conectan las implementaciones concretas. |
| Presentador | Adaptador que convierte la respuesta de un caso de uso en datos para una escena. |

## Correspondencia de nombres en el código

El código usa identificadores en inglés.

| Español | Código |
| --- | --- |
| Estudiante | `Student` |
| Sección | `Section` |
| Paquete | `Package` |
| Módulo | `Module` |
| Reto | `Challenge` |
| Nivel | `Level` |
| Ítem / actividad | `Item` |
| Intento | `Attempt` |
| Respuesta | `Answer` |
| Sesión de nivel | `LevelSession` |
| Medidor de peligro | `DangerMeter` |
| Calificación CNEB | `CnebGrade` |
| Recompensa | `Reward` |
| Área: Matemática / Comunicación / Ciencia y Tecnología | `math` / `language` / `science` |
| Capítulo: Sierra / Selva / Costa | `sierra` / `selva` / `costa` |
