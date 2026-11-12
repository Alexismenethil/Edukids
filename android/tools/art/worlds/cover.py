"""Portada: el valle de Huamanga en la mañana, en el estilo de caricatura limpia de los mundos.

Capas fijas (no se repiten) en unidades de pantalla de 1280 × 800: cada una va de x = -400 a 1680
para cubrir pantallas anchas y el vaivén de la cámara. Godot las pone en un ParallaxWorld con el
punto (640, 752) en el borde de abajo del botón Jugar.

    python3 tools/art/worlds/cover.py <carpeta de salida> [capa ...]

Capas: horizon (cordilleras nevadas), hills (lomas con andenes y chacras de colores), village
(pueblito con iglesia, casitas y eucaliptos), land (pradera con el camino, pircas y árboles grandes)
y front (pasto del primer plano). «preview» compone una vista de prueba.
"""

from __future__ import annotations

import math
import subprocess
import sys
from pathlib import Path

import numpy as np
from scipy.spatial import Voronoi

from cartoon import EUCALYPTUS, LEAF, RETAMA, SAGE, Shapes
from svgkit import Builder, Doc, circle_path, ellipse_path, fmt, poly, smooth_closed, smooth_open

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("out/cover")
OUT.mkdir(parents=True, exist_ok=True)

X0 = -400.0
W = 2080.0
HAZE = "#FFF1DE"
## Chimeneas del pueblito (x, y de pantalla): Godot les pone humo.
CHIMNEYS: list[tuple[float, float]] = []


def sx(x: float) -> float:
    """De x de pantalla a x del documento."""
    return x - X0


def curve(points, x: float) -> float:
    """Altura de una línea quebrada (x de pantalla) en x."""
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        if x0 <= x <= x1:
            t = (x - x0) / (x1 - x0)
            t = t * t * (3 - 2 * t)
            return y0 + (y1 - y0) * t
    return points[0][1] if x < points[0][0] else points[-1][1]


def sampled(points, step: float = 16.0):
    """Puntos del documento a lo largo de una cresta suave."""
    out = []
    x = points[0][0]
    while x <= points[-1][0]:
        out.append((sx(x), curve(points, x)))
        x += step
    return out


def land_shape(points, bottom: float) -> str:
    pts = sampled(points)
    return smooth_open(pts) + f" L{fmt(pts[-1][0])},{fmt(bottom)} L{fmt(pts[0][0])},{fmt(bottom)} Z"


def haze(doc: Doc, y0: float, y1: float, strength: float, color: str = HAZE) -> None:
    fill = doc.linear([(0.0, (color, 0.0)), (1.0, (color, strength))])
    doc.path(poly([(0, y0), (doc.width, y0), (doc.width, y1), (0, y1)]), fill)


def clip(doc: Doc, d: str) -> str:
    cid = doc.uid("c")
    doc.defs.append(f'<clipPath id="{cid}"><path d="{d}"/></clipPath>')
    return cid


# --- horizonte ----------------------------------------------------------------------------------

def horizon() -> None:
    doc = Doc(W, 340, top=190, comment="Portada: dos cordilleras nevadas con la luz de la mañana.")
    s = Shapes(doc, np.random.default_rng(7))
    back = [(-330, 420, 170), (-80, 400, 196), (230, 560, 262), (510, 360, 146), (770, 330, 124),
            (1060, 590, 272), (1370, 430, 200), (1630, 460, 214)]
    for cx, width, height in back:
        s.peak(sx(cx), 500, width, height, "#B5BCE7", "#FADDD3", "#E2E8FB", "#FFFFFF", snow=0.34,
               lean=s.rng.uniform(0.08, 0.2))
    front = [(-210, 360, 112), (80, 330, 104), (380, 390, 122), (640, 300, 72), (900, 360, 110),
             (1230, 380, 128), (1530, 340, 108)]
    for cx, width, height in front:
        s.peak(sx(cx), 522, width, height, "#9DA9DD", "#EEC6CD", "#D2DAF4", "#FFF7F1", snow=0.2,
               lean=s.rng.uniform(0.08, 0.2))
    haze(doc, 430, 530, 0.92)
    doc.save(str(OUT / "cover_horizon.svg"))


# --- lomas con andenes y chacras ----------------------------------------------------------------

