"""Cut out AI emblems; preserve original art and prompts beside the exports."""
from pathlib import Path
from collections import deque
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parents[1]
keys=['title_night_owl','title_early_bird','title_ice_guardian','title_flame_keeper','title_ocean_soul','title_crowned','badge_streak','badge_sessions','badge_hours']
preview=Image.new('RGB',(1200,800),'#FAF7F3')
font=ImageFont.truetype(str(root/'assets/fonts/Inter-600.ttf'),16)
for idx,key in enumerate(keys):
    folder=root/'design/frames_ai'/key;binary=folder/(key+'-ai-output.bin')
    if not binary.exists():continue
    im=Image.open(binary).convert('RGBA');im.save(folder/'original.png')
    w,h=im.size;px=im.load();seen=bytearray(w*h);todo=deque()
    background=[]
    for y in range(h):
        samples=[px[x,y][:3] for x in [0,1,2,w-3,w-2,w-1]]
        background.append(tuple(sorted(c[k] for c in samples)[3] for k in range(3)))
    def add(x,y):
        i=y*w+x
        if seen[i]:return
        seen[i]=1
        r,g,b,_=px[x,y]
        distance=sum((v-c)**2 for v,c in zip((r,g,b),background[y]))**.5
        if (min(r,g,b)>207 and max(r,g,b)-min(r,g,b)<38) or distance<58:todo.append((x,y))
    for x in range(w):add(x,0);add(x,h-1)
    for y in range(h):add(0,y);add(w-1,y)
    while todo:
        x,y=todo.popleft();r,g,b,_=px[x,y];px[x,y]=(r,g,b,0)
        if x:add(x-1,y)
        if x<w-1:add(x+1,y)
        if y:add(x,y-1)
        if y<h-1:add(x,y+1)
    bbox=im.getbbox()
    if not bbox:raise ValueError(key+' has no artwork')
    im=im.crop(bbox);im.thumbnail((900,900),Image.Resampling.LANCZOS)
    canvas=Image.new('RGBA',(1024,1024));canvas.alpha_composite(im,((1024-im.width)//2,(1024-im.height)//2))
    canvas.save(folder/'transparent.png')
    dest=root/'assets/cosmetics'/(key+'.png')
    if dest.exists() and not (folder/'previous.png').exists():(folder/'previous.png').write_bytes(dest.read_bytes())
    canvas.resize((512,512),Image.Resampling.LANCZOS).save(dest)
    x=idx%5*240;y=idx//5*390
    tile=canvas.resize((230,300),Image.Resampling.LANCZOS)
    # Preserve the square aspect ratio in the contact sheet.
    tile=canvas.resize((230,230),Image.Resampling.LANCZOS)
    preview.paste(tile,(x+5,y+35),tile)
    ImageDraw.Draw(preview).text((x+120,y+280),key,font=font,fill='#76695F',anchor='mt')
    print(key,'prepared')
preview.save(root/'docs/screenshots/emblems-ai-redesign.png')
