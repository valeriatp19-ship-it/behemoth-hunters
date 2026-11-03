# Lámina de las armas nuevas (armas2): una fila por Behemoth, una columna por tipo de arma.
# uso: python3 ver_armas2.py salida.png [familias separadas por coma] [ancho_celda] [alto_celda]
import os, sys, importlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw, ImageFont
from visor import render
from ver_armas import cajas
import lienzo
import armas2

FB = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
FR = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'

def piezas(filas, paleta):
    from contar import contar
    return contar(filas, paleta)

def celda(fam, tipo, ancho, alto, fondo=(16, 18, 26), yaw=-22, pitch=8):
    d = armas2.arma(fam, tipo)
    filas, paleta = lienzo.colorear(d['lienzo'], fam)
    cj = cajas(filas, paleta, d['pixel'], d['plano'])
    im, _ = render(cj, ancho, alto, yaw=(yaw + 100 if d['plano'] == 'ZY' else yaw), pitch=pitch, fondo=fondo, bloom=0.7)
    return im, d, filas, paleta

def lamina(salida, familias, ancho=210, alto=330):
    f1 = ImageFont.truetype(FB, 13); f2 = ImageFont.truetype(FR, 11)
    hoja = Image.new('RGB', (ancho * 6, (alto + 34) * len(familias)), (10, 12, 18))
    d0 = ImageDraw.Draw(hoja)
    for i, fam in enumerate(familias):
        for j, tipo in enumerate(armas2.TIPOS):
            im, d, filas, paleta = celda(fam, tipo, ancho, alto)
            x, y = j * ancho, i * (alto + 34)
            hoja.paste(im, (x, y))
            d0.text((x + 6, y + alto + 2), d['nombre'], fill=(255, 214, 120), font=f1)
            n = piezas(filas, paleta)
            d0.text((x + 6, y + alto + 18), f"{len(filas[0])}x{len(filas)}  {n} piezas", fill=(160, 166, 180), font=f2)
    hoja.save(salida)

if __name__ == '__main__':
    fams = sys.argv[2].split(',') if len(sys.argv) > 2 else list(armas2.NOMBRES)
    a = int(sys.argv[3]) if len(sys.argv) > 3 else 210
    h = int(sys.argv[4]) if len(sys.argv) > 4 else 330
    lamina(sys.argv[1], fams, a, h)