LEFT_HILL = [(-400, 452), (-150, 446), (80, 456), (260, 474), (420, 506), (560, 548), (680, 600), (760, 660)]
RIGHT_HILL = [(520, 660), (600, 610), (740, 558), (900, 516), (1060, 488), (1250, 470), (1450, 462), (1680, 468)]
FIELD_COLORS = ["#E9D27E", "#F3E19A", "#A9D774", "#8CCB6E", "#D98EA0", "#EAA86A", "#CDA77A", "#BFDB8A", "#B2D27A"]


def hills() -> None:
    doc = Doc(W, 290, top=400, comment="Portada: lomas con andenes, chacras de colores y arboledas.")
    s = Shapes(doc, np.random.default_rng(11))
    back = [(-400, 478), (-100, 470), (200, 488), (420, 512), (640, 532), (860, 510), (1100, 484), (1400, 472), (1680, 480)]
    doc.path(land_shape(back, 690), "#D7EDC6")
    doc.path(land_shape([(x, y + 5) for x, y in back], 690), doc.linear([(0.0, "#BCDFB4"), (1.0, "#A6D39F")]))
    _groves(doc, s, back, 26, 4.0, 7.0, ("#7DB58A", "#93C79A", "#B7DDB4"), (-380, 1660))
    haze(doc, 470, 560, 0.5)
    for crest, terraces, seed in [(LEFT_HILL, (-380, 300), 3), (RIGHT_HILL, (980, 1560), 5)]:
        rim = land_shape(crest, 690)
        doc.path(rim, "#D4EDB8")
        body = land_shape([(x, y + 5) for x, y in crest], 690)
        doc.path(body, doc.linear([(0.0, "#AEDB91"), (1.0, "#93CD7E")]))
        _fields(doc, s, crest, body, seed)
        _terraces(doc, s, crest, body, terraces)
        _groves(doc, s, crest, 16, 5.0, 9.0, ("#4F9A62", "#68B072", "#9BD28E"),
                (crest[0][0], crest[-1][0]), drop=(14, 90))
    haze(doc, 600, 690, 0.7)
    doc.save(str(OUT / "cover_hills.svg"))


def _fields(doc: Doc, s: Shapes, crest, body: str, seed: int) -> None:
    """Chacras en parches limpios (trigo, cebada, papa, quinua rosada y naranja, tierra arada)."""
    rng = np.random.default_rng(seed)
    count = 60
    xs = rng.uniform(crest[0][0], crest[-1][0], count)
    ys = np.array([curve(crest, x) + rng.uniform(12, 150) for x in xs])
    pts = np.column_stack([xs, ys])
    vor = Voronoi(pts * [1.0, 2.6])
    cid = clip(doc, body)
    tags = []
    for i in range(count):
        region = vor.regions[vor.point_region[i]]
        if not region or -1 in region:
            continue
        cell = [(vx, vy / 2.6) for vx, vy in vor.vertices[region]]
        cx = sum(p[0] for p in cell) / len(cell)
        cy = sum(p[1] for p in cell) / len(cell)
        inset = [(sx(cx + (px - cx) * 0.88), cy + (py - cy) * 0.82) for px, py in cell]
        color = FIELD_COLORS[int(rng.integers(len(FIELD_COLORS)))]
        tags.append(f'<path d="{smooth_closed(inset, 0.25)}" fill="{color}"/>')
        # Surcos: rayitas que siguen el campo, un poco más oscuras.
        if rng.random() < 0.6:
            w = max(p[0] for p in inset) - min(p[0] for p in inset)
            for k in range(3):
                yy = cy - 6 + k * 6
                tags.append(f'<path d="M{fmt(sx(cx) - w * 0.32)},{fmt(yy)} Q{fmt(sx(cx))},{fmt(yy - 2)} {fmt(sx(cx) + w * 0.32)},{fmt(yy)}" '
                            f'fill="none" stroke="#000000" stroke-opacity="0.06" stroke-width="2" stroke-linecap="round"/>')
    doc.body.append(f'<g clip-path="url(#{cid})" opacity="0.92">' + "".join(tags) + "</g>")


