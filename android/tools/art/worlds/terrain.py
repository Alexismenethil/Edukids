"""Piezas comunes de los mundos que corren sin fin (valle, selva y costa): crestas periódicas,
lomas con borde de luz, bandas de bruma y los elementos de la Selva y de la Costa (palmeras,
hojas grandes, helechos, lianas, islotes, caballitos de totora, conchas y estrellas de mar).

Mismo estilo que cartoon.py: formas nítidas, colores planos, una sombra y una luz por objeto.
"""

from __future__ import annotations

import math
import subprocess
from pathlib import Path

import numpy as np

from svgkit import Builder, Doc, ellipse_path, fmt, poly, smooth_closed, smooth_open


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


def ridge_y(points, x: float) -> float:
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        if x0 <= x <= x1:
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return points[0][1]


def hill(doc: Doc, points, bottom: float, rim: str, top_color: str, bottom_color: str, rim_width: float = 6.0) -> str:
    """Loma con borde de luz: la cresta en color claro y el cuerpo con degradado."""
    shape = smooth_open(points) + f" L{fmt(points[-1][0])},{fmt(bottom)} L{fmt(points[0][0])},{fmt(bottom)} Z"
    doc.path(shape, rim)
    lowered = [(x, y + rim_width) for x, y in points]
    body = smooth_open(lowered) + f" L{fmt(lowered[-1][0])},{fmt(bottom)} L{fmt(lowered[0][0])},{fmt(bottom)} Z"
    doc.path(body, doc.linear([(0.0, top_color), (1.0, bottom_color)]))
    return body


def haze_band(doc: Doc, y0: float, y1: float, strength: float, color: str) -> None:
    fill = doc.linear([(0.0, (color, 0.0)), (1.0, (color, strength))])
    doc.path(poly([(0, y0), (doc.width, y0), (doc.width, y1), (0, y1)]), fill)


def band(doc: Doc, y0: float, y1: float, top: str, bottom: str) -> None:
    doc.path(poly([(0, y0), (doc.width, y0), (doc.width, y1), (0, y1)]), doc.linear([(0.0, top), (1.0, bottom)]))


def _leaf_shape(x: float, y: float, length: float, width: float, angle: float, droop: float = 0.0) -> list:
    """Hoja en punta: de (x, y) hacia `angle`, con el extremo caído `droop`."""
    points = []
    steps = 9
    for side in (1, -1):
        rng_i = range(steps + 1) if side == 1 else range(steps - 1, 0, -1)
        for i in rng_i:
            t = i / steps
            along = length * t
            half = width * math.sin(math.pi * t) ** 0.8 * 0.5
            sag = droop * t * t * length
            px = x + math.cos(angle) * along - math.sin(angle) * half * side
            py = y + math.sin(angle) * along + math.cos(angle) * half * side + sag
            points.append((px, py))
    return points


def leaf(b: Builder, x: float, y: float, length: float, width: float, angle: float, colors, droop: float = 0.0,
         rib: bool = True) -> None:
    shadow, base, light = colors
    outline = _leaf_shape(x, y, length, width, angle, droop)
    b.path(smooth_closed(outline, 0.6), shadow)
    inner = _leaf_shape(x, y - width * 0.05, length * 0.94, width * 0.74, angle, droop)
    b.path(smooth_closed(inner, 0.6), base)
    if rib:
        tip = (x + math.cos(angle) * length * 0.9, y + math.sin(angle) * length * 0.9 + droop * 0.81 * length)
        mid = (x + math.cos(angle) * length * 0.5, y + math.sin(angle) * length * 0.5 + droop * 0.25 * length)
        b.stroke(smooth_open([(x, y), mid, tip]), light, max(1.2, width * 0.07), 0.9)
    xs = [p[0] for p in outline]
    b.span(min(xs), max(xs))


def palm(doc: Doc, rng, x: float, base: float, height: float,
         colors=("#2F7D4F", "#49A862", "#8AD27C"), bark=("#7A5A3C", "#A9825A", "#D1AE82")) -> None:
    """Palmera: tronco curvo y un penacho de hojas caídas."""
    b = Builder()
    lean = rng.uniform(-0.18, 0.18) * height
    top = (x + lean, base - height)
    width = max(4.0, height * 0.05)
    spine = [(x, base), (x + lean * 0.35, base - height * 0.5), top]
    b.stroke(smooth_open(spine), bark[0], width * 2.0)
    b.stroke(smooth_open(spine), bark[1], width * 1.3)
    b.stroke(smooth_open([(p[0] + width * 0.25, p[1]) for p in spine]), bark[2], width * 0.35, 0.9)
    fronds = 7
    for i in range(fronds):
        angle = math.pi * (1.08 + 0.84 * i / (fronds - 1)) + rng.uniform(-0.08, 0.08)
        length = height * rng.uniform(0.34, 0.44)
        leaf(b, top[0], top[1], length, length * 0.3, angle, colors, droop=0.5)
    for dx in (-width * 0.9, width * 0.6):
        b.path(ellipse_path(top[0] + dx, top[1] + width * 1.2, width * 0.8, width * 0.8), "#8A5A32")
    b.span(x - height * 0.45, x + height * 0.45)
    b.emit(doc)


