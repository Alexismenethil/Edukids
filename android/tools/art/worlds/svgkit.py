"""Herramientas para dibujar escenas limpias en SVG: curvas suaves, degradados, grupos y capas que
se repiten sin costura (lo que sale por un borde vuelve a entrar por el otro).

Estilo: formas nítidas, colores planos con degradados suaves, una sombra y una luz por objeto.
Nada de ruido ni texturas: el SVG queda limpio, liviano y editable."""

from __future__ import annotations

import math


def fmt(value: float) -> str:
    text = f"{value:.1f}"
    return text[:-2] if text.endswith(".0") else text


def smooth_closed(points, tension: float = 1.0) -> str:
    """Trazo cerrado suave (Catmull-Rom convertido a Bézier) que pasa por todos los puntos."""
    n = len(points)
    parts = [f"M{fmt(points[0][0])},{fmt(points[0][1])}"]
    for i in range(n):
        p0, p1, p2, p3 = points[(i - 1) % n], points[i], points[(i + 1) % n], points[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) * tension / 6, p1[1] + (p2[1] - p0[1]) * tension / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) * tension / 6, p2[1] - (p3[1] - p1[1]) * tension / 6)
        parts.append(f"C{fmt(c1[0])},{fmt(c1[1])} {fmt(c2[0])},{fmt(c2[1])} {fmt(p2[0])},{fmt(p2[1])}")
    parts.append("Z")
    return " ".join(parts)


def smooth_open(points, tension: float = 1.0) -> str:
    n = len(points)
    parts = [f"M{fmt(points[0][0])},{fmt(points[0][1])}"]
    for i in range(n - 1):
        p0 = points[max(0, i - 1)]
        p1, p2 = points[i], points[i + 1]
        p3 = points[min(n - 1, i + 2)]
        c1 = (p1[0] + (p2[0] - p0[0]) * tension / 6, p1[1] + (p2[1] - p0[1]) * tension / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) * tension / 6, p2[1] - (p3[1] - p1[1]) * tension / 6)
        parts.append(f"C{fmt(c1[0])},{fmt(c1[1])} {fmt(c2[0])},{fmt(c2[1])} {fmt(p2[0])},{fmt(p2[1])}")
    return " ".join(parts)


def poly(points) -> str:
    return "M" + " L".join(f"{fmt(x)},{fmt(y)}" for x, y in points) + " Z"


def circle_path(cx: float, cy: float, r: float) -> str:
    return (f"M{fmt(cx - r)},{fmt(cy)} a{fmt(r)},{fmt(r)} 0 1,0 {fmt(r * 2)},0 "
            f"a{fmt(r)},{fmt(r)} 0 1,0 {fmt(-r * 2)},0 Z")


def ellipse_path(cx: float, cy: float, rx: float, ry: float, angle: float = 0.0, count: int = 24) -> str:
    points = []
    ca, sa = math.cos(angle), math.sin(angle)
    for i in range(count):
        t = math.tau * i / count
        x, y = math.cos(t) * rx, math.sin(t) * ry
        points.append((cx + x * ca - y * sa, cy + x * sa + y * ca))
    return smooth_closed(points)


def blob(cx: float, cy: float, rx: float, ry: float, rng, wobble: float = 0.08, count: int = 14) -> list:
    """Puntos de un contorno redondeado y apenas irregular."""
    phase = [rng.uniform(0, math.tau) for _ in range(3)]
    points = []
    for i in range(count):
        t = math.tau * i / count
        r = 1 + wobble * (math.sin(2 * t + phase[0]) * 0.6 + math.sin(3 * t + phase[1]) * 0.4 + math.sin(5 * t + phase[2]) * 0.25)
        points.append((cx + math.cos(t) * rx * r, cy + math.sin(t) * ry * r))
    return points


def puff_outline(circles, steps: int = 6) -> list:
    """Contorno exterior de una unión de círculos (para nubes y copas de árbol): se toman los
    puntos de cada círculo que no caen dentro de otro, ordenados por ángulo alrededor del centro."""
    cx = sum(c[0] for c in circles) / len(circles)
    cy = sum(c[1] for c in circles) / len(circles)
    points = []
    for i, (x, y, r) in enumerate(circles):
        count = max(10, int(r * 0.9))
        for k in range(count):
            t = math.tau * k / count
            px, py = x + math.cos(t) * r, y + math.sin(t) * r
            inside = any((px - ox) ** 2 + (py - oy) ** 2 < (orad * 0.999) ** 2
                         for j, (ox, oy, orad) in enumerate(circles) if j != i)
            if not inside:
                points.append((math.atan2(py - cy, px - cx), px, py))
    points.sort()
    return [(px, py) for _, px, py in points]


