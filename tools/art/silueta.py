# Formas de las armaduras (comunes a los cuatro sets, con variantes). Cubitos de 0,2 studs.
# Cuerpo: torso i -5..4, j -5..4, k -2..2 · cabeza -3..3 · brazos/piernas i -2..2, j -5..4, k -2..2
# El frente es -k. Las zonas (nombres) deciden cómo se pinta cada parte.
from modelo import Pieza
def casco(estilo, ojos, negro_ojo):
    p = Pieza()
    p.capa('Head', -4, 4, -3, 4, -4, 4, arriba=True)
    p.caja('Head', -2, 2, -3, -1, -5, -5, 'mascara')
    for i in (-1, 1):
        p.pon('Head', i, -2, -5, 'rendija')
    p.caja('Head', -4, 4, 1, 1, -5, -5, 'ceja')
    for i in range(-4, 5):
        if abs(i) == 2:
            p.fija('Head', i, 0, -4, ojos[0])
        elif abs(i) in (1, 3):
            p.fija('Head', i, 0, -4, ojos[1])
        else:
            p.fija('Head', i, 0, -4, negro_ojo)
    for lado in (-5, 5):
        p.caja('Head', lado, lado, -3, 1, -3, 2, 'mejilla')
    if estilo == 'llamas':
        llamas = [(-3, -4, 4), (-1, -4, 6), (1, -4, 5), (3, -4, 3), (-4, -1, 3), (4, -1, 4), (-4, 2, 2), (4, 2, 3), (-2, 4, 3),
                  (0, 4, 4), (2, 4, 2), (0, 0, 5), (-2, 1, 3), (2, -1, 4)]
        for (i, k, alto) in llamas:
            for a in range(alto):
                t = a / max(1, alto - 1)
                p.pon('Head', i, 5 + a, k, f'llama{t:.2f}')
                if a < alto - 2:
                    p.pon('Head', i + (1 if i <= 0 else -1), 5 + a, k, f'llama{t * 0.8:.2f}')
    elif estilo == 'corona':
        # corona de bloques (como almenas) y tocado de faraón cayendo a los hombros
        for (i, k, alto) in ((-4, -4, 2), (-2, -4, 3), (0, -4, 4), (2, -4, 3), (4, -4, 2), (-4, 0, 2), (4, 0, 2), (-4, 4, 1), (4, 4, 1), (-2, 4, 2), (2, 4, 2), (0, 4, 1)):
            p.caja('Head', i, i + (1 if i < 4 else 0), 5, 4 + alto, k, k, 'corona')
        p.caja('Head', -1, 1, 1, 3, -5, -5, 'cobra'); p.pon('Head', 0, 2, -6, 'gema')
        for lado in (-1, 1):
            p.caja('Head', lado * 5, lado * 5, -7, 3, -3, 3, 'nemes')
            p.caja('Head', lado * 6, lado * 6, -8, -2, -2, 3, 'nemes')
    elif estilo == 'cresta':
        # cresta alta de púas (hacia arriba y atrás) y cuernos a los lados
        for (i, j, k) in ((0, 5, -2), (0, 6, -1), (0, 7, -1), (0, 8, 0), (0, 9, 0), (0, 10, 1), (0, 11, 2), (-1, 5, -1), (1, 5, -1),
                          (-1, 6, 0), (1, 6, 0), (-1, 7, 1), (1, 7, 1), (0, 5, 2), (0, 6, 3), (0, 7, 4), (0, 8, 5), (-2, 5, 1), (2, 5, 1),
                          (-2, 6, 2), (2, 6, 2), (-3, 5, -3), (3, 5, -3), (-4, 6, -3), (4, 6, -3)):
            p.pon('Head', i, j, k, 'cresta')
            if i == 0 and j < 10:
                p.pon('Head', 1 if k % 2 else -1, j, k, 'cresta')
        for lado in (-1, 1):
            for a, (di, dj) in enumerate(((0, 0), (1, 1), (1, 2), (2, 3), (2, 4))):
                p.pon('Head', lado * (5 + di), 2 + dj, 0, 'cuerno' if a < 4 else 'cuerno_punta')
    elif estilo == 'murcielago':
        # orejas enormes y puntiagudas de murciélago, hoja nasal en la frente y colmillos
        for lado in (-1, 1):
            for j in range(4, 13):
                fuera = (j - 4) // 3
                if j <= 7:
                    k0, k1 = -2, 2
                elif j <= 9:
                    k0, k1 = -1, 2
                elif j <= 11:
                    k0, k1 = 0, 1
                else:
                    k0, k1 = 1, 1
                for k in range(k0, k1 + 1):
                    i = lado * (3 + fuera)
                    p.pon('Head', i, j, k, 'oreja')
                    p.pon('Head', i + lado, j, k, 'oreja')
                    if k == k0 and j < 11:
                        p.pon('Head', i, j, k - 1, 'oreja_in')
            p.pon('Head', lado * 2, -4, -5, 'colmillo'); p.pon('Head', lado * 2, -5, -5, 'colmillo')
        for (j, ancho) in ((1, 1), (2, 1), (3, 0), (4, 0), (5, 0)):
            for i in range(-ancho, ancho + 1):
                p.pon('Head', i, j, -6 if j < 5 else -5, 'hoja')
        p.caja('Head', -4, 4, 5, 5, -4, 4, 'tocado')
    elif estilo == 'penacho':
        # penacho de plumas de Tláloc (abanico alto que se inclina hacia atrás) y anteojeras de turquesa
        for i in range(-4, 5):
            largo = 10 - abs(i) // 2
            for a in range(largo):
                k = 2 + a // 3
                x = i + (1 if i > 0 else (-1 if i < 0 else 0)) * (a // 2)   # las plumas se abren en abanico
                p.pon('Head', x, 5 + a, k, 'pluma_punta' if a >= largo - 2 else 'pluma')
        p.caja('Head', -4, 4, 4, 4, -5, -5, 'banda')
        for lado in (-2, 2):
            for (di, dj) in ((-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1)):
                p.pon('Head', lado + di, dj, -5, 'anteojera')
        for lado in (-1, 1):
            p.pon('Head', lado, -4, -5, 'colmillo'); p.pon('Head', lado, -5, -5, 'colmillo')
            for j in range(-2, 3):
                p.pon('Head', lado * 5, j, -2, 'orejera')
    elif estilo == 'jaguar':
        # casco del guerrero jaguar: la cabeza del jaguar con las fauces abiertas alrededor de la cara
        p.caja('Head', -4, 4, 2, 4, -7, -5, 'hocico')
        p.caja('Head', -1, 1, 4, 4, -8, -8, 'nariz')
        for lado in (-1, 1):
            p.caja('Head', lado * 3, lado * 4 if lado > 0 else lado * 3, 5, 6, -1, 0, 'oreja')
            p.caja('Head', lado * 4, lado * 4, 5, 6, -1, 0, 'oreja')
            p.pon('Head', lado * 2, 5, -6, 'ojo_jag')
            p.pon('Head', lado * 3, 1, -7, 'colmillo'); p.pon('Head', lado * 3, 0, -7, 'colmillo')
            p.pon('Head', lado * 3, -3, -6, 'colmillo')
        p.caja('Head', -4, 4, -5, -4, -6, -5, 'mandibula')
        p.caja('Head', -4, 4, -3, 4, 5, 5, 'piel')
        p.caja('Head', -3, 3, -6, -4, 5, 5, 'piel')
    elif estilo == 'caiman':
        # el hocico del caimán sale por encima de la cara, con dientes y ojos en lo alto
        for k in range(-10, -4):
            ancho = 3 if k > -8 else 2
            p.caja('Head', -ancho, ancho, 2, 4, k, k, 'hocico')
        for k in (-6, -8, -10):
            for lado in (-1, 1):
                p.pon('Head', lado * (3 if k > -8 else 2), 1, k, 'diente')
        for lado in (-1, 1):
            p.caja('Head', lado * 2, lado * 2, 5, 5, -4, -3, 'ojo_c')
        for k in range(-2, 5):
            p.pon('Head', 0, 5, k, 'cresta')
            if k % 2 == 0:
                p.pon('Head', 0, 6, k, 'cresta')
    elif estilo == 'bloques':
        p.capa('Head', -5, 5, -3, 5, -5, 4, arriba=True)            # casco más grande, de piedra
        p.quitar('Head', -4, 4, -1, 0, -5, -5)                      # el visor queda hundido
        for (i, k) in ((-5, -5), (-2, -5), (1, -5), (4, -5), (-5, -1), (4, 2), (-5, 2), (-2, 3), (1, 3), (4, -2)):
            p.caja('Head', i, i + 1, 6, 7, k, k + 1, 'almena')
        for lado in (-6, 6):
            p.caja('Head', lado, lado, -2, 3, -3, 1, 'hielo')
    return p
def pecho(hombro, emblema=True, espalda=True, capa=False):
    p = Pieza()
    if capa:
        # capa de membrana en la espalda, con el borde de abajo en picos (como alas plegadas)
        for i in range(-5, 5):
            pico = -10 - (2 if i % 3 == 0 else (1 if i % 3 == 1 else 0))
            for j in range(pico, 5):
                p.pon('Torso', i, j, 5, 'membrana' if j > pico + 1 else 'membrana_borde')
        for i in (-5, -2, 1, 4):
            for j in range(-8, 5):
                p.pon('Torso', i, j, 6, 'vena')
    p.capa('Torso', -4, 3, -5, 4, -3, 3)
    p.caja('Torso', -3, 2, 5, 5, -2, 2, 'collar')
    p.caja('Torso', -4, 3, 0, 4, -4, -4, 'peto')
    if emblema:
        p.caja('Torso', -1, 0, 2, 3, -5, -5, 'emblema')
    p.quitar('Torso', -4, 3, -5, -3, -3, 3)
    p.capa('Torso', -3, 2, -5, -3, -2, 2, 'cintura')
    p.caja('Torso', -3, 2, -2, -2, -4, -4, 'abdomen')
    p.caja('Torso', -4, 3, -4, -4, -3, 3, 'cinturon')
    p.caja('Torso', -1, 0, -4, -4, -4, -4, 'hebilla')
    if espalda:
        p.caja('Torso', -4, 3, -3, 4, 4, 4, 'espalda')
    # hombreras
    p.caja('Right Arm', -2, 2, 7, 7, -2, 2, 'hombro_arriba')
    p.capa('Right Arm', -2, 3, 5, 6, -3, 3, 'hombro_medio', arriba=True)
    p.capa('Right Arm', -2, 4, 3, 4, -4, 4, 'hombro_abajo', arriba=True)
    if hombro == 'redondo':
        for (i, j0, j1, k) in ((3, 5, 6, 3), (4, 3, 4, 4)):
            for kk in (-k, k):
                p.quitar('Right Arm', i, i, j0, j1, kk, kk)
    elif hombro == 'puas':
        for (i, k, alto) in ((0, -2, 4), (2, 0, 5), (0, 2, 3), (2, -2, 3)):
            for a in range(alto):
                p.pon('Right Arm', i + (a // 2), 8 + a, k, 'pua' if a < alto - 1 else 'pua_punta')
    elif hombro == 'branquias':
        # filamentos de branquia que salen del hombro, con la punta cargada de rayos
        for a, k in enumerate((-2, 0, 2)):
            for d in range(4):
                p.pon('Right Arm', 2 + d, 8 + d - (a % 2), k, 'branquia_punta' if d == 3 else 'branquia')
    elif hombro == 'escamas':
        # placas apiladas de escamas con una cresta encima
        p.caja('Right Arm', -2, 3, 8, 8, -3, 3, 'escudo')
        p.caja('Right Arm', -1, 2, 9, 9, -2, 2, 'escudo')
        for k in range(-2, 3):
            p.pon('Right Arm', 1, 10, k, 'cresta')
    elif hombro == 'alas':
        # el hueso del ala sale del hombro hacia arriba y afuera, con una garra en la punta
        for a, (di, dj) in enumerate(((0, 0), (1, 1), (1, 2), (2, 3), (2, 4), (3, 5), (3, 6))):
            for k in (-1, 0):
                p.pon('Right Arm', 2 + di, 8 + dj, k, 'ala_hueso' if a < 6 else 'pua_punta')
        # membrana que cae por detrás del hombro, con el borde en picos
        for i in range(-1, 5):
            fondo = 1 + (i % 2)
            for j in range(fondo, 8 + max(0, i - 1)):
                p.pon('Right Arm', i, j, 4, 'membrana')
    elif hombro == 'roca':
        p.caja('Right Arm', -1, 2, 8, 8, -2, 2, 'hielo')
        p.caja('Right Arm', 0, 1, 9, 9, -1, 1, 'hielo')
    p.capa('Right Arm', -3, 3, 0, 2, -3, 3, 'brazo_sup')
    p.espejar('Right Arm', 'Left Arm')
    return p
def brazos(cristales=False, garras=False):
    p = Pieza()
    if garras:
        # tres garras curvas al frente de cada guante
        for i in (-2, 0, 2):
            p.pon('Right Arm', i, -8, -4, 'garra'); p.pon('Right Arm', i, -9, -4, 'garra'); p.pon('Right Arm', i, -10, -3, 'garra_punta')
        # aleta de murciélago en el antebrazo
        for j in range(-4, 1):
            p.pon('Right Arm', 4, j, 1, 'membrana'); p.pon('Right Arm', 5, j + 1, 1, 'membrana')
        p.pon('Right Arm', 6, 1, 1, 'pua_punta')
    p.capa('Right Arm', -2, 3, -3, -1, -3, 3, 'antebrazo')
    p.caja('Right Arm', -3, 4, -4, -4, -4, 4, 'brazal')
    p.capa('Right Arm', -3, 4, -7, -5, -4, 4, 'guante', abajo=True)
    if cristales:
        for (i, j, k) in ((4, -3, -1), (5, -2, -1), (5, -1, 0), (4, -2, 1), (6, -1, 0), (3, -6, -5), (3, -7, -6), (0, -6, -5), (0, -7, -6)):
            p.pon('Right Arm', i, j, k, 'cristal')
    p.espejar('Right Arm', 'Left Arm')
    return p
def piernas(tabardo=False, bota_grande=False):
    p = Pieza()
    p.capa('Right Leg', -1, 3, 1, 6, -3, 3, 'muslo')
    p.caja('Right Leg', -1, 4, 5, 6, -4, 3, 'faldon', hueca=True)
    p.caja('Right Leg', -1, 3, -1, 0, -4, -4, 'rodilla')
    p.caja('Right Leg', -1, 2, -1, 0, -5, -5, 'rodilla2')
    p.capa('Right Leg', -1, 3, -4, 0, -3, 3, 'espinilla')
    if bota_grande:
        p.capa('Right Leg', -1, 4, -6, -4, -6, 4, 'bota', arriba=True)
    else:
        p.capa('Right Leg', -1, 4, -6, -5, -5, 3, 'bota', arriba=True)
    p.espejar('Right Leg', 'Left Leg')
    if tabardo:
        # tela al frente, del cinturón hasta las rodillas (cuelga del torso)
        for j in range(-13, -4):
            ancho = 2 if j > -12 else 1
            for i in range(-ancho, ancho):
                borde = i in (-ancho, ancho - 1) or j == -13
                p.pon('Torso', i, j, -5, 'tabardo_borde' if borde else 'tabardo')
    return p
