"""Valle del Qhapaq Ñan (persecución), estilo caricatura limpia.

Capas SVG periódicas (corren sin fin) en unidades del mundo: la vista de acción mide 1280 × 800 y
los pies de los personajes pisan el camino en y ≈ 650. Godot importa cada SVG a su escala.

    python3 tools/art/worlds/valley.py <carpeta de salida> [capa ...]
"""

from __future__ import annotations

import math
import subprocess
import sys
from pathlib import Path

import numpy as np
from scipy.spatial import Voronoi

from cartoon import EUCALYPTUS, LEAF, LEAF_DEEP, RETAMA, SAGE, Shapes
from svgkit import Builder, Doc, circle_path, ellipse_path, fmt, poly, smooth_closed, smooth_open

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("out/valley")
OUT.mkdir(parents=True, exist_ok=True)

HAZE = "#FFF0DC"
SKY = [(0.0, "#5AB4EC"), (0.42, "#A6DBF3"), (0.72, "#FFEFD6"), (1.0, "#FFDDB5")]


def ridge(period: float, base: float, amplitude: float, waves, seed: int, step: float = 12.0):
    """Cresta periódica: suma de ondas con un número entero de vueltas por periodo."""
    rng = np.random.default_rng(seed)
    phases = rng.uniform(0, math.tau, len(waves))
    points = []
    x = -step * 3
    while x <= period + step * 3:
        y = base
        for (cycles, weight), phase in zip(waves, phases):
            y -= amplitude * weight * math.sin(math.tau * cycles * x / period + phase)
        points.append((x, y))
        x += step
    return points


def hill(doc: Doc, points, bottom: float, rim: str, top_color: str, bottom_color: str, rim_width: float = 6.0) -> str:
    """Loma con borde de luz: la cresta en color claro y el cuerpo con degradado. Devuelve el
    trazo del cuerpo (sirve de máscara para chacras)."""
    shape = smooth_open(points) + f" L{fmt(points[-1][0])},{fmt(bottom)} L{fmt(points[0][0])},{fmt(bottom)} Z"
    doc.path(shape, rim)
    lowered = [(x, y + rim_width) for x, y in points]
    body = smooth_open(lowered) + f" L{fmt(lowered[-1][0])},{fmt(bottom)} L{fmt(lowered[0][0])},{fmt(bottom)} Z"
    fill = doc.linear([(0.0, top_color), (1.0, bottom_color)])
    doc.path(body, fill)
    return body


def haze_band(doc: Doc, y0: float, y1: float, strength: float, color: str = HAZE) -> None:
    fill = doc.linear([(0.0, (color, 0.0)), (1.0, (color, strength))])
    doc.path(poly([(0, y0), (doc.width, y0), (doc.width, y1), (0, y1)]), fill)


def ridge_y(points, x: float) -> float:
    x = x % points[-1][0] if x > points[-1][0] else x
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        if x0 <= x <= x1:
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return points[0][1]


def far() -> None:
    doc = Doc(2560, 330, top=250, period=2560, comment="Valle: cordillera nevada a lo lejos.")
    s = Shapes(doc, np.random.default_rng(3))
    base = 572
    x = 0.0
    while x < doc.width:
        width = s.rng.uniform(420, 640)
        s.peak(x + width / 2, base, width, s.rng.uniform(200, 260), "#ABB4E4", "#F6D3C9", "#DDE4FA", "#FFFFFF",
               snow=0.3, lean=s.rng.uniform(0.08, 0.2))
        x += width * s.rng.uniform(0.5, 0.7)
    x = 180.0
    while x < doc.width:
        width = s.rng.uniform(320, 480)
        s.peak(x + width / 2, base + 4, width, s.rng.uniform(120, 170), "#93A3DA", "#E6BDC6", "#CDD7F3", "#FFF8F2",
               snow=0.2, lean=s.rng.uniform(0.08, 0.2))
        x += width * s.rng.uniform(0.55, 0.8)
    haze_band(doc, 470, 580, 0.9)
    doc.save(str(OUT / "valley_far.svg"))


