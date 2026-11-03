# Herramientas para dibujar armas en pixel art: un lienzo de "materiales" con polígonos, trazos
# curvos que se afinan, discos, arcos y espejo. Después "colorear" convierte cada material en el
# color de la familia (núcleo oscuro con borde que brilla en degradado, como en la referencia).
#
# Materiales:
#   B, H, X  cuerpo (hoja, cabeza, cuerpo del bláster): borde que brilla + núcleo oscuro
#   Q        como el cuerpo, pero el centro es del material secundario (membrana, branquia, cristal)
#   C        canal que brilla en el centro         A  segundo brillo (acento de la familia)
#   G, g     metal / oro (oscuro y claro)          J  gema
#   W        hueso, dientes, garras                S  material secundario (piedra, membrana, plumas)
#   M, E     empuñadura (bandas)                   @  donde va la mano
import math
from collections import deque

class Lienzo:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [['.'] * w for _ in range(h)]

    # ---------- básicos ----------
    def pon(self, x, y, m):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = m

    def get(self, x, y):
        return self.g[y][x] if 0 <= x < self.w and 0 <= y < self.h else '.'

    def rect(self, x0, y0, x1, y1, m):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.pon(x, y, m)

    def lleno(self, x, y):
        return self.get(x, y) != '.'

    def donde(self, f, m, solo_lleno=False, solo_vacio=False):
        # pinta m en cada píxel donde f(x, y) es verdadero
        for y in range(self.h):
            for x in range(self.w):
                if f(x, y):
                    if solo_lleno and self.g[y][x] == '.':
                        continue
                    if solo_vacio and self.g[y][x] != '.':
                        continue
                    self.g[y][x] = m

    # ---------- formas ----------
    def poligono(self, pts, m, solo_lleno=False):
        # relleno par-impar, probando el centro de cada píxel
        n = len(pts)
        def dentro(px, py):
            c = False
            j = n - 1
            for i in range(n):
                xi, yi = pts[i]; xj, yj = pts[j]
                if (yi > py) != (yj > py):
                    xc = xi + (py - yi) * (xj - xi) / (yj - yi)
                    if px < xc:
                        c = not c
                j = i
            return c
        self.donde(dentro, m, solo_lleno=solo_lleno)

    def disco(self, cx, cy, r, m, solo_lleno=False):
        self.donde(lambda x, y: (x - cx) ** 2 + (y - cy) ** 2 <= r * r + 0.01, m, solo_lleno=solo_lleno)

    def elipse(self, cx, cy, rx, ry, m):
        self.donde(lambda x, y: ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0001, m)

    def arco(self, cx, cy, r0, r1, a0, a1, m):
        # banda entre los radios r0 y r1, de a0 a a1 grados (0 = derecha, 90 = arriba)
        def f(x, y):
            d = math.hypot(x - cx, y - cy)
            if d < r0 or d > r1:
                return False
            if a1 - a0 >= 360:
                return True
            a = math.degrees(math.atan2(cy - y, x - cx)) % 360
            lo, hi = a0 % 360, a1 % 360
            return lo <= a <= hi if lo <= hi else (a >= lo or a <= hi)
        self.donde(f, m)

    def linea(self, x0, y0, x1, y1, m, r=0.5):
        self.trazo([(x0, y0), (x1, y1)], m, r, r)

    def trazo(self, pts, m, r0, r1=None, suave=True, pasos=12):
        # trazo grueso que sigue los puntos (curva suave), con radio de r0 a r1
        if r1 is None:
            r1 = r0
        camino = curva(pts, pasos) if suave and len(pts) > 2 else lineal(pts, pasos)
        largo = [0.0]
        for i in range(1, len(camino)):
            largo.append(largo[-1] + math.dist(camino[i - 1], camino[i]))
        total = largo[-1] or 1
        for (p, l) in zip(camino, largo):
            r = r0 + (r1 - r0) * l / total
            self.disco(p[0], p[1], r, m)

    def hoja(self, pts, anchos, m, pasos=16):
        # como trazo, pero con un ancho en cada punto (afinado libre)
        camino = []
        radios = []
        for i in range(len(pts) - 1):
            for k in range(pasos):
                t = k / pasos
                camino.append((pts[i][0] + (pts[i + 1][0] - pts[i][0]) * t, pts[i][1] + (pts[i + 1][1] - pts[i][1]) * t))
                radios.append(anchos[i] + (anchos[i + 1] - anchos[i]) * t)
        camino.append(pts[-1]); radios.append(anchos[-1])
        for p, r in zip(camino, radios):
            self.disco(p[0], p[1], r, m)

    def espejo(self, cx, desde_izq=True):
        # copia una mitad sobre la otra (cx = columna del eje)
        for y in range(self.h):
            for x in range(self.w):
                xs = 2 * cx - x
                if desde_izq and x < cx and 0 <= xs < self.w:
                    self.g[y][xs] = self.g[y][x]
                elif not desde_izq and x > cx and 0 <= xs < self.w:
                    self.g[y][xs] = self.g[y][x]

    def borrar(self, f):
        self.donde(f, '.')

    def mango(self, x0, x1, y0, y1, agarre, cada=2, m1='M', m2='E'):
        # empuñadura con bandas; "agarre" = fila donde va la mano
        for y in range(y0, y1 + 1):
            self.rect(x0, y, x1, y, m2 if (y - y0) % cada == cada - 1 else m1)
        self.pon((x0 + x1) // 2 if (x1 - x0) % 2 == 0 else x0 + (x1 - x0) // 2, agarre, '@')

    def recorte(self):
        # quita filas y columnas vacías de los bordes (respetando la mano)
        filas = [y for y in range(self.h) if any(c != '.' for c in self.g[y])]
        cols = [x for x in range(self.w) if any(self.g[y][x] != '.' for y in range(self.h))]
        y0, y1, x0, x1 = filas[0], filas[-1], cols[0], cols[-1]
        nuevo = Lienzo(x1 - x0 + 1, y1 - y0 + 1)
        nuevo.g = [row[x0:x1 + 1] for row in self.g[y0:y1 + 1]]
        return nuevo


def lineal(pts, pasos):
    out = []
    for i in range(len(pts) - 1):
        for k in range(pasos):
            t = k / pasos
            out.append((pts[i][0] + (pts[i + 1][0] - pts[i][0]) * t, pts[i][1] + (pts[i + 1][1] - pts[i][1]) * t))
    out.append(pts[-1])
    return out


def curva(pts, pasos):
    # Catmull-Rom por los puntos
    out = []
    P = [pts[0]] + list(pts) + [pts[-1]]
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for k in range(pasos):
            t = k / pasos
            t2, t3 = t * t, t * t * t
            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
            out.append((x, y))
    out.append(pts[-1])
    return out


# ---------- colores por familia ----------
# (r, g, b, brilla). n/N núcleo, k borde, r segundo anillo, c canal, G/g metal, M/E empuñadura,
# J gema, A acento que brilla, W hueso, S material secundario.
FAM = {
 'sek': dict(n=(26, 38, 82), N=(38, 54, 108), k=(255, 206, 70, 1), r=(238, 160, 34, 0), c=(80, 226, 255, 1), G=(240, 172, 42, 0), g=(255, 216, 100, 0),
             M=(30, 42, 92, 0), E=(240, 172, 42, 0), J=(80, 226, 255, 1), A=(80, 226, 255, 1), W=(244, 232, 200, 0), S=(206, 160, 84, 0)),
 'khe': dict(n=(24, 12, 10), N=(40, 18, 14), k=(255, 168, 40, 1), r=(232, 52, 12, 1), c=(255, 126, 30, 1), G=(52, 26, 20, 0), g=(232, 60, 14, 0),
             M=(36, 18, 14, 0), E=(226, 56, 14, 0), J=(255, 206, 70, 1), A=(255, 226, 90, 1), W=(240, 214, 170, 0), S=(78, 38, 22, 0)),
 'ama': dict(n=(18, 7, 36), N=(32, 13, 62), k=(206, 110, 255, 1), r=(132, 30, 214, 1), c=(222, 130, 255, 1), G=(62, 26, 112, 0), g=(196, 186, 226, 0),
             M=(24, 10, 46, 0), E=(150, 40, 230, 0), J=(236, 150, 255, 1), A=(255, 110, 220, 1), W=(226, 216, 244, 0), S=(46, 18, 84, 0)),
 'cam': dict(n=(24, 12, 32), N=(38, 18, 50), k=(70, 236, 204, 1), r=(168, 28, 72, 1), c=(110, 255, 226, 1), G=(214, 160, 52, 0), g=(244, 204, 96, 0),
             M=(30, 16, 40, 0), E=(160, 30, 70, 0), J=(255, 56, 80, 1), A=(255, 56, 80, 1), W=(232, 226, 210, 0), S=(110, 20, 48, 0)),
 'xol': dict(n=(14, 30, 56), N=(22, 44, 78), k=(255, 236, 90, 1), r=(60, 200, 255, 1), c=(200, 250, 255, 1), G=(40, 170, 160, 0), g=(90, 220, 210, 0),
             M=(20, 34, 52, 0), E=(220, 60, 120, 0), J=(255, 236, 90, 1), A=(255, 120, 200, 1), W=(226, 240, 255, 0), S=(214, 70, 130, 0)),
 'bal': dict(n=(14, 12, 20), N=(26, 20, 34), k=(176, 116, 255, 1), r=(40, 230, 150, 1), c=(225, 200, 255, 1), G=(232, 178, 60, 0), g=(255, 214, 110, 0),
             M=(26, 20, 34, 0), E=(24, 150, 100, 0), J=(40, 230, 150, 1), A=(40, 230, 150, 1), W=(232, 228, 216, 0), S=(22, 120, 84, 0)),
 'cip': dict(n=(18, 30, 26), N=(28, 44, 38), k=(40, 230, 190, 1), r=(20, 130, 120, 1), c=(160, 255, 230, 1), G=(220, 212, 180, 0), g=(240, 232, 200, 0),
             M=(24, 34, 30, 0), E=(120, 24, 36, 0), J=(255, 120, 60, 1), A=(255, 140, 70, 1), W=(242, 234, 204, 0), S=(52, 82, 60, 0)),
 'apu': dict(n=(104, 106, 112), N=(84, 86, 94), k=(240, 186, 70, 0), r=(150, 152, 158, 0), c=(90, 196, 255, 1), G=(232, 176, 62, 0), g=(255, 214, 110, 0),
             M=(40, 46, 58, 0), E=(232, 176, 62, 0), J=(110, 214, 255, 1), A=(110, 214, 255, 1), W=(236, 244, 255, 0), S=(132, 136, 146, 0)),
}
# grosor máximo de cada color (en mitades: 3 -> hasta 5 píxeles de grueso)
GROSOR = {'k': 1, 'r': 1, 'n': 3, 'N': 3, 'c': 2, 'G': 3, 'g': 3, 'M': 2, 'E': 2, 'J': 2, 'A': 2, 'W': 2, 'S': 2}


def colorear(g, fam):
    P = FAM[fam]
    H, W = g.h, g.w
    lleno = lambda x, y: g.get(x, y) != '.'
    dist = [[0] * W for _ in range(H)]; q = deque()
    for y in range(H):
        for x in range(W):
            if lleno(x, y) and any(not lleno(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                dist[y][x] = 1; q.append((x, y))
    while q:
        x, y = q.popleft()
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if lleno(x + dx, y + dy) and dist[y + dy][x + dx] == 0:
                    dist[y + dy][x + dx] = dist[y][x] + 1; q.append((x + dx, y + dy))
    filas = []
    for y in range(H):
        f = ''
        for x in range(W):
            m = g.get(x, y)
            if m == '.':
                f += '.'
            elif m == '@':
                f += '@'
            elif m in ('B', 'H', 'X'):
                d = dist[y][x]
                if d == 1:
                    f += 'k'
                elif d == 2:
                    f += 'r'
                else:
                    f += 'n' if (x + y // 2) % 3 else 'N'
            elif m == 'Q':
                # como el cuerpo (borde que brilla) pero con el centro del material secundario
                d = dist[y][x]
                f += 'k' if d == 1 else ('r' if d == 2 else 'S')
            elif m == 'C':
                f += 'c' if dist[y][x] >= 2 else 'k'
            else:
                f += m
        filas.append(f)
    paleta = {}
    for letra in set(''.join(filas)):
        clave = 'M' if letra == '@' else letra
        if letra in ('@', '.'):
            continue
        c = P[clave]
        neon = len(c) > 3 and c[3] == 1
        paleta[letra] = (c[0], c[1], c[2], GROSOR.get(letra, 2), neon)
    paleta['e'] = P['M'][:3] + (GROSOR['M'], False)
    return filas, paleta
