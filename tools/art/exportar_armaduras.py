import os, sys, importlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))  # raíz del repositorio
PARTES_ORD = ['Head', 'Torso', 'Right Arm', 'Left Arm', 'Right Leg', 'Left Leg']
SETS = {'sekhmaur': 'guardian', 'kheprak': 'rodador', 'amaru': 'eclipse', 'apu': 'apu', 'xibalba': 'xibalba', 'tlaloc': 'tlaloc', 'jaguar': 'jaguar', 'cipactli': 'cipactli'}
L = ['--!nonstrict', '-- Armaduras de cuerpo completo siguiendo la imagen de referencia de los cuatro sets:',
     '-- formas de placas (casco, hombreras, peto, faldones, botas) en cubitos de 0,2 studs, con sus zonas',
     '-- de color y de brillo. Bloque = { parte, x, y, z, ancho, alto, fondo, color } en studs, relativo al',
     '-- centro de esa parte del cuerpo (el frente es -Z). "colores" = { r, g, b, brilla }.',
     '-- Las construye cada jugador (cliente > ArmadurasPixel), que además oculta el cuerpo que queda debajo.', '',
     'local ArteArmaduras = {}', 'ArteArmaduras.PARTES = { ' + ', '.join(f'"{p}"' for p in PARTES_ORD) + ' }']
sets = {}; datos = []; total = 0
for modulo, set_ in SETS.items():
    m = importlib.import_module(modulo)
    bl = m.armar()
    for id_, bloques in bl.items():
        sets[id_] = set_
        cols = []; idx = {}
        for b in bloques:
            c = b[7]
            if c not in idx:
                idx[c] = len(cols) + 1
                cols.append('{ %d, %d, %d, %s }' % (c[0], c[1], c[2], 'true' if c[3] else 'false'))
        datos.append(f'\t{id_} = {{'); datos.append('\t\tcolores = { ' + ', '.join(cols) + ' },'); datos.append('\t\tbloques = {')
        filas = ['{ %d, %s, %s, %s, %s, %s, %s, %d }' % (PARTES_ORD.index(p) + 1, x, y, z, sx, sy, sz, idx[c]) for (p, x, y, z, sx, sy, sz, c) in bloques]
        for i in range(0, len(filas), 5):
            datos.append('\t\t\t' + ', '.join(filas[i:i + 5]) + ',')
        datos.append('\t\t},'); datos.append('\t},'); total += len(bloques)
L.append('ArteArmaduras.SET = { ' + ', '.join(f'{k} = "{v}"' for k, v in sets.items()) + ' }')
L.append('ArteArmaduras.DATOS = {'); L += datos; L += ['}', '', 'return ArteArmaduras', '']
open(os.path.join(RAIZ, 'src', 'compartido', 'ArteArmaduras.luau'), 'w').write('\n'.join(L))
print('piezas:', len(sets), '· bloques:', total)