def mid() -> None:
    doc = Doc(2304, 250, top=410, period=2304, comment="Valle: lomas con chacras, arboledas y casitas.")
    s = Shapes(doc, np.random.default_rng(5))
    back = ridge(doc.width, 512, 22, [(3, 1.0), (5, 0.45), (8, 0.2)], 21)
    hill(doc, back, 660, "#D3EEB9", "#A9D99C", "#9DD094")
    front = ridge(doc.width, 566, 26, [(2, 1.0), (4, 0.5), (7, 0.25)], 33)
    body = hill(doc, front, 660, "#C1E8A0", "#8CCB7B", "#7DBF70")
    _fields(doc, s, front, body)
    for _ in range(18):
        x = s.rng.uniform(0, doc.width)
        y = ridge_y(front, x) + s.rng.uniform(10, 40)
        if s.rng.random() < 0.7:
            for k in range(int(s.rng.integers(2, 4))):
                s.round_tree(x + k * s.rng.uniform(12, 18), y + s.rng.uniform(-2, 3), s.rng.uniform(30, 42),
                             ("#5E9E6C", "#78B779", "#A8D598"), ("#8A7A68", "#A69380", "#C2B09A"))
        else:
            s.house(x, y + 4, s.rng.uniform(16, 22))
    haze_band(doc, 590, 662, 0.75)
    doc.save(str(OUT / "valley_mid.svg"))


def _fields(doc: Doc, s: Shapes, crest, body: str) -> None:
    """Chacras en parches limpios, recortadas por la loma."""
    rng = s.rng
    period = doc.width
    count = 70
    pts = np.column_stack([rng.uniform(0, period, count), rng.uniform(560, 680, count)])
    tiled = np.vstack([pts, pts + [period, 0], pts - [period, 0]])
    vor = Voronoi(tiled * [1.0, 2.0])
    colors = ["#A8D86E", "#CDE48C", "#E8D98C", "#96CF79", "#BEDC7E", "#E6C982", "#9FD88C"]
    cid = doc.uid("c")
    doc.defs.append(f'<clipPath id="{cid}"><path d="{body}"/></clipPath>')
    tags = []
    for i in range(count):
        region = vor.regions[vor.point_region[i]]
        if not region or -1 in region:
            continue
        cell = [(vx, vy / 2.0) for vx, vy in vor.vertices[region]]
        cx = sum(p[0] for p in cell) / len(cell)
        cy = sum(p[1] for p in cell) / len(cell)
        inset = [(cx + (px - cx) * 0.9, cy + (py - cy) * 0.86) for px, py in cell]
        color = colors[int(rng.integers(len(colors)))]
        tags.append(f'<path d="{smooth_closed(inset, 0.25)}" fill="{color}"/>')
        for dx in (-period, period):
            if min(p[0] for p in inset) + dx < period and max(p[0] for p in inset) + dx > 0:
                shifted = [(px + dx, py) for px, py in inset]
                tags.append(f'<path d="{smooth_closed(shifted, 0.25)}" fill="{color}"/>')
    doc.body.append(f'<g clip-path="url(#{cid})" opacity="0.9">' + "".join(tags) + "</g>")


