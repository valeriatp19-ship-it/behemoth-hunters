# Set del Jaguar (Balam): el guerrero jaguar mexica. Casco con la cabeza del jaguar y las fauces
# alrededor de la cara, placas de obsidiana con manchas de jade que brillan, púas en los hombros,
# garras en los guantes y ribetes de oro.
from modelo import *
from modelo import _h
import silueta
OBS = [(10, 8, 16, 0), (20, 16, 28, 0), (34, 28, 46, 0)]
VIOLETA = (150, 96, 255, 1)
JADE = (40, 230, 150, 1); JADE2 = (24, 140, 96, 0)
ORO = (226, 170, 52, 0); ORO_OSC = (160, 110, 34, 0)
MARFIL = (236, 228, 208, 0)
OJO = (190, 255, 110, 1); OJO2 = (40, 230, 150, 1)
def casco():
    return silueta.casco('jaguar', (OJO, OJO2), OBS[0])
def pecho():
    return silueta.pecho('puas')
def brazos():
    return silueta.brazos(garras=True)
def piernas():
    return silueta.piernas()
def roseta(x, y, z, n):
    # manchas del jaguar: anillos de jade en una grilla irregular
    ax = max(range(3), key=lambda q: abs(n[q]))
    u, v = [c for q, c in enumerate((x, y, z)) if q != ax]
    cu, cv = round(u / 0.55), round(v / 0.55)
    if _h('ros', cu, cv, ax) < 0.72:
        return None
    du, dv = u - cu * 0.55, v - cv * 0.55
    d = max(abs(du), abs(dv))
    if d < 0.08:
        return OBS[2]
    if d < 0.2:
        return JADE if d > 0.13 else JADE2
    return None
def color(id_, parte, x, y, z, zona, n):
    r1 = ruido(x * 1.3 + 3, y * 1.3, z * 1.3, 0.42, 41)
    r2 = ruido(x, y, z, 0.8, 43)
    if zona in ('hocico', 'oreja', 'piel', 'mandibula'):
        c = roseta(x, y, z, n) if zona != 'mandibula' else None
        return c or (OBS[1] if r2 < 0.6 else OBS[2])
    if zona == 'nariz':
        return (60, 36, 46, 0)
    if zona == 'ojo_jag':
        return OJO
    if zona in ('colmillo', 'garra', 'garra_punta'):
        return JADE if zona == 'colmillo' else MARFIL
    if zona == 'pua':
        return OBS[0]
    if zona == 'pua_punta':
        return VIOLETA
    if zona in ('mascara', 'mejilla', 'cintura'):
        return OBS[0]
    if zona == 'rendija':
        return JADE
    if zona in ('ceja', 'collar', 'cinturon', 'brazal', 'rodilla2'):
        return ORO if r1 > 0.3 else ORO_OSC
    if zona in ('emblema', 'hebilla'):
        return JADE
    if zona in ('membrana',):
        return OBS[1]
    c = roseta(x, y, z, n)
    if c and zona not in ('cintura', 'mascara'):
        return c
    es, inten, _ = juntas(x, y, z, n, 0.6, 0.6, 13)
    if es:
        return VIOLETA if inten > 0.94 else OBS[2]
    return OBS[min(2, int(r2 * 2.6))]
PIEZAS = {'yelmo_jag': casco, 'piel_jag': pecho, 'garras_jag': brazos, 'patas_jag': piernas}
def armar():
    return pintar({k: f() for k, f in PIEZAS.items()}, None, color, relieve=0.32, semilla=14, sale_max=0.09)
