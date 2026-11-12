"""Costa: del mar al desierto (capítulo 3), estilo caricatura limpia.

Capas SVG periódicas con las mismas medidas que el valle: el mar con islotes guaneros y botes a lo
lejos, olas con caballitos de totora, dunas con huarangos y pasto de playa, una franja de arena
firme con conchas y estrellas de mar, y un primer plano de dunas. Arena y ocre, turquesa y azul
profundo del mar, blanco de la espuma.

    python3 tools/art/worlds/coast.py <carpeta de salida> [capa ...]
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

from cartoon import Shapes
from svgkit import Doc, ellipse_path, fmt, poly, smooth_open
from terrain import band, haze_band, hill, islet, palm, preview as compose, ridge, ridge_y, shell, starfish, totora_boat

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("out/coast")
OUT.mkdir(parents=True, exist_ok=True)

SKY = [(0.0, "#3FA9E8"), (0.45, "#8FD4F2"), (0.78, "#FFF1D8"), (1.0, "#FFE0B5")]
HUARANGO = ("#5E8A4E", "#7FA860", "#B4D088")
DUNE_GRASS = ("#B89A3E", "#D9BC58", "#F2DC8C")


def _waves(doc: Doc, rng, y0: float, y1: float, count: int, color: str = "#FFFFFF") -> None:
    """Crestas de espuma: arquitos blancos, más grandes hacia la orilla."""
    for _ in range(count):
        y = rng.uniform(y0, y1)
        t = (y - y0) / max(1.0, y1 - y0)
        w = rng.uniform(16, 30) * (0.6 + t)
        x = rng.uniform(0, doc.width)
        d = f"M{fmt(x - w)},{fmt(y)} Q{fmt(x - w * 0.5)},{fmt(y - w * 0.22)} {fmt(x)},{fmt(y)} Q{fmt(x + w * 0.5)},{fmt(y - w * 0.22)} {fmt(x + w)},{fmt(y)}"
        doc.stroke(d, color, 1.6 + t * 1.8, 0.55 + 0.35 * t, (x - w, x + w))


def far() -> None:
    doc = Doc(2560, 330, top=250, period=2560, comment="Costa: el mar hasta el horizonte, con islotes guaneros y botes.")
    rng = np.random.default_rng(3)
    band(doc, 500, 582, "#2A86C2", "#3BA6CE")
    doc.path(poly([(0, 498), (doc.width, 498), (doc.width, 503), (0, 503)]), "#EAF8FB", 0.8)
    x = 140.0
    while x < doc.width - 100:
        w = rng.uniform(120, 260)
        islet(doc, rng, x, rng.uniform(512, 526), w, w * rng.uniform(0.28, 0.42))
        if rng.random() < 0.6:
            islet(doc, rng, x + w * 0.7, rng.uniform(520, 534), w * 0.35, w * 0.16)
        x += rng.uniform(420, 720)
    for _ in range(7):
        totora_boat(doc, rng.uniform(0, doc.width), rng.uniform(530, 560), rng.uniform(20, 30),
                    ["#FFFFFF", "#F28C28", "#C2185B"][int(rng.integers(3))])
    _waves(doc, rng, 512, 578, 150)
    haze_band(doc, 496, 540, 0.35, "#FFF6E8")
    doc.save(str(OUT / "coast_far.svg"))


def mid() -> None:
    doc = Doc(2304, 250, top=410, period=2304, comment="Costa: olas turquesa con caballitos de totora y la espuma de la orilla.")
    rng = np.random.default_rng(5)
    band(doc, 552, 662, "#3FB2D0", "#7ADCDC")
    crest = ridge(doc.width, 552, 2.5, [(9, 1.0), (17, 0.5)], 12, 8)
    doc.stroke(smooth_open(crest), "#EAF8FB", 3.0, 0.9, (0, doc.width))
    _waves(doc, rng, 562, 640, 170)
    for _ in range(6):
        x = rng.uniform(0, doc.width)
        totora_boat(doc, x, rng.uniform(574, 606), rng.uniform(46, 64), None if rng.random() < 0.5 else "#FFFFFF")
    for y, width, alpha in [(628, 5.0, 0.8), (646, 7.0, 0.95)]:
        foam = ridge(doc.width, y, 4.0, [(7, 1.0), (13, 0.6), (23, 0.3)], int(y), 8)
        doc.stroke(smooth_open(foam), "#FFFFFF", width, alpha, (0, doc.width))
    doc.save(str(OUT / "coast_mid.svg"))


def near() -> None:
    doc = Doc(2048, 390, top=300, period=2048, comment="Costa: dunas con huarangos, palmeras, pasto de playa y botes en la arena.")
    s = Shapes(doc, np.random.default_rng(8))
    back = ridge(doc.width, 606, 9, [(2, 1.0), (5, 0.5)], 41)
    hill(doc, back, 690, "#FFFFFF", "#BDEFE8", "#F3E3B4", 7.0)
    crest = ridge(doc.width, 620, 10, [(3, 1.0), (6, 0.5)], 55)
    hill(doc, crest, 690, "#FFF1C4", "#F4DC9E", "#EACB82")
    items = []
    x = 140.0
    while x < doc.width - 80:
        items.append((s.rng.choice(["huarango", "palm", "huarango", "boat", "post"]), x))
        x += s.rng.uniform(260, 430)
    for _ in range(16):
        items.append(("grass", s.rng.uniform(0, doc.width)))
    for _ in range(7):
        items.append(("rock", s.rng.uniform(0, doc.width)))
    for kind, x in sorted(items, key=lambda item: s.rng.random()):
        y = ridge_y(crest, x) + s.rng.uniform(8, 18)
        if kind == "huarango":
            doc.path(ellipse_path(x + 16, y + 2, 74, 8), "#C9A864", 0.45, (x - 60, x + 92))
            s.queñua(x, y, s.rng.uniform(150, 190), HUARANGO)
        elif kind == "palm":
            doc.path(ellipse_path(x + 12, y + 2, 44, 7), "#C9A864", 0.45, (x - 40, x + 60))
            palm(doc, s.rng, x, y, s.rng.uniform(190, 240), ("#3E8A52", "#5CAE68", "#A2DC8C"), ("#8A6A48", "#B48E64", "#DCBC92"))
        elif kind == "boat":
            # Caballito de totora parado a secar, apoyado en su poste.
            doc.stroke(f"M{fmt(x + 20)},{fmt(y + 4)} L{fmt(x + 26)},{fmt(y - 96)}", "#7A5A3C", 6.0, 1.0, (x, x + 40))
            doc.path(f"M{fmt(x - 14)},{fmt(y + 4)} Q{fmt(x - 22)},{fmt(y - 70)} {fmt(x + 22)},{fmt(y - 128)} "
                     f"Q{fmt(x + 14)},{fmt(y - 60)} {fmt(x + 12)},{fmt(y + 4)} Z", "#C99A4E", bbox=(x - 24, x + 30))
            doc.stroke(f"M{fmt(x - 4)},{fmt(y - 6)} Q{fmt(x - 6)},{fmt(y - 64)} {fmt(x + 16)},{fmt(y - 110)}", "#EBC982", 4.0, 0.95, (x - 24, x + 30))
            for k in range(4):
                yy = y - 16 - k * 24
                doc.stroke(f"M{fmt(x - 13 + k * 3)},{fmt(yy)} L{fmt(x + 12 + k * 2)},{fmt(yy - 5)}", "#9C7436", 2.4, 0.9, (x - 24, x + 30))
        elif kind == "post":
            for k in range(3):
                px = x + k * 44
                doc.stroke(f"M{fmt(px)},{fmt(y + 4)} L{fmt(px)},{fmt(y - 46 - (k % 2) * 10)}", "#6E4E34", 9.0, 1.0, (px - 6, px + 6))
                doc.stroke(f"M{fmt(px - 2)},{fmt(y)} L{fmt(px - 2)},{fmt(y - 42 - (k % 2) * 10)}", "#9A7450", 3.0, 0.9, (px - 6, px + 6))
            doc.stroke(f"M{fmt(x)},{fmt(y - 36)} Q{fmt(x + 22)},{fmt(y - 22)} {fmt(x + 44)},{fmt(y - 46)} Q{fmt(x + 66)},{fmt(y - 24)} {fmt(x + 88)},{fmt(y - 36)}",
                       "#E8D8B0", 3.0, 1.0, (x - 6, x + 94))
        elif kind == "grass":
            s.ichu(x, y + 6, s.rng.uniform(22, 38), DUNE_GRASS)
        else:
            s.stone(x, y + 8, s.rng.uniform(30, 56), s.rng.uniform(16, 28), ("#8A7E7A", "#B4A69E", "#E2D6CC"))
    doc.save(str(OUT / "coast_near.svg"))


def ground() -> None:
    doc = Doc(1536, 150, top=596, period=1536, comment="Costa: arena firme con conchas, estrellas de mar y huellas.")
    s = Shapes(doc, np.random.default_rng(13))
    rng = s.rng
    edge = ridge(doc.width, 603, 3, [(6, 1.0), (11, 0.5)], 7, 8)
    fill = doc.linear([(0.0, "#F6E2AC"), (1.0, "#E9CB86")])
    doc.path(smooth_open(edge) + f" L{fmt(edge[-1][0])},{fmt(760)} L{fmt(edge[0][0])},{fmt(760)} Z", fill)
    top, bottom = 627.0, 679.0
    doc.path(poly([(0, top), (doc.width, top), (doc.width, bottom), (0, bottom)]), doc.linear([(0.0, "#E4C180"), (1.0, "#D8B06A")]))
    for _ in range(80):
        x = rng.uniform(0, doc.width)
        y = rng.uniform(top + 5, bottom - 5)
        w = rng.uniform(14, 40)
        doc.path(ellipse_path(x, y, w, rng.uniform(2.0, 3.6)), "#F2D89A" if rng.random() < 0.65 else "#C99E58", 0.7, (x - w, x + w))
    shadow = doc.linear([(0.0, ("#9C7436", 0.3)), (1.0, ("#9C7436", 0.0))])
    doc.path(poly([(0, top), (doc.width, top), (doc.width, top + 10), (0, top + 10)]), shadow)
    for _ in range(18):
        x = rng.uniform(0, doc.width)
        y = rng.uniform(top + 8, bottom - 8)
        if rng.random() < 0.3:
            starfish(doc, x, y, rng.uniform(7, 10), ["#F28C28", "#E8588C", "#F2C14E"][int(rng.integers(3))], rng.uniform(0, 1.2))
        else:
            shell(doc, x, y + 3, rng.uniform(4.5, 7), ["#F6C6C0", "#FFFFFF", "#F2D9B0"][int(rng.integers(3))])
    for edge_y, count in [(629, 22), (682, 26)]:
        for _ in range(count):
            s.ichu(rng.uniform(0, doc.width), edge_y + rng.uniform(-1, 3), rng.uniform(12, 20), DUNE_GRASS)
    for _ in range(10):
        s.stone(rng.uniform(0, doc.width), rng.uniform(700, 735), rng.uniform(14, 24), rng.uniform(8, 13),
                ("#B89A6E", "#D8BE94", "#F4E4C4"))
    for _ in range(8):
        starfish(doc, rng.uniform(0, doc.width), rng.uniform(696, 734), rng.uniform(8, 12),
                 ["#F28C28", "#E8588C"][int(rng.integers(2))], rng.uniform(0, 1.2))
    doc.save(str(OUT / "coast_ground.svg"))


def front() -> None:
    doc = Doc(1792, 170, top=650, period=1792, comment="Costa: primer plano de dunas con pasto de playa, rocas y conchas.")
    s = Shapes(doc, np.random.default_rng(17))
    rng = s.rng
    edge = ridge(doc.width, 718, 7, [(4, 1.0), (9, 0.4)], 19, 8)
    fill = doc.linear([(0.0, "#DDB872"), (1.0, "#B88A4A")])
    doc.path(smooth_open(edge) + f" L{fmt(edge[-1][0])},{fmt(830)} L{fmt(edge[0][0])},{fmt(830)} Z", fill)
    doc.stroke(smooth_open([(px, py + 2) for px, py in edge]), "#F2D89A", 4.0, 0.9, (0, doc.width))
    clusters = rng.uniform(0, doc.width, 7)
    for _ in range(30):
        x = (clusters[int(rng.integers(len(clusters)))] + rng.normal(0, 55)) % doc.width
        s.ichu(x, rng.uniform(730, 768), rng.uniform(40, 70), ("#8E7A2E", "#B89A3E", "#E2C866"))
    for _ in range(6):
        s.stone(rng.uniform(0, doc.width), rng.uniform(752, 778), rng.uniform(48, 80), rng.uniform(24, 38),
                ("#7E706A", "#A8988E", "#DCCEC2"))
    for _ in range(7):
        starfish(doc, rng.uniform(0, doc.width), rng.uniform(738, 764), rng.uniform(13, 18),
                 ["#F28C28", "#E8588C", "#F2C14E"][int(rng.integers(3))], rng.uniform(0, 1.2))
    for _ in range(9):
        shell(doc, rng.uniform(0, doc.width), rng.uniform(742, 768), rng.uniform(8, 12), ["#F6C6C0", "#FFFFFF"][int(rng.integers(2))])
    doc.save(str(OUT / "coast_front.svg"))


def preview() -> None:
    compose(OUT, "coast", SKY, (1010, 300))


if __name__ == "__main__":
    for step in sys.argv[2:] or ["far", "mid", "near", "ground", "front"]:
        globals()[step]()
