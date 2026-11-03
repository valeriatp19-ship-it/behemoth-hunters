# Escribe Compartido/ArteArmas.luau: las 6 armas base (sin cambios) y las 48 de los Behemoths, cada una
# con su propio diseño (armas2.py).
import os, sys, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))  # raíz del repositorio
RUTA = os.path.join(RAIZ, 'src', 'compartido', 'ArteArmas.luau')
viejo = open(RUTA).read()
BASE = ['espada', 'guadanas', 'martillo', 'lanza', 'pistolas', 'punos']
def bloque_viejo(id_):
    m = re.search(r'\n\t' + id_ + r' = \{\n.*?\n\t\},\n', viejo, re.S)
    assert m, id_
    t = m.group(0)
    # agrega el "modo" a cada color: k = borde fino; lo que brilla, en relieve
    def modo(mm):
        letra, cuerpo, brilla = mm.group(1), mm.group(2), mm.group(3)
        md = '"borde"' if letra == 'k' else ('"sale"' if brilla == 'true' else 'nil')
        return f'{letra} = {{ {cuerpo}, {brilla}, {md} }}'
    return re.sub(r'(\w) = \{ ([\d, ]+?), (true|false) \}', modo, t)
L = ['--!nonstrict', '-- Armas en pixel art: cada arma es un dibujo (filas de letras) y cada letra un color de su paleta.',
     '-- Cada jugador construye el arma en 3D a partir del dibujo (ver cliente > ArmasPixel).',
     '-- plano "XY": el dibujo va de frente (ancho en X); "ZY": de lado (el frente es -Z).',
     '-- paleta: letra = { r, g, b, grosor, brilla, modo }. modo "borde" = línea fina; "sale" = en relieve.',
     '-- "@" = donde la mano sostiene el arma. Las 48 armas de los Behemoths siguen la imagen de referencia',
     '-- (núcleo oscuro, borde que brilla en degradado y canal central brillante) y cada una tiene su',
     '-- propia forma, inspirada en su bestia (se dibujan con arte/armas2.py).', '',
     'local ArteArmas = {}', 'ArteArmas.DATOS = {']
for id_ in BASE:
    L.append(bloque_viejo(id_).strip('\n'))
import armas2, lienzo
for fam, lista in armas2.NOMBRES.items():
    for tipo in armas2.TIPOS:
        d = armas2.arma(fam, tipo)
        id_, nombre, px, plano = d['id'], d['nombre'], d['pixel'], d['plano']
        filas, paleta = lienzo.colorear(d['lienzo'], fam)
        if tipo == 'martillo':
            for l in ('n', 'N'):
                c = paleta.get(l)
                if c: paleta[l] = (c[0], c[1], c[2], 4, c[4])
        anc = next((f.find('@'), r) for r, f in enumerate(filas) if '@' in f)
        pal = []
        for l, c in sorted(paleta.items()):  # orden fijo: el archivo no cambia si el dibujo no cambia
            md = '"borde"' if l == 'k' else ('"sale"' if l in ('c', 'J') else 'nil')
            pal.append(f'{l} = {{ {c[0]}, {c[1]}, {c[2]}, {c[3]}, {"true" if c[4] else "false"}, {md} }}')
        L.append(f'\t{id_} = {{')
        L.append(f'\t\tnombre = "{nombre}", plano = "{plano}", pixel = {px}, ancla = {{ {anc[0]}, {anc[1]} }},')
        L.append('\t\tpaleta = { ' + ', '.join(pal) + ' },')
        L.append('\t\tfilas = {'); L += [f'\t\t\t"{f}",' for f in filas]; L.append('\t\t},'); L.append('\t},')
L += ['}', '', 'return ArteArmas', '']
open(RUTA, 'w').write('\n'.join(L))
print('ok:', len(BASE) + sum(len(v) for v in armas2.NOMBRES.values()), 'armas')
