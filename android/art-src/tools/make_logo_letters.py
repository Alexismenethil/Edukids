"""Genera las letras del logotipo de EduKids a partir de Fredoka Bold (SIL OFL).

Cada letra lleva el color de una cuerda del quipu, contorno cálido, relieve, luz,
brillo y una franja tejida con rombos. Produce:
  - assets/art/ui/logo/ui_logo_letter_<n>.svg (+ .import a escala 2×)
  - scenes/ui/title/logo_word.tscn (letras ubicadas sobre una línea base común)

Uso (desde android/): python3 art-src/tools/make_logo_letters.py
Requiere fontTools (pip install fonttools).
"""
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = Path(__file__).resolve().parents[2]
FONT = ROOT / "assets/fonts/Fredoka-Variable.ttf"
OUT_DIR = ROOT / "assets/art/ui/logo"
SCENE = ROOT / "scenes/ui/title/logo_word.tscn"

WORD = "EduKids"
COLORS = ["#E8833A", "#3B7DD8", "#3FA34D", "#C2185B", "#F2C14E", "#1FA2A6", "#F27C5C"]
OUTLINE = "#4A2618"
PX_PER_UNIT = 0.17          # tamaño en la resolución base (1280 x 800)
STROKE = 92                 # contorno total; la mitad queda fuera de la letra
DEPTH = 54                  # relieve hacia abajo
PAD = STROKE // 2 + 12
TRACKING = -34              # letras un poco juntas, estilo logotipo
FRAME_TOP = 728 + PAD
BAND_BOTTOM, BAND_TOP = 92, 180   # franja tejida continua a lo largo de la palabra
FRAME_BOTTOM = -19 - PAD - DEPTH


def mix(hex_color: str, other: str, amount: float) -> str:
    a = [int(hex_color[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(other[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(x + (y - x) * amount):02X}" for x, y in zip(a, b))


def glyph_path(glyph_set, name: str, dy: float = 0.0) -> str:
    pen = SVGPathPen(glyph_set, ntos=lambda v: f"{v:.1f}".rstrip("0").rstrip("."))
    glyph_set[name].draw(TransformPen(pen, (1, 0, 0, -1, 0, dy)))
    return pen.getCommands()


def letter_svg(index: int, path: str, depth_path: str, bounds, color: str) -> tuple[str, float, float]:
    x_min, y_min, x_max, y_max = bounds
    left, right = x_min - PAD, x_max + PAD
    width_units, height_units = right - left, FRAME_TOP - FRAME_BOTTOM
    light, shade, deep = mix(color, "#FFFFFF", 0.30), mix(color, "#000000", 0.22), mix(color, "#2A1208", 0.55)
    height = y_max - y_min
    band_top = -BAND_TOP
    band_bottom = -BAND_BOTTOM
    light_line = -(y_max - height * 0.34)
    diamonds = []
    x = x_min + 40
    middle = (band_top + band_bottom) / 2
    half = (band_bottom - band_top) / 2 - 6
    while x < x_max:
        diamonds.append(f"M{x:.0f},{middle - half:.0f} L{x + half * 0.8:.0f},{middle:.0f} "
                        f"L{x:.0f},{middle + half:.0f} L{x - half * 0.8:.0f},{middle:.0f} Z")
        x += 74
    gloss_x, gloss_y = x_min + (x_max - x_min) * 0.28, -(y_max - height * 0.13)
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width_units * PX_PER_UNIT:.2f}" height="{height_units * PX_PER_UNIT:.2f}" viewBox="{left:.0f} {-FRAME_TOP:.0f} {width_units:.0f} {height_units:.0f}">
  <defs><clipPath id="glyph"><path d="{path}"/></clipPath></defs>
  <path d="{depth_path}" fill="{deep}" stroke="{OUTLINE}" stroke-width="{STROKE}" stroke-linejoin="round"/>
  <path d="{path}" fill="{OUTLINE}" stroke="{OUTLINE}" stroke-width="{STROKE}" stroke-linejoin="round"/>
  <path d="{path}" fill="{color}"/>
  <g clip-path="url(#glyph)">
    <rect x="{left:.0f}" y="{-FRAME_TOP:.0f}" width="{width_units:.0f}" height="{light_line + FRAME_TOP:.0f}" fill="{light}"/>
    <rect x="{left:.0f}" y="{band_top:.0f}" width="{width_units:.0f}" height="{band_bottom - band_top:.0f}" fill="{shade}"/>
    <path d="{' '.join(diamonds)}" fill="#FFF4E4"/>
    <ellipse cx="{gloss_x:.0f}" cy="{gloss_y:.0f}" rx="34" ry="20" fill="#FFFFFF" opacity="0.75" transform="rotate(-24 {gloss_x:.0f} {gloss_y:.0f})"/>
  </g>
</svg>
"""
    return svg, left, width_units


def main() -> None:
    font = instancer.instantiateVariableFont(TTFont(FONT), {"wght": 700, "wdth": 100})
    glyph_set = font.getGlyphSet()
    cmap = font.getBestCmap()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    letters = []
    pen_x = 0.0
    for index, char in enumerate(WORD):
        name = cmap[ord(char)]
        bounds_pen = BoundsPen(glyph_set)
        glyph_set[name].draw(bounds_pen)
        path = glyph_path(glyph_set, name)
        depth_path = glyph_path(glyph_set, name, dy=DEPTH)
        svg, left, width_units = letter_svg(index, path, depth_path, bounds_pen.bounds, COLORS[index])
        file_name = f"ui_logo_letter_{index}_{char.lower()}.svg"
        (OUT_DIR / file_name).write_text(svg, encoding="utf-8")
        (OUT_DIR / f"{file_name}.import").write_text(
            "[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n\n[deps]\n\n"
            f"source_file=\"res://assets/art/ui/logo/{file_name}\"\n\n[params]\n\n"
            "compress/mode=0\nmipmaps/generate=false\nprocess/fix_alpha_border=true\nsvg/scale=2.0\n",
            encoding="utf-8",
        )
        x_min, _, x_max, _ = bounds_pen.bounds
        letters.append({
            "file": file_name,
            "center": pen_x + (x_min + x_max) / 2,
            "offset_x": left - (x_min + x_max) / 2,
        })
        pen_x += font["hmtx"][name][0] + TRACKING

    word_width = pen_x - TRACKING
    lines = ["[gd_scene format=3]", ""]
    for index, letter in enumerate(letters):
        lines.append(f'[ext_resource type="Texture2D" path="res://assets/art/ui/logo/{letter["file"]}" id="{index + 1}_letter"]')
    lines += ["", '[node name="LogoWord" type="Node2D"]', ""]
    for index, letter in enumerate(letters):
        x = (letter["center"] - word_width / 2) * PX_PER_UNIT
        offset_x = letter["offset_x"] * PX_PER_UNIT * 2
        offset_y = -FRAME_TOP * PX_PER_UNIT * 2
        lines += [
            f'[node name="Letter{index}" type="Sprite2D" parent="."]',
            f"position = Vector2({x:.2f}, 0)",
            "scale = Vector2(0.5, 0.5)",
            f'texture = ExtResource("{index + 1}_letter")',
            "centered = false",
            f"offset = Vector2({offset_x:.2f}, {offset_y:.2f})",
            "",
        ]
    SCENE.parent.mkdir(parents=True, exist_ok=True)
    SCENE.write_text("\n".join(lines), encoding="utf-8")
    print(f"{len(letters)} letras; palabra de {word_width * PX_PER_UNIT:.0f} px de ancho; escena {SCENE.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
