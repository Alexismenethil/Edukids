"""Elementos del paisaje andino en estilo caricatura limpia: cada objeto tiene un color base, una
sombra nítida abajo a la izquierda y una luz arriba a la derecha (el sol de la tarde)."""

from __future__ import annotations

import math

from svgkit import (Builder, Doc, blob, circle_path, ellipse_path, fmt, poly, smooth_closed, smooth_open)

# Paletas (sombra, base, luz).
LEAF = ("#3C8A55", "#57AE60", "#8CD06C")
LEAF_DEEP = ("#2F7550", "#479B5B", "#78C267")
EUCALYPTUS = ("#3F8466", "#5AA57C", "#92CD9E")
SAGE = ("#5E8C66", "#7FAE77", "#AFD38E")
RETAMA = ("#4C9A4E", "#67B25A", "#97CF6D")
BARK = ("#6B4130", "#8E5A3E", "#B07A54")


def _x_at(side, y: float) -> float:
    """x de una línea quebrada (de la cumbre a la base) a la altura y."""
    for (x0, y0), (x1, y1) in zip(side, side[1:]):
        if y0 <= y <= y1:
            t = (y - y0) / max(1e-6, y1 - y0)
            return x0 + (x1 - x0) * t
    return side[-1][0]


class Shapes:
    """Fábrica de objetos para un documento."""

    def __init__(self, doc: Doc, rng):
        self.doc = doc
        self.rng = rng

    # --- utilidades -----------------------------------------------------------------------------

    def _clip(self, shapes: list[str]) -> str:
        cid = self.doc.uid("c")
        self.doc.defs.append(f'<clipPath id="{cid}">' + "".join(f'<path d="{d}"/>' for d in shapes) + "</clipPath>")
        return cid

    def _puffs(self, b: Builder, circles, palette, light_shift: float = 0.12, shrink: float = 0.9,
               highlights: int = 3) -> None:
        """Masa redonda (copa, arbusto): silueta en sombra, luz desplazada hacia el sol y brillos."""
        shadow, base, light = palette
        silhouette = [circle_path(x, y, r) for x, y, r in circles]
        cid = self._clip(silhouette)
        for d in silhouette:
            b.path(d, shadow)
        lit = []
        for x, y, r in circles:
            lit.append(circle_path(x + r * light_shift * 0.8, y - r * light_shift, r * shrink))
        inner = "".join(f'<path d="{d}" fill="{base}"/>' for d in lit)
        glints = sorted(circles, key=lambda c: (c[1] - c[0] * 0.6))[:highlights]
        for x, y, r in glints:
            inner += f'<path d="{circle_path(x + r * 0.28, y - r * 0.34, r * 0.42)}" fill="{light}"/>'
        b.tags.append(f'<g clip-path="url(#{cid})">{inner}</g>')
        for x, y, r in circles:
            b.span(x - r, x + r)

    # --- cielo ----------------------------------------------------------------------------------

    def cloud(self, cx: float, cy: float, w: float, h: float, tint: str = "#E9DDF3", body: str = "#FFFFFF",
              rim: str = "#FFFDF6", opacity: float = 1.0) -> None:
        """Cúmulo caricatura: base plana, copos al centro, sombra lila nítida abajo."""
        rng = self.rng
        b = Builder()
        circles = []
        count = max(3, int(w / h * 1.6))
        base_y = cy + h * 0.5
        for i in range(count):
            t = (i + 0.5) / count
            envelope = math.sin(math.pi * t) ** 0.6
            r = h * (0.3 + 0.32 * envelope) * rng.uniform(0.9, 1.08)
            circles.append((cx - w / 2 + w * t, base_y - r * 0.62 - envelope * h * 0.18, r))
        floor = poly([(cx - w, base_y), (cx + w, base_y), (cx + w, cy - h * 2), (cx - w, cy - h * 2)])
        fid = self._clip([floor])
        silhouette = "".join(f'<path d="{circle_path(x, y, r)}" fill="{tint}"/>' for x, y, r in circles)
        cid = self._clip([circle_path(x, y, r) for x, y, r in circles])
        lit = "".join(f'<path d="{circle_path(x - r * 0.05, y - r * 0.26, r * 0.98)}" fill="{body}"/>' for x, y, r in circles)
        top = max(circles, key=lambda c: c[2])
        shine = f'<path d="{ellipse_path(top[0] + top[2] * 0.25, top[1] - top[2] * 0.5, top[2] * 0.32, top[2] * 0.16, -0.35)}" fill="{rim}"/>'
        b.tags.append(f'<g clip-path="url(#{fid})">{silhouette}<g clip-path="url(#{cid})">{lit}{shine}</g></g>')
        b.span(cx - w * 0.75, cx + w * 0.75)
        b.emit(self.doc, opacity)

    # --- cerros ---------------------------------------------------------------------------------

    def peak(self, cx: float, base: float, width: float, height: float, shadow: str, lit: str,
             snow_shadow: str, snow_lit: str, snow: float = 0.3, lean: float = 0.12) -> None:
        """Una punta de cerro con dos caras (sombra y sol) y su gorro de nieve en zigzag."""
        rng = self.rng
        b = Builder()
        top = (cx + rng.uniform(-0.04, 0.04) * width, base - height)
        left_side = [top, (cx - width * rng.uniform(0.2, 0.3), base - height * rng.uniform(0.42, 0.58)), (cx - width / 2, base)]
        right_side = [top, (cx + width * rng.uniform(0.2, 0.3), base - height * rng.uniform(0.4, 0.56)), (cx + width / 2, base)]
        outline = left_side[::-1] + right_side[1:]
        b.path(poly(outline), shadow)
        ridge_mid = (top[0] + height * lean * 0.5 + width * rng.uniform(0.0, 0.05), base - height * 0.5)
        ridge_bottom = (top[0] + height * lean + width * 0.1, base)
        face = [top] + right_side[1:] + [ridge_bottom, ridge_mid]
        b.path(poly(face), lit)
        snow_y = top[1] + height * snow
        lx, rx = _x_at(left_side, snow_y), _x_at(right_side, snow_y)
        teeth = []
        steps = 6
        for k in range(steps + 1):
            t = k / steps
            x = rx + (lx - rx) * t
            drop = height * rng.uniform(0.07, 0.15) if k % 2 else -height * 0.01
            teeth.append((x, snow_y + drop))
        upper_left = [p for p in left_side if p[1] < snow_y]
        upper_right = [p for p in right_side if p[1] < snow_y]
        cap = upper_left[::-1][:-1] + [top] + upper_right[1:] + teeth
        cap = [top] + upper_right[1:] + teeth + upper_left[1:][::-1]
        cap_d = poly(cap)
        b.path(cap_d, snow_shadow)
        cid = self._clip([poly(face)])
        b.tags.append(f'<g clip-path="url(#{cid})"><path d="{cap_d}" fill="{snow_lit}"/></g>')
        b.span(cx - width / 2, cx + width / 2)
        b.emit(self.doc)

    # --- vegetación -----------------------------------------------------------------------------

    def trunk(self, b: Builder, x: float, base: float, top_x: float, top_y: float, width: float,
              palette=BARK, branches=()) -> None:
        shadow, base_color, light = palette
        mid = ((x + top_x) / 2 + width * 0.6, (base + top_y) / 2)
        left = [(x - width * 0.75, base), (mid[0] - width * 0.42, mid[1]), (top_x - width * 0.28, top_y)]
        right = [(top_x + width * 0.28, top_y), (mid[0] + width * 0.42, mid[1]), (x + width * 0.75, base)]
        b.path(smooth_open(left) + " L" + " L".join(f"{fmt(px)},{fmt(py)}" for px, py in right) + " Z", base_color)
        b.stroke(smooth_open([(x + width * 0.35, base - 2), (mid[0] + width * 0.18, mid[1]), (top_x + width * 0.1, top_y + 6)]),
                 light, max(1.5, width * 0.22), 0.9)
        for bx, by, ex, ey in branches:
            b.stroke(smooth_open([(bx, by), ((bx + ex) / 2, (by + ey) / 2 + width * 0.3), (ex, ey)]), base_color, width * 0.45)
        b.span(x - width, x + width)

    def round_tree(self, x: float, base: float, height: float, palette=LEAF, bark=BARK) -> None:
        """Molle: tronco curvo y copa de nube."""
        rng = self.rng
        b = Builder()
        crown_w, crown_h = height * 0.62, height * 0.5
        cy = base - height + crown_h * 0.5
        cx = x + rng.uniform(-0.05, 0.05) * height
        self.trunk(b, x, base, cx, cy + crown_h * 0.2, max(4.0, height * 0.075), bark,
                   branches=[(cx - 2, cy + crown_h * 0.35, cx - crown_w * 0.28, cy + crown_h * 0.05),
                             (cx + 2, cy + crown_h * 0.3, cx + crown_w * 0.3, cy + crown_h * 0.02)])
        circles = self._dome(cx, cy, crown_w, crown_h)
        self._puffs(b, circles, palette)
        b.emit(self.doc)

    def tall_tree(self, x: float, base: float, height: float, palette=EUCALYPTUS) -> None:
        """Eucalipto: tronco alto y claro con racimos de hojas a uno y otro lado."""
        rng = self.rng
        b = Builder()
        top_y = base - height * 0.9
        lean = rng.uniform(-0.03, 0.03) * height
        clumps = []
        for k in range(4):
            t = k / 3
            side = -1 if k % 2 == 0 else 1
            yy = base - height * (0.42 + 0.46 * t)
            r = height * (0.15 - 0.03 * t)
            clumps.append((x + lean * t + side * height * 0.08, yy, r))
        branches = [(x + lean * (k / 3), cy + r * 0.5, cx, cy + r * 0.2) for k, (cx, cy, r) in enumerate(clumps)]
        self.trunk(b, x, base, x + lean, top_y + height * 0.1, max(3.5, height * 0.045),
                   ("#9C8466", "#CDB591", "#EBDABA"), branches=branches)
        circles = []
        for cx, cy, r in clumps:
            circles += [(cx - r * 0.45, cy + r * 0.1, r * 0.75), (cx + r * 0.4, cy + r * 0.05, r * 0.72), (cx, cy - r * 0.3, r * 0.8)]
        self._puffs(b, circles, palette, highlights=4)
        b.emit(self.doc)

    def queñua(self, x: float, base: float, height: float, palette=SAGE) -> None:
        """Queñua: tronco rojizo y torcido, copa baja y ancha."""
        rng = self.rng
        b = Builder()
        cy = base - height * 0.68
        self.trunk(b, x, base, x + height * 0.12, cy + height * 0.08, max(4.0, height * 0.09),
                   ("#8C3E2A", "#B4573A", "#D9835C"),
                   branches=[(x + height * 0.05, base - height * 0.4, x - height * 0.25, cy + height * 0.05)])
        circles = self._dome(x + height * 0.04, cy, height * 0.75, height * 0.38)
        self._puffs(b, circles, palette)
        b.emit(self.doc)

    def _dome(self, cx: float, cy: float, w: float, h: float) -> list:
        rng = self.rng
        circles = []
        count = 7
        for i in range(count):
            angle = math.pi * (1.0 + i / (count - 1))
            r = min(w, h) * rng.uniform(0.34, 0.42)
            circles.append((cx + math.cos(angle) * (w / 2 - r * 0.8), cy + math.sin(angle) * (h / 2 - r * 0.6) + r * 0.2, r))
        circles.append((cx, cy + h * 0.12, min(w, h) * 0.48))
        circles.append((cx - w * 0.22, cy + h * 0.22, min(w, h) * 0.36))
        circles.append((cx + w * 0.24, cy + h * 0.2, min(w, h) * 0.36))
        return circles

    def bush(self, x: float, base: float, w: float, h: float, palette=RETAMA, flowers: str | None = None,
             amount: int = 0) -> None:
        rng = self.rng
        b = Builder()
        circles = []
        count = max(3, int(w / h * 2.2))
        for i in range(count):
            t = (i + 0.5) / count
            r = h * (0.38 + 0.18 * math.sin(math.pi * t)) * rng.uniform(0.9, 1.1)
            circles.append((x - w / 2 + w * t, base - r * 0.85 - math.sin(math.pi * t) * h * 0.18, r))
        self._puffs(b, circles, palette, highlights=2)
        if flowers and amount:
            for _ in range(amount):
                cx, cy, r = circles[rng.integers(len(circles))]
                a = rng.uniform(-math.pi, 0.1)
                d = rng.uniform(0.3, 0.85) * r
                fx, fy = cx + math.cos(a) * d, cy + math.sin(a) * d
                size = max(1.6, h * 0.075)
                b.path(circle_path(fx, fy, size), flowers)
                b.path(circle_path(fx + size * 0.3, fy - size * 0.3, size * 0.45), "#FFF3B0")
        b.emit(self.doc)

    def maguey(self, x: float, base: float, height: float, stalk: bool = False) -> None:
        """Maguey: hojas largas en punta; las de atrás más oscuras. A veces con su vara florida."""
        rng = self.rng
        b = Builder()
        if stalk:
            top = (x + height * 0.15, base - height * 3.0)
            b.stroke(smooth_open([(x, base - 4), (x + height * 0.02, base - height * 1.5), top]), "#8C7A4E", max(2.0, height * 0.06))
            for k in range(5):
                t = 0.6 + 0.4 * k / 4
                px = x + (top[0] - x) * t
                py = base + (top[1] - base) * t
                side = -1 if k % 2 else 1
                reach = height * (0.3 - 0.04 * k)
                end = (px + side * reach, py - reach * 0.3)
                b.stroke(f"M{fmt(px)},{fmt(py)} L{fmt(end[0])},{fmt(end[1])}", "#8C7A4E", max(1.2, height * 0.035))
                b.path(ellipse_path(end[0], end[1] - height * 0.04, height * 0.09, height * 0.06), "#E8C64B")
                b.path(ellipse_path(end[0] + height * 0.02, end[1] - height * 0.06, height * 0.045, height * 0.03), "#FBE58A")
        leaves = []
        count = int(rng.integers(9, 12))
        for i in range(count):
            a = math.pi * (0.1 + 0.8 * i / (count - 1)) + rng.uniform(-0.05, 0.05)
            length = height * rng.uniform(0.75, 1.0) * (1.0 - 0.2 * abs(math.cos(a)))
            leaves.append((abs(math.cos(a)) * -1, a, length))
        leaves.sort()
        for depth, a, length in leaves:
            back = depth < -0.45
            tip = (x - math.cos(a) * length, base - math.sin(a) * length)
            nx, ny = -math.sin(a), math.cos(a)
            width = height * 0.12
            mid = (x - math.cos(a) * length * 0.45, base - math.sin(a) * length * 0.45)
            d = (f"M{fmt(x + nx * width * 0.5)},{fmt(base + ny * width * 0.5)} "
                 f"Q{fmt(mid[0] + nx * width)},{fmt(mid[1] + ny * width)} {fmt(tip[0])},{fmt(tip[1])} "
                 f"Q{fmt(mid[0] - nx * width)},{fmt(mid[1] - ny * width)} {fmt(x - nx * width * 0.5)},{fmt(base - ny * width * 0.5)} Z")
            b.path(d, "#3F7F70" if back else "#5DA290")
            if not back:
                b.stroke(f"M{fmt(x)},{fmt(base)} Q{fmt(mid[0] + nx * width * 0.2)},{fmt(mid[1] + ny * width * 0.2)} {fmt(tip[0])},{fmt(tip[1])}",
                         "#9BD0B8", max(1.0, width * 0.18), 0.9)
        b.span(x - height * 1.1, x + height * 1.1)
        b.emit(self.doc)

    def tuna(self, x: float, base: float, height: float) -> None:
        """Tunal: paletas verdes con espinitas y tunas rojas."""
        rng = self.rng
        b = Builder()
        pads = [(x, base - height * 0.3, height * 0.18, height * 0.3, 0.0)]
        for _ in range(int(rng.integers(3, 6))):
            px, py, rx, ry, angle = pads[int(rng.integers(len(pads)))]
            tilt = angle + rng.uniform(-0.75, 0.75)
            nx, ny = px + math.sin(tilt) * ry * 1.35, py - math.cos(tilt) * ry * 1.35
            if ny < base - height * 1.05:
                continue
            pads.append((nx, ny, rx * 0.88, ry * 0.88, tilt))
        for px, py, rx, ry, angle in sorted(pads, key=lambda p: -p[1]):
            b.path(ellipse_path(px, py, rx, ry, angle), "#3E8B5E")
            b.path(ellipse_path(px + rx * 0.12, py - ry * 0.1, rx * 0.8, ry * 0.82, angle), "#5CAE71")
            b.path(ellipse_path(px + rx * 0.3, py - ry * 0.35, rx * 0.3, ry * 0.32, angle), "#8BD08A")
            for _ in range(5):
                a, d = rng.uniform(0, math.tau), rng.uniform(0.2, 0.75)
                b.path(circle_path(px + math.cos(a) * rx * d, py + math.sin(a) * ry * d, max(0.8, rx * 0.06)), "#E6F2CC")
            if rng.random() < 0.55:
                a = angle + rng.uniform(-0.9, 0.9)
                fx, fy = px + math.sin(a) * rx * 0.95, py - math.cos(a) * ry * 0.98
                b.path(ellipse_path(fx, fy, rx * 0.26, rx * 0.32), "#D6375F")
                b.path(circle_path(fx + rx * 0.08, fy - rx * 0.12, rx * 0.1), "#FF9BB0")
        b.span(x - height * 0.8, x + height * 0.8)
        b.emit(self.doc)

    def grass_tuft(self, x: float, base: float, height: float, colors=("#4E9A47", "#6CBA55", "#9AD46B"),
                   blades: int = 5, lean: float = 0.0) -> None:
        rng = self.rng
        b = Builder()
        for k in range(blades):
            t = (k + 0.5) / blades - 0.5
            length = height * (1.0 - abs(t) * 0.7) * rng.uniform(0.8, 1.05)
            tip = (x + t * height * 0.9 + lean * height * 0.4, base - length)
            width = max(1.6, height * 0.12)
            bx = x + t * height * 0.25
            d = (f"M{fmt(bx - width)},{fmt(base)} Q{fmt(bx - width * 0.3)},{fmt(base - length * 0.55)} {fmt(tip[0])},{fmt(tip[1])} "
                 f"Q{fmt(bx + width * 0.5)},{fmt(base - length * 0.5)} {fmt(bx + width)},{fmt(base)} Z")
            b.path(d, colors[1] if k % 2 else colors[0])
        b.path(f"M{fmt(x - height * 0.15)},{fmt(base)} Q{fmt(x)},{fmt(base - height * 0.55)} {fmt(x + height * 0.12)},{fmt(base - height * 0.8)} "
               f"Q{fmt(x + height * 0.05)},{fmt(base - height * 0.4)} {fmt(x + height * 0.12)},{fmt(base)} Z", colors[2])
        b.span(x - height, x + height)
        b.emit(self.doc)

    def ichu(self, x: float, base: float, height: float, colors=("#C59A3E", "#E2BC58", "#F6DC8C")) -> None:
        """Mata de ichu: hojas finas doradas que se abren como fuente."""
        rng = self.rng
        b = Builder()
        count = 9
        for k in range(count):
            t = (k + 0.5) / count - 0.5
            length = height * (1.0 - abs(t) * 0.5) * rng.uniform(0.85, 1.05)
            tip = (x + t * height * 1.5, base - length * (1 - abs(t) * 0.4))
            ctrl = (x + t * height * 0.35, base - length * 0.85)
            w = max(1.2, height * 0.05)
            d = (f"M{fmt(x - w)},{fmt(base)} Q{fmt(ctrl[0] - w)},{fmt(ctrl[1])} {fmt(tip[0])},{fmt(tip[1])} "
                 f"Q{fmt(ctrl[0] + w)},{fmt(ctrl[1])} {fmt(x + w)},{fmt(base)} Z")
            b.path(d, colors[k % 2])
        b.path(f"M{fmt(x - 2)},{fmt(base)} Q{fmt(x + height * 0.1)},{fmt(base - height * 0.7)} {fmt(x + height * 0.3)},{fmt(base - height * 0.85)} "
               f"Q{fmt(x + height * 0.12)},{fmt(base - height * 0.5)} {fmt(x + 3)},{fmt(base)} Z", colors[2])
        b.span(x - height, x + height)
        b.emit(self.doc)

    def flower(self, x: float, base: float, size: float, color: str, center: str = "#FFC93C",
               stem: str = "#4E9A47") -> None:
        b = Builder()
        top = base - size * 3.2
        b.stroke(f"M{fmt(x)},{fmt(base)} Q{fmt(x - size * 0.4)},{fmt(base - size * 1.6)} {fmt(x)},{fmt(top)}", stem, max(1.0, size * 0.28))
        b.path(ellipse_path(x - size * 0.7, base - size * 1.4, size * 0.55, size * 0.25, -0.5), stem)
        for p in range(5):
            a = math.tau * p / 5 - math.pi / 2
            b.path(circle_path(x + math.cos(a) * size * 0.62, top + math.sin(a) * size * 0.62, size * 0.52), color)
        b.path(circle_path(x, top, size * 0.42), center)
        b.path(circle_path(x - size * 0.12, top - size * 0.14, size * 0.16), "#FFF6D0")
        b.span(x - size * 2, x + size * 2)
        b.emit(self.doc)

    def cantuta(self, x: float, base: float, size: float, color: str = "#E8336D") -> None:
        """Cantuta: flor de campana colgante, la flor del Perú."""
        b = Builder()
        top = base - size * 3.4
        b.stroke(f"M{fmt(x)},{fmt(base)} Q{fmt(x + size * 0.5)},{fmt(base - size * 2)} {fmt(x + size * 0.9)},{fmt(top)}",
                 "#4E8C45", max(1.0, size * 0.25))
        bell_top = (x + size * 0.9, top)
        d = (f"M{fmt(bell_top[0] - size * 0.3)},{fmt(bell_top[1])} L{fmt(bell_top[0] + size * 0.3)},{fmt(bell_top[1])} "
             f"Q{fmt(bell_top[0] + size * 0.5)},{fmt(bell_top[1] + size)} {fmt(bell_top[0] + size * 0.8)},{fmt(bell_top[1] + size * 1.7)} "
             f"Q{fmt(bell_top[0])},{fmt(bell_top[1] + size * 1.45)} {fmt(bell_top[0] - size * 0.8)},{fmt(bell_top[1] + size * 1.7)} "
             f"Q{fmt(bell_top[0] - size * 0.5)},{fmt(bell_top[1] + size)} {fmt(bell_top[0] - size * 0.3)},{fmt(bell_top[1])} Z")
        b.path(d, color)
        b.path(f"M{fmt(bell_top[0] + size * 0.05)},{fmt(bell_top[1] + size * 0.2)} Q{fmt(bell_top[0] + size * 0.35)},{fmt(bell_top[1] + size)} "
               f"{fmt(bell_top[0] + size * 0.55)},{fmt(bell_top[1] + size * 1.45)}", "#FF8FB0", 0.9)
        b.path(ellipse_path(bell_top[0], bell_top[1] + size * 1.62, size * 0.62, size * 0.14), "#B81E52")
        b.span(x - size, x + size * 2)
        b.emit(self.doc)

    def stone(self, x: float, base: float, w: float, h: float, colors=("#8F8698", "#B9AEB6", "#E3D8D2")) -> None:
        """Piedra redondeada con sombra abajo y luz arriba."""
        rng = self.rng
        b = Builder()
        pts = blob(x, base - h / 2, w / 2, h / 2, rng, 0.07, 14)
        pts = [(px, min(py, base)) for px, py in pts]
        b.path(smooth_closed(pts), colors[0])
        cid = self._clip([smooth_closed(pts)])
        lit = smooth_closed([(px + w * 0.04, py - h * 0.14) for px, py in pts])
        shine = ellipse_path(x + w * 0.12, base - h * 0.72, w * 0.22, h * 0.13, -0.15)
        b.tags.append(f'<g clip-path="url(#{cid})"><path d="{lit}" fill="{colors[1]}"/><path d="{shine}" fill="{colors[2]}"/></g>')
        b.span(x - w, x + w)
        b.emit(self.doc)

    def house(self, x: float, base: float, w: float) -> None:
        """Casita de adobe con techo de teja."""
        b = Builder()
        h = w * 0.62
        b.path(poly([(x - w / 2, base), (x - w / 2, base - h), (x + w / 2, base - h), (x + w / 2, base)]), "#F1D3AA")
        b.path(poly([(x - w / 2, base), (x - w / 2, base - h), (x - w * 0.18, base - h), (x - w * 0.18, base)]), "#D9B48C")
        b.path(poly([(x - w * 0.62, base - h + 2), (x - w * 0.1, base - h - w * 0.36), (x + w * 0.62, base - h - w * 0.1), (x + w * 0.62, base - h + 2)]), "#D2643E")
        b.path(poly([(x - w * 0.62, base - h + 2), (x - w * 0.1, base - h - w * 0.36), (x - w * 0.02, base - h - w * 0.3), (x - w * 0.5, base - h + 2)]), "#E98A5A")
        b.path(poly([(x + w * 0.1, base), (x + w * 0.1, base - h * 0.62), (x + w * 0.28, base - h * 0.62), (x + w * 0.28, base)]), "#8C5236")
        b.span(x - w, x + w)
        b.emit(self.doc)
