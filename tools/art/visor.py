# Visor 3D: dibuja cajas (como las Parts de Roblox) con luz del sol, sombra suave y brillo (Bloom)
# para las piezas de neón. Cámara ortográfica girada (yaw) e inclinada (pitch).
import numpy as np, math
from PIL import Image, ImageFilter

def _rot(yaw, pitch):
    cy, sy = math.cos(yaw), math.sin(yaw); cp, sp = math.cos(pitch), math.sin(pitch)
    Ry = np.array([[cy, 0, -sy], [0, 1, 0], [sy, 0, cy]])
    Rx = np.array([[1, 0, 0], [0, cp, sp], [0, -sp, cp]])
    # el frente del personaje mira a -Z: visto de frente, su mano derecha (+X) queda a la izquierda de la imagen
    return np.diag([-1.0, 1.0, 1.0]) @ Rx @ Ry

CARAS = [((1, 0, 0), (0, 1, 2)), ((-1, 0, 0), (0, 1, 2)), ((0, 1, 0), (1, 0, 2)), ((0, -1, 0), (1, 0, 2)), ((0, 0, 1), (2, 0, 1)), ((0, 0, -1), (2, 0, 1))]

def render(cajas, ancho=520, alto=720, yaw=-28, pitch=12, fondo=(16, 18, 26), escala=None, centro=None, bloom=0.9):
    # cajas: lista de (cx, cy, cz, sx, sy, sz, (r, g, b), neon). El frente del personaje mira a -Z.
    # La cámara mira hacia +Z (ve el frente); yaw gira alrededor del personaje.
    R = _rot(math.radians(yaw), math.radians(pitch))
    pts = []
    for (cx, cy, cz, sx, sy, sz, col, neon) in cajas:
        for a in (-1, 1):
            for b in (-1, 1):
                for c in (-1, 1):
                    pts.append((cx + a * sx / 2, cy + b * sy / 2, cz + c * sz / 2))
    P = np.array(pts) @ R.T
    if escala is None:
        escala = min((ancho - 40) / (P[:, 0].max() - P[:, 0].min()), (alto - 40) / (P[:, 1].max() - P[:, 1].min()))
    if centro is None:
        centro = ((P[:, 0].max() + P[:, 0].min()) / 2, (P[:, 1].max() + P[:, 1].min()) / 2)
    ox, oy = ancho / 2 - centro[0] * escala, alto / 2 + centro[1] * escala
    zbuf = np.full((alto, ancho), np.inf); img = np.zeros((alto, ancho, 3)); emis = np.zeros((alto, ancho, 3))
    img[:] = np.array(fondo) / 255
    luz = np.array([-0.45, 0.8, -0.4]); luz /= np.linalg.norm(luz)
    for (cx, cy, cz, sx, sy, sz, col, neon) in cajas:
        mitad = np.array([sx, sy, sz]) / 2; cen = np.array([cx, cy, cz])
        colr = np.array(col) / 255
        for (n, (e0, e1, e2)) in CARAS:
            n = np.array(n, float); nc = R @ n
            if nc[2] >= -1e-6:
                continue
            # cuatro esquinas de la cara
            u = np.zeros(3); u[e1] = 1; v = np.zeros(3); v[e2] = 1
            base = cen + n * mitad
            p0 = base - u * mitad - v * mitad; p1 = base + u * mitad - v * mitad; p3 = base - u * mitad + v * mitad
            q0, q1, q3 = R @ p0, R @ p1, R @ p3
            s0 = np.array([ox + q0[0] * escala, oy - q0[1] * escala]); s1 = np.array([ox + q1[0] * escala, oy - q1[1] * escala]); s3 = np.array([ox + q3[0] * escala, oy - q3[1] * escala])
            E1, E2 = s1 - s0, s3 - s0
            det = E1[0] * E2[1] - E1[1] * E2[0]
            if abs(det) < 1e-9:
                continue
            xs = [s0[0], s1[0], s3[0], s1[0] + E2[0]]; ys = [s0[1], s1[1], s3[1], s1[1] + E2[1]]
            x0, x1 = max(0, int(min(xs))), min(ancho - 1, int(max(xs)) + 1)
            y0, y1 = max(0, int(min(ys))), min(alto - 1, int(max(ys)) + 1)
            if x1 < x0 or y1 < y0:
                continue
            gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
            dx, dy = gx - s0[0], gy - s0[1]
            uu = (dx * E2[1] - dy * E2[0]) / det; vv = (E1[0] * dy - E1[1] * dx) / det
            dentro = (uu >= -0.001) & (uu <= 1.001) & (vv >= -0.001) & (vv <= 1.001)
            z = q0[2] + uu * (q1[2] - q0[2]) + vv * (q3[2] - q0[2])
            zb = zbuf[y0:y1 + 1, x0:x1 + 1]
            gana = dentro & (z < zb)
            if not gana.any():
                continue
            zb[gana] = z[gana]
            if neon:
                c = np.clip(colr * 1.15 + 0.08, 0, 1); e = colr
            else:
                d = max(0.0, float(n @ luz))
                k = 0.5 + 0.62 * d + (0.08 if n[1] > 0 else 0)
                c = np.clip(colr * k, 0, 1); e = np.zeros(3)
            img[y0:y1 + 1, x0:x1 + 1][gana] = c
            emis[y0:y1 + 1, x0:x1 + 1][gana] = e
    # brillo (Bloom): las piezas de neón irradian luz
    if bloom:
        em = Image.fromarray((np.clip(emis, 0, 1) * 255).astype(np.uint8))
        b1 = np.asarray(em.filter(ImageFilter.GaussianBlur(4)), float) / 255
        b2 = np.asarray(em.filter(ImageFilter.GaussianBlur(12)), float) / 255
        img = img + (b1 * 0.55 + b2 * 0.6) * bloom
    return Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)), (escala, centro)

# cuerpo del cazador (para ver qué tapa la armadura)
CENTROS = {'Torso': (0, 0, 0), 'Head': (0, 1.7, 0), 'Right Arm': (1.5, -0.2, 0), 'Left Arm': (-1.5, -0.2, 0), 'Right Leg': (0.5, -2.3, 0), 'Left Leg': (-0.5, -2.3, 0)}
TAM = {'Torso': (2, 2, 1), 'Head': (1.4, 1.4, 1.4), 'Right Arm': (1, 2.4, 1), 'Left Arm': (1, 2.4, 1), 'Right Leg': (1, 2.6, 1), 'Left Leg': (1, 2.6, 1)}
def cuerpo(piel=(224, 172, 126), ropa=(120, 90, 70), pantalon=(96, 72, 52)):
    r = []
    for p, (cx, cy, cz) in CENTROS.items():
        sx, sy, sz = TAM[p]
        col = piel if p in ('Head', 'Right Arm', 'Left Arm') else (ropa if p == 'Torso' else pantalon)
        r.append((cx, cy, cz, sx, sy, sz, col, False))
    return r