def near() -> None:
    doc = Doc(2048, 390, top=300, period=2048, comment="Valle: pradera con molles, eucaliptos, retamas, magueyes y tunales.")
    s = Shapes(doc, np.random.default_rng(8))
    crest = ridge(doc.width, 618, 10, [(3, 1.0), (6, 0.5)], 51)
    hill(doc, crest, 690, "#A8E07C", "#72C05C", "#62B152")
    items = []
    x = 90.0
    while x < doc.width:
        items.append(("tree", x, s.rng.choice(["molle", "eucalipto", "molle", "queñua"])))
        x += s.rng.uniform(320, 520)
    for _ in range(10):
        items.append(("bush", s.rng.uniform(0, doc.width), None))
    for _ in range(5):
        items.append(("maguey", s.rng.uniform(0, doc.width), None))
    for _ in range(4):
        items.append(("tuna", s.rng.uniform(0, doc.width), None))
    items.sort(key=lambda item: item[1] * 0 + s.rng.random())
    for kind, x, sub in items:
        y = ridge_y(crest, x) + s.rng.uniform(8, 18)
        if kind == "tree":
            doc.path(ellipse_path(x + 14, y + 2, 70 if sub != "eucalipto" else 40, 9), "#3F8F48", 0.35, (x - 70, x + 90))
            if sub == "molle":
                s.round_tree(x, y, s.rng.uniform(190, 240), LEAF)
            elif sub == "eucalipto":
                s.tall_tree(x, y, s.rng.uniform(230, 280), EUCALYPTUS)
            else:
                s.queñua(x, y, s.rng.uniform(130, 160), SAGE)
        elif kind == "bush":
            s.bush(x, y + 4, s.rng.uniform(56, 90), s.rng.uniform(34, 48), RETAMA, "#FFD23F", 14)
        elif kind == "maguey":
            s.maguey(x, y + 4, s.rng.uniform(28, 38), stalk=s.rng.random() < 0.4)
        else:
            s.tuna(x, y + 4, s.rng.uniform(48, 62))
    doc.save(str(OUT / "valley_near.svg"))


def ground() -> None:
    doc = Doc(1536, 150, top=596, period=1536, comment="Valle: el camino inca empedrado con pasto y flores.")
    s = Shapes(doc, np.random.default_rng(13))
    rng = s.rng
    edge = ridge(doc.width, 603, 3, [(6, 1.0), (11, 0.5)], 7, 8)
    fill = doc.linear([(0.0, "#78C65E"), (1.0, "#5DAA4B")])
    doc.path(smooth_open(edge) + f" L{fmt(edge[-1][0])},{fmt(760)} L{fmt(edge[0][0])},{fmt(760)} Z", fill)
    top, bottom = 627.0, 679.0
    doc.path(poly([(0, top), (doc.width, top), (doc.width, bottom), (0, bottom)]), "#C8996A")
    _flagstones(doc, rng, top, bottom)
    shadow = doc.linear([(0.0, ("#5C3F2A", 0.35)), (1.0, ("#5C3F2A", 0.0))])
    doc.path(poly([(0, top), (doc.width, top), (doc.width, top + 10), (0, top + 10)]), shadow)
    for edge_y, count in [(629, 46), (681, 52)]:
        clusters = rng.uniform(0, doc.width, 12)
        for _ in range(count):
            x = (clusters[int(rng.integers(len(clusters)))] + rng.normal(0, 30)) % doc.width
            if rng.random() < 0.35:
                s.ichu(x, edge_y + rng.uniform(-1, 3), rng.uniform(14, 22))
            else:
                s.grass_tuft(x, edge_y + rng.uniform(-1, 3), rng.uniform(12, 20), lean=rng.uniform(-0.3, 0.3))
    flowers = ["#FF6B9A", "#FFD23F", "#FFFFFF", "#B98CF0"]
    for _ in range(34):
        x = rng.uniform(0, doc.width)
        if rng.random() < 0.25:
            s.cantuta(x, rng.choice([626.0, rng.uniform(690, 730)]), rng.uniform(3.2, 4.2))
        else:
            s.flower(x, rng.choice([625.0, rng.uniform(688, 730)]), rng.uniform(2.6, 3.4), flowers[int(rng.integers(len(flowers)))])
    for _ in range(8):
        s.stone(rng.uniform(0, doc.width), rng.uniform(700, 735), rng.uniform(16, 26), rng.uniform(9, 14),
                ("#7FA06A", "#A8BE8A", "#D3DDB5"))
    doc.save(str(OUT / "valley_ground.svg"))


