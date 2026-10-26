"""Layered 2D raster concept. OpenRaster source opens in Krita; no AI model used."""
from PIL import Image, ImageDraw, ImageFilter
import aggdraw, math, random, io, zipfile
from pathlib import Path
from xml.etree.ElementTree import Element, SubElement, tostring

ROOT=Path(__file__).resolve().parents[1]
S=1024
random.seed(42)
layers=[]
def layer(name):
    im=Image.new('RGBA',(S,S));layers.append((name,im));return im
def path(im,coords,fill,stroke=None,width=1):
    p=aggdraw.Path()
    for op,pts in coords:
        getattr(p,op)(*pts)
    d=aggdraw.Draw(im);d.path(p,aggdraw.Brush(fill) if fill else None,aggdraw.Pen(stroke,width) if stroke else None);d.flush()
def bezier(points,n=70):
    a,b,c,d=points
    return [((1-t)**3*a[0]+3*(1-t)**2*t*b[0]+3*(1-t)*t*t*c[0]+t**3*d[0],(1-t)**3*a[1]+3*(1-t)**2*t*b[1]+3*(1-t)*t*t*c[1]+t**3*d[1]) for t in [i/n for i in range(n+1)]]

metal=layer('01 • Champagne filigree')
d=ImageDraw.Draw(metal)
for r,w,col in [(351,12,'#a96e69'),(351,8,'#e7bd8b'),(350,3,'#fff1c7'),(338,2,'#d5a8a0'),(365,2,'#e4c4a0')]:
    d.ellipse((512-r,512-r,512+r,512+r),outline=col,width=w)
# Small ornamental beads along the upper and lower open arcs.
for angle in range(0,360,12):
    a=math.radians(angle);x=512+359*math.cos(a);y=512+359*math.sin(a)
    d.ellipse((x-2.5,y-2.5,x+2.5,y+2.5),fill='#fff0ce',outline='#c39373')

branches=layer('02 • Plum branches')
curves=[[(179,720),(100,566),(133,325),(346,197)],[(181,719),(196,811),(365,879),(487,866)],[(844,330),(905,438),(899,610),(813,714)],[(843,330),(826,209),(692,136),(572,157)],[(197,718),(236,710),(268,668),(279,624)],[(257,787),(296,781),(336,755),(355,732)],[(806,265),(765,287),(734,323),(720,364)],[(753,201),(737,231),(697,253),(665,256)]]
for i,points in enumerate(curves):
    pts=bezier(points)
    for j in range(len(pts)-1):
        width=max(1,int((9 if i<4 else 5)*(1-j/len(pts))+.7))
        ImageDraw.Draw(branches).line([pts[j],pts[j+1]],fill='#684554',width=width)
    hi=[(x-1.3,y-1) for x,y in pts]
    ImageDraw.Draw(branches).line(hi,fill='#b17c80',width=1)

foliage=layer('03 • Sage leaves')
def leaf(x,y,r,angle):
    im=Image.new('RGBA',(160,160));p=[('moveto',(80,126)),('curveto',(28,92,52,52,80,22)),('curveto',(113,62,122,100,80,126)),('close',())]
    path(im,p,'#7e9b88','#557768',1.5)
    path(im,[('moveto',(80,121)),('curveto',(74,89,80,52,80,30))],None,'#c9d2a6',2)
    im=im.resize((int(r*1.5),int(r*1.5)),Image.Resampling.LANCZOS).rotate(angle,resample=Image.Resampling.BICUBIC,expand=True)
    foliage.alpha_composite(im,(int(x-im.width/2),int(y-im.height/2)))
for args in [(158,566,52,35),(202,425,40,-40),(273,228,46,-75),(348,202,35,-110),(204,770,60,55),(307,822,46,130),(376,842,31,150),(875,431,46,190),(838,578,34,220),(773,219,53,-65),(693,166,43,-110),(727,333,34,20),(267,656,36,-30)]:leaf(*args)

