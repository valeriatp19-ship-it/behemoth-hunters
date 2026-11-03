# Las 48 armas de los Behemoths, cada una con su propio diseño (silueta inspirada en su bestia).
# Siguen el estilo de la imagen de referencia: núcleo oscuro, borde que brilla en degradado, canal
# central brillante, oro, gemas y empuñadura con bandas. Ver lienzo.py para los materiales.
#
# Reglas para que encajen en el juego (cliente > ArmasPixel, servidor > Equipo):
#   - el arma está "de pie": la parte que golpea arriba (la punta es la fila más alta) y la mano
#     ("@") abajo; espada, lanza, martillo y puños en el plano XY; guadañas y blásteres en el ZY
#     (las columnas van hacia adelante).
#   - guadañas: el mango a la izquierda (columna ~6) y la hoja hacia la derecha (adelante).
#   - blásteres: la boca del cañón arriba, la culata abajo a la derecha.
#   - puños: los nudillos arriba, la mano en el centro.
import math
from lienzo import Lienzo

TIPOS = ['espada', 'lanza', 'guadana', 'martillo', 'blaster', 'guantelete']
PIXEL = {'espada': 0.2, 'lanza': 0.19, 'guadana': 0.17, 'martillo': 0.2, 'blaster': 0.13, 'guantelete': 0.12}
PLANO = {'espada': 'XY', 'lanza': 'XY', 'guadana': 'ZY', 'martillo': 'XY', 'blaster': 'ZY', 'guantelete': 'XY'}
NOMBRES = {
 'sek': [('colmillo', 'Espada del León'), ('serket', 'Lanza de las Dunas'), ('remolino', 'Guadañas Eternas'), ('esfinge', 'Martillo del Desierto'), ('sol_dorado', 'Blaster Solar'), ('zarpas_leon', 'Zarpas del León')],
 'khe': [('mandibula', 'Espada Solar'), ('hercules', 'Lanza Ígnea'), ('pinzas', 'Guadañas de Fuego'), ('sol_rodante', 'Martillo Solar'), ('brasa', 'Blaster Carmesí'), ('nudillos_brasa', 'Nudillos de Brasa')],
 'ama': [('filo_eclipse', 'Espada Serpiente'), ('lanza_uku', 'Lanza del Uku Pacha'), ('alas_amaru', 'Guadañas Sombrías'), ('martillo_uku', 'Martillo del Abismo'), ('blasteres_eclipse', 'Blaster Nocturno'), ('punos_eclipse', 'Puños del Eclipse')],
 'apu': [('filo_inti', 'Espada de Piedra'), ('lanza_sol', 'Lanza del Sol Naciente'), ('hoces_granito', 'Guadañas del Alba'), ('puno_apu', 'Martillo de la Cima'), ('blasteres_inti', 'Blaster del Sol'), ('guanteletes_inti', 'Guanteletes del Inti')],
 'cam': [('colmillo_xib', 'Colmillo de Xibalbá'), ('aguijon_inf', 'Aguijón del Inframundo'), ('alas_obs', 'Alas de Obsidiana'), ('tambor_cam', 'Tambor de Camazotz'), ('blasteres_eco', 'Blásteres de Eco'), ('garras_cam', 'Garras de Camazotz')],
 'xol': [('macuahuitl', 'Macuahuitl del Trueno'), ('atlatl', 'Atlatl de Tormenta'), ('branquias_ajo', 'Branquias del Ajolote'), ('mazo_tlaloc', 'Mazo de Tláloc'), ('blasteres_cenote', 'Blásteres del Cenote'), ('punos_tormenta', 'Puños de Tormenta')],
 'bal': [('filo_obs', 'Filo de Obsidiana'), ('lanza_nocturna', 'Lanza del Cazador Nocturno'), ('garras_balam', 'Garras de Balam'), ('mazo_jaguar', 'Mazo del Jaguar'), ('blasteres_jade', 'Blásteres de Jade'), ('zarpas_obs', 'Zarpas de Obsidiana')],
 'cip': [('diente_cip', 'Diente de Cipactli'), ('arpon_abismo', 'Arpón del Abismo'), ('hoces_creacion', 'Hoces de la Creación'), ('mazo_pantano', 'Mazo del Pantano'), ('blasteres_abismo', 'Blásteres del Abismo'), ('fauces_cip', 'Fauces del Caimán')],
}
DIS = {}


def diseno(fam, tipo):
    def reg(f):
        DIS[(fam, tipo)] = f
        return f
    return reg


def arma(fam, tipo):
    g = DIS[(fam, tipo)]()
    i = TIPOS.index(tipo)
    id_, nombre = NOMBRES[fam][i]
    return dict(lienzo=g, pixel=PIXEL[tipo], plano=PLANO[tipo], id=id_, nombre=nombre)


# ---------- piezas que se repiten ----------
def rayos(g, cx, cy, r0, r1, n, m, a0=0, a1=360, grueso=0.5):
    for k in range(n):
        a = math.radians(a0 + (a1 - a0) * (k + 0.5) / n) if a1 - a0 < 360 else math.radians(a0 + 360 * k / n)
        g.linea(cx + r0 * math.cos(a), cy - r0 * math.sin(a), cx + r1 * math.cos(a), cy - r1 * math.sin(a), m, grueso)


def culata_blaster(g, x0=10, x1=12, y0=14, y1=21, agarre=18):
    g.mango(x0, x1, y0, y1 - 1, agarre, cada=3)
    g.rect(x0, y1, x1, y1, 'G')


# =====================================================================
# SEKHMAUR · león guardián de las dunas (oro, azul noche y cian)
# =====================================================================
@diseno('sek', 'espada')
def _():
    # colmillo de león: hoja ancha con el lomo recto y la panza curva; guarda de melena (sol)
    g = Lienzo(21, 38); cx = 10
    g.poligono([(9, 0), (11.6, 3), (13.6, 8), (14.2, 13), (13.8, 18), (12.8, 22.5), (7.6, 22.5), (7.4, 15), (7.6, 7), (8.2, 2)], 'B')
    for y in (7, 11.5, 16):                                    # garras en el lomo
        g.poligono([(7.6, y), (5.4, y + 1.6), (7.6, y + 2.6)], 'B')
    g.trazo([(9.8, 4), (10.5, 12), (10.6, 20)], 'C', 0.5)
    rayos(g, cx, 25, 3.5, 6.6, 12, 'g', grueso=0.65)          # melena de rayos
    g.disco(cx, 25, 4.2, 'G')
    g.disco(cx, 25, 2.5, 'S')
    g.pon(cx - 1, 24, 'A'); g.pon(cx + 1, 24, 'A')            # ojos del león
    g.rect(cx - 1, 26, cx + 1, 26, 'G')
    g.mango(cx - 1, cx + 1, 30, 34, 32)
    g.disco(cx, 36, 1.6, 'G'); g.pon(cx, 36, 'J')
    return g