def _terraces(doc: Doc, s: Shapes, crest, body: str, span) -> None:
    """Andenes: escalones que siguen la loma, con su muro de piedra y cultivos de colores."""
    x0, x1 = span
    cid = clip(doc, body)
    tags = []
    colors = ["#BEE39A", "#D7E68E", "#A8D883", "#E8DB92", "#B5DE8C", "#CFE49A"]
    for k in range(9):
        top = []
        x = x0
        while x <= x1:
            fade = min(1.0, (x - x0) / 120.0, (x1 - x) / 120.0)
            top.append((sx(x), curve(crest, x) + 18 + k * 13 - (1 - fade) * 4))
            x += 14
        bottom = [(px, py + 9) for px, py in reversed(top)]
        d = smooth_open(top) + " L" + " L".join(f"{fmt(px)},{fmt(py)}" for px, py in bottom) + " Z"
        tags.append(f'<path d="{d}" fill="{colors[k % len(colors)]}"/>')
        wall = smooth_open([(px, py + 9) for px, py in top])
        tags.append(f'<path d="{wall}" fill="none" stroke="#C9B48C" stroke-width="2.6" stroke-linecap="round"/>')
        tags.append(f'<path d="{wall}" fill="none" stroke="#E9DDBE" stroke-width="1" stroke-linecap="round" transform="translate(0,-1.4)"/>')
    doc.body.append(f'<g clip-path="url(#{cid})">' + "".join(tags) + "</g>")


def _groves(doc: Doc, s: Shapes, crest, count: int, r0: float, r1: float, palette, span, drop=(6, 40)) -> None:
    """Arboledas chiquitas (eucaliptos y molles a lo lejos) sobre las lomas."""
    rng = s.rng
    for _ in range(count):
        x = rng.uniform(span[0], span[1])
        y = curve(crest, x) + rng.uniform(*drop)
        b = Builder()
        circles = []
        for k in range(int(rng.integers(2, 5))):
            r = rng.uniform(r0, r1)
            circles.append((sx(x) + k * r * 1.1, y - r * rng.uniform(0.6, 1.4), r))
        s._puffs(b, circles, palette, highlights=1)
        b.emit(doc)


# --- pueblito -----------------------------------------------------------------------------------

FLOOR = [(-400, 622), (0, 612), (300, 598), (500, 590), (640, 586), (800, 590), (1000, 600), (1300, 612), (1680, 622)]


def village() -> None:
    doc = Doc(W, 250, top=470, comment="Portada: el pueblito con su iglesia blanca, casitas, eucaliptos y chacras.")
    s = Shapes(doc, np.random.default_rng(17))
    doc.path(land_shape(FLOOR, 720), "#C9EAAA")
    floor = land_shape([(x, y + 4) for x, y in FLOOR], 720)
    doc.path(floor, doc.linear([(0.0, "#A9DA8E"), (1.0, "#94CF7E")]))
    rng = s.rng
    # Chacras chicas a los lados del pueblo.
    cid = clip(doc, floor)
    tags = []
    for x0, x1 in [(-380, 300), (960, 1660)]:
        x = x0
        while x < x1:
            w = rng.uniform(70, 130)
            y = curve(FLOOR, x) + rng.uniform(6, 30)
            h = rng.uniform(10, 18)
            color = FIELD_COLORS[int(rng.integers(len(FIELD_COLORS)))]
            pts = [(sx(x) + 4, y), (sx(x + w) - 4, y - 2), (sx(x + w) + 6, y + h), (sx(x) - 6, y + h + 2)]
            tags.append(f'<path d="{smooth_closed(pts, 0.2)}" fill="{color}"/>')
            x += w + rng.uniform(6, 16)
    doc.body.append(f'<g clip-path="url(#{cid})" opacity="0.9">' + "".join(tags) + "</g>")
    # Eucaliptos detrás de las casas.
    for x, base, height in [(236, 600, 96), (262, 602, 118), (292, 600, 88), (980, 604, 104), (1010, 606, 124), (1046, 606, 92),
                            (-120, 616, 110), (1460, 618, 112)]:
        s.tall_tree(sx(x), base, height, ("#4E9474", "#67AE84", "#9FD2A8"))
    for x, base, height in [(326, 604, 46), (548, 596, 40), (744, 596, 42), (960, 604, 48)]:
        s.round_tree(sx(x), base, height, ("#4F9A62", "#68B072", "#9BD28E"))
    # Casitas: blancas con zócalo azul y techo de teja; algunas de adobe y de dos pisos.
    for x, base, w, style in [(360, 606, 30, "white"), (398, 603, 26, "adobe"), (440, 601, 36, "tall"), (486, 598, 25, "white"),
                              (526, 600, 22, "adobe"), (790, 600, 26, "white"), (832, 601, 34, "tall"), (876, 604, 26, "adobe"),
                              (918, 607, 30, "white")]:
        casita(doc, x, base, w, style)
    iglesia(doc, 640, 594)
    doc.path(ellipse_path(sx(640), 600, 58, 6), "#EBDDB6")
    haze(doc, 640, 720, 0.35)
    doc.save(str(OUT / "cover_village.svg"))


