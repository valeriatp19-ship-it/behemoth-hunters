# Dibuja las escenas exportadas por foto.luau (bloques orientados, como las Parts de Roblox).
# uso: python3 dibujar.py escenas.json salida.png [yaw] [pitch] [columnas] [ancho] [alto]
import json, math, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def rot_cam(yaw, pitch):
    cy, sy = math.cos(yaw), math.sin(yaw); cp, sp = math.cos(pitch), math.sin(pitch)
    Ry = np.array([[cy, 0, -sy], [0, 1, 0], [sy, 0, cy]])
    Rx = np.array([[1, 0, 0], [0, cp, sp], [0, -sp, cp]])
    return np.diag([-1.0, 1.0, 1.0]) @ Rx @ Ry

CARAS = [(0, 1), (0, -1), (1, 1), (1, -1), (2, 1), (2, -1)]

def prismas(cajas):
    # convierte cada caja en (centro, R, mitad, color, neon, transp)
    out = []
    for b in cajas:
        R = np.array(b['r'], float).reshape(3, 3)
        s = np.array(b['s'], float)
        forma = b.get('forma', 'Block')
        if forma == 'Ball':
            s = s * 0.82
        out.append((np.array(b['c'], float), R, s / 2, np.array(b['col'], float) / 255, b.get('neon', False), b.get('t', 0), forma))
    return out

def render(escena, ancho, alto, yaw, pitch, escala, centro, fondo=(18, 20, 28), brillo=1.0):
    Rc = rot_cam(math.radians(yaw), math.radians(pitch))
    zbuf = np.full((alto, ancho), np.inf); img = np.zeros((alto, ancho, 3)); emis = np.zeros((alto, ancho, 3))
    img[:] = np.array(fondo) / 255
    luz = np.array([-0.45, 0.8, -0.4]); luz /= np.linalg.norm(luz)
    ox, oy = ancho / 2 - centro[0] * escala, alto / 2 + centro[1] * escala
    objetos = prismas(escena['cajas'])
    # suelo
    for g in escena.get('suelo', []):
        objetos.append((np.array(g['c'], float), np.eye(3), np.array(g['s'], float) / 2, np.array((58, 70, 52)) / 255, False, 0, 'Block'))
    # cazador de referencia (unos 6 studs de alto)
    cz = escena.get('cazador')
    if cz:
        x, y, z = cz
        for (dx, dy, dz, sx, sy, sz, col) in [(0, 3.6, 0, 2, 2, 1, (60, 120, 200)), (0, 5.3, 0, 1.4, 1.4, 1.4, (224, 172, 126)), (-1.5, 3.4, 0, 1, 2.4, 1, (60, 120, 200)), (1.5, 3.4, 0, 1, 2.4, 1, (60, 120, 200)), (-0.5, 1.3, 0, 1, 2.6, 1, (50, 50, 70)), (0.5, 1.3, 0, 1, 2.6, 1, (50, 50, 70))]:
            objetos.append((np.array((x + dx, y + dy, z + dz)), np.eye(3), np.array((sx, sy, sz)) / 2, np.array(col) / 255, False, 0, 'Block'))
    for (c, R, h, col, neon, tr, forma) in objetos:
        if tr >= 0.97:
            continue
        for (eje, sg) in CARAS:
            nl = np.zeros(3); nl[eje] = sg
            nw = R @ nl
            nc = Rc @ nw
            if nc[2] >= -1e-6:
                continue
            e1, e2 = [k for k in range(3) if k != eje]
            u = np.zeros(3); u[e1] = h[e1]; v = np.zeros(3); v[e2] = h[e2]
            basel = nl * h[eje]
            p0 = c + R @ (basel - u - v); p1 = c + R @ (basel + u - v); p3 = c + R @ (basel - u + v)
            q0, q1, q3 = Rc @ p0, Rc @ p1, Rc @ p3
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
            dentro = (uu >= -0.002) & (uu <= 1.002) & (vv >= -0.002) & (vv <= 1.002)
            z = q0[2] + uu * (q1[2] - q0[2]) + vv * (q3[2] - q0[2])
            zb = zbuf[y0:y1 + 1, x0:x1 + 1]
            gana = dentro & (z < zb)
            if not gana.any():
                continue
            zb[gana] = z[gana]
            if neon:
                cc = np.clip(col * 1.15 + 0.08, 0, 1); e = col
            else:
                d = max(0.0, float(nw @ luz))
                k = 0.45 + 0.62 * d + (0.06 if nw[1] > 0.5 else 0)
                cc = np.clip(col * k * brillo, 0, 1); e = np.zeros(3)
            if tr > 0.05:
                # mezcla simple con lo que había detrás
                fondo_px = img[y0:y1 + 1, x0:x1 + 1][gana]
                cc = cc * (1 - tr) + fondo_px * tr
                img[y0:y1 + 1, x0:x1 + 1][gana] = cc
                zb[gana] = np.inf if tr > 0.5 else zb[gana]
            else:
                img[y0:y1 + 1, x0:x1 + 1][gana] = cc
            emis[y0:y1 + 1, x0:x1 + 1][gana] = e * (1 - tr)
    em = Image.fromarray((np.clip(emis, 0, 1) * 255).astype(np.uint8))
    b1 = np.asarray(em.filter(ImageFilter.GaussianBlur(4)), float) / 255
    b2 = np.asarray(em.filter(ImageFilter.GaussianBlur(12)), float) / 255
    img = img + (b1 * 0.5 + b2 * 0.55) * 0.9
    return Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8))

def main():
    escenas = json.load(open(sys.argv[1]))
    salida = sys.argv[2]
    yaw = float(sys.argv[3]) if len(sys.argv) > 3 else -35
    pitch = float(sys.argv[4]) if len(sys.argv) > 4 else 14
    cols = int(sys.argv[5]) if len(sys.argv) > 5 else min(3, len(escenas))
    ancho = int(sys.argv[6]) if len(sys.argv) > 6 else 520
    alto = int(sys.argv[7]) if len(sys.argv) > 7 else 440
    escala = float(sys.argv[8]) if len(sys.argv) > 8 else 7.0
    cy = float(sys.argv[9]) if len(sys.argv) > 9 else 14
    brillo = float(sys.argv[10]) if len(sys.argv) > 10 else 1.0
    vistas = sys.argv[11].split(',') if len(sys.argv) > 11 else None
    if vistas:
        # una misma escena desde varios ángulos: yaw/pitch separados por /
        escenas = [dict(escenas[0], pose=escenas[0]['pose'] + ' ' + v, vista=v) for v in vistas]
    filas = math.ceil(len(escenas) / cols)
    hoja = Image.new('RGB', (cols * ancho, filas * alto), (10, 10, 14))
    try:
        fuente = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 16)
    except Exception:
        fuente = None
    for i, e in enumerate(escenas):
        y, pch = yaw, pitch
        if e.get('vista'):
            y, pch = [float(x) for x in e['vista'].split('/')]
        im = render(e, ancho, alto, y, pch, escala, (0, cy), brillo=brillo)
        d = ImageDraw.Draw(im)
        d.text((10, 8), e['pose'], fill=(240, 230, 200), font=fuente)
        hoja.paste(im, ((i % cols) * ancho, (i // cols) * alto))
    hoja.save(salida)

if __name__ == '__main__':
    main()