class Doc:
    """Documento SVG. Con `period`, cada forma que cruza un borde se repite del otro lado."""

    def __init__(self, width: float, height: float, top: float = 0.0, period: float | None = None,
                 comment: str = ""):
        self.width, self.height, self.top, self.period = width, height, top, period
        self.defs: list[str] = []
        self.body: list[str] = []
        self.comment = comment
        self._ids = 0

    def uid(self, prefix: str) -> str:
        self._ids += 1
        return f"{prefix}{self._ids}"

    def linear(self, stops, x1=0.0, y1=0.0, x2=0.0, y2=1.0, units: str = "objectBoundingBox") -> str:
        gid = self.uid("g")
        stop_tags = "".join(_stop(offset, color) for offset, color in stops)
        self.defs.append(f'<linearGradient id="{gid}" gradientUnits="{units}" x1="{fmt(x1)}" y1="{fmt(y1)}" '
                         f'x2="{fmt(x2)}" y2="{fmt(y2)}">{stop_tags}</linearGradient>')
        return f"url(#{gid})"

    def radial(self, stops, cx=0.5, cy=0.5, r=0.5, units: str = "objectBoundingBox") -> str:
        gid = self.uid("r")
        stop_tags = "".join(_stop(offset, color) for offset, color in stops)
        self.defs.append(f'<radialGradient id="{gid}" gradientUnits="{units}" cx="{fmt(cx)}" cy="{fmt(cy)}" '
                         f'r="{fmt(r)}">{stop_tags}</radialGradient>')
        return f"url(#{gid})"

    def path(self, d: str, fill: str, opacity: float = 1.0, bbox: tuple | None = None, extra: str = "") -> None:
        tag = f'<path d="{d}" fill="{fill}"' + (f' opacity="{fmt(opacity)}"' if opacity < 1 else "") + extra + "/>"
        self._emit(tag, bbox)

    def stroke(self, d: str, color: str, width: float, opacity: float = 1.0, bbox: tuple | None = None,
               cap: str = "round") -> None:
        tag = (f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{fmt(width)}" stroke-linecap="{cap}" '
               f'stroke-linejoin="round"' + (f' opacity="{fmt(opacity)}"' if opacity < 1 else "") + "/>")
        self._emit(tag, bbox)

    def raw(self, tag: str, bbox: tuple | None = None) -> None:
        self._emit(tag, bbox)

    def group(self, tags: list[str], bbox: tuple | None = None, opacity: float = 1.0) -> None:
        inner = "".join(tags)
        tag = f"<g{f' opacity={chr(34)}{fmt(opacity)}{chr(34)}' if opacity < 1 else ''}>{inner}</g>"
        self._emit(tag, bbox)

    def _emit(self, tag: str, bbox: tuple | None) -> None:
        self.body.append(tag)
        if self.period and bbox:
            x0, x1 = bbox
            if x0 < 0:
                self.body.append(f'<g transform="translate({fmt(self.period)},0)">{tag}</g>')
            if x1 > self.width:
                self.body.append(f'<g transform="translate({fmt(-self.period)},0)">{tag}</g>')

    def save(self, path: str) -> None:
        header = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{fmt(self.width)}" height="{fmt(self.height)}" '
                  f'viewBox="0 {fmt(self.top)} {fmt(self.width)} {fmt(self.height)}">\n')
        comment = f"  <!-- {self.comment} -->\n" if self.comment else ""
        defs = "  <defs>" + "".join(self.defs) + "</defs>\n" if self.defs else ""
        body = "\n".join("  " + tag for tag in self.body)
        with open(path, "w") as handle:
            handle.write(header + comment + defs + body + "\n</svg>\n")


def _stop(offset: float, color: str) -> str:
    if isinstance(color, tuple):
        hex_color, alpha = color
        return f'<stop offset="{fmt(offset)}" stop-color="{hex_color}" stop-opacity="{alpha:.2f}"/>'
    return f'<stop offset="{fmt(offset)}" stop-color="{color}"/>'


class Builder:
    """Junta trazos de un objeto (árbol, nube, piedra) para emitirlos juntos con su caja."""

    def __init__(self):
        self.tags: list[str] = []
        self.x0 = math.inf
        self.x1 = -math.inf

    def path(self, d: str, fill: str, opacity: float = 1.0) -> None:
        self.tags.append(f'<path d="{d}" fill="{fill}"' + (f' opacity="{fmt(opacity)}"' if opacity < 1 else "") + "/>")

    def stroke(self, d: str, color: str, width: float, opacity: float = 1.0) -> None:
        self.tags.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{fmt(width)}" '
                         f'stroke-linecap="round" stroke-linejoin="round"'
                         + (f' opacity="{fmt(opacity)}"' if opacity < 1 else "") + "/>")

    def span(self, x0: float, x1: float) -> None:
        self.x0 = min(self.x0, x0)
        self.x1 = max(self.x1, x1)

    def emit(self, doc: Doc, opacity: float = 1.0) -> None:
        if self.tags:
            doc.group(self.tags, (self.x0, self.x1), opacity)
