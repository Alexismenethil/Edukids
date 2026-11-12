# Mundos de las escenas de juego

Generadores de los fondos en SVG de las mecánicas (estilo caricatura limpia: formas nítidas,
colores planos con degradados suaves, una sombra y una luz por objeto, sin texturas). Cada mundo se
pinta por capas para el paralaje de `ParallaxWorld` (`scenes/world/`).

| Script | Mundo | Capas |
| --- | --- | --- |
| `valley.py` | Valle del Qhapaq Ñan (persecución, menús y mapa) | `valley_far`, `valley_mid`, `valley_near`, `valley_ground`, `valley_front`, nubes y obstáculos |
| `canyon.py` | Cañón del puente colgante | `canyon_far`, `canyon_mid`, `canyon_near` y los tramos del puente |
| `lagoon.py` | Laguna de Coco | `lagoon_far`, `lagoon_mid`, `lagoon_near`, el nenúfar y la canasta |

`svgkit.py` arma los documentos SVG (curvas suaves, degradados, capas que se repiten sin costura) y
`cartoon.py` dibuja los elementos del paisaje andino (cerros nevados, molles, eucaliptos, queñuas,
retamas, magueyes, tunales, ichu, cantutas, piedras, casitas y nubes).

## Uso

Desde `android/`, con Python 3, `numpy` y `scipy`:

```bash
python3 tools/art/worlds/valley.py assets/art/worlds/valley
python3 tools/art/worlds/canyon.py assets/art/worlds/canyon
python3 tools/art/worlds/lagoon.py assets/art/worlds/lagoon
```

Se puede pintar una sola capa: `python3 tools/art/worlds/valley.py assets/art/worlds/valley near`.
Godot importa cada SVG a la escala que dice su `.import` (`svg/scale`): las capas cercanas a más
resolución que las lejanas, con mipmaps para que se vean nítidas cuando la cámara se aleja.

Las capas que se repiten (`valley_*`) miden lo mismo que su periodo; lo que sale por un borde vuelve a
entrar por el otro. Las coordenadas de los SVG son las del mundo del juego (la vista de acción mide
1280 × 800), así las alturas de los scripts coinciden con las de las escenas en GDScript.
