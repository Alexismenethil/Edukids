"""Selva del valle del Apurímac (capítulo 2), estilo caricatura limpia.

Capas SVG periódicas con las mismas medidas que el valle, así el mundo corre sin fin y sirve para
las mismas mecánicas: cerros cubiertos de bosque entre la neblina, colinas de copas apretadas,
árboles altos con palmeras y lianas, un sendero de tierra con helechos y un primer plano de hojas
grandes. Verdes profundos y esmeralda, lila de la neblina y el naranja de las flores.

    python3 tools/art/worlds/jungle.py <carpeta de salida> [capa ...]
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

from cartoon import Shapes
from svgkit import Doc, ellipse_path, fmt, poly, smooth_open
from terrain import big_leaf, fern, haze_band, heliconia, hill, liana, palm, preview as compose, ridge, ridge_y

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("out/jungle")
OUT.mkdir(parents=True, exist_ok=True)

MIST = "#EDE6FA"
SKY = [(0.0, "#55B7DC"), (0.42, "#A5E0E4"), (0.72, "#E9F6E4"), (1.0, "#D9F0D2")]
CANOPY = ("#2E8659", "#46A96A", "#8FD98A")
CANOPY_DEEP = ("#1F6B4C", "#34915C", "#72C67C")
CANOPY_FAR = ("#5FA78E", "#7DBF9E", "#B4E0BC")
BARK = ("#6B4A36", "#8E6648", "#B98F68")


def far() -> None:
    doc = Doc(2560, 330, top=250, period=2560, comment="Selva: cerros cubiertos de bosque entre la neblina.")
    rng = np.random.default_rng(2)
    for base, amp, waves, seed, rim, top, bottom, bump in [
        (402, 70, [(2, 1.0), (5, 0.4), (9, 0.18)], 4, "#BFE6DA", "#8FCFC4", "#7CC2B6", 15),
        (462, 54, [(3, 1.0), (4, 0.5), (8, 0.22)], 9, "#A6E0C6", "#6CBFA2", "#5BB294", 17),
        (522, 40, [(2, 1.0), (6, 0.45), (11, 0.2)], 15, "#98DCB0", "#4FAE84", "#44A277", 19),
    ]:
        crest = ridge(doc.width, base, amp, waves, seed)
        # Copas redondas sobre la cresta: el cerro se lee como bosque.
        x = 0.0
        while x < doc.width:
            r = rng.uniform(bump * 0.7, bump * 1.25)
            y = ridge_y(crest, x) + r * 0.25
            doc.path(ellipse_path(x, y, r, r * 0.85), rim, bbox=(x - r, x + r))
            doc.path(ellipse_path(x - r * 0.08, y + r * 0.2, r * 0.92, r * 0.8), top, bbox=(x - r, x + r))
            x += r * rng.uniform(0.9, 1.35)
        hill(doc, [(px, py + 8) for px, py in crest], 600, top, top, bottom, 1.0)
        haze_band(doc, base + 6, base + 66, 0.42, MIST)
    haze_band(doc, 520, 584, 0.8, MIST)
    doc.save(str(OUT / "jungle_far.svg"))


def mid() -> None:
    doc = Doc(2304, 250, top=410, period=2304, comment="Selva: colinas de copas apretadas y palmeras.")
    s = Shapes(doc, np.random.default_rng(6))
    back = ridge(doc.width, 520, 24, [(3, 1.0), (5, 0.45), (8, 0.2)], 23)
    hill(doc, back, 660, "#A8E2A8", "#6FC088", "#62B47C")
    for _ in range(110):
        x = s.rng.uniform(0, doc.width)
        s.round_tree(x, ridge_y(back, x) + s.rng.uniform(2, 36), s.rng.uniform(40, 62), ("#4E9E7C", "#68B88C", "#A4DEAC"),
                     ("#5E8A76", "#7AA48E", "#9CC0A8"))
    front = ridge(doc.width, 572, 24, [(2, 1.0), (4, 0.5), (7, 0.25)], 35)
    hill(doc, front, 660, "#92DC8C", "#55AE6C", "#49A161")
    for _ in range(90):
        x = s.rng.uniform(0, doc.width)
        y = ridge_y(front, x) + s.rng.uniform(4, 50)
        if s.rng.random() < 0.2:
            palm(doc, s.rng, x, y, s.rng.uniform(80, 110), ("#2A8254", "#44A866", "#88D686"), ("#5E6E56", "#7E8E72", "#A4B494"))
        else:
            s.round_tree(x, y, s.rng.uniform(54, 84), ("#2F8A5C", "#48AC6E", "#8CD88C"), ("#4E6E58", "#6A8A72", "#8CAC92"))
    haze_band(doc, 596, 662, 0.7, MIST)
    doc.save(str(OUT / "jungle_mid.svg"))


def near() -> None:
    doc = Doc(2048, 390, top=300, period=2048, comment="Selva: árboles altos, palmeras, lianas, helechos y flores.")
    s = Shapes(doc, np.random.default_rng(10))
    crest = ridge(doc.width, 618, 9, [(3, 1.0), (6, 0.5)], 53)
    hill(doc, crest, 690, "#86DA78", "#3FA35E", "#35964F")
    items = []
    x = 110.0
    while x < doc.width - 60:
        items.append((s.rng.choice(["tree", "palm", "tree", "palm", "tree"]), x))
        x += s.rng.uniform(180, 300)
    for _ in range(22):
        items.append(("fern", s.rng.uniform(0, doc.width)))
    for _ in range(9):
        items.append(("flower", s.rng.uniform(0, doc.width)))
    for kind, x in sorted(items, key=lambda item: s.rng.random()):
        y = ridge_y(crest, x) + s.rng.uniform(8, 18)
        if kind == "tree":
            height = s.rng.uniform(230, 290)
            doc.path(ellipse_path(x + 14, y + 2, 78, 9), "#2B7A46", 0.35, (x - 80, x + 100))
            s.round_tree(x, y, height, CANOPY if s.rng.random() < 0.6 else CANOPY_DEEP, BARK)
            for k in range(int(s.rng.integers(1, 3))):
                liana(doc, s.rng, x + s.rng.uniform(-0.2, 0.22) * height, y - height * 0.62, s.rng.uniform(70, 130))
        elif kind == "palm":
            doc.path(ellipse_path(x + 10, y + 2, 46, 8), "#2B7A46", 0.35, (x - 50, x + 60))
            palm(doc, s.rng, x, y, s.rng.uniform(210, 280))
        elif kind == "fern":
            fern(doc, s.rng, x, y + 6, s.rng.uniform(40, 62))
        else:
            s.bush(x, y + 4, s.rng.uniform(60, 96), s.rng.uniform(36, 52), ("#237A4C", "#3C9C5E", "#7ED082"),
                   ["#FF8A3C", "#FF5C8A", "#FFD23F"][int(s.rng.integers(3))], 12)
    doc.save(str(OUT / "jungle_near.svg"))


def ground() -> None:
    doc = Doc(1536, 150, top=596, period=1536, comment="Selva: sendero de tierra con raíces, hojas caídas y helechos.")
    s = Shapes(doc, np.random.default_rng(14))
    rng = s.rng
    edge = ridge(doc.width, 603, 3, [(6, 1.0), (11, 0.5)], 9, 8)
    fill = doc.linear([(0.0, "#4DB262"), (1.0, "#33934D")])
    doc.path(smooth_open(edge) + f" L{fmt(edge[-1][0])},{fmt(760)} L{fmt(edge[0][0])},{fmt(760)} Z", fill)
    top, bottom = 627.0, 679.0
    doc.path(poly([(0, top), (doc.width, top), (doc.width, bottom), (0, bottom)]), doc.linear([(0.0, "#B98058"), (1.0, "#A56C48")]))
    for _ in range(70):
        x = rng.uniform(0, doc.width)
        y = rng.uniform(top + 5, bottom - 5)
        w = rng.uniform(12, 34)
        doc.path(ellipse_path(x, y, w, rng.uniform(2.2, 4.2)), "#CE9A70" if rng.random() < 0.6 else "#8E5A3C", 0.75, (x - w, x + w))
    for _ in range(26):
        x = rng.uniform(0, doc.width)
        y = rng.uniform(top + 6, bottom - 6)
        color = ["#E8A23A", "#C96A3A", "#7CBF5A", "#F2C14E"][int(rng.integers(4))]
        doc.path(ellipse_path(x, y, rng.uniform(5, 8), 2.6, rng.uniform(-0.6, 0.6)), color, 0.95, (x - 9, x + 9))
    shadow = doc.linear([(0.0, ("#4A2E1C", 0.35)), (1.0, ("#4A2E1C", 0.0))])
    doc.path(poly([(0, top), (doc.width, top), (doc.width, top + 10), (0, top + 10)]), shadow)
    for edge_y, count in [(629, 30), (682, 34)]:
        for _ in range(count):
            x = rng.uniform(0, doc.width)
            if rng.random() < 0.3:
                fern(doc, rng, x, edge_y + rng.uniform(0, 3), rng.uniform(16, 26))
            else:
                s.grass_tuft(x, edge_y + rng.uniform(-1, 3), rng.uniform(12, 20), ("#2F8F55", "#49B06A", "#8CDA86"),
                             lean=rng.uniform(-0.3, 0.3))
    for _ in range(22):
        x = rng.uniform(0, doc.width)
        s.flower(x, rng.choice([625.0, rng.uniform(690, 730)]), rng.uniform(2.8, 3.8),
                 ["#FF8A3C", "#FF5C8A", "#FFFFFF", "#C89BF2"][int(rng.integers(4))])
    for _ in range(7):
        s.stone(rng.uniform(0, doc.width), rng.uniform(700, 735), rng.uniform(16, 26), rng.uniform(9, 14),
                ("#4E8A5E", "#74AE7A", "#B4D8A8"))
    doc.save(str(OUT / "jungle_ground.svg"))


def front() -> None:
    doc = Doc(1792, 170, top=650, period=1792, comment="Selva: primer plano de hojas grandes, helechos y flores.")
    s = Shapes(doc, np.random.default_rng(18))
    rng = s.rng
    edge = ridge(doc.width, 718, 6, [(5, 1.0), (9, 0.4)], 21, 8)
    fill = doc.linear([(0.0, "#2F8A4E"), (1.0, "#1C6038")])
    doc.path(smooth_open(edge) + f" L{fmt(edge[-1][0])},{fmt(830)} L{fmt(edge[0][0])},{fmt(830)} Z", fill)
    x = 60.0
    while x < doc.width - 40:
        kind = rng.random()
        if kind < 0.45:
            for k in range(int(rng.integers(2, 4))):
                big_leaf(doc, rng, x + k * 14, rng.uniform(770, 800), rng.uniform(86, 120), -1.57 + rng.uniform(-0.75, 0.75))
        elif kind < 0.8:
            fern(doc, rng, x, rng.uniform(760, 790), rng.uniform(56, 84), ("#15563A", "#22784A", "#4FAE68"))
        else:
            heliconia(doc, rng, x, rng.uniform(770, 796), rng.uniform(52, 70))
        x += rng.uniform(120, 230)
    for _ in range(9):
        s.flower(rng.uniform(0, doc.width), rng.uniform(730, 756), rng.uniform(4.5, 6.2), ["#FF8A3C", "#FF5C8A", "#FFFFFF"][int(rng.integers(3))])
    doc.save(str(OUT / "jungle_front.svg"))


def preview() -> None:
    compose(OUT, "jungle", SKY, (1010, 330))


if __name__ == "__main__":
    for step in sys.argv[2:] or ["far", "mid", "near", "ground", "front"]:
        globals()[step]()