def casita(doc: Doc, x: float, base: float, w: float, style: str) -> None:
    """Casita andina: paredes blancas o de adobe, techo de teja, puerta y ventana azules."""
    h = w * (0.95 if style == "tall" else 0.62)
    wall, wall_shade = ("#F1D3AA", "#D9B48C") if style == "adobe" else ("#FFFBF3", "#E8DFD2")
    b = Builder()
    left, right = sx(x) - w / 2, sx(x) + w / 2
    b.path(poly([(left, base), (left, base - h), (right, base - h), (right, base)]), wall)
    b.path(poly([(right - w * 0.26, base), (right - w * 0.26, base - h), (right, base - h), (right, base)]), wall_shade)
    if style != "adobe":
        b.path(poly([(left, base), (left, base - h * 0.16), (right, base - h * 0.16), (right, base)]), "#4E8FD6")
    roof_h = w * 0.34
    b.path(poly([(left - w * 0.1, base - h + 1), (sx(x) - w * 0.04, base - h - roof_h), (right + w * 0.1, base - h + 1)]), "#C95A35")
    b.path(poly([(left - w * 0.1, base - h + 1), (sx(x) - w * 0.04, base - h - roof_h), (sx(x) + w * 0.06, base - h - roof_h * 0.82),
                 (left + w * 0.02, base - h + 1)]), "#E7865A")
    for k in range(4):
        t = (k + 0.5) / 4
        rx = left - w * 0.1 + (right + w * 0.1 - left + w * 0.1) * t
        b.stroke(f"M{fmt(rx)},{fmt(base - h + 1)} L{fmt(sx(x) - w * 0.04 + (rx - sx(x)) * 0.25)},{fmt(base - h - roof_h * 0.7)}",
                 "#B04A2B", 0.8, 0.5)
    door_w = w * 0.22
    b.path(poly([(sx(x) - door_w * 0.2, base), (sx(x) - door_w * 0.2, base - h * 0.5), (sx(x) + door_w * 0.8, base - h * 0.5),
                 (sx(x) + door_w * 0.8, base)]), "#2F6FB8")
    b.path(poly([(left + w * 0.12, base - h * 0.62), (left + w * 0.12, base - h * 0.84), (left + w * 0.3, base - h * 0.84),
                 (left + w * 0.3, base - h * 0.62)]), "#3B7DD8")
    if style == "tall":
        b.path(poly([(right - w * 0.36, base - h * 0.62), (right - w * 0.36, base - h * 0.84), (right - w * 0.16, base - h * 0.84),
                     (right - w * 0.16, base - h * 0.62)]), "#3B7DD8")
    chimney = (sx(x) + w * 0.22, base - h - roof_h * 0.55)
    if style in ("white", "tall") and len(CHIMNEYS) < 5:
        b.path(poly([(chimney[0] - 2.4, chimney[1] + 6), (chimney[0] - 2.4, chimney[1] - 5), (chimney[0] + 2.4, chimney[1] - 5),
                     (chimney[0] + 2.4, chimney[1] + 6)]), "#B9A58A")
        CHIMNEYS.append((round(x + w * 0.22, 1), round(chimney[1] - 6, 1)))
    b.span(left - w * 0.2, right + w * 0.2)
    b.emit(doc)


