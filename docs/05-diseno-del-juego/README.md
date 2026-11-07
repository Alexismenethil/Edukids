# 05. Diseño del juego (GDD)

## Ficha del juego

| Campo | Definición |
| --- | --- |
| Título de trabajo | EduKids: el quipu de los saberes |
| Género | Aventura educativa 2D con niveles de preguntas y minijuegos |
| Plataforma | Tablets Android (APK), 100 % offline en el aula |
| Motor | Godot 4.7 ([ADR-009](../01-analisis-de-sistema/decisiones/ADR-009-godot-como-motor.md)) |
| Público | Estudiantes de 6.° grado de primaria (11 y 12 años) |
| Áreas | Matemática, Comunicación y Ciencia y Tecnología |
| Ambientación | Sierra, Selva y Costa del Perú, con Ayacucho como punto de partida |
| Sesión típica | 2 horas, una vez por semana |
| Estilo visual | Caricatura 2D limpia, colorida y expresiva |
| Audio | Música y efectos de sonido, sin voces |
| Idioma | Español, con saludos y palabras en quechua |

## Pilares de diseño

1. **Aprender jugando:** cada respuesta mueve la aventura. El error se convierte en una pista y en otra oportunidad, no en un castigo permanente.
2. **Identidad:** personajes, paisajes y saberes de Ayacucho y del Perú, representados con respeto.
3. **Claridad:** interfaz limpia, textos cortos y botones grandes; nada distrae de la pregunta.
4. **Evaluación auténtica:** situaciones reales al estilo PISA y calificación con la escala del CNEB.
5. **Ligereza:** pensado para tablets de gama media y para jugar sin internet.

## Del módulo de la v2.0 al juego

| v2.0 | En el juego |
| --- | --- |
| Teoría | Explicación del guía, con diálogos breves e ilustraciones |
| PDF | Ficha de lectura, con las páginas como imágenes |
| Ejercicios | Niveles de práctica con mecánicas, vidas y estrellas |
| Examen | Desafío final, calificado con AD, A, B o C |

## Referencias visuales

Las imágenes de referencia elegidas por el autor (*Tunche*, *Inka Aventura: la saga de Pachakutiq* y *Tinkina y los juguetes mágicos*) marcan el tono buscado: caricatura limpia, personajes expresivos, paisajes peruanos con luz cálida y tipografía con motivos textiles. EduKids **no copia** personajes, escenarios, nombres ni recursos de esos juegos; todo el arte es original ([guía de arte y audio](08-guia-de-arte-y-audio.md)).

## Documentos

| Documento | Contenido |
| --- | --- |
| [01. Concepto y narrativa](01-concepto-y-narrativa.md) | Premisa, historia y tono |
| [02. Personajes](02-personajes.md) | Avatar, guías, Atoq, Mama Sisa y personajes de las paradas |
| [03. Capítulos y mapa](03-capitulos-y-mapa.md) | Sierra, Selva, Costa y estructura de una parada |
| [04. Mecánicas y actividades](04-mecanicas-y-actividades.md) | Bucle de juego, medidor de peligro, mecánicas y tipos de actividad |
| [05. Progresión y recompensas](05-progresion-y-recompensas.md) | Estrellas, vidas, insignias, cartas, accesorios y quipu |
| [06. Sesión de clase y niveles](06-sesion-de-clase-y-niveles.md) | Duración de niveles y organización de las 2 horas |
| [07. Interfaz y pantallas](07-interfaz-y-pantallas.md) | Flujo de pantallas, interfaz del nivel y accesibilidad |
| [08. Guía de arte y audio](08-guia-de-arte-y-audio.md) | Estilo, paletas, tipografía, animación, especificaciones técnicas y sonido |
