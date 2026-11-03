# Arma las armas en 3D igual que el juego (cliente > ArmasPixel) y las dibuja con el visor.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from collections import deque
from visor import render
from PIL import Image
def cajas(filas, paleta, px=0.2, plano='XY'):
    H, W = len(filas), len(filas[0])
    letra = lambda x, y: filas[y][x] if 0 <= x < W and 0 <= y < H else '.'
    dist = [[0] * W for _ in range(H)]; q = deque()
    for y in range(H):
        for x in range(W):
            if letra(x, y) != '.' and any(letra(x + dx, y + dy) == '.' for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy):
                dist[y][x] = 1; q.append((x, y))
    while q:
        x, y = q.popleft()
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                nx, ny = x + dx, y + dy
                if letra(nx, ny) != '.' and dist[ny][nx] == 0:
                    dist[ny][nx] = dist[y][x] + 1; q.append((nx, ny))
    out = []
    for y in range(H):
        for x in range(W):
            l = letra(x, y)
            if l == '.': continue
            c = paleta['e' if l == '@' else l]
            if l == 'k':
                gro = 1
            else:
                gro = max(1, min(c[3] * 2 - 1, 2 * dist[y][x] - 1))
                if l in ('c', 'J'):
                    vec = max([max(1, min(paleta.get(letra(x+dx, y+dy), (0,0,0,1))[3] * 2 - 1, 2 * dist[y+dy][x+dx] - 1)) if letra(x+dx, y+dy) not in ('.', '@') else 1
                               for dx in (-1, 0, 1) for dy in (-1, 0, 1) if 0 <= x+dx < W and 0 <= y+dy < H])
                    gro = min(vec + 2, 7)
            if plano == 'XY':
                out.append((x * px, -y * px, 0, px, px, gro * px, c[:3], c[4]))
            else:
                out.append((0, -y * px, -x * px, gro * px, px, px, c[:3], c[4]))
    return out
def lamina(armas, salida, alto=360, yaw=-30):
    ims = []
    for (filas, paleta, px, plano, nombre) in armas:
        cj = cajas(filas, paleta, px, plano)
        im, _ = render(cj, 190, alto, yaw=(yaw + 90 if plano == 'ZY' else yaw), pitch=10, bloom=0.7)
        ims.append(im)
    W = sum(i.width for i in ims); hoja = Image.new('RGB', (W, alto), (14, 16, 24)); x = 0
    for i in ims:
        hoja.paste(i, (x, 0)); x += i.width
    hoja.save(salida)