def _flagstones(doc: Doc, rng, top: float, bottom: float) -> None:
    """Empedrado del camino inca: hileras de losas redondeadas, más bajas hacia el fondo."""
    period = doc.width
    rows = [(top + 3.0, 12.5), (top + 17.5, 14.5), (top + 34.0, 15.5)]
    for row, (y0, height) in enumerate(rows):
        x = rng.uniform(0, 20)
        widths = []
        while x < period:
            w = rng.uniform(30, 52) * (0.9 + row * 0.06)
            if x + w > period - 18:
                w = period - x
            widths.append((x, w))
            x += w
        for x0, w in widths:
            if w < 10:
                continue
            gap = 2.6
            sx, sw = x0 + gap / 2, w - gap
            sy, sh = y0 + rng.uniform(-0.8, 0.8), height - gap
            r = sh * 0.42
            tone = rng.uniform(-1, 1)
            base = _shade("#EDCB98", tone * 0.045)
            shadow = _shade("#CC9F6E", tone * 0.045)
            light = _shade("#FBE6BF", tone * 0.03)
            b = Builder()
            b.path(_rounded(sx, sy, sw, sh, r), shadow)
            b.path(_rounded(sx + 0.6, sy - 0.4, sw - 1.6, sh - 3.0, r * 0.9), base)
            b.path(_rounded(sx + sw * 0.18, sy + 1.4, sw * 0.5, max(1.6, sh * 0.2), sh * 0.1), light, 0.95)
            b.span(sx, sx + sw)
            b.emit(doc)


def _rounded(x: float, y: float, w: float, h: float, r: float) -> str:
    r = min(r, w / 2, h / 2)
    return (f"M{fmt(x + r)},{fmt(y)} L{fmt(x + w - r)},{fmt(y)} Q{fmt(x + w)},{fmt(y)} {fmt(x + w)},{fmt(y + r)} "
            f"L{fmt(x + w)},{fmt(y + h - r)} Q{fmt(x + w)},{fmt(y + h)} {fmt(x + w - r)},{fmt(y + h)} "
            f"L{fmt(x + r)},{fmt(y + h)} Q{fmt(x)},{fmt(y + h)} {fmt(x)},{fmt(y + h - r)} "
            f"L{fmt(x)},{fmt(y + r)} Q{fmt(x)},{fmt(y)} {fmt(x + r)},{fmt(y)} Z")


def _shade(color: str, amount: float) -> str:
    value = color.lstrip("#")
    rgb = [int(value[i:i + 2], 16) for i in (0, 2, 4)]
    rgb = [max(0, min(255, int(c + amount * 255))) for c in rgb]
    return "#" + "".join(f"{c:02X}" for c in rgb)


def front() -> None:
    doc = Doc(1792, 170, top=650, period=1792, comment="Valle: primer plano de pasto, flores y piedras.")
    s = Shapes(doc, np.random.default_rng(17))
    rng = s.rng
    edge = ridge(doc.width, 716, 6, [(5, 1.0), (9, 0.4)], 19, 8)
    fill = doc.linear([(0.0, "#4E9E4E"), (1.0, "#2F7740")])
    doc.path(smooth_open(edge) + f" L{fmt(edge[-1][0])},{fmt(830)} L{fmt(edge[0][0])},{fmt(830)} Z", fill)
    clusters = rng.uniform(0, doc.width, 8)
    for _ in range(46):
        x = (clusters[int(rng.integers(len(clusters)))] + rng.normal(0, 60)) % doc.width
        s.grass_tuft(x, rng.uniform(722, 760), rng.uniform(34, 60), ("#2F7A3E", "#3F9147", "#62AE55"),
                     blades=6, lean=rng.uniform(-0.35, 0.35))
    for _ in range(6):
        s.stone(rng.uniform(0, doc.width), rng.uniform(748, 775), rng.uniform(46, 76), rng.uniform(24, 36),
                ("#5C6E66", "#7F928A", "#B4C3B6"))
    for _ in range(12):
        x = rng.uniform(0, doc.width)
        if rng.random() < 0.4:
            s.cantuta(x, rng.uniform(728, 752), rng.uniform(5.5, 7))
        else:
            s.flower(x, rng.uniform(728, 752), rng.uniform(4.5, 6), ["#FF6B9A", "#FFD23F", "#FFFFFF"][int(rng.integers(3))])
    doc.save(str(OUT / "valley_front.svg"))


