"""Fauna del paisaje (llamas y ovejas) por piezas, para animarlas con un rig recortado.

Escribe los SVG maestros en art-src/fauna/ (cada grupo part_* es una pieza). Después se arma el
rig con tools/art/build_cutout_rig.gd y su .rig.json.

    python3 tools/art/fauna.py art-src/fauna

La llama se dibuja en grises para teñirla (blanca, caramelo o café) y lleva su manta tejida y las
borlas de las orejas en color propio. La oveja va en sus colores.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "worlds"))
from svgkit import puff_outline, smooth_closed  # noqa: E402

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("art-src/fauna")
OUT.mkdir(parents=True, exist_ok=True)

# Grises que se tiñen: base, sombra, luz y contorno.
BASE, SHADE, DEEP, LIGHT, LINE = "#EDEDED", "#CFCFCF", "#B5B5B5", "#FFFFFF", "#8A8A8A"
FAR_BASE, FAR_SHADE = "#C9C9C9", "#ADADAD"


def group(name: str, body: str) -> str:
    return f'  <g id="part_{name}">\n{body}  </g>\n'


def leg(x_top: float, y_top: float, x_foot: float, y_foot: float, base: str, shade: str, hoof: str) -> str:
    """Pata de llama: muslo lanudo, caña fina y pezuña."""
    mid_x = (x_top + x_foot) / 2 + 1.5
    return (f'    <path d="M{x_top - 7},{y_top} C{x_top - 7.5},{y_top + 14} {mid_x - 4.5},{y_top + 22} {x_foot - 3.6},{y_foot - 4} '
            f'L{x_foot + 3.6},{y_foot - 4} C{mid_x + 4},{y_top + 22} {x_top + 7.5},{y_top + 14} {x_top + 7},{y_top} Z" '
            f'fill="{base}" stroke="{LINE}" stroke-width="2" stroke-linejoin="round"/>\n'
            f'    <path d="M{x_top + 3},{y_top + 4} C{x_top + 4},{y_top + 14} {mid_x + 2},{y_top + 24} {x_foot + 2},{y_foot - 8}" '
            f'fill="none" stroke="{shade}" stroke-width="3" stroke-linecap="round"/>\n'
            f'    <ellipse cx="{x_foot + 0.5}" cy="{y_foot - 1.5}" rx="6.5" ry="3.6" fill="{hoof}"/>\n')


def llama() -> None:
    """Llama de perfil mirando a la derecha. Suelo en y = 182."""
    parts = []
    parts.append(group("leg_bf", leg(42, 110, 38, 182, FAR_BASE, FAR_SHADE, "#4A4A4A")))
    parts.append(group("leg_ff", leg(92, 110, 94, 182, FAR_BASE, FAR_SHADE, "#4A4A4A")))
    parts.append(group("leg_bn", leg(34, 112, 30, 182, BASE, SHADE, "#3A3A3A")))
    parts.append(group("leg_fn", leg(100, 112, 104, 182, BASE, SHADE, "#3A3A3A")))
    parts.append(group("tail", (
        f'    <path d="M26,92 C14,90 8,80 12,70 C16,62 26,64 26,72 C30,66 36,74 32,82 C34,88 32,92 26,92 Z" '
        f'fill="{BASE}" stroke="{LINE}" stroke-width="2" stroke-linejoin="round"/>\n'
        f'    <path d="M16,76 C18,70 22,70 24,74" fill="none" stroke="{LIGHT}" stroke-width="2.5" stroke-linecap="round"/>\n')))
    # Cuerpo lanudo: unión de círculos con un solo contorno (sin huecos entre los rulos).
    circles = [(40, 100, 22), (60, 99, 25), (82, 99, 24), (100, 95, 17), (30, 90, 12), (36, 80, 10), (49, 75, 10),
               (63, 72, 10), (77, 72, 10), (91, 74, 10), (104, 80, 9), (112, 92, 8)]
    outline = smooth_closed(puff_outline(circles, 6), 0.6)
    body = (f'    <defs><clipPath id="llama_body"><path d="{outline}"/></clipPath></defs>\n'
            f'    <path d="{outline}" fill="{BASE}" stroke="{LINE}" stroke-width="2.2" stroke-linejoin="round"/>\n'
            '    <g clip-path="url(#llama_body)">\n'
            f'      <path d="M10,110 C40,118 80,120 130,106 L130,140 L10,140 Z" fill="{SHADE}"/>\n'
            f'      <ellipse cx="66" cy="80" rx="34" ry="6" fill="{LIGHT}" opacity="0.8"/>\n'
            '    </g>\n')
    for cx, cy in [(44, 108), (64, 112), (86, 108)]:
        body += f'    <path d="M{cx - 5},{cy} C{cx - 4},{cy - 4} {cx + 4},{cy - 4} {cx + 5},{cy}" fill="none" stroke="{DEEP}" stroke-width="1.8" stroke-linecap="round"/>\n'
    parts.append(group("body", body))
    # Manta tejida (aguayo) sobre el lomo: franjas de colores y flecos.
    stripes = [("#C2185B", 0, 5), ("#F28C28", 5, 9), ("#FFD23F", 9, 12), ("#1FA2A6", 12, 16), ("#7B2D8E", 16, 20),
               ("#C2185B", 20, 26)]
    blanket = ('    <defs><clipPath id="llama_blanket"><path d="M50,70 C62,66 78,66 90,70 L94,100 C80,104 62,104 48,100 Z"/>'
               '</clipPath></defs>\n    <g clip-path="url(#llama_blanket)">\n')
    for color, a, b in stripes:
        blanket += f'      <rect x="40" y="{66 + a * 1.4}" width="60" height="{(b - a) * 1.4 + 0.5}" fill="{color}"/>\n'
    for k in range(6):
        x = 54 + k * 7
        blanket += f'      <path d="M{x},80 L{x + 3.5},76 L{x + 7},80 L{x + 3.5},84 Z" fill="#FFF4DC"/>\n'
    blanket += '    </g>\n'
    blanket += ('    <path d="M50,70 C62,66 78,66 90,70 L94,100 C80,104 62,104 48,100 Z" fill="none" stroke="#7A1B3F" '
                'stroke-width="2" stroke-linejoin="round"/>\n')
    for k in range(9):
        x = 50 + k * 5.4
        blanket += f'    <path d="M{x},{101 + (k % 2)} L{x - 0.5},{107 + (k % 2)}" stroke="#F28C28" stroke-width="2" stroke-linecap="round"/>\n'
    parts.append(group("blanket", blanket))
    neck = (f'    <path d="M90,100 C92,82 100,62 108,44 C110,38 122,36 126,42 C124,62 118,84 116,100 Z" fill="{BASE}" '
            f'stroke="{LINE}" stroke-width="2.2" stroke-linejoin="round"/>\n'
            f'    <path d="M119,48 C117,64 113,80 112,96" fill="none" stroke="{SHADE}" stroke-width="5" stroke-linecap="round"/>\n'
            f'    <path d="M104,52 C100,62 97,72 96,82" fill="none" stroke="{LIGHT}" stroke-width="4" stroke-linecap="round"/>\n')
    parts.append(group("neck", neck))
    head = (
        # Oreja de atrás (más oscura) y oreja de adelante: largas como plátanos.
        f'    <path d="M112,30 C108,18 108,8 112,2 C116,6 118,18 118,28 Z" fill="{FAR_BASE}" stroke="{LINE}" stroke-width="2" stroke-linejoin="round"/>\n'
        f'    <path d="M122,30 C122,18 124,8 130,2 C132,10 130,22 128,30 Z" fill="{BASE}" stroke="{LINE}" stroke-width="2" stroke-linejoin="round"/>\n'
        f'    <path d="M126,26 C126,18 127,12 129,8" fill="none" stroke="{SHADE}" stroke-width="2" stroke-linecap="round"/>\n'
        # Cabeza y hocico.
        f'    <path d="M106,40 C104,30 110,24 120,24 C130,24 136,28 142,32 C150,34 154,40 152,46 C150,52 142,54 134,52 '
        f'C126,52 118,52 112,50 C107,48 106,44 106,40 Z" fill="{BASE}" stroke="{LINE}" stroke-width="2.2" stroke-linejoin="round"/>\n'
        f'    <path d="M136,34 C144,34 150,38 150,44 C150,50 144,52 138,50" fill="{LIGHT}" opacity="0.9"/>\n'
        f'    <path d="M148,38 C150,38 151,40 150,42" fill="none" stroke="#3A3A3A" stroke-width="2.4" stroke-linecap="round"/>\n'
        f'    <path d="M141,48 C144,50 147,50 149,48" fill="none" stroke="#3A3A3A" stroke-width="1.8" stroke-linecap="round"/>\n'
        # Ojo grande y amable, con pestañas.
        '    <ellipse cx="124" cy="35" rx="4.6" ry="5.4" fill="#2A2A2A"/>\n'
        '    <circle cx="125.6" cy="33" r="1.8" fill="#FFFFFF"/>\n'
        '    <path d="M119,31 L116.5,29 M120.5,29.5 L119,26.8" stroke="#2A2A2A" stroke-width="1.5" stroke-linecap="round"/>\n'
        f'    <ellipse cx="118" cy="44" rx="5" ry="3" fill="{SHADE}" opacity="0.8"/>\n')
    parts.append(group("head", head))
    tassels = ''
    for cx, cy, color in [(118, 25, "#E8336D"), (123, 22, "#F28C28"), (128, 25, "#1FA2A6"), (112, 24, "#FFD23F")]:
        tassels += (f'    <path d="M{cx},{cy} L{cx - 1.5},{cy + 7} M{cx},{cy} L{cx + 1.5},{cy + 7}" stroke="{color}" stroke-width="1.6" stroke-linecap="round"/>\n'
                    f'    <circle cx="{cx}" cy="{cy}" r="3.2" fill="{color}" stroke="#5A2E16" stroke-width="1"/>\n')
    parts.append(group("tassels", tassels))
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 170 186" width="170" height="186">\n'
           '  <!-- Llama del paisaje, de perfil mirando a la derecha. Las piezas en gris se tiñen (blanca,\n'
           '       caramelo o café); la manta tejida y las borlas de las orejas van en sus colores. -->\n'
           + "".join(parts) + '</svg>\n')
    (OUT / "llama.svg").write_text(svg)


def sheep() -> None:
    """Oveja de perfil mirando a la derecha: lana blanca, cara y patas oscuras. Suelo en y = 106."""
    wool, wool_shade, wool_line, dark = "#FFFDF6", "#E6DED0", "#A89A88", "#3B3434"
    parts = []
    for name, x_top, x_foot, color in [("leg_bf", 34, 32, "#2C2626"), ("leg_ff", 74, 76, "#2C2626"),
                                       ("leg_bn", 28, 25, dark), ("leg_fn", 80, 83, dark)]:
        parts.append(group(name, f'    <path d="M{x_top - 3.5},70 L{x_foot - 3},104 L{x_foot + 3},104 L{x_top + 3.5},70 Z" fill="{color}"/>\n'
                                 f'    <ellipse cx="{x_foot}" cy="104" rx="4.2" ry="2.4" fill="#1E1A1A"/>\n'))
    parts.append(group("tail", f'    <circle cx="14" cy="52" r="7" fill="{wool}" stroke="{wool_line}" stroke-width="1.8"/>\n'))
    puffs = [(22, 58, 13), (30, 44, 13), (44, 38, 14), (58, 37, 14), (72, 41, 13), (82, 52, 12), (76, 66, 13),
             (60, 72, 14), (42, 72, 14), (26, 68, 12)]
    body = ''
    for cx, cy, r in puffs:
        body += f'    <circle cx="{cx}" cy="{cy}" r="{r + 1.8}" fill="{wool_line}"/>\n'
    for cx, cy, r in puffs:
        body += f'    <circle cx="{cx}" cy="{cy}" r="{r}" fill="{wool}"/>\n'
    body += f'    <ellipse cx="52" cy="56" rx="34" ry="20" fill="{wool}"/>\n'
    body += f'    <ellipse cx="52" cy="70" rx="26" ry="5" fill="{wool_shade}" opacity="0.6"/>\n'
    for cx, cy in [(40, 44), (56, 42), (68, 48), (34, 58), (50, 56)]:
        body += f'    <path d="M{cx - 4},{cy} C{cx - 3},{cy - 4} {cx + 3},{cy - 4} {cx + 4},{cy}" fill="none" stroke="{wool_shade}" stroke-width="2" stroke-linecap="round"/>\n'
    parts.append(group("body", body))
    head = (f'    <path d="M82,46 C78,58 84,70 94,72 C104,74 110,66 108,56 C106,46 96,40 88,42 Z" fill="{dark}"/>\n'
            f'    <path d="M84,50 C78,52 72,58 72,62 C76,62 82,58 86,54 Z" fill="{dark}"/>\n'
            f'    <path d="M104,50 C110,50 114,54 116,58 C112,58 106,56 103,54 Z" fill="{dark}"/>\n'
            f'    <circle cx="86" cy="42" r="7" fill="{wool}" stroke="{wool_line}" stroke-width="1.5"/>\n'
            f'    <circle cx="94" cy="40" r="6" fill="{wool}" stroke="{wool_line}" stroke-width="1.5"/>\n'
            '    <circle cx="99" cy="56" r="3.2" fill="#FFFFFF"/>\n'
            '    <circle cx="100" cy="56.5" r="1.8" fill="#1E1A1A"/>\n'
            '    <circle cx="100.6" cy="55.6" r="0.7" fill="#FFFFFF"/>\n'
            '    <path d="M103,68 C105,69 107,68 108,66" fill="none" stroke="#8A7F7F" stroke-width="1.4" stroke-linecap="round"/>\n'
            '    <ellipse cx="94" cy="64" rx="3.5" ry="2" fill="#F28A80" opacity="0.5"/>\n')
    parts.append(group("head", head))
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 122 110" width="122" height="110">\n'
           '  <!-- Oveja del paisaje, de perfil mirando a la derecha: lana blanca, cara y patas oscuras. -->\n'
           + "".join(parts) + '</svg>\n')
    (OUT / "sheep.svg").write_text(svg)


if __name__ == "__main__":
    llama()
    sheep()
    print("Fauna lista en", OUT)
