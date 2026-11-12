"""Laguna de Coco, estilo caricatura limpia.

El muelle va de x = -260 a x = 330 con la cubierta en y = 600; el agua empieza en y = 572 en la
orilla de enfrente. Las capas cubren x de -700 a 2000.

    python3 tools/art/worlds/lagoon.py <carpeta de salida> [capa ...]
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

from cartoon import EUCALYPTUS, LEAF, RETAMA, SAGE, Shapes
from svgkit import Builder, Doc, circle_path, ellipse_path, fmt, poly, smooth_closed, smooth_open

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("out/lagoon")
OUT.mkdir(parents=True, exist_ok=True)
X0 = -700.0
WIDTH = 2700.0
WATER = 572.0
DECK = 600.0


def X(x: float) -> float:
    return x - X0


def ridge(x0: float, x1: float, base: float, amp: float, k: float, phase: float, step: float = 24.0):
    points = []
    x = x0
    while x <= x1 + 0.1:
        points.append((X(x), base - amp * math.sin(x / k + phase) - amp * 0.4 * math.sin(x / (k * 0.41) + phase * 1.7)))
        x += step
    return points


def hill(doc: Doc, points, bottom: float, rim: str, body: str, body_bottom: str, rim_width: float = 6.0) -> None:
    doc.path(smooth_open(points) + f" L{fmt(points[-1][0])},{fmt(bottom)} L{fmt(points[0][0])},{fmt(bottom)} Z", rim)
    lowered = [(x, y + rim_width) for x, y in points]
    fill = doc.linear([(0.0, body), (1.0, body_bottom)])
    doc.path(smooth_open(lowered) + f" L{fmt(lowered[-1][0])},{fmt(bottom)} L{fmt(lowered[0][0])},{fmt(bottom)} Z", fill)


def chapel(doc: Doc, x: float, base: float, scale: float = 1.0) -> None:
    """Capillita de pueblo: muros blancos, torre con campana y techo de teja."""
    b = Builder()
    w, h = 70 * scale, 44 * scale
    b.path(poly([(x - w / 2, base), (x - w / 2, base - h), (x + w / 2, base - h), (x + w / 2, base)]), "#FFF6EA")
    b.path(poly([(x - w / 2, base), (x - w / 2, base - h), (x - w * 0.2, base - h), (x - w * 0.2, base)]), "#EADFD2")
    b.path(poly([(x - w * 0.58, base - h + 2), (x - w * 0.1, base - h - 22 * scale), (x + w * 0.58, base - h - 8 * scale), (x + w * 0.58, base - h + 2)]), "#D2643E")
    tx = x + w * 0.36
    b.path(poly([(tx - 14 * scale, base - h), (tx - 14 * scale, base - h - 46 * scale), (tx + 14 * scale, base - h - 46 * scale), (tx + 14 * scale, base - h)]), "#FFF6EA")
    b.path(poly([(tx - 17 * scale, base - h - 46 * scale), (tx, base - h - 66 * scale), (tx + 17 * scale, base - h - 46 * scale)]), "#D2643E")
    b.path(ellipse_path(tx, base - h - 32 * scale, 6 * scale, 8 * scale), "#8C5236")
    b.path(circle_path(tx, base - h - 30 * scale, 3.2 * scale), "#F2C14E")
    b.stroke(f"M{fmt(tx)},{fmt(base - h - 66 * scale)} L{fmt(tx)},{fmt(base - h - 78 * scale)} M{fmt(tx - 4 * scale)},{fmt(base - h - 74 * scale)} L{fmt(tx + 4 * scale)},{fmt(base - h - 74 * scale)}", "#8C5236", 2.0 * scale)
    b.path(poly([(x - 8 * scale, base), (x - 8 * scale, base - 22 * scale), (x + 8 * scale, base - 22 * scale), (x + 8 * scale, base)]), "#8C5236")
    b.span(x - w, x + w)
    b.emit(doc)


def reeds(s: Shapes, x: float, base: float, height: float, count: int = 7) -> None:
    """Totoras: tallos largos con su espiga marrón."""
    rng = s.rng
    b = Builder()
    for k in range(count):
        t = (k + 0.5) / count - 0.5
        h = height * rng.uniform(0.75, 1.05)
        tip = (x + t * height * 0.35 + rng.uniform(-4, 4), base - h)
        width = max(2.0, height * 0.035)
        color = "#5FA24A" if k % 2 else "#4C8F42"
        b.path(f"M{fmt(x + t * 10 - width)},{fmt(base)} Q{fmt(x + t * 18)},{fmt(base - h * 0.5)} {fmt(tip[0])},{fmt(tip[1])} "
               f"Q{fmt(x + t * 18 + width)},{fmt(base - h * 0.5)} {fmt(x + t * 10 + width)},{fmt(base)} Z", color)
        if k % 2 == 0:
            b.path(ellipse_path(tip[0] + 1, tip[1] + h * 0.12, width * 1.6, h * 0.09), "#8A5A3A")
            b.path(ellipse_path(tip[0] - width * 0.4, tip[1] + h * 0.1, width * 0.6, h * 0.05), "#B07A54")
    # Hojas anchas abajo.
    for side in (-1, 1):
        b.path(f"M{fmt(x - 4)},{fmt(base)} Q{fmt(x + side * height * 0.2)},{fmt(base - height * 0.3)} {fmt(x + side * height * 0.42)},{fmt(base - height * 0.36)} "
               f"Q{fmt(x + side * height * 0.18)},{fmt(base - height * 0.16)} {fmt(x + 4)},{fmt(base)} Z", "#6DB253")
    b.span(x - height * 0.5, x + height * 0.5)
    b.emit(s.doc)


def far() -> None:
    doc = Doc(WIDTH, 300, top=360, comment="Laguna: lomas del fondo con un pueblito y su capilla.")
    s = Shapes(doc, np.random.default_rng(61))
    back = ridge(X0 - 40, X0 + WIDTH + 40, 470, 34, 220, 0.5)
    hill(doc, back, 660, "#D3EEB9", "#AAD99C", "#9DD094")
    front = ridge(X0 - 40, X0 + WIDTH + 40, 520, 26, 170, 2.1)
    hill(doc, front, 660, "#C1E8A0", "#8DCB7B", "#7FBF70")
    for x in [-520, -300, 120, 420, 980, 1260, 1560, 1820]:
        for k in range(int(s.rng.integers(2, 4))):
            s.round_tree(X(x + k * 16), 528 + s.rng.uniform(-4, 6), s.rng.uniform(34, 46), ("#5E9E6C", "#78B779", "#A8D598"),
                         ("#8A7A68", "#A69380", "#C2B09A"))
    chapel(doc, X(760), 520, 0.9)
    for x in [690, 830, 880, 640]:
        s.house(X(x), 524 + s.rng.uniform(-3, 3), s.rng.uniform(18, 24))
    haze = doc.linear([(0.0, ("#FFF0DC", 0.2)), (1.0, ("#FFF0DC", 0.75))])
    doc.path(poly([(0, 470), (WIDTH, 470), (WIDTH, 660), (0, 660)]), haze)
    doc.save(str(OUT / "lagoon_far.svg"))


def mid() -> None:
    doc = Doc(WIDTH, 300, top=340, comment="Laguna: la orilla de enfrente con totoras y molles.")
    s = Shapes(doc, np.random.default_rng(67))
    shore = ridge(X0 - 40, X0 + WIDTH + 40, 562, 6, 90, 0.3, 18)
    shore_d = smooth_open(shore) + f" L{fmt(shore[-1][0])},{fmt(WATER + 6)} L{fmt(shore[0][0])},{fmt(WATER + 6)} Z"
    doc.path(shore_d, "#A8E07C")
    lowered = [(x, y + 5) for x, y in shore]
    doc.path(smooth_open(lowered) + f" L{fmt(lowered[-1][0])},{fmt(WATER + 6)} L{fmt(lowered[0][0])},{fmt(WATER + 6)} Z", "#76C25E")
    for x in [-560, -180, 300, 760, 1240, 1700]:
        s.round_tree(X(x + s.rng.uniform(-60, 60)), 566, s.rng.uniform(120, 160), ("#4B9A5E", "#64B266", "#97D27A"))
    for x in [-400, 40, 520, 1000, 1460, 1880]:
        s.tall_tree(X(x + s.rng.uniform(-40, 40)), 566, s.rng.uniform(150, 190), ("#4F8F78", "#67AB8D", "#9BCFAE"))
    x = X0
    while x < X0 + WIDTH:
        clump = int(s.rng.integers(2, 5))
        for k in range(clump):
            reeds(s, X(x + k * s.rng.uniform(14, 22)), WATER + 4, s.rng.uniform(38, 64), 5)
        x += s.rng.uniform(110, 260)
    doc.save(str(OUT / "lagoon_mid.svg"))


def near() -> None:
    doc = Doc(WIDTH, 560, top=360, comment="Laguna: orilla cercana con el muelle, la canasta, flores y totoras.")
    s = Shapes(doc, np.random.default_rng(71))
    rng = s.rng
    # Orilla izquierda (donde espera el avatar) y la derecha (donde termina el paseo).
    left = [(X(X0), 604), (X(-160), 598), (X(-40), 606), (X(40), 640), (X(20), 720), (X(80), 900), (X(X0), 900)]
    doc.path(smooth_closed(left, 0.6), "#C98E58")
    left_grass = [(X(X0), 596), (X(-150), 590), (X(-30), 598), (X(30), 618), (X(-10), 626), (X(X0), 626)]
    doc.path(smooth_closed(left_grass, 0.6), "#6DBB57")
    doc.path(smooth_open([(X(X0), 594), (X(-150), 588), (X(-30), 596)]) + f" L{fmt(X(-30))},{fmt(601)} L{fmt(X(X0))},{fmt(601)} Z", "#A2DD78")
    right = [(X(1180), 640), (X(1230), 600), (X(1400), 590), (X(X0 + WIDTH), 586), (X(X0 + WIDTH), 900), (X(1170), 900)]
    doc.path(smooth_closed(right, 0.6), "#C98E58")
    right_grass = [(X(1190), 612), (X(1240), 590), (X(1400), 582), (X(X0 + WIDTH), 580), (X(X0 + WIDTH), 604), (X(1200), 618)]
    doc.path(smooth_closed(right_grass, 0.6), "#6DBB57")
    # Muelle de madera.
    for x in [-230, -120, -10, 100, 210, 316]:
        doc.path(poly([(X(x - 7), DECK - 6), (X(x + 7), DECK - 6), (X(x + 7), 760), (X(x - 7), 760)]), "#7A4E2E")
        doc.path(poly([(X(x + 1), DECK - 6), (X(x + 6), DECK - 6), (X(x + 6), 760), (X(x + 1), 760)]), "#9A6A42")
    doc.path(poly([(X(-262), DECK - 10), (X(334), DECK - 10), (X(334), DECK + 8), (X(-262), DECK + 8)]), "#8C5A36")
    for k in range(15):
        x0 = -260 + k * 39.6
        doc.path(poly([(X(x0 + 1.5), DECK - 12), (X(x0 + 38), DECK - 12), (X(x0 + 38), DECK + 2), (X(x0 + 1.5), DECK + 2)]), "#C98A4E")
        doc.path(poly([(X(x0 + 1.5), DECK - 12), (X(x0 + 38), DECK - 12), (X(x0 + 38), DECK - 8), (X(x0 + 1.5), DECK - 8)]), "#E2AD72")
    # Plantas en las orillas.
    s.round_tree(X(-460), 596, 250, LEAF)
    s.queñua(X(-330), 598, 150, SAGE)
    s.round_tree(X(1560), 586, 240, LEAF)
    s.tall_tree(X(1800), 586, 280, EUCALYPTUS)
    for x in [-600, -380, -200, 1300, 1460, 1700]:
        s.bush(X(x + rng.uniform(-20, 20)), 598, rng.uniform(56, 84), rng.uniform(34, 44), RETAMA, "#FFD23F", 12)
    for x in [60, 100, 140, 1140, 1180, 1220, 1260]:
        reeds(s, X(x + rng.uniform(-8, 8)), 640 + rng.uniform(-6, 6), rng.uniform(90, 130), 7)
    for _ in range(26):
        x = rng.uniform(X0, -60) if rng.random() < 0.5 else rng.uniform(1260, X0 + WIDTH)
        if rng.random() < 0.3:
            s.cantuta(X(x), 600, rng.uniform(3.6, 4.6))
        else:
            s.flower(X(x), 600, rng.uniform(2.8, 3.6), ["#FF6B9A", "#FFD23F", "#FFFFFF", "#B98CF0"][int(rng.integers(4))])
    for _ in range(18):
        x = rng.uniform(X0, -60) if rng.random() < 0.5 else rng.uniform(1260, X0 + WIDTH)
        s.grass_tuft(X(x), 600, rng.uniform(12, 20), lean=rng.uniform(-0.3, 0.3))
    doc.save(str(OUT / "lagoon_near.svg"))


def props() -> None:
    """Nenúfar con flor y la canasta tejida de frutas."""
    doc = Doc(140, 70, top=0, comment="Nenúfar con su flor.")
    doc.path(ellipse_path(70, 44, 60, 18), "#3E9A5C")
    doc.path(ellipse_path(66, 40, 54, 14), "#5DBB6E")
    doc.path(poly([(70, 44), (130, 34), (126, 46)]), "#3E9A5C")
    for k in range(6):
        a = math.pi * (0.1 + 0.8 * k / 5)
        doc.path(ellipse_path(52 + math.cos(a) * 9, 30 - math.sin(a) * 8, 9, 5, -a + math.pi / 2), "#FF9EC4")
    doc.path(ellipse_path(52, 30, 8, 6), "#FFD23F")
    doc.save(str(OUT / "prop_lily.svg"))
    doc = Doc(110, 80, top=0, comment="Canasta tejida para las frutas.")
    doc.path("M8,30 L102,30 Q98,74 80,76 L30,76 Q12,74 8,30 Z", "#C2185B")
    for y, color in [(38, "#F28C28"), (50, "#FFD23F"), (62, "#1FA2A6")]:
        doc.path(f"M10,{y} L100,{y} L99,{y + 5} L11,{y + 5} Z", color)
    for k in range(7):
        x = 18 + k * 12.5
        doc.path(poly([(x - 4, 44), (x, 40), (x + 4, 44), (x, 48)]), "#FFF4DC")
    doc.path("M4,26 Q55,18 106,26 L106,33 Q55,25 4,33 Z", "#8A1E44")
    doc.save(str(OUT / "prop_basket.svg"))


if __name__ == "__main__":
    for step in sys.argv[2:] or ["far", "mid", "near", "props"]:
        globals()[step]()
