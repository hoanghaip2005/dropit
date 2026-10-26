"""Prepare original Krita-cloud artwork as transparent avatar overlays."""
from pathlib import Path
from collections import deque
from PIL import Image,ImageDraw,ImageChops,ImageFont
import json

root=Path(__file__).resolve().parents[1]
keys=['frame_leaf','frame_sunset','frame_galaxy','frame_frost','frame_phoenix','frame_tidal','frame_cyber','frame_royal']
labels=['Lá Xanh','Hoàng Hôn','Ngân Hà','Băng Tinh','Hỏa Phượng','Hải Triều','Cơ Giới','Vương Miện']
preview=Image.new('RGB',(1200,660),'#f2efeb')
font=ImageFont.truetype(str(root/'assets/fonts/Inter-600.ttf'),18)
report=[]
for idx,key in enumerate(keys):
    folder=root/'design/frames_ai'/key
    binary=folder/(key+'-ai-output.bin')
    if not binary.exists():continue
    im=Image.open(binary).convert('RGBA');im.save(folder/'original.png')
    w,h=im.size;px=im.load();seen=bytearray(w*h);todo=deque()
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
    # Remove non-white studio backdrops too (some AI outputs use a vertical
    # gradient). Estimate each row from its far left/right margins.
    for y in range(h):
        samples=[px[x,y][:3] for x in [0,1,2,w-3,w-2,w-1]]
        bg=tuple(sorted(c[k] for c in samples)[3] for k in range(3))
        for x in range(w):
            r,g,b,a=px[x,y]
            if not a:continue
            distance=sum((v-c)**2 for v,c in zip((r,g,b),bg))**.5
            if distance<48:px[x,y]=(r,g,b,0)
            elif distance<68:px[x,y]=(r,g,b,int(a*(distance-48)/20))
    # AI may paint scenery in the opening. Reserve a consistent unobstructed
    # face aperture, matching FramedAvatar's existing 62% diameter.
    if key=='frame_royal':
        shifted=Image.new('RGBA',(w,h))
        shifted.alpha_composite(im,(0,-38))
        im=shifted
    opening=Image.new('L',(w,h),255)
    radius=w*(.245 if key=='frame_royal' else .375)
    ImageDraw.Draw(opening).ellipse((w/2-radius,h/2-radius,w/2+radius,h/2+radius),fill=0)
    im.putalpha(ImageChops.multiply(im.getchannel('A'),opening))
    # Discard square decorative borders and background remnants in corners.
    outer=Image.new('L',(w,h),0)
    ImageDraw.Draw(outer).ellipse((w*.015,h*.015,w*.985,h*.985),fill=255)
    im.putalpha(ImageChops.multiply(im.getchannel('A'),outer))
    canvas=Image.new('RGBA',(1024,1024))
    im=im.resize((840,840),Image.Resampling.LANCZOS);canvas.alpha_composite(im,(92,92))
    assert canvas.getpixel((512,512))[3]==0, f'{key}: center not clear'
    canvas.save(folder/'transparent.png')
    runtime=root/'assets/cosmetics'/(key+'.png')
    backup=folder/'previous.png'
    if not backup.exists() and runtime.exists():backup.write_bytes(runtime.read_bytes())
    canvas.resize((768,768),Image.Resampling.LANCZOS).save(runtime)
    x=(idx%4)*300;y=(idx//4)*330
    tile=Image.new('RGBA',(300,300));d=ImageDraw.Draw(tile)
    inset=90 if key=='frame_royal' else 57
    d.ellipse((inset,inset,300-inset,300-inset),fill='#f5ddcc')
    tile.alpha_composite(canvas.resize((300,300),Image.Resampling.LANCZOS))
    preview.paste(tile,(x,y),tile)
    ImageDraw.Draw(preview).text((x+150,y+301),labels[idx],fill='#493d45',font=font,anchor='mt')
    report.append({'key':key,'size':[768,768],'center_alpha':0,'source':'Krita AI Diffusion Cloud / zavychromaxl_v80'})
    print(key,'prepared')
preview.save(root/'docs/screenshots/frames-ai-redesign.png')
(root/'design/frames_ai/manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
