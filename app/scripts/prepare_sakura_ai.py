"""Extract the connected neutral background from the approved AI concept."""
from pathlib import Path
from collections import deque
from PIL import Image, ImageDraw, ImageFilter

root=Path(__file__).resolve().parents[1]
source=root/'design/sakura_ai/sakura-ai-original.png'
im=Image.open(source).convert('RGBA')
w,h=im.size
px=im.load();seen=bytearray(w*h);todo=deque()
def add(x,y):
    i=y*w+x
    if seen[i]:return
    seen[i]=1
    r,g,b,_=px[x,y]
    if min(r,g,b)>210 and max(r,g,b)-min(r,g,b)<34:todo.append((x,y))
for x in range(w):add(x,0);add(x,h-1)
for y in range(h):add(0,y);add(w-1,y)
add(w//2,h//2)
while todo:
    x,y=todo.popleft();r,g,b,_=px[x,y];px[x,y]=(r,g,b,0)
    if x:add(x-1,y)
    if x<w-1:add(x+1,y)
    if y:add(x,y-1)
    if y<h-1:add(x,y+1)
# Match the existing avatar overlay dimensions; retain all petals within canvas.
canvas=Image.new('RGBA',(1024,1024))
im=im.resize((840,840),Image.Resampling.LANCZOS)
canvas.alpha_composite(im,(92,92))
canvas.save(root/'design/sakura_ai/sakura-ai-transparent.png')
canvas.resize((768,768),Image.Resampling.LANCZOS).save(root/'assets/cosmetics/frame_sakura.png')
assert canvas.getpixel((512,512))[3]==0
preview=Image.new('RGB',(1000,500),'#f3f1ee')
d=ImageDraw.Draw(preview);d.rectangle((500,0,1000,500),fill='#24202d')
for x in [0,500]:
    d.ellipse((x+95,95,x+405,405),fill='#f3d6c8')
    overlay=canvas.resize((500,500),Image.Resampling.LANCZOS);preview.paste(overlay,(x,0),overlay)
preview.save(root/'docs/screenshots/sakura-ai-integrated.png')
print('Transparent AI artwork installed')
