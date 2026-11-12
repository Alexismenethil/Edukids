"""Cañón del puente colgante, estilo caricatura limpia.

El puente va de x = 300 a x = 1080 con la cubierta en y = 470; el río corre abajo (y ≈ 780).
Las capas cubren x de -700 a 2080 (la cámara se desliza un poco siguiendo al avatar).

    python3 tools/art/worlds/canyon.py <carpeta de salida> [capa ...]
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

from cartoon import EUCALYPTUS, LEAF, RETAMA, SAGE, Shapes
from svgkit import Builder, Doc, circle_path, ellipse_path, fmt, poly, smooth_closed, smooth_open

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("out/canyon")
OUT.mkdir(parents=True, exist_ok=True)
X0 = -700.0
WIDTH = 2780.0
DECK = 470.0
LEFT_EDGE = 300.0
RIGHT_EDGE = 1080.0


def X(x: float) -> float:
    return x - X0


def wavy(x0: float, x1: float, y: float, amp: float, waves: float, phase: float, step: float = 20.0):
    points = []
    x = x0
    while x <= x1 + 0.1:
        points.append((X(x), y + amp * math.sin(x / waves + phase) + amp * 0.4 * math.sin(x / (waves * 0.37) + phase * 2)))
        x += step
    return points


def cliff(doc: Doc, s: Shapes, outline, strata, lit_face: bool, face_x: float) -> str:
    """Barranco: silueta, franjas de roca recortadas y luz (o sombra) en la cara del cañón."""
    shape = poly(outline)
    cid = doc.uid("c")
    doc.defs.append(f'<clipPath id="{cid}"><path d="{shape}"/></clipPath>')
    tags = [f'<path d="{shape}" fill="{strata[-1][1]}"/>']
    for y_top, color, amp in strata[:-1][::-1]:
        top = wavy(X0 - 40, X0 + WIDTH + 40, y_top, amp, 70.0, y_top * 0.01)
        d = smooth_open(top) + f" L{fmt(top[-1][0])},{fmt(1100)} L{fmt(top[0][0])},{fmt(1100)} Z"
        tags.insert(1, f'<path d="{d}" fill="{color}"/>')
    # Grietas verticales suaves.
    for k in range(26):
        x = s.rng.uniform(X0, X0 + WIDTH)
        y = s.rng.uniform(DECK + 40, 960)
        length = s.rng.uniform(30, 90)
        tags.append(f'<path d="M{fmt(X(x))},{fmt(y)} Q{fmt(X(x) + 6)},{fmt(y + length / 2)} {fmt(X(x) - 2)},{fmt(y + length)}" '
                    f'fill="none" stroke="#8A4E34" stroke-width="3" stroke-linecap="round" opacity="0.35"/>')
    if lit_face:
        light = doc.linear([(0.0, ("#FFE2B0", 0.0)), (1.0, ("#FFE2B0", 0.55))], x1=0, y1=0, x2=1, y2=0)
        tags.append(f'<path d="{poly([(X(face_x - 110), DECK), (X(face_x + 40), DECK), (X(face_x + 70), 1100), (X(face_x - 110), 1100)])}" fill="{light}"/>')
    else:
        shade = doc.linear([(0.0, ("#5B3F7A", 0.45)), (1.0, ("#5B3F7A", 0.0))], x1=0, y1=0, x2=1, y2=0)
        tags.append(f'<path d="{poly([(X(face_x - 40), DECK), (X(face_x + 160), DECK), (X(face_x + 160), 1100), (X(face_x - 70), 1100)])}" fill="{shade}"/>')
    doc.body.append(f'<g clip-path="url(#{cid})">' + "".join(tags) + "</g>")
    return shape


def grass_cap(doc: Doc, x0: float, x1: float, y: float, rng) -> None:
    """Pasto sobre el barranco: borde de luz arriba y flecos redondeados que cuelgan."""
    top = wavy(x0, x1, y - 4, 2.5, 60.0, x0 * 0.01, 16)
    bottom = []
    x = x1
    while x >= x0 - 0.1:
        drip = 10 + 9 * abs(math.sin(x * 0.045 + x0)) + rng.uniform(0, 6)
        bottom.append((X(x), y + drip))
        x -= 14
    doc.path(smooth_open(top) + " L" + " L".join(f"{fmt(px)},{fmt(py)}" for px, py in bottom) + " Z", "#5DAA4B")
    lit = [(px, py) for px, py in top]
    lower = [(px, py + 6) for px, py in top[::-1]]
    doc.path(smooth_open(lit) + " L" + " L".join(f"{fmt(px)},{fmt(py)}" for px, py in lower) + " Z", "#9ED974")


def near() -> None:
    doc = Doc(WIDTH, 820, top=200, comment="Cañón: barrancos cercanos con el pasto, los pilares del puente y plantas.")
    s = Shapes(doc, np.random.default_rng(41))
    rng = s.rng
    strata = [(DECK + 22, "#EDA868", 4), (DECK + 70, "#DD9358", 6), (DECK + 140, "#CC804C", 7),
              (DECK + 230, "#B96F43", 8), (DECK + 330, "#A4603E", 8), (0, "#8E5238", 0)]
    left = [(X(X0), DECK), (X(LEFT_EDGE), DECK), (X(LEFT_EDGE + 16), DECK + 50), (X(LEFT_EDGE + 4), DECK + 130),
            (X(LEFT_EDGE + 30), DECK + 240), (X(LEFT_EDGE + 18), DECK + 360), (X(LEFT_EDGE + 46), 1020), (X(X0), 1020)]
    cliff(doc, s, left, strata, True, LEFT_EDGE)
    right = [(X(RIGHT_EDGE), DECK), (X(X0 + WIDTH), DECK), (X(X0 + WIDTH), 1020), (X(RIGHT_EDGE - 50), 1020),
             (X(RIGHT_EDGE - 22), DECK + 360), (X(RIGHT_EDGE - 36), DECK + 240), (X(RIGHT_EDGE - 6), DECK + 130),
             (X(RIGHT_EDGE - 18), DECK + 50)]
    cliff(doc, s, right, strata, False, RIGHT_EDGE)
    grass_cap(doc, X0, LEFT_EDGE + 6, DECK, rng)
    grass_cap(doc, RIGHT_EDGE - 6, X0 + WIDTH, DECK, rng)
    # Plantas sobre los barrancos (detrás de los pilares).
    s.round_tree(X(-120), DECK + 2, 230, LEAF)
    s.queñua(X(110), DECK + 2, 140, SAGE)
    s.tall_tree(X(1500), DECK + 2, 260, EUCALYPTUS)
    s.round_tree(X(1780), DECK + 2, 210, LEAF)
    for x in [-420, -260, 40, 190, 1240, 1360, 1660, 1920]:
        s.bush(X(x + rng.uniform(-30, 30)), DECK + 4, rng.uniform(60, 90), rng.uniform(36, 48), RETAMA, "#FFD23F", 12)
    for x in [-560, -330, -40, 160, 1180, 1420, 1600, 2000]:
        s.maguey(X(x + rng.uniform(-30, 30)), DECK + 6, rng.uniform(26, 34), stalk=rng.random() < 0.35)
    # Pilares de piedra que sostienen las sogas (como en el Q'eswachaka).
    for x in [LEFT_EDGE - 16, RIGHT_EDGE + 16]:
        for k, (w, h) in enumerate([(54, 30), (46, 26), (40, 24)]):
            s.stone(X(x + rng.uniform(-2, 2)), DECK + 6 - k * 24, w, h, ("#8F8698", "#BCB1B8", "#E8DDD6"))
    for _ in range(40):
        x = rng.uniform(X0, X0 + WIDTH)
        if LEFT_EDGE - 30 < x < RIGHT_EDGE + 30:
            continue
        if rng.random() < 0.4:
            s.ichu(X(x), DECK + 6, rng.uniform(16, 24))
        else:
            s.grass_tuft(X(x), DECK + 6, rng.uniform(12, 20), lean=rng.uniform(-0.3, 0.3))
    for _ in range(20):
        x = rng.uniform(X0, X0 + WIDTH)
        if LEFT_EDGE - 40 < x < RIGHT_EDGE + 40:
            continue
        if rng.random() < 0.3:
            s.cantuta(X(x), DECK + 6, rng.uniform(3.4, 4.4))
        else:
            s.flower(X(x), DECK + 6, rng.uniform(2.8, 3.6), ["#FF6B9A", "#FFD23F", "#FFFFFF", "#B98CF0"][int(rng.integers(4))])
    doc.save(str(OUT / "canyon_near.svg"))


def mid() -> None:
    doc = Doc(WIDTH, 700, top=320, comment="Cañón: paredes del fondo, más pálidas por la distancia, y una cascada.")
    s = Shapes(doc, np.random.default_rng(43))
    strata = [(520, "#F0BE95", 5), (590, "#E6AE86", 6), (680, "#D99E7B", 7), (0, "#C98E72", 0)]
    left = [(X(X0), 500), (X(470), 506), (X(500), 560), (X(486), 650), (X(520), 760), (X(510), 1020), (X(X0), 1020)]
    cliff(doc, s, left, strata, True, 480)
    right = [(X(880), 492), (X(X0 + WIDTH), 486), (X(X0 + WIDTH), 1020), (X(870), 1020), (X(890), 760),
             (X(862), 650), (X(880), 560)]
    cliff(doc, s, right, strata, False, 880)
    for x0, x1, y in [(X0, 480, 504), (874, X0 + WIDTH, 490)]:
        top = wavy(x0, x1, y - 3, 2.0, 50.0, x0 * 0.02, 18)
        lower = [(px, py + 12) for px, py in top[::-1]]
        doc.path(smooth_open(top) + " L" + " L".join(f"{fmt(px)},{fmt(py)}" for px, py in lower) + " Z", "#9CCF86")
    for x in [-600, -380, -150, 60, 300, 1000, 1180, 1420, 1650, 1900]:
        top_y = 500 if x < 500 else 488
        s.round_tree(X(x + s.rng.uniform(-40, 40)), top_y + 4, s.rng.uniform(70, 110), ("#6FA77A", "#86BC87", "#B2D7A6"),
                     ("#A28C7A", "#B9A390", "#D0BCA6"))
    # Cascada en la pared derecha.
    fall_x = X(960)
    doc.path(f"M{fmt(fall_x - 16)},{fmt(492)} Q{fmt(fall_x - 22)},{fmt(640)} {fmt(fall_x - 30)},{fmt(780)} L{fmt(fall_x + 26)},{fmt(780)} "
             f"Q{fmt(fall_x + 18)},{fmt(640)} {fmt(fall_x + 14)},{fmt(492)} Z", "#DFF4FB")
    for k in range(4):
        x = fall_x - 10 + k * 7
        doc.stroke(f"M{fmt(x)},{fmt(500)} Q{fmt(x - 4)},{fmt(640)} {fmt(x - 8)},{fmt(770)}", "#FFFFFF", 2.5, 0.8)
    for k in range(6):
        doc.path(circle_path(fall_x + s.rng.uniform(-36, 36), 776 + s.rng.uniform(-8, 8), s.rng.uniform(10, 18)), "#F4FBFE", 0.9)
    haze = doc.linear([(0.0, ("#FFF0DC", 0.0)), (1.0, ("#FFF0DC", 0.6))])
    doc.path(poly([(0, 640), (WIDTH, 640), (WIDTH, 1020), (0, 1020)]), haze)
    doc.save(str(OUT / "canyon_mid.svg"))


def far() -> None:
    doc = Doc(WIDTH, 420, top=420, comment="Cañón: lomas lejanas que cierran el valle.")
    s = Shapes(doc, np.random.default_rng(47))
    for k, (base, color, rim) in enumerate([(560, "#B9D7AE", "#D9EDC6"), (600, "#A7CFA0", "#C8E6B4")]):
        points = []
        x = X0 - 40
        while x <= X0 + WIDTH + 40:
            points.append((X(x), base - 40 * math.sin(x / 260 + k) - 18 * math.sin(x / 97 + k * 2)))
            x += 24
        doc.path(smooth_open(points) + f" L{fmt(points[-1][0])},{fmt(840)} L{fmt(points[0][0])},{fmt(840)} Z", rim)
        lowered = [(px, py + 6) for px, py in points]
        doc.path(smooth_open(lowered) + f" L{fmt(lowered[-1][0])},{fmt(840)} L{fmt(lowered[0][0])},{fmt(840)} Z", color)
    haze = doc.linear([(0.0, ("#FFF0DC", 0.15)), (1.0, ("#FFF0DC", 0.8))])
    doc.path(poly([(0, 520), (WIDTH, 520), (WIDTH, 840), (0, 840)]), haze)
    doc.save(str(OUT / "canyon_far.svg"))


def props() -> None:
    """Tablas del puente: madera, madera con amarre dorado (corregida) y soga de remiendo."""
    for name, wood, light, dark, tie in [("plank_wood", "#C98A4E", "#E2AD72", "#94603A", None),
                                         ("plank_gold", "#C98A4E", "#E2AD72", "#94603A", "#F2C14E")]:
        doc = Doc(120, 30, top=0, comment="Tramo del puente: tres tablas.")
        for k in range(3):
            x = 4 + k * 39
            doc.path(f"M{fmt(x + 4)},4 L{fmt(x + 32)},4 Q{fmt(x + 36)},4 {fmt(x + 36)},8 L{fmt(x + 36)},22 Q{fmt(x + 36)},26 {fmt(x + 32)},26 "
                     f"L{fmt(x + 4)},26 Q{fmt(x)},26 {fmt(x)},22 L{fmt(x)},8 Q{fmt(x)},4 {fmt(x + 4)},4 Z", dark)
            doc.path(f"M{fmt(x + 4)},4 L{fmt(x + 32)},4 Q{fmt(x + 36)},4 {fmt(x + 36)},8 L{fmt(x + 36)},18 L{fmt(x)},18 L{fmt(x)},8 Q{fmt(x)},4 {fmt(x + 4)},4 Z", wood)
            doc.stroke(f"M{fmt(x + 6)},8 L{fmt(x + 28)},8", light, 2.4)
            doc.path(circle_path(x + 8, 21, 1.6), "#6E4430")
            doc.path(circle_path(x + 28, 21, 1.6), "#6E4430")
            if tie:
                doc.path(poly([(x + 14, 3), (x + 22, 3), (x + 22, 27), (x + 14, 27)]), tie)
                doc.stroke(f"M{fmt(x + 15)},8 L{fmt(x + 21)},14 M{fmt(x + 15)},16 L{fmt(x + 21)},22", "#FFF1B0", 1.6)
        doc.save(str(OUT / f"{name}.svg"))
    doc = Doc(120, 30, top=0, comment="Remiendo de soga tejida (cuando una pregunta del repaso vuelve a fallar).")
    for k, color in enumerate(["#D9B26F", "#E8833A", "#D9B26F"]):
        y = 9 + k * 6
        doc.stroke(f"M2,{fmt(y)} Q60,{fmt(y + 4)} 118,{fmt(y)}", "#8A6A3A", 6.5)
        doc.stroke(f"M2,{fmt(y)} Q60,{fmt(y + 4)} 118,{fmt(y)}", color, 4.0)
    doc.path(circle_path(60, 15, 7), "#C2185B")
    doc.path(circle_path(58, 13, 2.5), "#FF8FB3")
    doc.save(str(OUT / "plank_rope.svg"))


if __name__ == "__main__":
    for step in sys.argv[2:] or ["far", "mid", "near", "props"]:
        globals()[step]()
