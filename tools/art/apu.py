# Set del Apu (Apu Rumi): bloques de piedra en varios grises, paneles de oro que brillan,
# hielo azul en hombros y casco, casco de bloques con almenas y botas enormes.
import math
from modelo import *
from modelo import _h
import silueta
PIEDRA = [(34, 38, 48, 0), (52, 56, 66, 0), (78, 76, 78, 0), (112, 112, 116, 0), (148, 152, 156, 0)]
PESOS = [0.12, 0.18, 0.25, 0.27, 0.18]
JUNTA = (18, 20, 26, 0)
ORO = (243, 198, 87, 1); ORO_BORDE = (192, 134, 60, 0); ORO_CLARO = (255, 230, 150, 1)
HIELO = [(48, 112, 169, 0), (90, 160, 214, 0), (170, 214, 240, 0)]
OJO = (255, 236, 150, 1); OJO2 = (255, 196, 70, 1)
def casco():
    return silueta.casco('bloques', (OJO, OJO2), JUNTA)
def pecho():
    return silueta.pecho('roca')
def brazos():
    return silueta.brazos()
def piernas():
    return silueta.piernas(bota_grande=True)
def piedra(x, y, z, n, semilla=3):
    es, inten, _ = juntas(x, y, z, n, 0.6, 0.6, semilla)
    if es and inten < 0.45:
        return JUNTA
    # cada bloque de piedra con su propio gris
    ax = max(range(3), key=lambda q: abs(n[q]))
    clave = (round(x / 0.6), round(y / 0.6), round(z / 0.6), ax)
    h = _h('gris', clave, semilla); acum = 0
    oro = _h('oro', clave, semilla)
    if oro < 0.24:
        # bloques de oro repartidos (algunos con el centro que brilla)
        es2, _, _ = juntas(x, y, z, n, 0.6, 0.6, semilla)
        if oro < 0.09 and not es2 and _h('c', round(x / C), round(y / C), round(z / C)) > 0.4:
            return ORO
        return (232, 176, 62, 0) if not es2 else ORO_BORDE
    for p_, col in zip(PESOS, PIEDRA):
        acum += p_
        if h <= acum:
            return col
    return PIEDRA[-1]
def panel(x, y, cx, cy, r):
    # panel de oro cuadrado: centro que brilla, borde dorado oscuro
    d = max(abs(x - cx), abs(y - cy))
    if d <= r * 0.5:
        return ORO_CLARO if d < r * 0.2 else ORO
    if d <= r:
        return ORO_BORDE
    return None
def color(id_, parte, x, y, z, zona, n):
    r1 = ruido(x * 1.2, y * 1.2, z * 1.2, 0.45, 9)
    if zona in ('hielo',):
        return HIELO[0] if r1 < 0.4 else (HIELO[1] if r1 < 0.75 else HIELO[2])
    if zona == 'almena':
        return PIEDRA[3] if r1 < 0.5 else ORO_BORDE
    if zona in ('mascara', 'rendija'):
        return PIEDRA[0]
    if zona == 'mejilla':
        return HIELO[0]
    if zona == 'ceja':
        return ORO_BORDE if abs(x) > 0.3 else ORO
    if zona in ('emblema', 'hebilla'):
        return ORO_CLARO
    if zona == 'peto' and n[2] < 0:
        c = panel(x, y, -0.1, 0.5, 0.5)
        if c:
            return c
    if zona in ('hombro_medio', 'hombro_abajo') and n[1] == 0 and (abs(n[0]) > 0 or n[2] < 0):
        u = z if abs(n[0]) > 0 else x - 0.4
        c = panel(u, y, 0.0, 1.2 if zona == 'hombro_medio' else 0.8, 0.3)
        if c:
            return c
    if zona == 'hombro_arriba':
        return HIELO[1] if r1 > 0.45 else HIELO[0]
    if zona in ('rodilla', 'rodilla2'):
        return (ORO if abs(x) < 0.2 else ORO_BORDE) if zona == 'rodilla2' else ORO_BORDE
    if zona == 'espinilla' and n[2] < 0:
        c = panel(x if parte == 'Right Leg' else -x, y, 0.1, -0.4, 0.24)
        if c:
            return c
    if zona == 'guante' and n[2] < 0 and y < -1.0:
        return ORO_BORDE
    if zona in ('brazal', 'collar'):
        return HIELO[0] if r1 < 0.5 else HIELO[1]
    if zona in ('cintura', 'cinturon'):
        return PIEDRA[0] if r1 < 0.6 else PIEDRA[1]
    return piedra(x, y, z, n)
PIEZAS = {'corona': casco, 'coraza_granito': pecho, 'punos_piedra': brazos, 'grebas_montana': piernas}
def armar():
    return pintar({k: f() for k, f in PIEZAS.items()}, None, color, relieve=0.36, semilla=6, sale_max=0.12)
