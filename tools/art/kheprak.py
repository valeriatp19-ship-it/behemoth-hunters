# Set del Rodador (Kheprak): placas negras con zonas de lava (amarillo -> naranja -> rojo -> negro),
# corona de llamas, sol en el pecho y ojos ardientes. Basado en la imagen de referencia.
# Cubitos de 0,2 studs. Cuerpo: torso i -5..4, j -5..4, k -2..2 · cabeza -3..3 · brazos/piernas i -2..2, j -5..4, k -2..2
import math
from modelo import *
from modelo import _h
NEGRO = [(22, 10, 10, 0), (36, 16, 14, 0), (52, 24, 20, 0)]
RAMPA = [(0.30, None), (0.40, (92, 16, 10, 0)), (0.52, (176, 26, 10, 0)), (0.68, (232, 40, 10, 0)),
         (0.80, (246, 106, 18, 1)), (0.93, (250, 172, 30, 1)), (9, (255, 222, 96, 1))]
OJO = (255, 226, 210, 1); OJO2 = (255, 64, 30, 1)
import silueta
def casco():
    return silueta.casco('llamas', (OJO, OJO2), NEGRO[0])
def pecho():
    p = silueta.pecho('redondo')
    for (q, z) in list(p.v.items()):
        if z == 'emblema':
            p.v[q] = 'sol'
    return p
def brazos():
    return silueta.brazos()
def piernas():
    return silueta.piernas()
def disco(a, b, ca, cb, r):
    return max(0.0, 1 - math.hypot(a - ca, b - cb) / r)
def calor(id_, parte, x, y, z, zona, n):
    r1 = ruido(x * 1.2 + 3, y * 1.2, z * 1.2, 0.42, 7)
    r2 = ruido(x, y, z, 0.8, 11)
    ridge = 1 - abs(r1 - 0.5) * 7          # vetas finas de lava
    lado_interior = (parte in ('Right Arm', 'Right Leg') and n[0] < 0) or (parte in ('Left Arm', 'Left Leg') and n[0] > 0)
    t = 0.1
    if zona.startswith('llama'):
        t = 0.5 + 0.44 * float(zona[5:]) + (r1 - 0.5) * 0.15
    elif zona == 'sol':
        t = 0.97
    elif zona in ('peto',):
        if n[2] < 0:
            d = disco(x, y, -0.1, 0.5, 1.25)
            rayo = max(0, math.cos(math.atan2(y - 0.5, x + 0.1) * 4)) ** 2
            t = d * (0.6 + 0.5 * rayo) + 0.12 + (r1 - 0.5) * 0.3
        else:
            t = 0.45 + (r1 - 0.5) * 0.5
    elif zona == 'abdomen':
        t = 0.5 + (r1 - 0.5) * 0.9
    elif zona in ('ceja', 'brazal'):
        t = 0.66 + (r1 - 0.5) * 0.6
    elif zona == 'collar':
        t = 0.45 + (r1 - 0.5) * 0.6
    elif zona == 'hebilla':
        t = 0.9
    elif zona in ('cinturon', 'cintura'):
        t = 0.15
    elif zona == 'faldon':
        t = (0.7 if y < 1.1 else 0.35) + (r1 - 0.5) * 0.6
    elif zona == 'hombro_arriba':
        t = 0.55 + (r1 - 0.5) * 0.8
    elif zona == 'hombro_medio':
        t = 0.2 + (r1 - 0.5) * 0.4
    elif zona == 'hombro_abajo':
        t = (0.72 if y < 0.8 else 0.3) + (r1 - 0.5) * 0.7
    elif zona == 'guante':
        t = (0.7 if (y < -1.2 or n[2] < 0 and r1 > 0.55) else 0.2) + (r1 - 0.5) * 0.5
    elif zona in ('rodilla', 'rodilla2'):
        t = (0.6 if zona == 'rodilla' else 0.86) + (r1 - 0.5) * 0.4
    elif zona == 'bota':
        t = (0.62 if y > -1.1 else 0.12) + (r1 - 0.5) * 0.5
    elif zona == 'espalda':
        es, inten, caliente = juntas(x, y, z, n, 0.6, 0.6, 9)
        t = max(ridge * 0.9, (0.45 + inten * 0.5) if es else 0.12)
    elif zona in ('mascara', 'mejilla'):
        t = 0.05
    elif zona == 'rendija':
        t = 0.7
    else:
        es, inten, caliente = juntas(x, y, z, n, 0.6, 0.6, 5)
        if caliente:
            t = 0.36 + r1 * 0.12
        elif es:
            extra = 0.12 if parte != 'Torso' and parte != 'Head' else 0
            t = 0.4 + extra + inten * 0.55 + (r1 - 0.5) * 0.2
        else:
            t = 0.1 + r2 * 0.12
            if _h('chispa', round(x / C), round(y / C), round(z / C)) > 0.93:
                t = 0.7                     # alguna chispa suelta dentro de la placa
    if parte in ('Right Leg', 'Left Leg', 'Right Arm', 'Left Arm') and not zona.startswith('hombro'):
        # manchas de lava en brazos y piernas (como en la imagen)
        m = ruido(x * 1.0 + 9, y * 1.0, z * 1.0, 0.5, 21)
        if m > 0.6:
            t = max(t, 0.55 + (m - 0.6) * 1.6)
    if lado_interior:
        t *= 0.6                            # los costados interiores, más oscuros
    if t <= RAMPA[0][0]:
        return NEGRO[0 if zona in ('mascara', 'mejilla', 'cinturon') else min(2, int(r2 * 3))]
    return rampa(t, RAMPA)
PIEZAS = {'yelmo': casco, 'caparazon': pecho, 'guanteletes': brazos, 'grebas_escarabajo': piernas}
CUBRE = {'yelmo': ['Head'], 'caparazon': ['Torso'], 'guanteletes': [], 'grebas_escarabajo': ['Right Leg', 'Left Leg']}
def armar():
    return pintar({k: f() for k, f in PIEZAS.items()}, None, calor, relieve=0.3, semilla=3)
