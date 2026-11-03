# Set de Xibalbá (Camazotz): placas negro-violeta con ribetes de oro maya, membranas rojo sangre,
# glifos de jade que brillan, casco de murciélago con orejas enormes, hombros con huesos de ala,
# capa de membrana en la espalda y garras en los guantes.
import math
from modelo import *
from modelo import _h
import silueta
OSCURO = [(14, 9, 22, 0), (26, 15, 38, 0), (40, 22, 56, 0)]
VIOLETA = (66, 34, 92, 0)
ORO = (222, 164, 50, 0); ORO_OSC = (160, 108, 34, 0); ORO_CLARO = (255, 214, 110, 1)
MEMBRANA = [(92, 12, 36, 0), (120, 20, 50, 0), (146, 30, 62, 0)]
JADE = [(30, 120, 100, 0), (50, 210, 176, 1), (140, 255, 226, 1)]
MARFIL = (236, 228, 208, 0)
OJO = (255, 60, 70, 1); OJO2 = (255, 20, 40, 1)
def casco():
    return silueta.casco('murcielago', (OJO, OJO2), OSCURO[0])
def pecho():
    return silueta.pecho('alas', capa=True)
def brazos():
    return silueta.brazos(garras=True)
def piernas():
    return silueta.piernas(tabardo=True)
def glifo(x, y, cx, cy, r):
    # glifo maya cuadrado: marco de oro, cuadros de jade que brillan adentro
    dx, dy = abs(x - cx), abs(y - cy)
    d = max(dx, dy)
    if d > r:
        return None
    if d > r * 0.72:
        return ORO
    q = (round((x - cx) / C) + round((y - cy) / C)) % 3
    return JADE[1] if q == 0 else (JADE[2] if d < r * 0.25 else OSCURO[1])
def color(id_, parte, x, y, z, zona, n):
    r1 = ruido(x * 1.3 + 2, y * 1.3, z * 1.3, 0.42, 21)
    r2 = ruido(x, y, z, 0.8, 23)
    if zona in ('oreja',):
        return OSCURO[1] if r2 < 0.55 else OSCURO[2]
    if zona == 'oreja_in':
        return JADE[1] if r1 > 0.3 else JADE[0]
    if zona == 'hoja':
        return MEMBRANA[2]
    if zona in ('colmillo', 'garra', 'garra_punta'):
        return MARFIL
    if zona == 'tocado':
        return ORO if (round(x / C) % 2) else ORO_OSC
    if zona in ('ala_hueso',):
        return OSCURO[2]
    if zona == 'pua_punta':
        return MARFIL
    vena = 1 - abs(r1 - 0.5) * 12           # venas finas de energía
    if zona in ('membrana', 'tabardo'):
        if vena > 0.55:
            return (230, 40, 86, 1)          # venas rojo sangre que brillan
        return MEMBRANA[1 if r2 < 0.6 else 2]
    if zona in ('membrana_borde', 'tabardo_borde'):
        return MEMBRANA[0]
    if zona == 'vena':
        return OSCURO[2]
    if zona in ('mascara', 'mejilla', 'cintura'):
        return OSCURO[0]
    if zona == 'rendija':
        return OJO2
    if zona in ('ceja', 'collar', 'cinturon', 'brazal', 'rodilla2'):
        return ORO if r1 > 0.3 else ORO_OSC
    if zona in ('emblema', 'hebilla'):
        return JADE[2]
    if zona == 'peto' and n[2] < 0:
        c = glifo(x, y, -0.1, 0.45, 0.62)
        if c:
            return c
    if zona == 'espinilla' and n[2] < 0:
        c = glifo(x if parte == 'Right Leg' else -x, y, 0.1, -0.45, 0.3)
        if c:
            return c
    if zona == 'antebrazo' and n[2] < 0 and abs(x) < 0.2:
        return JADE[1]
    if zona in ('hombro_abajo',) and n[1] == 0 and y < 0.75:
        return ORO_OSC if r1 > 0.5 else ORO
    if zona in ('hombro_medio', 'hombro_arriba', 'brazo_sup', 'muslo', 'bota', 'espalda', 'peto', 'antebrazo', 'guante', 'espinilla', 'base') and vena > 0.6:
        return JADE[2] if vena > 0.88 else JADE[1]   # venas de jade sobre las placas
    es, inten, _ = juntas(x, y, z, n, 0.6, 0.6, 9)
    if es:
        return VIOLETA if inten > 0.6 else OSCURO[2]
    return OSCURO[min(2, int(r2 * 2.6))]
PIEZAS = {'yelmo_xib': casco, 'coraza_xib': pecho, 'garras_xib': brazos, 'grebas_xib': piernas}
def armar():
    return pintar({k: f() for k, f in PIEZAS.items()}, None, color, relieve=0.32, semilla=8, sale_max=0.1)