@diseno('sek', 'lanza')
def _():
    # aguijón de escorpión: la cola en segmentos con anillos de oro, la vesícula y el aguijón
    g = Lienzo(19, 50); cx = 9
    g.mango(cx, cx, 24, 47, 38, cada=6)
    segs = [(9, 21.4, 2.1), (9.6, 17.8, 2.4), (10.6, 14.2, 2.6), (11.2, 10.6, 2.7)]
    for (x, y, r) in segs:
        g.disco(x, y, r, 'B')
    g.disco(10.2, 6.6, 3.1, 'B')
    g.hoja([(9.4, 4.0), (8.0, 1.8), (6.2, 0.4), (4.8, 0.9)], [1.4, 1.1, 0.7, 0.35], 'B')
    for (a, b) in zip(segs, segs[1:] + [(10.2, 6.6, 3.1)]):
        mx_, my_ = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        g.linea(mx_ - 2.1, my_ + 0.3, mx_ + 2.1, my_ - 0.3, 'G', 0.5)
    for (x, y, _r) in segs:
        g.pon(x, y, 'C')
    g.disco(10.2, 6.6, 1.2, 'C')
    for s in (-1, 1):                                          # pinzas
        g.hoja([(cx + s * 1.2, 23.4), (cx + s * 4.4, 21.6), (cx + s * 6.6, 18.4)], [1.3, 1.1, 0.4], 'B')
        g.hoja([(cx + s * 1.2, 24.6), (cx + s * 5.0, 24.4), (cx + s * 7.4, 21.8)], [1.1, 0.9, 0.35], 'B')
    g.rect(cx - 1, 23, cx + 1, 25, 'G'); g.pon(cx, 24, 'J')
    for i in range(-3, 4):                                     # media luna en la base
        g.pon(cx + i, 48 - abs(i) // 2 - (1 if abs(i) == 3 else 0), 'g')
    g.rect(cx - 1, 48, cx + 1, 49, 'G')
    return g


@diseno('sek', 'guadana')
def _():
    # khopesh: sube recta y se curva en un gancho con el filo por fuera; bandas de oro y espolón
    g = Lienzo(30, 35); mx = 6
    g.mango(mx - 1, mx + 1, 18, 30, 24, cada=4)
    g.rect(mx - 2, 17, mx + 2, 17, 'G'); g.rect(mx - 2, 31, mx + 2, 31, 'G'); g.rect(mx - 1, 32, mx + 1, 33, 'G'); g.pon(mx, 34, 'J')
    camino = [(6, 16), (6, 11), (7, 6), (10, 2.6), (15, 1.4), (20, 3), (23.8, 7), (25, 12), (23.2, 16.6)]
    g.hoja(camino, [2.3, 2.3, 2.4, 2.5, 2.6, 2.5, 2.3, 1.8, 0.5], 'B')
    g.poligono([(4, 12.4), (1.6, 9.6), (4.2, 10.4)], 'B')        # espolón
    g.trazo([(6.6, 11), (7.6, 6.4), (10.6, 3.4), (15, 2.6), (19.4, 4), (22.6, 7.4), (23.6, 11)], 'C', 0.5)
    g.linea(4.4, 8.4, 8.8, 9.4, 'G', 0.6)                        # bandas de oro
    g.linea(17.8, -0.4, 16.4, 4.8, 'G', 0.6)
    g.rect(mx - 2, 13, mx + 2, 15, 'G'); g.pon(mx, 14, 'J')
    g.pon(mx - 3, 12, 'g'); g.pon(mx + 3, 12, 'g')
    return g


@diseno('sek', 'martillo')
def _():
    # cabeza de esfinge: el tocado a rayas, la cara de piedra y la cobra en la frente
    g = Lienzo(23, 39); cx = 11
    g.mango(cx - 1, cx + 1, 17, 34, 30, cada=5)
    g.poligono([(6, 1), (16, 1), (20.4, 6), (21.6, 16.4), (0.4, 16.4), (1.6, 6)], 'H')
    for y in range(4, 17, 2):                                   # rayas del tocado
        for x in range(0, 23):
            if g.get(x, y) == 'H' and (x < 7 or x > 15):
                g.pon(x, y, 'G')
    g.rect(8, 4, 14, 12, 'S')                                   # cara
    g.rect(8, 6, 9, 6, 'A'); g.rect(13, 6, 14, 6, 'A')          # ojos
    g.rect(11, 7, 11, 9, 'G')
    g.rect(10, 13, 12, 16, 'G')                                 # barba
    g.rect(11, 0, 11, 3, 'G'); g.pon(11, 1, 'J')                # cobra
    g.rect(cx - 2, 17, cx + 2, 18, 'G')
    g.rect(cx - 2, 35, cx + 2, 36, 'G'); g.pon(cx, 37, 'J')
    return g


@diseno('sek', 'blaster')
def _():
    # sol alado: un disco de sol en la boca y alas egipcias a los lados
    g = Lienzo(17, 23); cx = 8
    g.rect(cx - 1, 4, cx + 1, 11, 'X')
    rayos(g, cx, 3.2, 2.6, 4.0, 10, 'g', grueso=0.5)
    g.disco(cx, 3.2, 2.8, 'G'); g.disco(cx, 3.2, 1.5, 'A')
    g.poligono([(cx - 1, 7), (cx - 5, 6), (0.2, 6.6), (0.6, 8.2), (2.4, 9.6), (cx - 1, 10.6)], 'B')
    g.espejo(cx)
    for x in (2, 4, 6):                                         # plumas
        g.linea(x, 7.4, x - 0.6, 9.4, 'G', 0.4)
        g.linea(16 - x, 7.4, 16.6 - x, 9.4, 'G', 0.4)
    g.rect(4, 10, 12, 14, 'X'); g.rect(cx - 1, 11, cx + 1, 12, 'J'); g.rect(4, 14, 12, 14, 'G')
    culata_blaster(g, 10, 12, 15, 21, 18)
    return g


@diseno('sek', 'guantelete')
def _():
    # zarpa de león: dedos redondos, cuatro garras de marfil curvas y la melena en la muñeca
    g = Lienzo(15, 19); cx = 7
    g.elipse(cx, 9.6, 6.4, 4.0, 'X')
    for x in (2.2, 5.4, 8.6, 11.8):
        g.disco(x, 5.8, 1.9, 'X')
    for x in (2.2, 5.4, 8.6, 11.8):
        g.trazo([(x, 4.4), (x - 0.1, 2.4), (x + 1.0, 0.5)], 'W', 1.0, 0.45)
    g.disco(cx, 9.8, 1.9, 'G'); g.disco(cx, 9.8, 0.9, 'J')
    g.rect(3, 13, 11, 16, 'X'); g.rect(3, 14, 11, 14, 'G')
    for x in range(2, 13):
        g.pon(x, 17, 'g')
        if x % 2 == 0:
            g.pon(x, 18, 'g')
    g.pon(cx, 8, '@')
    return g


# =====================================================================
# KHEPRAK · escarabajo del sol (caparazón oscuro, fuego naranja y rojo)
# =====================================================================
@diseno('khe', 'espada')
def _():
    # mandíbula de ciervo volante: hoja que se curva con dientes en el lado de adentro
    g = Lienzo(21, 37); cx = 10
    g.hoja([(10.5, 23), (10.8, 16), (10.2, 9.5), (8.6, 4.4), (5.6, 0.6)], [3.3, 3.3, 2.9, 2.0, 0.5], 'B')
    for (y, x) in [(9, 7.4), (13, 7.6), (17, 7.6)]:            # dientes hacia adentro
        g.poligono([(x, y), (x - 2.6, y + 0.4), (x, y + 2.2)], 'B')
    g.trazo([(10.4, 20), (10.4, 13), (9.6, 7.5), (8.2, 4.6)], 'C', 0.5)
    g.elipse(cx, 24.6, 6.6, 2.0, 'G')                           # caparazón de guarda
    g.rect(cx - 6, 24, cx + 6, 24, 'g')
    for s in (-1, 1):                                           # llamas en las puntas
        g.poligono([(cx + s * 5, 23.6), (cx + s * 7.4, 20.2), (cx + s * 6.4, 23), (cx + s * 7.8, 22.4), (cx + s * 7.2, 24.6)], 'A')
    g.pon(cx, 25, 'J')
    g.mango(cx - 1, cx + 1, 27, 32, 30)
    g.disco(cx, 34.4, 1.9, 'g'); g.pon(cx, 34, 'J')
    return g


@diseno('khe', 'lanza')
def _():
    # cuernos del escarabajo hércules: uno largo con dientes arriba y otro curvo abajo
    g = Lienzo(19, 50); cx = 9
    g.mango(cx, cx, 25, 47, 38, cada=5)
    g.hoja([(8.6, 22), (8.4, 15), (7.8, 8), (6.4, 0.6)], [2.5, 2.2, 1.6, 0.5], 'B')
    for y in (8.5, 12.5):
        g.poligono([(9.6, y), (12.2, y + 1), (9.6, y + 2.2)], 'B')
    g.hoja([(10.6, 22), (13.4, 17.4), (14.8, 12.6), (14, 9.4)], [2.0, 1.7, 1.2, 0.4], 'B')
    g.trazo([(8.6, 19), (8.3, 12), (7.6, 6)], 'C', 0.5)
    g.elipse(9.6, 23, 4.8, 2.6, 'H')
    g.rect(5, 23, 14, 23, 'g'); g.pon(cx, 23, 'J')
    for s in (-1, 1):
        g.poligono([(cx + s * 4, 25), (cx + s * 7.4, 22.4), (cx + s * 6.2, 26), (cx + s * 4.4, 27.2)], 'A')
    g.rect(cx - 1, 48, cx + 1, 49, 'G')
    return g


@diseno('khe', 'guadana')
def _():
    # pata cavadora del escarabajo: hoja en gancho con grandes dientes en el filo de afuera
    g = Lienzo(30, 35); mx = 6
    g.mango(mx - 1, mx + 1, 18, 30, 24, cada=4)
    g.rect(mx - 2, 17, mx + 2, 17, 'G'); g.rect(mx - 2, 31, mx + 2, 31, 'G'); g.rect(mx - 1, 32, mx + 1, 33, 'G'); g.pon(mx, 34, 'J')
    camino = [(6, 16), (6.6, 10), (9.4, 5.6), (14.6, 3.6), (20.6, 4.4), (25.6, 8.4), (27.4, 13)]
    g.hoja(camino, [2.2, 2.4, 2.5, 2.4, 2.1, 1.4, 0.4], 'B')
    for (x, y, dx, dy) in [(9, 3.6, -1.2, -3.2), (14.4, 1.6, 0.4, -3.4), (20.4, 2.4, 2.2, -2.8), (25, 6.2, 3.2, -1.6)]:
        g.poligono([(x - 1.4, y + 1.2), (x + dx, y + dy), (x + 1.6, y + 0.8)], 'B')
    g.trazo([(6.6, 13), (8.4, 7.6), (13, 5.2), (19, 5.4), (24, 8.8)], 'C', 0.5)
    for (x, y) in [(10, 8.6), (16, 7.2), (22, 8.6)]:            # brasas
        g.pon(x, y, 'A')
    g.rect(mx - 2, 14, mx + 2, 16, 'G')
    return g


@diseno('khe', 'martillo')
def _():
    # la bola del sol que rueda el escarabajo, con corona de llamas, sujeta por sus patas
    g = Lienzo(23, 38); cx = 11
    g.mango(cx - 1, cx + 1, 19, 34, 30, cada=4)
    for k in range(10):                                         # corona de llamas
        a = math.radians(k * 36 + 18)
        x0, y0 = cx + 6.4 * math.cos(a), 8.6 - 6.4 * math.sin(a)
        x1, y1 = cx + 9.6 * math.cos(a + 0.18), 8.6 - 9.6 * math.sin(a + 0.18)
        g.poligono([(x0 - 1.4 * math.sin(a), y0 - 1.4 * math.cos(a)), (x1, y1), (x0 + 1.4 * math.sin(a), y0 + 1.4 * math.cos(a))], 'B')
    g.disco(cx, 8.6, 6.6, 'H')
    g.arco(cx, 8.6, 3.4, 4.3, 0, 360, 'C')
    g.disco(cx, 8.6, 2.2, 'A')
    for s in (-1, 1):                                           # patas que la sujetan
        g.linea(cx + s * 1, 17, cx + s * 4.6, 13.4, 'G', 0.6)
        g.linea(cx + s * 4.6, 13.4, cx + s * 6.2, 14.6, 'G', 0.5)
    g.rect(cx - 2, 16, cx + 2, 18, 'G')
    g.rect(cx - 2, 35, cx + 2, 36, 'g'); g.pon(cx, 37, 'J')
    return g


@diseno('khe', 'blaster')
def _():
    # un escarabajo: caparazón ovalado partido en dos, cuerno en la boca y brasas
    g = Lienzo(17, 24); cx = 8
    g.elipse(cx, 10.4, 5.6, 6.6, 'X')
    g.rect(cx - 2, 2.6, cx + 2, 4.6, 'X')
    g.hoja([(cx, 3), (cx, 1.4), (cx - 0.6, 0)], [1.5, 1.0, 0.4], 'X')
    g.rect(cx, 5, cx, 16, 'G')                                  # línea de los élitros
    for (x, y) in [(5, 8), (11, 8), (4.6, 12), (11.4, 12)]:
        g.pon(x, y, 'A')
    for s in (-1, 1):                                           # patas
        g.linea(cx + s * 5.4, 7, cx + s * 7.6, 5.6, 'G', 0.45)
        g.linea(cx + s * 5.6, 12, cx + s * 7.8, 13.6, 'G', 0.45)
    g.pon(cx, 4, 'J')
    culata_blaster(g, 10, 12, 16, 22, 19)
    return g


@diseno('khe', 'guantelete')
def _():
    # nudillos de brasa: caparazón con tres cuernos encendidos y brasas en los élitros
    g = Lienzo(15, 18); cx = 7
    g.rect(2, 6, 12, 12, 'X'); g.elipse(cx, 6.4, 5.4, 2.0, 'X')
    for x in (3.4, 7, 10.6):
        dx = 0 if x == cx else (0.7 if x > cx else -0.7)
        g.hoja([(x, 6), (x, 3), (x + dx, 0.4)], [1.6, 1.0, 0.35], 'B')
        g.pon(x + dx, 0.6, 'A'); g.pon(x + dx * 0.5, 1.6, 'A')
    g.rect(cx, 7, cx, 12, 'G')
    g.pon(4, 9, 'A'); g.pon(10, 9, 'A'); g.pon(4.4, 11, 'A'); g.pon(9.6, 11, 'A')
    g.rect(3, 12, 11, 16, 'X'); g.rect(3, 14, 11, 14, 'g'); g.pon(cx, 14, 'J')
    g.pon(cx, 8, '@')
    return g


# =====================================================================
# AMARU · serpiente del eclipse (negro, violeta y lila)
# =====================================================================
@diseno('ama', 'espada')
def _():
    # hoja ondulada como una serpiente, guarda de capucha de cobra y pomo de eclipse
    g = Lienzo(21, 37); cx = 10
    g.hoja([(10, 23), (8.6, 19), (11.4, 15), (8.6, 11), (11.2, 7), (9.6, 3), (10, 0.2)], [2.6, 2.6, 2.5, 2.3, 2.0, 1.4, 0.4], 'B', pasos=20)
    g.trazo([(10, 21), (8.9, 18.6), (11.1, 15), (8.9, 11), (10.9, 7), (9.8, 4)], 'C', 0.45)
    g.poligono([(cx, 21.4), (4, 22.6), (2.6, 25.4), (5.4, 27), (cx, 26), (14.6, 27), (17.4, 25.4), (16, 22.6)], 'G')
    g.disco(5.6, 24.4, 0.8, 'A'); g.disco(14.4, 24.4, 0.8, 'A')
    g.arco(cx, 24.4, 1.0, 1.9, 0, 360, 'g'); g.pon(cx, 24.4, 'J')
    g.mango(cx - 1, cx + 1, 27, 32, 30)
    g.disco(cx, 34.4, 1.9, 'g'); g.disco(cx, 34.4, 1.0, 'G')
    return g


@diseno('ama', 'lanza')
def _():
    # un eclipse (disco negro con corona que brilla) atravesado por la punta; la serpiente enroscada
    g = Lienzo(19, 50); cx = 9
    g.mango(cx, cx, 16, 47, 38, cada=6)
    g.arco(cx, 9, 4.0, 5.6, 0, 360, 'C')
    g.disco(cx, 9, 4.0, 'S')
    rayos(g, cx, 9, 5.8, 8.4, 8, 'A', grueso=0.5)
    g.hoja([(cx, 17), (cx, 9), (cx, 0.2)], [1.3, 1.2, 0.4], 'B')
    for k in range(6):
        y = 18 + k * 3.2
        g.linea(cx - 1.6, y, cx + 1.6, y + 1.6, 'g', 0.6)
    g.disco(cx, 16.4, 1.4, 'g'); g.pon(cx, 16.4, 'J')
    g.rect(cx - 1, 48, cx + 1, 49, 'G')
    return g


@diseno('ama', 'guadana')
def _():
    # ala de plumas: el arco del ala y plumas largas que cuelgan del filo de adentro
    g = Lienzo(31, 35); mx = 6
    g.mango(mx - 1, mx + 1, 18, 30, 24, cada=4)
    g.rect(mx - 2, 17, mx + 2, 17, 'G'); g.rect(mx - 2, 31, mx + 2, 31, 'G'); g.rect(mx - 1, 32, mx + 1, 33, 'G'); g.pon(mx, 34, 'J')
    g.hoja([(6, 16), (7, 9), (11, 4), (17, 2), (23, 3.6), (27.6, 8)], [2.2, 2.4, 2.4, 2.2, 1.7, 0.6], 'B')
    for (x, y, dx, dy) in [(8.6, 9, 1.6, 6.4), (11.6, 6.4, 2.2, 6.4), (15, 5, 2.6, 6.6), (18.6, 5, 2.8, 6.2), (22, 6.2, 2.8, 5.6), (25.2, 8.4, 2.4, 4.6)]:
        g.hoja([(x, y), (x + dx, y + dy)], [1.3, 0.35], 'B')
    g.trazo([(7, 12), (8.4, 7), (12, 4), (17, 3), (22, 4.2)], 'C', 0.45)
    g.disco(mx, 14.6, 1.6, 'G'); g.pon(mx, 14.6, 'J')
    return g


@diseno('ama', 'martillo')
def _():
    # cabeza de serpiente con las fauces abiertas: colmillos largos y ojo rasgado
    g = Lienzo(23, 38); cx = 11
    g.mango(cx - 1, cx + 1, 18, 34, 30, cada=5)
    g.poligono([(0.6, 6.4), (4, 2.4), (11, 1), (18, 2), (22.4, 5.4), (21.6, 8.2), (15, 8.6), (8, 9.8), (1.4, 10.4)], 'H')
    g.poligono([(1.4, 11.6), (8, 11.6), (15, 12.8), (21, 15.6), (19.6, 17), (10, 16.2), (1.4, 14.8)], 'H')
    for x in (16.6, 12.8):
        g.poligono([(x - 0.9, 8.4), (x, 13.4), (x + 0.9, 8.4)], 'W')
    g.poligono([(18.2, 15.4), (19, 12.4), (19.8, 15.6)], 'W')
    g.rect(15, 3, 17, 5, 'A'); g.rect(16, 3, 16, 5, 'J')
    for (x, y) in [(4, 4.4), (7.4, 3.4), (10.8, 3), (4.4, 7.6), (8, 6.8), (3.6, 13), (7, 13.4)]:
        g.linea(x, y, x + 1.4, y + 1.2, 'g', 0.4)
    g.rect(cx - 2, 16, cx + 2, 18, 'G')
    g.rect(cx - 2, 35, cx + 2, 36, 'G'); g.pon(cx, 37, 'J')
    return g


@diseno('ama', 'blaster')
def _():
    # el eclipse en la boca del cañón, con aletas de pluma
    g = Lienzo(17, 23); cx = 8
    g.arco(cx, 4.4, 2.4, 4.2, 0, 360, 'X')
    g.disco(cx, 4.4, 2.4, 'S')
    rayos(g, cx, 4.4, 4.0, 5.0, 8, 'A', grueso=0.45)
    g.rect(cx - 1, 8, cx + 1, 11, 'X')
    for s in (-1, 1):
        g.hoja([(cx + s * 3, 11.4), (cx + s * 7.2, 7.4)], [1.3, 0.4], 'B')
        g.hoja([(cx + s * 3.6, 13), (cx + s * 7.6, 11.2)], [1.1, 0.35], 'B')
    g.rect(4, 11, 12, 15, 'X'); g.rect(cx - 1, 12, cx + 1, 13, 'J'); g.rect(4, 15, 12, 15, 'G')
    culata_blaster(g, 10, 12, 16, 21, 19)
    return g


@diseno('ama', 'guantelete')
def _():
    # dos colmillos de serpiente y una luna menguante en el dorso
    g = Lienzo(15, 18); cx = 7
    g.rect(2, 4, 12, 12, 'X')
    for x in (4.2, 9.8):
        g.hoja([(x, 5), (x - 0.3, 2), (x + 0.6, 0.2)], [1.3, 0.9, 0.3], 'W')
    g.arco(cx, 8.4, 1.8, 3.0, 60, 300, 'g')
    g.pon(cx + 1, 8, 'J')
    g.rect(3, 12, 11, 16, 'X')
    for y in (13, 15):
        for x in range(3, 12, 2):
            g.pon(x, y, 'G')
    g.pon(cx, 6, '@')
    return g


# =====================================================================
# APU RUMI · espíritu de la montaña y del sol (piedra, oro y hielo)
# =====================================================================
@diseno('apu', 'espada')
def _():
    # losa de piedra escalonada con una grieta de hielo y guarda de sol
    g = Lienzo(21, 37); cx = 10
    g.poligono([(10, 0), (13, 3), (14, 5), (14, 8), (15.4, 9), (15.4, 14), (14.2, 15), (14.2, 19.4), (13, 22.6), (7, 22.6), (5.8, 19.4), (5.8, 15), (4.6, 14), (4.6, 9), (6, 8), (6, 5), (7, 3)], 'B')
    g.trazo([(10, 3), (8.8, 7), (11.2, 11), (8.8, 15), (10.6, 19.6)], 'C', 0.55, suave=False)
    rayos(g, cx, 24.6, 3, 5.2, 8, 'g', grueso=0.6)
    g.disco(cx, 24.6, 3.0, 'G'); g.pon(cx, 24.6, 'J')
    g.mango(cx - 1, cx + 1, 28, 32, 30)
    g.rect(cx - 2, 33, cx + 2, 34, 'S'); g.pon(cx, 35, 'J')
    return g


@diseno('apu', 'lanza')
def _():
    # sol naciente: medio sol de oro con rayos detrás de la punta de piedra
    g = Lienzo(19, 50); cx = 9
    g.mango(cx - 1, cx, 17, 47, 38, cada=6)
    rayos(g, cx, 14, 6.2, 9.0, 7, 'g', a0=0, a1=180, grueso=0.6)
    g.arco(cx, 14, 0, 6.2, 0, 180, 'G')
    g.arco(cx, 14, 3.0, 4.0, 0, 180, 'A')
    g.hoja([(cx, 15), (cx, 7), (cx, 0.2)], [2.6, 2.1, 0.4], 'B')
    g.trazo([(cx, 12), (cx, 3)], 'C', 0.5)
    g.rect(cx - 3, 14, cx + 3, 16, 'S'); g.pon(cx, 15, 'J')
    g.rect(cx - 2, 48, cx + 1, 49, 'G')
    return g


@diseno('apu', 'guadana')
def _():
    # hoz de granito en facetas con cristales de hielo que le crecen en el lomo y la punta
    g = Lienzo(31, 37); mx = 6
    g.mango(mx - 1, mx + 1, 20, 32, 26, cada=4)
    g.rect(mx - 2, 19, mx + 2, 19, 'G'); g.rect(mx - 2, 33, mx + 2, 33, 'G'); g.rect(mx - 1, 34, mx + 1, 35, 'G'); g.pon(mx, 36, 'J')
    pts = [(4.6, 18), (4.6, 10), (8, 5), (14, 2.4), (21, 3), (26, 6.6), (28.4, 11.4), (25.8, 14), (23.4, 10.6), (19.6, 8), (15, 7.4), (10.6, 9.4), (8.4, 13), (8.4, 18)]
    g.poligono(pts, 'B')
    g.poligono([(25.8, 14), (28.4, 11.4), (30, 16), (27.4, 19)], 'A')
    for (x, y, dx, dy) in [(9.4, 5.6, -2.2, -4.6), (11.4, 4.2, 0.4, -4.0), (17.4, 2.6, -0.6, -2.6), (19.4, 2.8, 1.6, -2.8), (25, 5.6, 2.6, -3.0)]:
        g.poligono([(x - 1.1, y + 0.8), (x + dx, y + dy), (x + 1.1, y + 0.4)], 'A')
    for (a, b) in [((8, 11), (11.4, 6.6)), ((14, 7.6), (16, 3.4)), ((20, 8.2), (22.6, 4.2))]:
        g.linea(a[0], a[1], b[0], b[1], 'S', 0.45)
    g.trazo([(6.4, 15), (8.2, 8.6), (13.4, 5), (19.6, 5), (24.6, 8.4)], 'C', 0.45, suave=False)
    g.rect(mx - 2, 16, mx + 2, 18, 'G'); g.pon(mx, 17, 'J')
    return g


@diseno('apu', 'martillo')
def _():
    # la cima: dos picos nevados sobre una banda de oro
    g = Lienzo(23, 38); cx = 11
    g.mango(cx - 1, cx + 1, 17, 34, 30, cada=5)
    g.poligono([(0.4, 15.4), (5, 4), (8.6, 8.4), (12.4, 0.4), (17.6, 9), (19.4, 7), (22.6, 15.4)], 'H')
    g.poligono([(12.4, 0.4), (10.2, 4.8), (11.4, 4.2), (12.4, 5.4), (13.6, 4.2), (14.6, 4.4)], 'W')
    g.poligono([(5, 4), (3.6, 7.6), (4.6, 7), (5.4, 8), (6.6, 6.8)], 'W')
    g.trazo([(12.4, 6), (11.4, 9), (12.8, 12)], 'C', 0.45, suave=False)
    g.rect(1, 13, 21, 15, 'G')
    for x in (4, 8, 14, 18):
        g.pon(x, 14, 'J')
    g.rect(cx - 2, 16, cx + 2, 17, 'S')
    g.rect(cx - 2, 35, cx + 2, 36, 'G'); g.pon(cx, 37, 'J')
    return g


@diseno('apu', 'blaster')
def _():
    # cañón de piedra de tres bocas (los tres rayos de sol) con anillo de oro
    g = Lienzo(17, 23); cx = 8
    g.rect(cx - 1, 2, cx + 1, 10, 'X')
    g.trazo([(cx - 1.4, 9), (cx - 3.6, 4), (cx - 4.6, 1.4)], 'X', 1.1, 0.9)
    g.trazo([(cx + 1.4, 9), (cx + 3.6, 4), (cx + 4.6, 1.4)], 'X', 1.1, 0.9)
    for x in (cx - 4.6, cx, cx + 4.6):
        g.pon(x, 1 if x != cx else 2, 'A')
    g.arco(cx, 9.4, 2.6, 3.6, 0, 360, 'G')
    g.rect(3, 10, 13, 15, 'X'); g.rect(4, 12, 12, 12, 'S'); g.rect(cx - 1, 13, cx + 1, 14, 'J')
    culata_blaster(g, 10, 12, 16, 21, 19)
    return g


@diseno('apu', 'guantelete')
def _():
    # puño de piedra con cristales de hielo en los nudillos y el sol de oro en el dorso
    g = Lienzo(15, 18); cx = 7
    g.poligono([(1, 5), (2, 4), (12, 4), (13, 5), (13, 12), (12, 13), (2, 13), (1, 12)], 'X')
    for x in (2.6, 5.6, 8.6, 11.4):
        g.poligono([(x - 1, 4.4), (x - 0.4, 1.2), (x + 0.4, 0.4), (x + 1, 4.4)], 'A')
    rayos(g, cx, 8.6, 2.2, 3.6, 8, 'g', grueso=0.45)
    g.disco(cx, 8.6, 2.2, 'G'); g.pon(cx, 8.6, 'J')
    g.rect(3, 13, 11, 16, 'S'); g.rect(3, 14, 11, 14, 'G')
    g.pon(cx, 6, '@')
    return g


# =====================================================================
# CAMAZOTZ · murciélago de Xibalbá (negro violáceo, turquesa, carmesí y oro)
# =====================================================================
@diseno('cam', 'espada')
def _():
    # colmillo curvo con guarda de alas de murciélago abiertas
    g = Lienzo(21, 36); cx = 10
    g.poligono([(9, 22), (1.6, 19.6), (0.2, 22.4), (1.8, 23.2), (2.6, 25.6), (4.6, 24.4), (6, 26.4), (9, 25)], 'S')
    g.linea(9, 23, 1.6, 19.8, 'G', 0.5); g.linea(9, 23.4, 2.6, 25.4, 'G', 0.45)
    g.espejo(cx)
    g.hoja([(10.4, 22), (11, 16), (10.8, 10), (9.4, 5), (7.2, 1.6), (5.4, 0.4)], [3.4, 3.4, 3.1, 2.4, 1.3, 0.4], 'B')
    g.trazo([(10.8, 19), (10.8, 12), (9.8, 7), (8.4, 4)], 'C', 0.5)
    g.rect(cx - 1, 22, cx + 1, 25, 'G'); g.pon(cx, 23.4, 'J')
    g.mango(cx - 1, cx + 1, 26, 31, 29)
    g.poligono([(cx - 2, 32), (cx - 1.4, 35.4), (cx, 32.4), (cx + 1.4, 35.4), (cx + 2, 32)], 'G')
    return g


@diseno('cam', 'lanza')
def _():
    # aguja larga entre dos orejas de murciélago (membrana carmesí) y ondas de eco
    g = Lienzo(19, 50); cx = 9
    g.mango(cx, cx, 23, 47, 38, cada=5)
    g.hoja([(cx, 22), (cx, 12), (cx, 0.2)], [1.4, 1.5, 0.35], 'B')
    g.trazo([(cx, 18), (cx, 5)], 'C', 0.4)
    g.poligono([(cx - 0.6, 22), (1.2, 10.6), (2.8, 13.8), (3.4, 21)], 'Q')
    g.poligono([(cx + 0.6, 22), (16.8, 10.6), (15.2, 13.8), (14.6, 21)], 'Q')
    g.arco(cx, 9.6, 3.4, 4.2, 30, 150, 'A')
    g.arco(cx, 6.4, 5.0, 5.8, 40, 140, 'A')
    g.rect(cx - 1, 22, cx + 1, 23, 'G'); g.pon(cx, 22, 'J')
    for y in (28, 34):
        g.rect(cx - 1, y, cx + 1, y, 'G')
    g.rect(cx - 1, 48, cx + 1, 49, 'G')
    return g


@diseno('cam', 'guadana')
def _():
    # ala de murciélago: brazo que brilla arriba, dedos de oro y membrana carmesí con festones hondos
    g = Lienzo(31, 35); mx = 6
    g.mango(mx - 1, mx + 1, 18, 30, 24, cada=4)
    g.rect(mx - 2, 17, mx + 2, 17, 'G'); g.rect(mx - 2, 31, mx + 2, 31, 'G'); g.rect(mx - 1, 32, mx + 1, 33, 'G'); g.pon(mx, 34, 'J')
    muneca = (9, 6)
    puntas = [(29.6, 13.6), (23.6, 16), (16.4, 16.4), (9.4, 16)]
    hondos = [(24.6, 8.6), (19.4, 9.8), (12.6, 10.4)]
    contorno = [(4.6, 16), (4.8, 10), (7, 5), (11.4, 2), (17, 0.6), (22.4, 1.2), (26.4, 4), (28.6, 8.6), puntas[0], hondos[0], puntas[1], hondos[1], puntas[2], hondos[2], puntas[3], (8.4, 16)]
    g.poligono(contorno, 'Q')
    g.trazo([(5.6, 15.6), (6, 9), (9, 4.2), (14, 1.8), (20, 1.4), (25.6, 3.6), (28.4, 8)], 'B', 1.1, 0.6)
    for p in puntas:
        g.linea(muneca[0], muneca[1], p[0], p[1], 'G', 0.45)
    g.disco(muneca[0], muneca[1], 1.2, 'J')
    return g


@diseno('cam', 'martillo')
def _():
    # tambor de guerra con parche de hueso, cordaje de oro y orejas de murciélago
    g = Lienzo(21, 37); cx = 10
    g.mango(cx - 1, cx + 1, 16, 33, 29, cada=4)
    g.poligono([(2.6, 3), (17.4, 3), (19.4, 8.4), (17.4, 14), (2.6, 14), (0.6, 8.4)], 'H')
    g.rect(3, 2, 17, 3, 'W')
    for x0 in range(3, 17, 3):                                  # cordaje en zigzag
        g.linea(x0, 4.4, x0 + 1.5, 12.6, 'g', 0.4)
        g.linea(x0 + 1.5, 12.6, x0 + 3, 4.4, 'g', 0.4)
    g.rect(2, 14, 18, 14, 'G'); g.rect(2, 4, 18, 4, 'G')
    for s in (-1, 1):
        g.poligono([(cx + s * 4, 2), (cx + s * 5.6, -0.4), (cx + s * 7.2, 2)], 'H')
    g.disco(cx, 8.6, 1.4, 'J')
    g.rect(cx - 2, 34, cx + 2, 35, 'G'); g.pon(cx, 36, 'J')
    return g


@diseno('cam', 'blaster')
def _():
    # cabeza de murciélago en la boca: orejas grandes, ojos rojos y alas plegadas
    g = Lienzo(17, 23); cx = 8
    g.poligono([(4.4, 7.4), (3.4, 3.4), (4.6, 0.2), (6.4, 3.4), (9.6, 3.4), (11.4, 0.2), (12.6, 3.4), (11.6, 7.4), (9.6, 9), (6.4, 9)], 'X')
    g.pon(6, 5, 'A'); g.pon(10, 5, 'A')
    g.rect(7, 7, 9, 7, 'C')
    for s in (-1, 1):
        g.poligono([(cx + s * 3.6, 9.4), (cx + s * 7.6, 8.6), (cx + s * 7, 10.6), (cx + s * 7.8, 12.4), (cx + s * 4, 13)], 'S')
    g.rect(4, 9, 12, 14, 'X'); g.rect(4, 12, 12, 12, 'G'); g.pon(cx, 10.6, 'J')
    culata_blaster(g, 10, 12, 15, 21, 18)
    return g


@diseno('cam', 'guantelete')
def _():
    # tres garras largas en gancho y membranas carmesí a los lados
    g = Lienzo(15, 18); cx = 7
    g.poligono([(2, 6), (3, 5), (11, 5), (12, 6), (12, 12.4), (2, 12.4)], 'X')
    for x in (3.4, 7, 10.6):
        g.hoja([(x, 6), (x - 0.6, 3.4), (x + 0.4, 1), (x + 1.8, 0.2)], [1.3, 1.0, 0.6, 0.3], 'W')
    g.poligono([(2, 5.6), (0, 7), (1, 8.6), (0, 10.4), (2, 12)], 'Q')
    g.poligono([(12, 5.6), (14, 7), (13, 8.6), (14, 10.4), (12, 12)], 'Q')
    g.rect(3, 12, 11, 16, 'X'); g.rect(3, 14, 11, 14, 'G')
    g.pon(cx, 9.6, 'J')
    g.pon(cx, 7.6, '@')
    return g


# =====================================================================
# XOLOTL · ajolote de la tormenta (azul noche, amarillo rayo, celeste y rosa)
# =====================================================================
@diseno('xol', 'espada')
def _():
    # macuahuitl: pala plana con navajas de obsidiana en los dos filos y un rayo en el centro
    g = Lienzo(21, 36); cx = 10
    g.poligono([(7, 1.4), (8.4, 0.2), (11.6, 0.2), (13, 1.4), (13.4, 22), (6.6, 22)], 'B')
    for y in range(2, 21, 4):
        g.rect(4, y, 5, y + 1, 'X'); g.rect(15, y, 16, y + 1, 'X')
    g.trazo([(10, 3), (8.6, 7), (11.4, 10.4), (8.6, 14), (11.4, 17.4), (10, 20)], 'C', 0.55, suave=False)
    g.rect(5, 22, 15, 24, 'G')
    g.arco(7.6, 23, 0.8, 1.7, 0, 360, 'g'); g.arco(12.4, 23, 0.8, 1.7, 0, 360, 'g')
    g.pon(7.6, 23, 'J'); g.pon(12.4, 23, 'J')
    g.mango(cx - 1, cx + 1, 25, 30, 28)
    for dx in (-2, 0, 2):                                       # branquias en el pomo
        g.linea(cx, 31, cx + dx * 1.4, 34.6, 'A', 0.5)
    return g


@diseno('xol', 'lanza')
def _():
    # dardo de atlatl: punta en forma de rayo y plumas de branquia rosadas
    g = Lienzo(19, 50); cx = 9
    g.mango(cx, cx, 21, 47, 38, cada=5)
    g.poligono([(10, 0), (14.6, 7), (11.2, 7), (14, 13.4), (10.4, 13.4), (11, 19.6), (5.0, 10.4), (8.6, 10.4), (5.4, 4.6)], 'B')
    g.trazo([(9.8, 3), (11, 7), (9.6, 10.8), (10.4, 15.4)], 'C', 0.5, suave=False)
    for s in (-1, 1):
        for k, (dy, largo) in enumerate([(0, 6.4), (2, 7.4), (4, 6.0)]):
            y = 21 + dy
            g.trazo([(cx + s * 0.8, y), (cx + s * largo * 0.55, y - 1.4), (cx + s * largo, y - 3.6 + k * 0.6)], 'A', 0.6, 0.4)
    g.rect(cx - 1, 20, cx + 1, 22, 'G')
    g.poligono([(cx, 44), (cx + 3.4, 45), (cx + 3.4, 47.4), (cx + 1, 46.4), (cx, 49)], 'G')
    return g


@diseno('xol', 'guadana')
def _():
    # abanico de tres branquias rosadas (con el borde que brilla) y sus filamentos
    from lienzo import curva
    g = Lienzo(31, 35); mx = 6
    g.mango(mx - 1, mx + 1, 18, 30, 24, cada=4)
    g.rect(mx - 2, 17, mx + 2, 17, 'G'); g.rect(mx - 2, 31, mx + 2, 31, 'G'); g.rect(mx - 1, 32, mx + 1, 33, 'G'); g.pon(mx, 34, 'J')
    frondas = [
        ([(6.4, 15), (8, 8), (13, 3.4), (20, 2), (27.6, 5)], 2.6, 0.7, -1),
        ([(7, 15), (11, 10.6), (17, 8.8), (23.4, 9.8), (27.4, 13)], 2.2, 0.6, -1),
        ([(7.4, 15.6), (12, 14.4), (17, 14.6), (21.4, 17)], 1.9, 0.5, 1),
    ]
    for camino, r0, r1, _l in frondas:
        g.trazo(camino, 'Q', r0, r1)
    for camino, r0, r1, lado in frondas:
        pts = curva(camino, 10)
        for i in range(7, len(pts) - 4, 7):
            (x0, y0), (x1, y1) = pts[i - 1], pts[i + 1]
            dx, dy = x1 - x0, y1 - y0
            n = math.hypot(dx, dy) or 1
            nx, ny = dy / n * lado, -dx / n * lado
            px, py = pts[i]
            t = i / len(pts)
            r = r0 + (r1 - r0) * t
            g.linea(px + nx * (r - 0.2), py + ny * (r - 0.2), px + nx * (r + 2.4) + dx / n * 1.2, py + ny * (r + 2.4) + dy / n * 1.2, 'A', 0.45)
    for camino, _a, _b, _l in frondas:
        g.trazo(camino[:3], 'C', 0.4)
    g.disco(mx + 0.6, 15, 1.9, 'G'); g.pon(mx + 0.6, 15, 'J')
    return g


@diseno('xol', 'martillo')
def _():
    # máscara de Tláloc: anteojeras, bigote enroscado, colmillos y penacho
    g = Lienzo(23, 39); cx = 11
    g.mango(cx - 1, cx + 1, 18, 35, 31, cada=4)
    g.rect(1, 2, 21, 15, 'H')
    for x in (3, 7, 15, 19):                                    # penacho
        g.poligono([(x - 1, 2), (x, -0.4 + (1 if x in (7, 15) else 0)), (x + 1, 2)], 'A')
    for s in (-1, 1):
        g.arco(cx + s * 5, 7, 1.6, 3.2, 0, 360, 'g')
        g.disco(cx + s * 5, 7, 1.0, 'J')
    g.trazo([(3.4, 11.6), (7, 12.4), (cx, 11), (15, 12.4), (18.6, 11.6)], 'G', 0.75)
    g.disco(3.4, 11, 1.0, 'G'); g.disco(18.6, 11, 1.0, 'G')
    for x in (8, 14):
        g.poligono([(x - 1, 14), (x, 18), (x + 1, 14)], 'W')
    g.rect(cx - 2, 16, cx + 2, 17, 'G')
    g.rect(cx - 2, 36, cx + 2, 37, 'G'); g.pon(cx, 38, 'J')
    return g


@diseno('xol', 'blaster')
def _():
    # nube de tormenta con un rayo por cañón y gotas de lluvia
    g = Lienzo(17, 23); cx = 8
    g.poligono([(9.4, 0), (12.4, 3.6), (10.2, 3.6), (12, 7.4), (6.2, 3), (8.6, 3), (6.8, 0.4)], 'C')
    for (x, y, r) in [(4.4, 10.4, 2.6), (8, 8.6, 3.2), (11.6, 10.2, 2.6)]:
        g.disco(x, y, r, 'X')
    g.rect(2, 10, 14, 13, 'X')
    g.rect(2, 13, 14, 13, 'G')
    for (x, y) in [(3.4, 14.6), (5.8, 15.6), (8, 14.6)]:
        g.pon(x, y, 'A'); g.pon(x, y + 1, 'A')
    g.rect(cx - 1, 10, cx + 1, 11, 'J')
    culata_blaster(g, 10, 12, 14, 21, 18)
    return g


@diseno('xol', 'guantelete')
def _():
    # puño de tormenta: tres rayos en los nudillos y branquias rosadas a los lados
    g = Lienzo(15, 18); cx = 7
    g.rect(2, 6, 12, 12, 'X')
    for x in (3.4, 7, 10.6):
        g.poligono([(x - 0.6, 6.2), (x + 1.4, 3.2), (x - 0.1, 3.2), (x + 0.9, 0), (x - 1.6, 3.8), (x, 3.8), (x - 1.6, 6.2)], 'C')
    for s in (-1, 1):
        for k in range(3):
            g.linea(cx + s * 5.4, 7 + k * 2, cx + s * 7.4, 5.6 + k * 2, 'A', 0.5)
    g.rect(3, 12, 11, 16, 'X'); g.rect(3, 14, 11, 14, 'G')
    g.disco(cx, 9.4, 1.3, 'G'); g.pon(cx, 9.4, 'J')
    g.pon(cx, 7, '@')
    return g


# =====================================================================
# BALAM · jaguar de obsidiana (negro, violeta, jade y oro)
# =====================================================================
@diseno('bal', 'espada')
def _():
    # hoja de obsidiana tallada a golpes: forma de hoja con el filo mellado y facetas
    g = Lienzo(21, 37); cx = 10
    g.poligono([(10, 0), (12, 3), (13.4, 4), (13.6, 7), (14.8, 8.4), (14.2, 11), (15.2, 13), (14.2, 16), (14.8, 18.4), (13, 22.4), (7, 22.4), (5.2, 18.4), (5.8, 16), (4.8, 13), (5.8, 11), (5.2, 8.4), (6.4, 7), (6.6, 4), (8, 3)], 'B')
    for (a, b) in [((8, 6), (10.4, 9.4)), ((12.2, 8.6), (10, 12)), ((7.8, 13.6), (10.2, 16.6)), ((12.2, 16), (10.2, 19.4))]:
        g.linea(a[0], a[1], b[0], b[1], 'C', 0.45)
    g.rect(cx - 5, 22, cx + 5, 24, 'G')                         # cabeza de jaguar en la guarda
    g.rect(cx - 5, 21, cx - 4, 21, 'G'); g.rect(cx + 4, 21, cx + 5, 21, 'G')
    g.pon(cx - 2, 23, 'J'); g.pon(cx + 2, 23, 'J')
    g.rect(cx - 1, 25, cx + 1, 25, 'W')
    g.mango(cx - 1, cx + 1, 26, 31, 29)
    g.disco(cx, 33.4, 1.7, 'S'); g.pon(cx, 33.4, 'J')
    return g


@diseno('bal', 'lanza')
def _():
    # punta ancha de obsidiana, cuna de luna menguante y borla de cola de jaguar con manchas
    g = Lienzo(19, 50); cx = 9
    g.mango(cx, cx, 21, 47, 38, cada=6)
    g.poligono([(cx, 0.2), (11, 3), (12.4, 7), (12.8, 11), (11.6, 15), (cx + 0.6, 19), (cx - 0.6, 19), (6.4, 15), (5.2, 11), (5.6, 7), (7, 3)], 'B')
    for (y, s) in [(6, 1), (10, -1), (13.6, 1)]:                 # muescas del tallado
        g.pon(cx + s * 3.6, y, '.')
    g.trazo([(cx, 16), (cx, 3)], 'C', 0.5)
    g.arco(cx, 18, 3.0, 4.4, 195, 345, 'g')
    g.rect(cx - 1, 19, cx + 1, 21, 'G'); g.pon(cx, 20, 'J')
    g.trazo([(cx + 1, 22), (cx + 3.4, 25.4), (cx + 4.2, 30), (cx + 3, 34)], 'G', 1.0, 0.7)
    for (x, y) in [(cx + 2.6, 24.6), (cx + 3.8, 28), (cx + 3.6, 31.6)]:
        g.pon(x, y, 'S')
    g.rect(cx - 1, 48, cx + 1, 49, 'G')
    return g


@diseno('bal', 'guadana')
def _():
    # tres garras curvas de jaguar que salen de una barra de oro
    g = Lienzo(31, 35); mx = 6
    g.mango(mx - 1, mx + 1, 19, 30, 25, cada=4)
    g.rect(mx - 2, 31, mx + 2, 31, 'G'); g.rect(mx - 1, 32, mx + 1, 33, 'G'); g.pon(mx, 34, 'J')
    garras = [
        ([(6.4, 15), (8.6, 8), (13.6, 3.2), (20.4, 1.2), (26, 2.8)], [1.7, 1.8, 1.6, 1.0, 0.3]),
        ([(8, 16), (11, 11.2), (16, 7.8), (22, 7.2), (26.6, 9.2)], [1.6, 1.7, 1.4, 0.9, 0.3]),
        ([(9.4, 17.4), (13, 14.6), (18, 12.8), (23, 13.6), (25.6, 15.6)], [1.5, 1.5, 1.2, 0.7, 0.3]),
    ]
    for camino, anchos in garras:
        g.hoja(camino, anchos, 'B')
    for camino, _a in garras:
        g.trazo(camino[1:4], 'C', 0.4)
    g.trazo([(5, 15.4), (8, 16.6), (10.4, 18.4)], 'G', 1.2)
    g.pon(7.4, 16.6, 'J')
    return g


@diseno('bal', 'martillo')
def _():
    # cabeza de jaguar de frente: orejas, ojos de jade, colmillos y rosetas
    g = Lienzo(21, 38); cx = 10
    g.mango(cx - 1, cx + 1, 18, 34, 30, cada=4)
    g.poligono([(2.4, 4), (5.6, 1.6), (cx + 0.6, 1.2), (cx + 0.6, 15.4), (6.4, 15.4), (2.6, 12.8), (0.6, 8)], 'H')
    g.poligono([(2.4, 4.6), (2.6, 0), (5.6, 2)], 'H')
    g.rect(5, 6, 7, 6, 'J'); g.pon(6, 5, 'J')
    g.arco(4, 11, 0.4, 1.3, 0, 360, 'A')
    g.pon(7, 3.4, 'A'); g.pon(3, 7.6, 'A')
    g.espejo(cx)
    g.poligono([(cx - 1.6, 8.8), (cx + 1.6, 8.8), (cx, 10.9)], 'G')
    for x in (7.4, 12.6):
        g.poligono([(x - 0.9, 13), (x, 17.4), (x + 0.9, 13)], 'W')
    g.rect(cx - 2, 35, cx + 2, 36, 'G'); g.pon(cx, 37, 'J')
    return g


@diseno('bal', 'blaster')
def _():
    # racimo de cristales de jade como cañones, con garra de oro que los sujeta
    g = Lienzo(17, 23); cx = 8
    g.poligono([(cx, 0), (cx + 1.8, 1.8), (cx + 1.8, 11), (cx - 1.8, 11), (cx - 1.8, 1.8)], 'A')
    g.linea(cx, 1.4, cx, 10, 'S', 0.4)
    for s in (-1, 1):
        g.poligono([(cx + s * 2.2, 9), (cx + s * 5.4, 2.4), (cx + s * 6.6, 3.2), (cx + s * 4, 10)], 'A')
    g.rect(3, 10, 13, 15, 'X')
    for x in (4, 7, 10):
        g.poligono([(x, 10), (x + 1, 8.4), (x + 2, 10)], 'G')
    g.rect(3, 15, 13, 15, 'G')
    culata_blaster(g, 10, 12, 16, 21, 19)
    return g


@diseno('bal', 'guantelete')
def _():
    # zarpas de obsidiana: cuatro hojas curvas que salen de los nudillos y rosetas de jade
    g = Lienzo(15, 18); cx = 7
    g.poligono([(1.6, 6.4), (3, 5), (11, 5), (12.4, 6.4), (12.4, 12.4), (1.6, 12.4)], 'X')
    for x in (2.6, 5.6, 8.6, 11.4):
        g.hoja([(x, 6), (x + 0.2, 2.6), (x + 1.3, 0)], [1.2, 0.9, 0.3], 'B')
    g.arco(4.6, 9.4, 0.5, 1.4, 0, 360, 'A'); g.arco(9.6, 10.4, 0.5, 1.4, 0, 360, 'A')
    g.rect(2, 12, 12, 16, 'X'); g.rect(2, 13, 12, 13, 'G'); g.rect(2, 15, 12, 15, 'G')
    g.pon(cx, 14, 'J')
    g.pon(cx, 8, '@')
    return g


# =====================================================================
# CIPACTLI · caimán de la creación (verde oscuro, turquesa, marfil y naranja)
# =====================================================================
@diseno('cip', 'espada')
def _():
    # hoja dentada como el hocico del pez sierra: dientes de marfil en los dos filos
    g = Lienzo(21, 37); cx = 10
    g.poligono([(8.4, 1.2), (10, 0), (11.6, 1.2), (12.2, 22.4), (7.8, 22.4)], 'B')
    for y in range(3, 21, 3):
        g.poligono([(8, y), (5.6, y - 1.2), (8, y + 1.4)], 'W')
        g.poligono([(12, y), (14.4, y - 1.2), (12, y + 1.4)], 'W')
    g.trazo([(10, 3), (10, 20)], 'C', 0.5)
    g.rect(cx - 6, 22, cx + 6, 24, 'G')                         # guarda: mandíbulas
    for x in range(cx - 6, cx + 7, 2):
        g.pon(x, 21, 'W')
    g.pon(cx - 4, 23, 'J'); g.pon(cx + 4, 23, 'J')
    g.mango(cx - 1, cx + 1, 25, 30, 28)
    g.disco(cx, 32.4, 1.7, 'G'); g.pon(cx, 32.4, 'J')
    return g


@diseno('cip', 'lanza')
def _():
    # arpón: punta de flecha grande, dos pares de púas hacia atrás y cuerda enrollada
    g = Lienzo(19, 50); cx = 9
    g.mango(cx, cx, 11, 47, 38, cada=6)
    g.poligono([(cx, 0), (14.4, 8.6), (11.2, 7.4), (11.2, 11.6), (6.8, 11.6), (6.8, 7.4), (3.6, 8.6)], 'B')
    for y in (14, 19):
        g.poligono([(cx + 0.4, y), (14, y + 4.4), (11, y + 3.6)], 'B')
        g.poligono([(cx - 0.4, y), (4, y + 4.4), (7, y + 3.6)], 'B')
    g.trazo([(cx, 3), (cx, 10)], 'C', 0.5)
    for k in range(6):
        y = 26 + k * 1.6
        g.linea(cx - 1.6, y, cx + 1.6, y + 0.8, 'G', 0.55)
    g.pon(cx, 11, 'J')
    g.rect(cx - 1, 48, cx + 1, 49, 'G')
    return g


@diseno('cip', 'guadana')
def _():
    # fauces abiertas: mandíbula de arriba y de abajo con dientes de marfil, ojo naranja
    g = Lienzo(31, 35); mx = 6
    g.mango(mx - 1, mx + 1, 18, 30, 24, cada=4)
    g.rect(mx - 2, 17, mx + 2, 17, 'G'); g.rect(mx - 2, 31, mx + 2, 31, 'G'); g.rect(mx - 1, 32, mx + 1, 33, 'G'); g.pon(mx, 34, 'J')
    g.hoja([(6, 16), (8, 8.6), (14, 4.4), (21, 3.6), (28, 5.4)], [2.5, 2.7, 2.4, 1.9, 0.8], 'B')
    g.hoja([(7, 16), (12, 13.4), (18, 12.8), (24, 11.6)], [2.1, 1.9, 1.4, 0.6], 'B')
    for x in (12, 15, 18, 21, 24):                              # dientes de arriba
        y = 6.4 + (x - 12) * -0.1
        g.poligono([(x - 0.8, y), (x, y + 2.6), (x + 0.8, y)], 'W')
    for x in (13.4, 16.4, 19.4, 22.2):                          # dientes de abajo
        y = 11.4 - (x - 13) * 0.08
        g.poligono([(x - 0.8, y), (x, y - 2.4), (x + 0.8, y)], 'W')
    g.disco(10, 6.4, 1.0, 'J')
    g.trazo([(7, 13), (9.6, 8), (15, 5), (21, 4.2)], 'C', 0.45)
    return g


@diseno('cip', 'martillo')
def _():
    # maza de cola de caimán: placas del lomo en punta y escamas
    g = Lienzo(23, 38); cx = 11
    g.mango(cx - 1, cx + 1, 16, 34, 30, cada=5)
    g.poligono([(0.6, 5), (21.6, 3.6), (22.4, 9), (21.6, 14), (0.6, 13)], 'H')
    for x in (2.6, 7, 11.4, 15.8, 20):
        g.poligono([(x - 1.6, 4.6 - (x - 1) * 0.06), (x, 0.2), (x + 1.6, 4.2 - (x - 1) * 0.06)], 'H')
    for y in (7, 10):
        for x in range(2, 21, 3):
            g.rect(x, y, x + 1, y, 'S')
    g.trazo([(1.6, 8.6), (21, 8.6)], 'C', 0.4)
    g.rect(cx - 2, 14, cx + 2, 16, 'G'); g.pon(cx, 15, 'J')
    g.rect(cx - 2, 35, cx + 2, 36, 'G'); g.pon(cx, 37, 'J')
    return g


@diseno('cip', 'blaster')
def _():
    # hocico de caimán: el cañón largo con dientes, narinas y ojos naranjas
    g = Lienzo(17, 23); cx = 8
    g.poligono([(6, 0.4), (10, 0.4), (10.8, 10), (5.2, 10)], 'X')
    for y in range(2, 10, 2):
        g.pon(4.6 if y % 4 else 4.8, y + 0.4, 'W'); g.pon(11.4 if y % 4 else 11.2, y + 0.4, 'W')
    g.pon(7, 1, 'J'); g.pon(9, 1, 'J')
    g.rect(3, 10, 13, 15, 'X')
    g.disco(4.4, 10, 1.3, 'X'); g.disco(11.6, 10, 1.3, 'X')
    g.pon(4.4, 10, 'A'); g.pon(11.6, 10, 'A')
    g.rect(3, 13, 13, 13, 'G')
    culata_blaster(g, 10, 12, 16, 21, 19)
    return g


@diseno('cip', 'guantelete')
def _():
    # fauces del caimán: dos mandíbulas en U con dientes hacia adentro y el puño en la garganta
    g = Lienzo(15, 18); cx = 7
    g.hoja([(3, 12), (2.2, 6.4), (2.6, 2.4), (4, 0.4)], [2.4, 2.2, 1.6, 0.8], 'X')
    g.hoja([(11, 12), (11.8, 6.4), (11.4, 2.4), (10, 0.4)], [2.4, 2.2, 1.6, 0.8], 'X')
    for y in (2.6, 4.8, 7, 9.2):
        g.poligono([(4.4, y), (6.4, y + 0.7), (4.4, y + 1.4)], 'W')
        g.poligono([(9.6, y), (7.6, y + 0.7), (9.6, y + 1.4)], 'W')
    g.rect(1, 10, 13, 13, 'X')
    g.disco(2.4, 10.4, 0.9, 'J'); g.disco(11.6, 10.4, 0.9, 'J')
    g.rect(5, 10, 9, 10, 'A')
    g.rect(2, 13, 12, 17, 'X')
    for y in (14, 16):
        for x in range(2 + (y % 4 == 0), 13, 2):
            g.pon(x, y, 'S')
    g.pon(cx, 11, '@')
    return g


