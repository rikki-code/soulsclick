import math


def tube(pts, w0, w1):
    """Polygon around a centre line; half-width w0 at the start, w1 at the end."""
    m = len(pts)
    L, R = [], []
    for i, (x, y) in enumerate(pts):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, m - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        d = math.hypot(dx, dy) or 1
        nx, ny = -dy / d, dx / d
        w = w0 + (w1 - w0) * i / max(m - 1, 1)
        L.append((x + nx * w, y + ny * w))
        R.append((x - nx * w, y - ny * w))
    return L + R[::-1]


def feather(base, ang, ln, w):
    """Tapered feather from base along ang (deg, 0 = +x, clockwise)."""
    a = math.radians(ang)
    dx, dy = math.cos(a), math.sin(a)
    nx, ny = -dy, dx
    bx, by = base
    def p(t, s):
        return (bx + dx * ln * t + nx * s, by + dy * ln * t + ny * s)
    return [p(0, -w * 0.6), p(0.55, -w), p(0.9, -w * 0.5), p(1.0, 0), p(0.9, w * 0.5), p(0.55, w), p(0, w * 0.6)]
