# Set del Eclipse (Amaru): placas casi negras y moradas, venas de energía violeta que brillan,
# cresta alta de púas, cuernos, antebrazos con energía y cristales, emblema y tabardo oscuro.
import math
from modelo import *
from modelo import _h
import silueta
OSCURO = [(10, 4, 22, 0), (22, 9, 46, 0), (36, 14, 74, 0)]
MEDIO = (60, 14, 130, 0); MEDIO2 = (84, 40, 130, 0)
RAMPA = [(0.45, None), (0.6, (66, 12, 140, 0)), (0.74, (110, 20, 200, 1)), (0.88, (160, 30, 240, 1)), (9, (200, 90, 255, 1))]
OJO = (255, 200, 255, 1); OJO2 = (210, 70, 255, 1)
def casco():
    return silueta.casco('cresta', (OJO, OJO2), OSCURO[0])
def pecho():
    return silueta.pecho('puas')
def brazos():
    return silueta.brazos(cristales=True)
def piernas():
    return silueta.piernas(tabardo=True)
def disco(a, b, ca, cb, r):
    return max(0.0, 1 - math.hypot(a - ca, b - cb) / r)
def color(id_, parte, x, y, z, zona, n):
    r1 = ruido(x * 1.2 + 5, y * 1.2, z * 1.2, 0.42, 13)
    r2 = ruido(x, y, z, 0.8, 17)
    vena = 1 - abs(r1 - 0.5) * 13           # venas finas de energía
    t = 0.1
    if zona == 'cresta':
        return OSCURO[0] if r2 < 0.6 else OSCURO[1]
    if zona in ('cuerno',):
        return (190, 180, 220, 0)
    if zona in ('cuerno_punta', 'pua_punta', 'cristal', 'emblema', 'hebilla'):
        return RAMPA[-1][1] if zona in ('emblema', 'cristal') else RAMPA[-2][1]
    if zona == 'pua':
        return OSCURO[1]
    if zona in ('mascara', 'mejilla', 'cintura', 'cinturon'):
        return OSCURO[0]
    if zona == 'rendija':
        return RAMPA[-2][1]
    if zona == 'peto' and n[2] < 0:
        # emblema del pecho: una "V" de energía que baja hacia la gema
        d = disco(x, y, -0.1, 0.5, 0.95)
        v = max(0, 1 - abs(abs(x + 0.1) - (y - 0.1) * 0.8) / 0.18) if y > 0.1 else 0
        t = max(d * 0.5, v * 0.9) + (r1 - 0.5) * 0.15
    elif zona in ('antebrazo', 'guante'):
        # antebrazos y guanteletes cargados de energía (como en la imagen)
        borde = (zona == 'guante' and y < -1.0) or (zona == 'antebrazo' and n[2] < 0 and abs(x) < 0.25)
        t = 0.8 + r1 * 0.2 if borde else max(vena * 0.9, 0.15 + r1 * 0.2)
    elif zona == 'tabardo':
        t = 0.75 if (j := round(y / C)) > -7 and abs(x) < 0.15 else 0.1 + r2 * 0.2
    elif zona == 'tabardo_borde':
        return MEDIO2
    elif zona in ('hombro_abajo', 'brazal', 'bota', 'rodilla2'):
        t = (0.66 + (r1 - 0.5) * 0.5) if (zona != 'hombro_abajo' or y < 0.8) and r1 > 0.45 else 0.2
    elif zona == 'ceja':
        t = 0.6
    else:
        t = max(vena * 0.9, 0.1)
    if t <= RAMPA[0][0]:
        es, inten, _ = juntas(x, y, z, n, 0.6, 0.6, 7)
        if es:
            return MEDIO if inten > 0.5 else OSCURO[2]
        return OSCURO[min(2, int(r2 * 2.6))]
    return rampa(t, RAMPA)
PIEZAS = {'mascara': casco, 'manto': pecho, 'brazales': brazos, 'botas_uku': piernas}
def armar():
    return pintar({k: f() for k, f in PIEZAS.items()}, None, color, relieve=0.3, semilla=5, sale_max=0.08)
