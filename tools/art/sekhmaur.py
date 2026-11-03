# Set del Guardián (Sekhmaur): placas doradas en varios tonos con juntas oscuras, capa negra debajo,
# franjas azules, corona de bloques, tocado de faraón, ojos y gema cian y tabardo al frente.
import math
from modelo import *
from modelo import _h
import silueta
ORO = [(255, 214, 86, 0), (246, 178, 42, 0), (226, 146, 30, 0)]          # claro, medio, oscuro
ORO_LUZ = (252, 226, 120, 0); ORO_SOMBRA = (172, 100, 24, 0)
JUNTA = (96, 52, 14, 0); NEGRO = [(14, 12, 11, 0), (28, 22, 18, 0)]
AZUL = (24, 58, 112, 0); AZUL2 = (44, 96, 170, 0)
CIAN = (70, 220, 255, 1); CIAN2 = (150, 240, 255, 1)
GRIS = (136, 149, 150, 0); GRIS2 = (110, 122, 128, 0)
def casco():
    return silueta.casco('corona', (CIAN2, CIAN), NEGRO[0])
def pecho():
    return silueta.pecho('redondo')
def brazos():
    return silueta.brazos()
def piernas():
    return silueta.piernas(tabardo=True)
def oro_placa(x, y, z, n, ancho=0.8, alto=0.6, semilla=3):
    es, inten, _ = juntas(x, y, z, n, ancho, alto, semilla)
    if es and inten < 0.55:
        return JUNTA if inten < 0.2 else ORO_SOMBRA
    tono = _h('tono', round(x / ancho), round(y / alto), round(z / ancho), semilla)
    base = ORO[0] if tono < 0.3 else (ORO[1] if tono < 0.78 else ORO[2])
    if _h('brillo', round(x / C), round(y / C), round(z / C)) > 0.95:
        return ORO_LUZ
    return base
def color(id_, parte, x, y, z, zona, n):
    r1 = ruido(x * 1.2, y * 1.2, z * 1.2, 0.45, 5)
    if zona == 'nemes':
        # tocado de faraón: franjas horizontales azul y dorado
        return AZUL if (round(y / C) // 2) % 2 == 0 else ORO[1]
    if zona == 'corona':
        return ORO[0] if y > 0.95 else ORO[1]
    if zona == 'cobra':
        return ORO[0]
    if zona == 'gema':
        return CIAN
    if zona in ('mascara', 'mejilla'):
        return NEGRO[0] if zona == 'mascara' else ORO[2]
    if zona == 'rendija':
        return NEGRO[0]
    if zona == 'ceja':
        return AZUL
    if zona == 'emblema':
        return CIAN
    if zona == 'peto' and n[2] < 0:
        # pecho dorado con un marco azul alrededor de la gema
        d = max(abs(x + 0.1), abs(y - 0.5))
        if 0.28 < d < 0.48:
            return AZUL if r1 > 0.35 else AZUL2
        return oro_placa(x, y, z, n, 0.6, 0.4)
    if zona in ('cintura', 'brazo_sup', 'antebrazo'):
        # la capa negra de debajo (como en la imagen), con alguna placa dorada
        if zona == 'antebrazo' and n[2] < 0 and r1 > 0.55:
            return ORO[2]
        return NEGRO[0] if r1 < 0.6 else NEGRO[1]
    if zona == 'cinturon':
        return AZUL if (round(x / C)) % 3 else ORO[1]
    if zona == 'hebilla':
        return CIAN
    if zona == 'hombro_abajo' and y < 0.8:
        return AZUL if (round((x + z) / C)) % 4 else AZUL2           # borde azul de la hombrera
    if zona == 'brazal' or zona == 'rodilla2':
        return AZUL
    if zona == 'bota' and y > -1.1:
        return AZUL
    if zona in ('tabardo', 'tabardo_borde'):
        if zona == 'tabardo_borde':
            return ORO[1]
        return GRIS if r1 < 0.62 else (GRIS2 if r1 < 0.8 else AZUL)
    if zona == 'collar':
        return AZUL if (round(x / C)) % 2 else ORO[1]
    return oro_placa(x, y, z, n)
PIEZAS = {'capucha': casco, 'coraza': pecho, 'garras': brazos, 'grebas': piernas}
def armar():
    return pintar({k: f() for k, f in PIEZAS.items()}, None, color, relieve=0.34, semilla=4, sale_max=0.1)