flowers=layer('04 • Sakura petals and stamens')
def flower(x,y,r,rotation=0):
    N=256
    bloom=Image.new('RGBA',(N,N));q=128
    for i in range(5):
        petal=Image.new('RGBA',(N,N));mask=Image.new('L',(N,N));m=aggdraw.Draw(mask);p=aggdraw.Path()
        p.moveto(q,q+9);p.curveto(q-24,q-6,q-65,q-53,q-39,q-86);p.curveto(q-29,q-103,q-12,q-104,q,q-88);p.curveto(q+14,q-106,q+33,q-98,q+42,q-83);p.curveto(q+65,q-47,q+24,q-7,q,q+9);p.close()
        m.path(p,aggdraw.Brush('white'));m.flush()
        # Cream rim, blush at the root; the mask carries the split petal silhouette.
        grad=Image.new('RGBA',(N,N));gd=ImageDraw.Draw(grad)
        for row in range(N):
            t=max(0,min(1,(row-24)/110))
            color=tuple(int(a+(b-a)*t) for a,b in zip((255,242,229),(217,111,145)))
            gd.line((0,row,N,row),fill=(*color,255))
        grad.putalpha(mask);petal.alpha_composite(grad)
        path(petal,[('moveto',(q-39,q-86)),('curveto',(q-29,q-103,q-12,q-104,q,q-88)),('curveto',(q+14,q-106,q+33,q-98,q+42,q-83))],None,'#ffece1',2)
        for off in [-15,-6,6,16]:
            path(petal,[('moveto',(q,q-3)),('curveto',(q+off*.4,q-26,q+off*1.2,q-44,q+off,q-67))],None,(185,88,127,80),.8)
        petal=petal.rotate(i*72+rotation,resample=Image.Resampling.BICUBIC)
        bloom.alpha_composite(petal)
    bd=ImageDraw.Draw(bloom)
    bd.ellipse((q-14,q-14,q+14,q+14),fill='#bc6382')
    for j in range(19):
        a=j*math.tau/19;length=random.uniform(15,28)
        ex=q+math.cos(a)*length;ey=q+math.sin(a)*length
        bd.line((q,q,ex,ey),fill='#f6d3a5',width=1)
        bd.ellipse((ex-2.2,ey-2.2,ex+2.2,ey+2.2),fill='#fff0ad',outline='#cb9c68')
    n=int(r*2.5);bloom=bloom.resize((n,n),Image.Resampling.LANCZOS)
    shadow=Image.new('RGBA',bloom.size,'#67374b');shadow.putalpha(bloom.getchannel('A').point(lambda a:int(a*.17)));shadow=shadow.filter(ImageFilter.GaussianBlur(2))
    flowers.alpha_composite(shadow,(int(x-n/2+2),int(y-n/2+4)))
    flowers.alpha_composite(bloom,(int(x-n/2),int(y-n/2)))

for args in [(183,673,43,12),(188,742,64,28),(247,793,54,3),(313,825,32,14),(149,578,28,20),(202,363,22,30),(276,229,28,12),(815,294,66,18),(772,223,51,6),(704,181,33,30),(850,377,31,8),(750,331,29,16),(835,656,23,35)]:flower(*args)

details=layer('05 • Drifting petals and gold dust')
for x,y,r,rot in [(359,167,12,30),(657,132,11,-35),(899,339,12,-50),(138,636,10,60),(347,871,12,20),(796,724,11,70)]:
    im=Image.new('RGBA',(64,64));path(im,[('moveto',(12,43)),('curveto',(8,16,32,8,48,13)),('curveto',(49,32,34,48,12,43)),('close',())],'#efb5c2','#ffe4df',1)
    im=im.resize((r*2,r*2)).rotate(rot,expand=True,resample=Image.Resampling.BICUBIC);details.alpha_composite(im,(x-r,y-r))
dd=ImageDraw.Draw(details)
for _ in range(45):
    a=random.uniform(0,math.tau);r=random.uniform(373,393);x=512+r*math.cos(a);y=512+r*math.sin(a)
    rr=random.choice([1,1.5,2]);dd.ellipse((x-rr,y-rr,x+rr,y+rr),fill='#e6ba82')

# Preserve the avatar opening exactly; decoration never covers the face.
hole=Image.new('L',(S,S),255);ImageDraw.Draw(hole).ellipse((200,200,824,824),fill=0)
from PIL import ImageChops
for _,im in layers:im.putalpha(ImageChops.multiply(im.getchannel('A'),hole))
merged=Image.new('RGBA',(S,S))
for _,im in layers:merged.alpha_composite(im)
out=ROOT/'design/sakura_2d';out.mkdir(parents=True,exist_ok=True)
merged.save(out/'frame_sakura_2d.png')
merged.resize((768,768),Image.Resampling.LANCZOS).save(ROOT/'assets/cosmetics/frame_sakura.png')
def png(im):
    b=io.BytesIO();im.save(b,format='PNG');return b.getvalue()
root=Element('image',{'w':str(S),'h':str(S),'name':'Sakura • 2D concept','version':'0.0.3'})
stack=SubElement(root,'stack')
with zipfile.ZipFile(out/'sakura_2d.ora','w') as z:
    z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
    for i,(name,im) in enumerate(reversed(layers)):
        src=f'data/layer{i}.png';z.writestr(src,png(im));SubElement(stack,'layer',{'name':name,'src':src,'opacity':'1.0','visibility':'visible','composite-op':'svg:src-over','x':'0','y':'0'})
    z.writestr('stack.xml',tostring(root,encoding='utf-8'));z.writestr('mergedimage.png',png(merged));z.writestr('Thumbnails/thumbnail.png',png(merged.resize((256,256))))
# Compare against light and dark UI without changing production app colors.
preview=Image.new('RGB',(1100,590),'#f4f1ed');dr=ImageDraw.Draw(preview);dr.rectangle((550,0,1100,590),fill='#23212c')
for cx,col,ink in [(275,'#f8e4d9','#89544e'),(825,'#453944','#f3d7cc')]:
    dr.ellipse((cx-156,119,cx+156,431),fill=col)
    stamp=merged.resize((500,500),Image.Resampling.LANCZOS);preview.paste(stamp,(cx-250,25),stamp)
preview.save(ROOT/'docs/screenshots/sakura-2d-concept.png')
print(out/'sakura_2d.ora')
