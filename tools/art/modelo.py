# Armaduras en cubitos de 0,2 studs, modeladas por formas y pintadas con "campos" de color
# (zonas que se degradan, como en la imagen de referencia).
import math, hashlib
C = 0.2
# cuerpo del cazador: brazos de 2,4 y piernas de 2,6 studs
DIM = {'Head': (7, 7, 7), 'Torso': (10, 10, 5), 'Right Arm': (5, 12, 5), 'Left Arm': (5, 12, 5), 'Right Leg': (5, 13, 5), 'Left Leg': (5, 13, 5)}
CENTROS = {'Torso': (0, 0, 0), 'Head': (0, 1.7, 0), 'Right Arm': (1.5, -0.2, 0), 'Left Arm': (-1.5, -0.2, 0), 'Right Leg': (0.5, -2.3, 0), 'Left Leg': (-0.5, -2.3, 0)}
def off(parte):
    return tuple(0.5 if d % 2 == 0 else 0.0 for d in DIM[parte])
def pos(parte, i, j, k):
    o = off(parte)
    return ((i + o[0]) * C, (j + o[1]) * C, (k + o[2]) * C)
def rango(parte, eje, margen=0):
    # índices de cubitos que ocupa el cuerpo en ese eje (más un margen hacia afuera)
    n = DIM[parte][eje]
    lo = -(n // 2) if n % 2 else -(n // 2)
    hi = lo + n - 1
    return lo - margen, hi + margen
# ---------- ruido suave (para que los bordes de cada zona queden irregulares, en cubitos) ----------
def _h(*k):
    return int(hashlib.md5('|'.join(map(str, k)).encode()).hexdigest()[:8], 16) / 0xffffffff
def ruido(x, y, z, esc=0.5, semilla=0):
    # ruido de valor 3D suavizado; esc = tamaño de las manchas en studs
    x, y, z = x / esc, y / esc, z / esc
    xi, yi, zi = math.floor(x), math.floor(y), math.floor(z)
    fx, fy, fz = x - xi, y - yi, z - zi
    s = lambda t: t * t * (3 - 2 * t)
    fx, fy, fz = s(fx), s(fy), s(fz)
    v = 0
    for a in (0, 1):
        for b in (0, 1):
            for c in (0, 1):
                w = (fx if a else 1 - fx) * (fy if b else 1 - fy) * (fz if c else 1 - fz)
                v += w * _h(xi + a, yi + b, zi + c, semilla)
    return v
class Pieza:
    def __init__(self):
        self.v = {}        # (parte, i, j, k) -> etiqueta de zona (para pintar)
        self.fijo = {}     # (parte, i, j, k) -> color fijo (r, g, b, neon)
    def pon(self, parte, i, j, k, zona='base'):
        self.v[(parte, i, j, k)] = zona
    def fija(self, parte, i, j, k, col):
        self.v[(parte, i, j, k)] = 'fijo'; self.fijo[(parte, i, j, k)] = col
    def caja(self, parte, i0, i1, j0, j1, k0, k1, zona='base', hueca=False):
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                for k in range(k0, k1 + 1):
                    if hueca and i0 < i < i1 and j0 < j < j1 and k0 < k < k1:
                        continue
                    self.pon(parte, i, j, k, zona)
    def cubierta(self, parte, margen, j0, j1, zona='base', tapa_arriba=False, tapa_abajo=False, mi=None, mk=None):
        # cascarón de un cubito de grosor alrededor de la parte del cuerpo, entre las filas j0..j1
        i0, i1 = rango(parte, 0, mi if mi is not None else margen)
        k0, k1 = rango(parte, 2, mk if mk is not None else margen)
        for j in range(j0, j1 + 1):
            for i in range(i0, i1 + 1):
                for k in range(k0, k1 + 1):
                    borde = i in (i0, i1) or k in (k0, k1) or (tapa_arriba and j == j1) or (tapa_abajo and j == j0)
                    if borde:
                        self.pon(parte, i, j, k, zona)
    def capa(self, parte, i0, i1, j0, j1, k0, k1, zona='base', arriba=False, abajo=False):
        # cascarón de un cubito de grosor de esa caja (abierto arriba y abajo, salvo que se pida tapa)
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                for k in range(k0, k1 + 1):
                    if i in (i0, i1) or k in (k0, k1) or (arriba and j == j1) or (abajo and j == j0):
                        self.pon(parte, i, j, k, zona)
    def quitar(self, parte, i0, i1, j0, j1, k0, k1):
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                for k in range(k0, k1 + 1):
                    self.v.pop((parte, i, j, k), None)
    def espejar(self, de, a):
        # copia una parte al lado contrario (brazo derecho -> izquierdo), reflejando X
        for (p, i, j, k), z in list(self.v.items()):
            if p == de:
                self.v[(a, -i, j, k)] = z
                if (p, i, j, k) in self.fijo:
                    self.fijo[(a, -i, j, k)] = self.fijo[(p, i, j, k)]
VECINOS = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
def pintar(piezas, paleta, campo, relieve=0.3, semilla=0, sale_max=0.06):
    # piezas: { id: Pieza }. campo(id, parte, x, y, z, zona, normal) -> color (r, g, b, neon)
    # Devuelve { id: [ (parte, cx, cy, cz, sx, sy, sz, color) ] } con los cubitos unidos en bloques.
    # el cuerpo cuenta como lleno (lo que queda pegado a él no se ve); cada pieza se revisa sola,
    # así no quedan huecos si alguien combina piezas de sets distintos
    cuerpo = set()
    salida = {}
    for id_, p in piezas.items():
        todo = cuerpo | set(p.v)
        cel = {}
        for (parte, i, j, k), zona in p.v.items():
            expuestas = [n for n in VECINOS if (parte, i + n[0], j + n[1], k + n[2]) not in todo]
            if not expuestas:
                continue   # escondido dentro de la armadura: no hace falta
            x, y, z = pos(parte, i, j, k)
            if zona == 'fijo':
                col = p.fijo[(parte, i, j, k)]
            else:
                normal = expuestas[0] if len(expuestas) == 1 else tuple(sum(n[a] for n in expuestas) for a in range(3))
                col = campo(id_, parte, x, y, z, zona, normal)
            # relieve: en parches de 2x2, algunos cubitos de una cara plana sobresalen un poco
            sale = 0.0; dirn = None
            if len(expuestas) == 1 and expuestas[0][1] == 0:
                n = expuestas[0]
                a = tuple((v // 2) if n[q] == 0 else v for q, v in enumerate((i, j, k)))
                if _h(parte, a, n, semilla, id_) < relieve:
                    sale = sale_max; dirn = n
            cel[(parte, i, j, k)] = (col, sale, dirn)
        salida[id_] = unir(cel)
    return salida
def unir(cel):
    # une cubitos vecinos del mismo color y relieve en bloques (menos piezas en el juego)
    usados = set(); bloques = []
    for clave in sorted(cel, key=lambda q: (q[0], q[3], q[2], q[1])):
        if clave in usados:
            continue
        parte, i, j, k = clave; val = cel[clave]
        def igual(a, b, c):
            q = (parte, a, b, c); return q in cel and q not in usados and cel[q] == val
        i1 = i
        while igual(i1 + 1, j, k): i1 += 1
        j1 = j
        while all(igual(a, j1 + 1, k) for a in range(i, i1 + 1)): j1 += 1
        k1 = k
        while all(igual(a, b, k1 + 1) for a in range(i, i1 + 1) for b in range(j, j1 + 1)): k1 += 1
        for a in range(i, i1 + 1):
            for b in range(j, j1 + 1):
                for c in range(k, k1 + 1):
                    usados.add((parte, a, b, c))
        col, sale, dirn = val
        x0, y0, z0 = pos(parte, i, j, k); x1, y1, z1 = pos(parte, i1, j1, k1)
        cx, cy, cz = (x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2
        sx, sy, sz = (i1 - i + 1) * C, (j1 - j + 1) * C, (k1 - k + 1) * C
        if sale and dirn:
            if dirn[0]: sx += sale; cx += dirn[0] * sale / 2
            if dirn[2]: sz += sale; cz += dirn[2] * sale / 2
        bloques.append((parte, round(cx, 3), round(cy, 3), round(cz, 3), round(sx, 3), round(sy, 3), round(sz, 3), col))
    return bloques
def rampa(t, tramos):
    # tramos: lista de (umbral, color); devuelve el color del primer umbral que t no supera
    for umbral, col in tramos:
        if t <= umbral:
            return col
    return tramos[-1][1]
def a_cajas(bloques_por_pieza):
    out = []
    for bl in bloques_por_pieza.values():
        for (parte, x, y, z, sx, sy, sz, col) in bl:
            cx, cy, cz = CENTROS[parte]
            out.append((cx + x, cy + y, cz + z, sx, sy, sz, col[:3], bool(col[3])))
    return out

def juntas(x, y, z, n, ancho=0.6, alto=0.6, semilla=0):
    # Divide cada cara en placas (como ladrillos) y devuelve (es_junta, intensidad 0..1, placa_caliente)
    # Las juntas son las líneas de un cubito entre placas.
    ax = max(range(3), key=lambda q: abs(n[q]))
    if ax == 0:
        u, v = z, y
    elif ax == 2:
        u, v = x, y
    else:
        u, v = x, z
    fila = math.floor(v / alto + 1000)
    u2 = u + (ancho / 2 if fila % 2 else 0)
    du = (u2 / ancho) % 1.0; dv = (v / alto) % 1.0
    tol_u = C / ancho * 0.55; tol_v = C / alto * 0.55
    es = du < tol_u or dv < tol_v
    placa = (math.floor(u2 / ancho + 1000), fila, ax, n[ax] > 0)
    inten = _h('j', placa, semilla)
    caliente = _h('p', placa, semilla) > 0.93
    return es, inten, caliente
