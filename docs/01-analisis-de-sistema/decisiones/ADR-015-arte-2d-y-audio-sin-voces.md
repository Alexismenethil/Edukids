# ADR-015: Arte 2D caricaturesco y audio sin voces

**Estado:** Aceptada (v3.0, 06/11/2026).

## Contexto

El juego debe ser inmersivo, bonito, limpio y caricaturesco, y a la vez liviano para tablets de gama media. Se decidió que no habrá voces, solo música.

## Decisión

- Arte **2D vectorial** de estilo caricaturesco y limpio, con proporciones de cabeza grande y paisajes peruanos con luz cálida.
- Animación **por piezas** (cut-out) con `Skeleton2D` y `AnimationPlayer`, que necesita pocas texturas y permite muchas expresiones.
- Todo el arte es original. Los juegos de referencia solo orientan el tono.
- Audio con música por capítulo y efectos de sonido en OGG, **sin voces ni narración**. Los diálogos se muestran en globos de texto.

Los detalles están en la [guía de arte y audio](../../05-diseno-del-juego/08-guia-de-arte-y-audio.md).

## Alternativas consideradas

- **Pixel art:** encantador, pero los textos largos y las ilustraciones educativas se leen peor a la resolución de una tablet.
- **3D:** más pesado para el hardware y más costoso de producir.
- **Voces:** aumentan el tamaño, el costo y el tiempo de producción; quedaron descartadas.

## Consecuencias

- Como no hay narración, los textos deben ser breves y muy legibles (RNF-11).
- El arte vectorial se puede exportar a distintas resoluciones sin rehacerlo.
