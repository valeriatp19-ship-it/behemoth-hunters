# Set de Cipactli: escamas verde abismo con placas en relieve, grietas que brillan como el agua
# profunda, el hocico del caimán como casco, dientes de hueso y placas apiladas en los hombros.
from modelo import *
from modelo import _h
import silueta
ESC = [(16, 28, 24, 0), (28, 44, 36, 0), (42, 62, 50, 0)]
BRILLO = (40, 230, 190, 1); BRILLO2 = (160, 255, 230, 1)
HUESO = (220, 212, 180, 0); HUESO2 = (180, 170, 140, 0)
ROJO = (140, 30, 40, 0)
OJO = (60, 255, 210, 1); OJO2 = (40, 230, 190, 1)
def casco():
    return silueta.casco('caiman', (OJO, OJO2), ESC[0])
def pecho():
    return silueta.pecho('escamas', capa=False)
def brazos():
    return silueta.brazos()
def piernas():
    return silueta.piernas()
def escama(x, y, z, n):
    # escamas cuadradas grandes con una grieta brillante entre ellas
    ax = max(range(3), key=lambda q: abs(n[q]))
    u, v = [c for q, c in enumerate((x, y, z)) if q != ax]
    fu, fv = (u / 0.6) % 1, (v / 0.6) % 1
    if min(fu, 1 - fu) < 0.12 or min(fv, 1 - fv) < 0.12:
        return 'grieta'
    return _h('esc', round(u / 0.6), round(v / 0.6), ax)
def color(id_, parte, x, y, z, zona, n):
    r1 = ruido(x * 1.3 + 9, y * 1.3, z * 1.3, 0.42, 51)
    if zona == 'hocico':
        return ESC[1] if r1 < 0.6 else ESC[2]
    if zona in ('diente', 'colmillo'):
        return HUESO
    if zona == 'ojo_c':
        return OJO
    if zona == 'cresta':
        return ESC[0]
    if zona in ('mascara', 'mejilla', 'cintura'):
        return ESC[0]
    if zona == 'rendija':
        return BRILLO
    if zona in ('ceja', 'collar', 'cinturon', 'brazal', 'rodilla2'):
        return HUESO if r1 > 0.35 else HUESO2
    if zona in ('emblema', 'hebilla'):
        return (255, 120, 60, 1)
    if zona == 'escudo':
        return ESC[2] if r1 > 0.5 else ESC[1]
    e = escama(x, y, z, n)
    if e == 'grieta':
        return BRILLO if r1 > 0.7 else ESC[0]
    return ESC[min(2, int(e * 2.8))]
PIEZAS = {'fauces_casco': casco, 'caparazon_cip': pecho, 'brazales_cip': brazos, 'grebas_cip': piernas}
def armar():
    return pintar({k: f() for k, f in PIEZAS.items()}, None, color, relieve=0.3, semilla=16, sale_max=0.1)