def iglesia(doc: Doc, x: float, base: float) -> None:
    """Iglesia blanca de Huamanga: nave con techo de teja, torre con campanario, cúpula y cruz."""
    cx = sx(x)
    b = Builder()
    white, shade, roof, roof_light = "#FFFDF6", "#E9E2D6", "#C95A35", "#E7865A"
    # Nave.
    b.path(poly([(cx - 22, base), (cx - 22, base - 36), (cx + 34, base - 36), (cx + 34, base)]), white)
    b.path(poly([(cx + 22, base), (cx + 22, base - 36), (cx + 34, base - 36), (cx + 34, base)]), shade)
    b.path(poly([(cx - 26, base - 35), (cx + 6, base - 52), (cx + 38, base - 35)]), roof)
    b.path(poly([(cx - 26, base - 35), (cx + 6, base - 52), (cx + 12, base - 49), (cx - 18, base - 35)]), roof_light)
    b.path(f"M{fmt(cx - 1)},{fmt(base)} L{fmt(cx - 1)},{fmt(base - 14)} Q{fmt(cx + 6)},{fmt(base - 22)} {fmt(cx + 13)},{fmt(base - 14)} "
           f"L{fmt(cx + 13)},{fmt(base)} Z", "#8C5236")
    b.path(circle_path(cx + 6, base - 27, 3.6), "#F2C14E")
    b.path(circle_path(cx + 6, base - 27, 2.0), "#FFF3B0")
    # Torre con campanario.
    tx = cx - 34
    b.path(poly([(tx - 11, base), (tx - 11, base - 62), (tx + 11, base - 62), (tx + 11, base)]), white)
    b.path(poly([(tx + 5, base), (tx + 5, base - 62), (tx + 11, base - 62), (tx + 11, base)]), shade)
    b.path(poly([(tx - 13, base - 62), (tx + 13, base - 62), (tx + 13, base - 66), (tx - 13, base - 66)]), shade)
    b.path(f"M{fmt(tx - 6)},{fmt(base - 66)} L{fmt(tx - 6)},{fmt(base - 78)} Q{fmt(tx)},{fmt(base - 86)} {fmt(tx + 6)},{fmt(base - 78)} "
           f"L{fmt(tx + 6)},{fmt(base - 66)} Z", "#5B6E8F")
    b.path(poly([(tx - 3, base - 70), (tx + 3, base - 70), (tx + 2.4, base - 76), (tx - 2.4, base - 76)]), "#F2C14E")
    b.path(poly([(tx - 10, base - 66), (tx - 10, base - 84), (tx - 7, base - 84), (tx - 7, base - 66)]), white)
    b.path(poly([(tx + 7, base - 66), (tx + 7, base - 84), (tx + 10, base - 84), (tx + 10, base - 66)]), shade)
    b.path(f"M{fmt(tx - 12)},{fmt(base - 84)} Q{fmt(tx)},{fmt(base - 104)} {fmt(tx + 12)},{fmt(base - 84)} Z", white)
    b.path(f"M{fmt(tx + 2)},{fmt(base - 92)} Q{fmt(tx + 9)},{fmt(base - 90)} {fmt(tx + 12)},{fmt(base - 84)} L{fmt(tx + 2)},{fmt(base - 84)} Z", shade)
    b.stroke(f"M{fmt(tx)},{fmt(base - 96)} L{fmt(tx)},{fmt(base - 110)} M{fmt(tx - 4.5)},{fmt(base - 105)} L{fmt(tx + 4.5)},{fmt(base - 105)}",
             "#C79A3E", 2.2)
    b.path(f"M{fmt(tx - 3)},{fmt(base - 40)} Q{fmt(tx)},{fmt(base - 46)} {fmt(tx + 3)},{fmt(base - 40)} L{fmt(tx + 3)},{fmt(base - 32)} "
           f"L{fmt(tx - 3)},{fmt(base - 32)} Z", "#5B6E8F")
    b.span(cx - 60, cx + 60)
    b.emit(doc)


# --- pradera con el camino ----------------------------------------------------------------------

MEADOW = [(-400, 640), (-100, 636), (200, 628), (420, 632), (560, 627), (640, 622), (720, 627), (900, 632), (1150, 625),
          (1400, 632), (1680, 640)]