def fern(doc: Doc, rng, x: float, base: float, size: float, colors=("#1F6B45", "#2F8F55", "#6CC47A")) -> None:
    """Helecho: abanico de hojas largas que se arquean."""
    b = Builder()
    count = int(rng.integers(5, 8))
    for i in range(count):
        angle = math.pi * (1.12 + 0.76 * i / (count - 1))
        length = size * rng.uniform(0.75, 1.05)
        leaf(b, x, base, length, length * 0.2, angle, colors, droop=0.45)
    b.emit(doc)


def big_leaf(doc: Doc, rng, x: float, base: float, length: float, angle: float,
             colors=("#17603F", "#22804E", "#57B26C")) -> None:
    """Hoja grande de platanillo: sale de la tierra y se abre ancha."""
    b = Builder()
    stem = (x + math.cos(angle) * length * 0.25, base + math.sin(angle) * length * 0.25)
    b.stroke(smooth_open([(x, base), stem]), colors[0], max(3.0, length * 0.035))
    leaf(b, stem[0], stem[1], length * 0.8, length * 0.36, angle, colors, droop=0.12)
    b.emit(doc)


def liana(doc: Doc, rng, x: float, top: float, length: float, colors=("#2B7448", "#4FA862", "#8ED27E")) -> None:
    """Liana que cuelga con hojitas a los lados."""
    b = Builder()
    sway = rng.uniform(-0.12, 0.12) * length
    points = [(x, top), (x + sway * 0.6, top + length * 0.5), (x + sway, top + length)]
    b.stroke(smooth_open(points), colors[0], 3.2)
    for i in range(int(length // 26)):
        t = (i + 0.6) / (length // 26 + 0.2)
        px = x + sway * t * (0.6 + 0.4 * t)
        py = top + length * t
        side = 1 if i % 2 == 0 else -1
        leaf(b, px, py, 15.0, 8.0, math.pi * 0.5 - side * 1.1, colors, rib=False)
    b.span(x - 24, x + 24)
    b.emit(doc)


def heliconia(doc: Doc, rng, x: float, base: float, size: float) -> None:
    """Flor de la selva: tallo que se arquea con brácteas rojas y amarillas a los lados."""
    b = Builder()
    top = (x + size * 0.18, base - size)
    spine = [(x, base), (x + size * 0.02, base - size * 0.55), top]
    b.stroke(smooth_open(spine), "#2F8F55", max(1.8, size * 0.07))
    for i in range(5):
        t = 0.42 + 0.13 * i
        px = x + size * 0.02 + (top[0] - x - size * 0.02) * max(0.0, (t - 0.55) / 0.45)
        py = base - size * t
        side = 1 if i % 2 == 0 else -1
        leaf(b, px, py, size * 0.3, size * 0.14, -0.35 if side > 0 else math.pi + 0.35, ("#C9302A", "#EE4B32", "#FFD23F"), rib=True)
    b.span(x - size * 0.4, x + size * 0.5)
    b.emit(doc)


def islet(doc: Doc, rng, x: float, base: float, w: float, h: float) -> None:
    """Islote guanero: roca con la cima blanca y la espuma en la orilla."""
    b = Builder()
    points = [(x - w / 2, base)]
    for i in range(1, 7):
        t = i / 7
        points.append((x - w / 2 + w * t, base - h * (math.sin(math.pi * t) ** 0.7) * rng.uniform(0.75, 1.0)))
    points.append((x + w / 2, base))
    b.path(smooth_closed(points, 0.5), "#8A7A78")
    lit = [(px - w * 0.03, py + h * 0.06) for px, py in points[1:-1]]
    b.path(smooth_closed([(x - w * 0.42, base)] + lit + [(x + w * 0.3, base)], 0.5), "#B3A19A")
    cap = [(px, py + h * 0.04) for px, py in points[2:-2]]
    cap += [(px, py + h * 0.3) for px, py in reversed(points[2:-2])]
    b.path(smooth_closed(cap, 0.5), "#F6F1E6")
    b.path(ellipse_path(x, base, w * 0.58, max(2.0, h * 0.07)), "#FFFFFF", 0.85)
    b.span(x - w * 0.6, x + w * 0.6)
    b.emit(doc)


def totora_boat(doc: Doc, x: float, y: float, w: float, sail: str | None = None) -> None:
    """Caballito de totora (o bote con vela si se indica el color)."""
    b = Builder()
    h = w * 0.2
    hull = (f"M{fmt(x - w / 2)},{fmt(y)} Q{fmt(x - w * 0.1)},{fmt(y + h * 1.2)} {fmt(x + w / 2)},{fmt(y - h * 1.5)} "
            f"Q{fmt(x + w * 0.2)},{fmt(y + h * 0.1)} {fmt(x - w / 2)},{fmt(y)} Z")
    b.path(hull, "#C99A4E")
    b.stroke(f"M{fmt(x - w * 0.3)},{fmt(y + h * 0.25)} Q{fmt(x)},{fmt(y + h * 0.5)} {fmt(x + w * 0.36)},{fmt(y - h * 0.7)}",
             "#EBC982", max(1.2, h * 0.22))
    if sail:
        b.stroke(f"M{fmt(x)},{fmt(y)} L{fmt(x)},{fmt(y - w * 0.62)}", "#7A5A3C", max(1.4, w * 0.03))
        b.path(poly([(x + w * 0.03, y - w * 0.6), (x + w * 0.36, y - w * 0.12), (x + w * 0.03, y - w * 0.1)]), sail)
    b.path(ellipse_path(x, y + h * 0.5, w * 0.5, max(1.5, h * 0.3)), "#FFFFFF", 0.7)
    b.span(x - w * 0.6, x + w * 0.6)
    b.emit(doc)


def starfish(doc: Doc, x: float, y: float, size: float, color: str = "#F28C28", turn: float = 0.0) -> None:
    points = []
    for i in range(10):
        r = size if i % 2 == 0 else size * 0.45
        points.append((x + math.cos(turn + math.pi * i / 5 - math.pi / 2) * r, y + math.sin(turn + math.pi * i / 5 - math.pi / 2) * r * 0.62))
    doc.path(smooth_closed(points, 0.35), color, bbox=(x - size, x + size))
    doc.path(ellipse_path(x, y, size * 0.22, size * 0.14), "#FFD9A0", 0.9, (x - size, x + size))


def shell(doc: Doc, x: float, y: float, size: float, color: str = "#F6C6C0") -> None:
    b = Builder()
    points = [(x - size, y)]
    for i in range(1, 8):
        angle = math.pi * (1.0 + i / 8)
        points.append((x + math.cos(angle) * size, y + math.sin(angle) * size * 0.8))
    points.append((x + size, y))
    b.path(smooth_closed(points, 0.4), color)
    for i in range(1, 4):
        angle = math.pi * (1.0 + i / 4)
        b.stroke(f"M{fmt(x)},{fmt(y)} L{fmt(x + math.cos(angle) * size * 0.8)},{fmt(y + math.sin(angle) * size * 0.62)}",
                 "#E09A92", max(0.8, size * 0.1))
    b.span(x - size, x + size)
    b.emit(doc)


def preview(out: Path, prefix: str, sky, sun, name: str = "preview", cam_x: float = 0.0) -> None:
    """Compone las capas como las verá el juego (rsvg-convert + PIL) para revisar."""
    from PIL import Image, ImageDraw
    view = Image.new("RGBA", (1280, 800))
    column = Image.new("RGBA", (1, 800))
    for y in range(800):
        t = min(1.0, y / 600)
        for (p0, c0), (p1, c1) in zip(sky, sky[1:]):
            if p0 <= t <= p1:
                k = (t - p0) / (p1 - p0)
                a = [int(c0[i:i + 2], 16) for i in (1, 3, 5)]
                c = [int(c1[i:i + 2], 16) for i in (1, 3, 5)]
                column.putpixel((0, y), tuple(int(a[i] + (c[i] - a[i]) * k) for i in range(3)) + (255,))
                break
    view.alpha_composite(column.resize((1280, 800)))
    glow = Image.new("RGBA", (1280, 800), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((sun[0] - 50, sun[1] - 50, sun[0] + 50, sun[1] + 50), fill=(255, 250, 230, 255))
    view.alpha_composite(glow)
    for layer, depth, top in [("far", 0.12, 250), ("mid", 0.3, 410), ("near", 0.6, 300), ("ground", 1.0, 596), ("front", 1.4, 650)]:
        svg = out / f"{prefix}_{layer}.svg"
        png = svg.with_suffix(".png")
        subprocess.run(["rsvg-convert", str(svg), "-o", str(png)], check=True)
        image = Image.open(png).convert("RGBA")
        png.unlink()
        x = -(int(cam_x * depth) % image.width)
        while x < 1280:
            if x >= 0:
                view.alpha_composite(image, (x, top))
            else:
                view.alpha_composite(image.crop((-x, 0, image.width, image.height)), (0, top))
            x += image.width
    view.save(out / f"{name}.png")