def clouds() -> None:
    rng = np.random.default_rng(11)
    for index, (w, h) in enumerate([(300, 92), (220, 70), (380, 110), (170, 56)]):
        doc = Doc(w * 1.5, h * 1.6, top=0, comment="Nube de tarde.")
        s = Shapes(doc, rng)
        s.cloud(w * 0.75, h * 0.8, w, h)
        doc.save(str(OUT / f"cloud_{index}.svg"))


def preview(cam_x: float = 0.0, name: str = "preview") -> None:
    """Compone las capas como las verá el juego (rsvg-convert + PIL) para revisar."""
    from PIL import Image, ImageDraw
    view = Image.new("RGBA", (1280, 800))
    sky = Image.new("RGBA", (1, 800))
    stops = SKY
    for y in range(800):
        t = min(1.0, y / 600)
        for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
            if p0 <= t <= p1:
                k = (t - p0) / (p1 - p0)
                a = [int(c0[i:i + 2], 16) for i in (1, 3, 5)]
                b = [int(c1[i:i + 2], 16) for i in (1, 3, 5)]
                sky.putpixel((0, y), tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3)) + (255,))
                break
    view.alpha_composite(sky.resize((1280, 800)))
    glow = Image.new("RGBA", (1280, 800), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((1010 - 60, 360 - 60, 1010 + 60, 360 + 60), fill=(255, 250, 230, 255))
    view.alpha_composite(glow)

    def render(svg: Path) -> Image.Image:
        png = svg.with_suffix(".png")
        subprocess.run(["rsvg-convert", str(svg), "-o", str(png)], check=True)
        return Image.open(png).convert("RGBA")
    for index, (x, y) in enumerate([(120, 120), (560, 70), (860, 170), (380, 230)]):
        view.alpha_composite(render(OUT / f"cloud_{index}.svg"), (x, y))
    for layer, depth, top in [("far", 0.12, 250), ("mid", 0.3, 410), ("near", 0.6, 300), ("ground", 1.0, 596), ("front", 1.4, 650)]:
        img = render(OUT / f"valley_{layer}.svg")
        offset = int(cam_x * depth) % img.width
        x = -offset
        while x < 1280:
            if x >= 0:
                view.alpha_composite(img, (x, top))
            else:
                view.alpha_composite(img.crop((-x, 0, img.width, img.height)), (0, top))
            x += img.width
    view.save(OUT / f"{name}.png")



def props() -> None:
    """Obstáculos del camino y el arco tejido de la meta."""
    rng = np.random.default_rng(29)
    doc = Doc(120, 80, top=0, comment="Piedra grande del camino.")
    s = Shapes(doc, rng)
    s.stone(60, 74, 92, 58, ("#8A8197", "#B5AAB4", "#E6DAD2"))
    doc.path(ellipse_path(42, 30, 12, 6, -0.3), "#7DBB5F", 0.9)
    doc.save(str(OUT / "prop_stone.svg"))
    doc = Doc(110, 110, top=0, comment="Apacheta: montoncito de piedras de los viajeros.")
    s = Shapes(doc, rng)
    for row, (count, y, w, h) in enumerate([(3, 104, 32, 22), (2, 84, 30, 20), (1, 64, 28, 19), (1, 46, 20, 15)]):
        for k in range(count):
            x = 55 + (k - (count - 1) / 2) * w * 0.95 + rng.uniform(-2, 2)
            s.stone(x, y, w, h, ("#8F8698", "#BCB1B8", "#E8DDD6"))
    doc.save(str(OUT / "prop_apacheta.svg"))
    doc = Doc(120, 70, top=0, comment="Mata grande de ichu en el camino.")
    s = Shapes(doc, rng)
    s.ichu(60, 68, 58)
    doc.save(str(OUT / "prop_ichu.svg"))
    _arch()
    _cantuta_bush()


## Flores de la mata de cantuta: (x, y de donde cuelga, inclinación, tamaño, color). La boca de cada
## campana queda a 2.4·tamaño de su punto de unión, en la dirección inclinada; el picaflor de la
## portada visita esas bocas.
CANTUTAS = [(36, 126, 0.48, 12, "#E8336D"), (58, 96, 0.3, 13, "#D7263D"), (90, 78, 0.1, 12, "#E8336D"),
            (128, 78, -0.12, 13, "#F2A93B"), (160, 94, -0.3, 12, "#D7263D"), (184, 122, -0.46, 12, "#E8336D"),
            (108, 108, 0.04, 12, "#D7263D")]


def _cantuta_bush() -> None:
    """Mata de cantuta, la flor del Perú, con sus campanas colgantes (portada)."""
    rng = np.random.default_rng(41)
    doc = Doc(220, 196, top=0, comment="Mata de cantuta con campanas fucsias, rojas y doradas.")
    s = Shapes(doc, rng)
    b = Builder()
    circles = [(36, 156, 28), (62, 122, 30), (98, 102, 34), (138, 104, 33), (172, 126, 29), (190, 160, 24),
               (110, 152, 46), (66, 166, 30), (152, 164, 32), (24, 176, 18)]
    s._puffs(b, circles, LEAF, highlights=3)
    b.emit(doc)
    mouths = []
    for x, y, tilt, size, color in CANTUTAS:
        mouths.append(_hanging_cantuta(doc, x, y, tilt, size, color))
    doc.save(str(OUT / "prop_cantuta.svg"))
    print("Bocas de la cantuta:", [(round(mx, 1), round(my, 1)) for mx, my in mouths])


def _hanging_cantuta(doc: Doc, x: float, y: float, tilt: float, size: float, color: str) -> tuple:
    """Campana tubular que cuelga de la rama: cáliz verde, trompeta que se abre y estambres."""
    c, sn = math.cos(tilt), math.sin(tilt)

    def at(px: float, py: float) -> tuple:
        return (x + px * c - py * sn, y + px * sn + py * c)

    s = size
    deep = {"#E8336D": "#A3164A", "#D7263D": "#8E1430", "#F2A93B": "#B5651D"}.get(color, "#8E1430")
    light = {"#E8336D": "#FF8FB0", "#D7263D": "#FF7A82", "#F2A93B": "#FFD98A"}.get(color, "#FFB0C0")
    tube = [at(-0.2 * s, 0.3 * s), at(0.2 * s, 0.3 * s), at(0.34 * s, 1.5 * s), at(0.62 * s, 2.3 * s),
            at(0.3 * s, 2.2 * s), at(0.0, 2.42 * s), at(-0.3 * s, 2.2 * s), at(-0.62 * s, 2.3 * s), at(-0.34 * s, 1.5 * s)]
    doc.path(smooth_closed(tube), color)
    doc.path(smooth_open([at(-0.06 * s, 0.5 * s), at(-0.14 * s, 1.4 * s), at(-0.32 * s, 2.06 * s)]), "none")
    doc.stroke(smooth_open([at(-0.05 * s, 0.55 * s), at(-0.13 * s, 1.35 * s), at(-0.3 * s, 2.0 * s)]), light, max(1.2, s * 0.13))
    mouth = at(0.0, 2.3 * s)
    doc.path(ellipse_path(mouth[0], mouth[1], 0.42 * s, 0.11 * s, tilt), deep)
    for dx in (-0.12, 0.0, 0.12):
        tip = at(dx * s, 2.62 * s)
        doc.stroke(f"M{fmt(mouth[0] + dx * s * 0.5)},{fmt(mouth[1])} L{fmt(tip[0])},{fmt(tip[1])}", "#FFE9A8", max(0.8, s * 0.07))
        doc.path(circle_path(tip[0], tip[1], max(0.9, s * 0.08)), "#FFD23F")
    doc.path(smooth_closed([at(-0.26 * s, 0.0), at(0.26 * s, 0.0), at(0.18 * s, 0.42 * s), at(-0.18 * s, 0.42 * s)]), "#3C7F3A")
    return mouth


def _arch() -> None:
    doc = Doc(240, 270, top=0, comment="Arco tejido de la meta.")
    poles = [(30, "#8E5A3E", "#B07A54"), (210, "#8E5A3E", "#B07A54")]
    for x, base, light in poles:
        doc.path(_rounded_rect(x - 9, 40, 18, 228, 6), base)
        doc.path(_rounded_rect(x + 1, 44, 6, 220, 3), light)
        doc.path(ellipse_path(x, 40, 13, 8), "#6B4130")
    band_top, band_h = 26.0, 44.0
    stripes = [("#C2185B", 0.0, 0.22), ("#F28C28", 0.22, 0.36), ("#FFD23F", 0.36, 0.46), ("#1FA2A6", 0.46, 0.6),
               ("#C2185B", 0.6, 0.82), ("#7B2D8E", 0.82, 1.0)]
    for color, t0, t1 in stripes:
        y0, y1 = band_top + band_h * t0, band_top + band_h * t1
        doc.path(f"M8,{fmt(y0)} Q120,{fmt(y0 + 10)} 232,{fmt(y0)} L232,{fmt(y1)} Q120,{fmt(y1 + 10)} 8,{fmt(y1)} Z", color)
    for k in range(11):
        cx = 18 + k * 20.4
        cy = band_top + band_h * 0.71 + 10 * (1 - ((cx - 120) / 112) ** 2)
        doc.path(poly([(cx - 6, cy), (cx, cy - 5), (cx + 6, cy), (cx, cy + 5)]), "#FFF4DC")
    for k in range(12):
        x = 14 + k * 19.3
        y = band_top + band_h + 9 * (1 - ((x - 120) / 112) ** 2) - 1
        doc.stroke(f"M{fmt(x)},{fmt(y)} L{fmt(x + 1)},{fmt(y + 16)}", ["#C2185B", "#F28C28", "#1FA2A6"][k % 3], 3.2)
    doc.save(str(OUT / "prop_arch.svg"))


def _rounded_rect(x: float, y: float, w: float, h: float, r: float) -> str:
    return (f"M{fmt(x + r)},{fmt(y)} L{fmt(x + w - r)},{fmt(y)} Q{fmt(x + w)},{fmt(y)} {fmt(x + w)},{fmt(y + r)} "
            f"L{fmt(x + w)},{fmt(y + h - r)} Q{fmt(x + w)},{fmt(y + h)} {fmt(x + w - r)},{fmt(y + h)} "
            f"L{fmt(x + r)},{fmt(y + h)} Q{fmt(x)},{fmt(y + h)} {fmt(x)},{fmt(y + h - r)} "
            f"L{fmt(x)},{fmt(y + r)} Q{fmt(x)},{fmt(y)} {fmt(x + r)},{fmt(y)} Z")


if __name__ == "__main__":
    # «preview» compone una vista de prueba con PNG intermedios: usarlo con una carpeta de pruebas.
    steps = sys.argv[2:] or ["far", "mid", "near", "ground", "front", "clouds", "props"]
    for step in steps:
        globals()[step]()
