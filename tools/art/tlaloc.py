# Set de Tláloc (Xolotl): placas azul tormenta con ribetes de turquesa, venas de rayo amarillas,
# penacho de plumas magenta y turquesa, anteojeras de Tláloc y branquias en los hombros.
from modelo import *
import silueta
AZUL = [(12, 26, 50, 0), (20, 40, 72, 0), (32, 58, 96, 0)]
TURQ = (40, 180, 170, 0); TURQ2 = (90, 230, 220, 1)
RAYO = (255, 236, 90, 1); RAYO2 = (255, 250, 200, 1)
MAGENTA = [(200, 50, 110, 0), (255, 110, 160, 0)]
MARFIL = (236, 228, 208, 0)
OJO = (255, 250, 200, 1); OJO2 = (255, 236, 90, 1)
def casco():
    return silueta.casco('penacho', (OJO, OJO2), AZUL[0])
def pecho():
    return silueta.pecho('branquias')
def brazos():
    return silueta.brazos()
def piernas():
    return silueta.piernas(tabardo=True)
def color(id_, parte, x, y, z, zona, n):
    r1 = ruido(x * 1.3 + 7, y * 1.3, z * 1.3, 0.42, 31)
    r2 = ruido(x, y, z, 0.8, 33)
    vena = 1 - abs(r1 - 0.5) * 12
    if zona == 'pluma':
        return MAGENTA[0] if (round(x / C) % 2) else (TURQ if r2 < 0.5 else MAGENTA[1])
    if zona == 'pluma_punta':
        return RAYO
    if zona in ('banda', 'orejera'):
        return TURQ if r1 > 0.35 else TURQ2
    if zona == 'anteojera':
        return TURQ2
    if zona == 'colmillo':
        return MARFIL
    if zona == 'branquia':
        return MAGENTA[1] if r1 > 0.5 else MAGENTA[0]
    if zona == 'branquia_punta':
        return RAYO
    if zona in ('mascara', 'mejilla', 'cintura'):
        return AZUL[0]
    if zona == 'rendija':
        return RAYO
    if zona in ('ceja', 'collar', 'cinturon', 'brazal', 'rodilla2'):
        return TURQ if r1 > 0.3 else TURQ2
    if zona in ('emblema', 'hebilla'):
        return RAYO2
    if zona in ('tabardo',):
        return MAGENTA[0] if r2 < 0.5 else (170, 40, 96, 0)
    if zona == 'tabardo_borde':
        return TURQ
    if zona == 'peto' and n[2] < 0:
        # rayo en zigzag en el pecho
        zz = abs(x + 0.1 - ((round(y / C) // 2) % 2 - 0.5) * 0.25)
        if zz < 0.12 and -0.2 < y < 1.0:
            return RAYO
    if vena > 0.62 and zona not in ('mascara',):
        return RAYO if vena > 0.85 else (110, 200, 255, 1)
    es, inten, _ = juntas(x, y, z, n, 0.6, 0.6, 11)
    if es:
        return TURQ if inten > 0.7 else AZUL[2]
    return AZUL[min(2, int(r2 * 2.6))]
PIEZAS = {'penacho_tla': casco, 'pectoral_tla': pecho, 'brazales_tla': brazos, 'sandalias_tla': piernas}
def armar():
    return pintar({k: f() for k, f in PIEZAS.items()}, None, color, relieve=0.3, semilla=12, sale_max=0.09)