def land() -> None:
    doc = Doc(W, 450, top=380, comment="Portada: pradera con el camino que llega al pueblo, pircas, árboles y flores.")
    s = Shapes(doc, np.random.default_rng(23))
    rng = s.rng
    # Árboles grandes que enmarcan la escena (detrás de la pradera).
    doc.path(ellipse_path(sx(1190), 694, 110, 12), "#3F8F48", 0.3)
    s.round_tree(sx(1190), 692, 300, LEAF)
    s.tall_tree(sx(26), 712, 360, EUCALYPTUS)
    s.tall_tree(sx(-120), 690, 300, EUCALYPTUS)
    s.round_tree(sx(1400), 690, 250, LEAF)
    doc.path(land_shape(MEADOW, 830), "#BFE895")
    meadow = land_shape([(x, y + 5) for x, y in MEADOW], 830)
    doc.path(meadow, doc.linear([(0.0, "#90D270"), (0.45, "#74C35E"), (1.0, "#56A84C")]))
    _road(doc, s)
    _pirca(doc, s, 300, 560, 6)
    _pirca(doc, s, 728, 980, 4)
    s.bush(sx(196), 664, 86, 46, RETAMA, "#FFD23F", 16)
    s.bush(sx(1070), 660, 92, 50, RETAMA, "#FFD23F", 18)
    s.maguey(sx(808), 700, 34, stalk=True)
    s.tuna(sx(-60), 714, 60)
    s.queñua(sx(1530), 700, 150, SAGE)
    for _ in range(60):
        x = rng.uniform(-380, 1660)
        if 520 < x < 760:
            continue
        y = rng.uniform(650, 812)
        if rng.random() < 0.3:
            s.grass_tuft(sx(x), y, rng.uniform(10, 18), lean=rng.uniform(-0.3, 0.3))
        else:
            s.flower(sx(x), y, rng.uniform(2.4, 3.4), ["#FF6B9A", "#FFD23F", "#FFFFFF", "#B98CF0"][int(rng.integers(4))])
    doc.save(str(OUT / "cover_land.svg"))


def _road(doc: Doc, s: Shapes) -> None:
    """El camino de tierra: nace bajo el botón Jugar y sube serpenteando hasta perderse en la loma."""
    rng = s.rng
    center = [(640, 624), (630, 640), (612, 664), (606, 690), (622, 720), (646, 760), (650, 830)]
    left, right = [], []
    y = 624.0
    while y <= 830:
        cx = curve([(py, px) for px, py in center], y)
        half = 4 + (max(0.0, y - 624) / 206.0) ** 1.35 * 200
        left.append((sx(cx - half), y))
        right.append((sx(cx + half), y))
        y += 6
    outline = smooth_open(left) + " L" + " L".join(f"{fmt(px)},{fmt(py)}" for px, py in reversed(right)) + " Z"
    doc.path(outline, "#C99A66")
    inner_l = [(px + 3, py) for px, py in left]
    inner_r = [(px - 3, py) for px, py in right]
    inner = smooth_open(inner_l) + " L" + " L".join(f"{fmt(px)},{fmt(py)}" for px, py in reversed(inner_r)) + " Z"
    doc.path(inner, doc.linear([(0.0, "#E3BE88"), (1.0, "#EFD3A2")]))
    cid = clip(doc, inner)
    tags = []
    for _ in range(46):
        y = rng.uniform(640, 820)
        cx = curve([(py, px) for px, py in center], y)
        half = 4 + (max(0.0, y - 624) / 206.0) ** 1.35 * 200
        x = cx + rng.uniform(-0.8, 0.8) * half
        r = 1.2 + (y - 624) / 206.0 * 4.5
        tags.append(f'<path d="{ellipse_path(sx(x), y, r * 1.5, r * 0.7)}" fill="#D5AE7C"/>')
        tags.append(f'<path d="{ellipse_path(sx(x) - r * 0.3, y - r * 0.25, r * 0.7, r * 0.3)}" fill="#F7E3BD"/>')
    doc.body.append(f'<g clip-path="url(#{cid})">' + "".join(tags) + "</g>")
    for k in range(18):
        y = 650 + k * 9.5
        cx = curve([(py, px) for px, py in center], y)
        half = 4 + (max(0.0, y - 624) / 206.0) ** 1.35 * 200
        for side in (-1, 1):
            s.grass_tuft(sx(cx + side * (half + 2)), y + 2, 6 + (y - 624) / 206.0 * 14, lean=side * 0.25)


