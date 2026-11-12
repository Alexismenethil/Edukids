# Mundos de las escenas de juego

Generadores de los fondos en SVG de las mecánicas (estilo caricatura limpia: formas nítidas,
colores planos con degradados suaves, una sombra y una luz por objeto, sin texturas). Cada mundo se
pinta por capas para el paralaje de `ParallaxWorld` (`scenes/world/`).

| Script | Mundo | Capas |
| --- | --- | --- |
| `valley.py` | Valle del Qhapaq Ñan (persecución, menús y mapa) | `valley_far`, `valley_mid`, `valley_near`, `valley_ground`, `valley_front`, nubes y obstáculos |
| `canyon.py` | Cañón del puente colgante | `canyon_far`, `canyon_mid`, `canyon_near` y los tramos del puente |
| `lagoon.py` | Laguna de Coco | `lagoon_far`, `lagoon_mid`, `lagoon_near`, el nenúfar y la canasta |
| `jungle.py` | Selva del valle del Apurímac (capítulo 2) | `jungle_far`, `jungle_mid`, `jungle_near`, `jungle_ground`, `jungle_front` |
| `coast.py` | Costa: del mar al desierto (capítulo 3) | `coast_far`, `coast_mid`, `coast_near`, `coast_ground`, `coast_front` |
| `cover.py` | Portada: el valle de Huamanga en la mañana | `cover_horizon` (cordilleras), `cover_hills` (andenes y chacras), `cover_village` (iglesia, casitas y eucaliptos), `cover_land` (pradera, camino, pircas y árboles) y `cover_front` |

`svgkit.py` arma los documentos SVG (curvas suaves, degradados, capas que se repiten sin costura) y
`cartoon.py` dibuja los elementos del paisaje andino (cerros nevados, molles, eucaliptos, queñuas,
retamas, magueyes, tunales, ichu, cantutas, piedras, casitas y nubes).

`terrain.py` tiene lo común de los mundos que corren (crestas periódicas, lomas, bruma) y los elementos de
la Selva y la Costa (palmeras, hojas grandes, helechos, lianas, islotes guaneros, caballitos de totora,
conchas y estrellas de mar). `jungle.py` y `coast.py` usan las mismas medidas que el valle, así el juego
cambia de región sin tocar las mecánicas (`WorldSets.REGION_WORLDS`). Con el paso `preview` componen las
capas en una imagen para revisarlas.

## Uso

Desde `android/`, con Python 3, `numpy` y `scipy`:

```bash
python3 tools/art/worlds/valley.py assets/art/worlds/valley
python3 tools/art/worlds/canyon.py assets/art/worlds/canyon
python3 tools/art/worlds/lagoon.py assets/art/worlds/lagoon
python3 tools/art/worlds/jungle.py assets/art/worlds/jungle
python3 tools/art/worlds/coast.py assets/art/worlds/coast
python3 tools/art/worlds/cover.py assets/art/worlds/cover
```

Las capas de la portada no se repiten: están dibujadas en unidades de pantalla de 1280 × 800 y van de x = -400
a 1680 para cubrir pantallas anchas. `cover.py` imprime dónde quedan las chimeneas del pueblito (la portada les
pone humo) y con el paso `preview` compone una vista de prueba. La mata de cantuta del picaflor de la portada es
`prop_cantuta.svg` (paso `props` de `valley.py`), que imprime la boca de cada flor.

Se puede pintar una sola capa: `python3 tools/art/worlds/valley.py assets/art/worlds/valley near`.
Godot importa cada SVG a la escala que dice su `.import` (`svg/scale`): las capas cercanas a más
resolución que las lejanas, con mipmaps para que se vean nítidas cuando la cámara se aleja.

Las capas que se repiten (`valley_*`) miden lo mismo que su periodo; lo que sale por un borde vuelve a
entrar por el otro. Las coordenadas de los SVG son las del mundo del juego (la vista de acción mide
1280 × 800), así las alturas de los scripts coinciden con las de las escenas en GDScript.
