# Cuenta cuántas piezas (Parts) usa un arma en el juego, igual que cliente > ArmasPixel.
from collections import deque
def contar(filas, paleta):
    H, W = len(filas), len(filas[0])
    L = lambda x, y: filas[y][x] if 0 <= x < W and 0 <= y < H else '.'
    dist = [[0]*W for _ in range(H)]; q = deque()
    for y in range(H):
        for x in range(W):
            if L(x,y) != '.' and any(L(x+dx,y+dy)=='.' for dx in (-1,0,1) for dy in (-1,0,1) if dx or dy):
                dist[y][x]=1; q.append((x,y))
    while q:
        x,y=q.popleft()
        for dx in (-1,0,1):
            for dy in (-1,0,1):
                nx,ny=x+dx,y+dy
                if L(nx,ny)!='.' and dist[ny][nx]==0:
                    dist[ny][nx]=dist[y][x]+1; q.append((nx,ny))
    def pal(l): return paleta['e' if l=='@' else l]
    prof=[[0]*W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            l=L(x,y)
            if l!='.':
                c=pal(l); prof[y][x]=max(1,min(c[3]*2-1,2*dist[y][x]-1))
    def modo(l): return 'borde' if l=='k' else ('sale' if l in ('c','J') else None)
    def gro(x,y):
        l=L(x,y); m=modo('M' if l=='@' else l)
        if m=='borde': return 1
        if m=='sale':
            v=1
            for dy in (-1,0,1):
                for dx in (-1,0,1):
                    if 0<=y+dy<H and 0<=x+dx<W: v=max(v,prof[y+dy][x+dx])
            return min(v+2,7)
        return prof[y][x]
    n=0
    for y in range(H):
        x=0
        while x<W:
            l=L(x,y)
            if l=='.': x+=1; continue
            g=gro(x,y); fin=x
            while fin+1<W and L(fin+1,y)!='.' and pal(L(fin+1,y))==pal(l) and gro(fin+1,y)==g: fin+=1
            n+=1; x=fin+1
    return n