def _pirca(doc: Doc, s: Shapes, x0: float, x1: float, seed: int) -> None:
    """Pirca: muro bajo de piedras redondeadas con pasto encima."""
    rng = np.random.default_rng(seed)
    x = x0
    stones = []
    while x < x1:
        w = rng.uniform(13, 20)
        y = curve(MEADOW, x) + 18 + math.sin((x - x0) * 0.02) * 2
        stones.append((x + w / 2, y, w))
        x += w * 0.86
    for row in range(2):
        for cx, y, w in stones:
            cy = y - row * 9
            if row == 1 and rng.random() < 0.25:
                continue
            tone = rng.uniform(-0.04, 0.04)
            b = Builder()
            b.path(ellipse_path(sx(cx), cy, w * 0.56, 6.2), _shade("#A79C88", tone))
            b.path(ellipse_path(sx(cx) - 1, cy - 1.4, w * 0.46, 4.4), _shade("#CFC5B1", tone))
            b.path(ellipse_path(sx(cx) - w * 0.15, cy - 3, w * 0.16, 1.4), "#EDE6D6")
            b.span(sx(cx) - w, sx(cx) + w)
            b.emit(doc)
    for cx, y, w in stones[::3]:
        s.grass_tuft(sx(cx), y - 13, rng.uniform(8, 13), ("#5FA552", "#7CC05F", "#A6D877"), lean=rng.uniform(-0.3, 0.3))


def _shade(color: str, amount: float) -> str:
    value = color.lstrip("#")
    rgb = [max(0, min(255, int(int(value[i:i + 2], 16) + amount * 255))) for i in (0, 2, 4)]
    return "#" + "".join(f"{c:02X}" for c in rgb)


# --- primer plano -------------------------------------------------------------------------------

def front() -> None:
    doc = Doc(W, 130, top=700, comment="Portada: pasto y flores del primer plano, en las esquinas.")
    s = Shapes(doc, np.random.default_rng(31))
    rng = s.rng
    for x0, x1 in [(-400, 300), (1000, 1680)]:
        for _ in range(int((x1 - x0) / 22)):
            x = rng.uniform(x0, x1)
            s.grass_tuft(sx(x), rng.uniform(782, 828), rng.uniform(30, 54), ("#2F7A3E", "#3F9147", "#62AE55"),
                         blades=6, lean=rng.uniform(-0.35, 0.35))
        for _ in range(int((x1 - x0) / 90)):
            x = rng.uniform(x0, x1)
            if rng.random() < 0.4:
                s.cantuta(sx(x), rng.uniform(788, 812), rng.uniform(5, 6.5))
            else:
                s.flower(sx(x), rng.uniform(788, 812), rng.uniform(4.2, 5.6), ["#FF6B9A", "#FFD23F", "#FFFFFF"][int(rng.integers(3))])
    doc.save(str(OUT / "cover_front.svg"))


def preview() -> None:
    """Vista de prueba: cielo, capas y una luz de sol detrás del logo (rsvg-convert + PIL)."""
    from PIL import Image, ImageDraw, ImageFilter
    view = Image.new("RGBA", (1280, 800))
    top, bottom = (79, 168, 221), (255, 226, 181)
    for y in range(800):
        t = min(1.0, y / 640)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        ImageDraw.Draw(view).line([(0, y), (1280, y)], fill=color)
    glow = Image.new("RGBA", (1280, 800), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((640 - 260, 118 - 260, 640 + 260, 118 + 260), fill=(255, 246, 214, 150))
    view.alpha_composite(glow.filter(ImageFilter.GaussianBlur(80)))
    for layer, top_y in [("horizon", 190), ("hills", 400), ("village", 470), ("land", 380), ("front", 700)]:
        png = OUT / f"cover_{layer}.png"
        subprocess.run(["rsvg-convert", str(OUT / f"cover_{layer}.svg"), "-o", str(png)], check=True)
        img = Image.open(png).convert("RGBA")
        view.alpha_composite(img.crop((400, 0, 1680, img.height)), (0, top_y))
        png.unlink()
    view.save(OUT / "cover_preview.png")


if __name__ == "__main__":
    steps = sys.argv[2:] or ["horizon", "hills", "village", "land", "front"]
    for step in steps:
        globals()[step]()
    if "village" in steps:
        print("Chimeneas:", CHIMNEYS)
