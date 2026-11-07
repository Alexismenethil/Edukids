# 08. Guía de arte y audio

## Dirección de arte

**Caricatura 2D limpia, cálida y expresiva**, con paisajes peruanos llenos de luz ([ADR-015](../01-analisis-de-sistema/decisiones/ADR-015-arte-2d-y-audio-sin-voces.md)).

- **Proporciones:** cabeza grande (cerca de un tercio del cuerpo) para los niños y los guías; ojos expresivos.
- **Contornos:** suaves, del color de la sombra del objeto (nunca negro puro).
- **Color:** colores planos con una sombra y una luz; sin texturas recargadas.
- **Formas:** redondeadas para lo amigable; algo más puntiagudas para Atoq, sin dejar de ser simpático.
- **Luz:** cálida y de dirección clara; cada capítulo tiene su ambiente (sol de la puna, neblina de la selva, atardecer en la costa).

## Lo que se toma de las referencias

Las referencias orientan el tono; no se copia ningún elemento.

| Referencia | Qué inspira |
| --- | --- |
| *Tunche* | Personajes de cabeza grande muy expresivos y la selva nocturna con luz cálida |
| *Inka Aventura* | Tipografía de títulos con motivos textiles andinos y detalles dorados |
| *Tinkina y los juguetes mágicos* | Paleta luminosa y sensación de aventura amable |

## Paletas

### Interfaz

| Token | Color | Uso |
| --- | --- | --- |
| `fondo` | `#FFF8EC` | Fondo de paneles y tarjetas |
| `texto` | `#2A2220` | Texto principal |
| `primario` | `#1F7A70` | Botones principales, con texto blanco |
| `acento` | `#F2C14E` | Resaltados y estrellas, con texto oscuro |
| `exito` | `#2E9E5B` | Aciertos, con icono o texto grande |
| `error` | `#D1495B` | Errores, con icono o texto grande |

### Áreas

| Área | Color | Icono |
| --- | --- | --- |
| Matemática | `#E8833A` | Nudos |
| Comunicación | `#3B7DD8` | Libro |
| Ciencia y Tecnología | `#3FA34D` | Hoja con lupa |

Sobre los colores de área se usa texto oscuro o texto blanco grande y en negrita. Cada combinación se verifica con un comprobador de contraste (WCAG AA).

### Capítulos

| Capítulo | Colores base |
| --- | --- |
| Sierra | Cielo `#6EC1E4`, ichu `#D9B26F`, puna `#A8B85A`, terracota `#B8623B`, adobe `#E3B98F`; acentos textiles `#C2185B`, `#F28C28` y `#1FA2A6` |
| Selva | Verde profundo `#1E5B3A`, esmeralda `#2E8B57`, hoja `#7BC67B`, río `#3E8FB0`, neblina `#C9C3E6`, cacao `#7B4A2E`; acento del gallito `#FF6A13` |
| Costa | Arena `#E9D3A3`, desierto `#D8A657`, mar `#2BB3B1`, océano `#1D4E89`, espuma `#F2F7F5`; acento del atardecer `#F27C5C` |

## Tipografía

| Uso | Fuente | Licencia |
| --- | --- | --- |
| Títulos e interfaz | Fredoka | SIL Open Font License |
| Lecturas y preguntas | Andika, diseñada para lectores que aprenden | SIL Open Font License |
| Logotipo y títulos de capítulo | Letras propias con motivos textiles andinos | Propia |

Tamaños en la resolución base: títulos de 40 a 56 px, preguntas de 28 px, lecturas de 26 px, botones de 26 px en negrita y ningún texto menor de 20 px. Interlineado de 1,4.

## Personajes

- Cada personaje tiene una hoja de modelo: vista de frente, de perfil y de tres cuartos, con sus colores.
- **Animación por piezas (cut-out):** cabeza, ojos, bocas intercambiables, torso, brazos, piernas y cola o alas, armadas con `Skeleton2D` y animadas con `AnimationPlayer`.
- Expresiones mínimas: alegría, ánimo, pensar, sorpresa y tristeza leve.
- Movimiento con anticipación, estiramiento y rebote, para que se sienta vivo y "dinámico".
- Las piezas de cada personaje van en un solo atlas de 2048 × 2048 px como máximo.

## Escenarios

- Fondos en 3 o 4 capas con desplazamiento parallax (cielo, montañas o árboles lejanos, plano medio y suelo).
- Elementos reutilizables entre paradas del mismo capítulo (rocas, árboles, casas, nubes) para ahorrar producción y memoria.
- Los caminos de las persecuciones se arman con piezas que se repiten.

## Efectos visuales

- Partículas ligeras: brillos en los aciertos, hojas, polvo de la carrera y neblina.
- Efectos suaves de escala y color en botones y tarjetas.
- Sin posprocesado pesado, para cuidar el rendimiento.

## Especificaciones técnicas

| Aspecto | Especificación |
| --- | --- |
| Resolución base | 1280 × 800, con escalado `canvas_items` y aspecto `expand` |
| Archivos fuente | SVG (vectorial), guardados fuera de la exportación |
| Personajes e interfaz | PNG o WebP a 2× de su tamaño en la resolución base |
| Fondos | WebP a 1,5× por capa |
| Compresión | Compresión de VRAM (ETC2 o ASTC) para fondos grandes; sin pérdida para interfaz y textos |
| Memoria de texturas | 64 MB o menos por escena |
| Nombres | `char_`, `bg_`, `ui_`, `icon_`, `fx_`, `mus_` y `sfx_`, en `snake_case`; por ejemplo `char_quwi_idle.png` |

## Audio

**Sin voces ni narración** ([ADR-015](../01-analisis-de-sistema/decisiones/ADR-015-arte-2d-y-audio-sin-voces.md)).

| Pieza | Descripción |
| --- | --- |
| Música de la Sierra | Quena, charango y percusión suave, inspirada en el huayno |
| Música de la Selva | Flautas, percusiones de madera y ambiente del bosque |
| Música de la Costa | Guitarra y cajón, con olas de fondo |
| Música del mapa y de los menús | Tema principal tranquilo |
| Música del desafío final | Tema concentrado y sin percusión intensa |

**Efectos de sonido:** acierto, error suave, estrella, vida perdida, game over cómico, victoria, botón, cambio de página, pasos, salto, risa instrumental de Atoq, cuerda del quipu y pausa activa.

- Formato OGG Vorbis; música en bucles de 1 a 2 minutos; efectos en mono.
- Volumen de música y de efectos ajustable por separado (RF-36).
- La música baja de volumen mientras el estudiante lee.

## Representación cultural

- [ ] La vestimenta y la arquitectura se basan en referencias reales del lugar.
- [ ] Los rasgos físicos son diversos y respetuosos, sin caricaturas étnicas.
- [ ] Ningún elemento sagrado o ritual se usa como objeto de juego.
- [ ] Las palabras en quechua están validadas por un hablante.
- [ ] Los docentes revisaron los personajes y escenarios del capítulo.

## Producción del MVP

| Recurso | Cantidad |
| --- | --- |
| Avatar base (niño y niña) con 6 animaciones | 2 |
| Quwi, Atoq y Mama Sisa con sus animaciones mínimas | 3 |
| Parada Huamanga: fondo en capas y personaje local | 1 |
| Mapa general y mapa de la Sierra | 2 |
| Kit de interfaz: botones, tarjetas, HUD, teclado numérico e iconos de área | 1 |
| Música: tema principal y tema de la Sierra | 2 |
| Efectos de sonido | 12 |
