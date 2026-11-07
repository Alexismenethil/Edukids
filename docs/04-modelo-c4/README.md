# 04. Modelo C4

Diagramas de la arquitectura de EduKids v3.0 según el modelo C4, dibujados con Mermaid. Cada nivel acerca la vista un paso más.

| Nivel | Documento | Muestra |
| --- | --- | --- |
| 1 | [Contexto](Nivel1-Contexto.md) | Las personas que usan EduKids y el sistema como una caja |
| 2 | [Contenedores](Nivel2-Contenedores.md) | Aplicaciones y almacenes de datos, con su tecnología |
| 3 | [Componentes](Nivel3-Componentes.md) | Componentes del juego y de la API, ordenados por capas de Clean Architecture |
| 4 | [Código](Nivel4-Codigo.md) | Clases del motor de niveles y su relación con los puertos |

**Notación:** las personas aparecen con bordes redondeados y la etiqueta [Persona]; los contenedores indican su tecnología entre corchetes; las flechas indican quién usa a quién o, en el nivel 4, quién depende de quién. El nivel 4 es una propuesta de diseño que se ajustará con el código real.
