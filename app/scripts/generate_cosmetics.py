"""Original DropIt! vector assets. Run from repository root; no external media."""
from pathlib import Path
from math import sin,cos,pi
out=Path(__file__).resolve().parents[1]/'assets/cosmetics'
out.mkdir(parents=True,exist_ok=True)
def save(name,body,view='0 0 200 200'):
 (out/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view}">{body}</svg>',encoding='utf-8')
def star(x,y,r,color):
 return f'<path d="M{x} {y-r} L{x+r*.28} {y-r*.28} L{x+r} {y} L{x+r*.28} {y+r*.28} L{x} {y+r} L{x-r*.28} {y+r*.28} L{x-r} {y} L{x-r*.28} {y-r*.28}Z" fill="{color}"/>'
def ring(a,b):
 return f'<defs><linearGradient id="g" x2="1" y2="1"><stop stop-color="{a}"/><stop offset=".5" stop-color="{b}"/><stop offset="1" stop-color="{a}"/></linearGradient></defs><circle cx="100" cy="100" r="81" fill="none" stroke="url(#g)" stroke-width="8"/><circle cx="100" cy="100" r="73" fill="none" stroke="{a}" stroke-width="1.5" opacity=".55"/>'
s=ring('#287353','#B4DBA2')
for angle in range(0,360,30):
 s+=f'<g transform="rotate({angle} 100 100)"><path d="M100 25 Q76 18 88 5 Q105 5 100 25Z" fill="#77AD79"/><path d="M100 25 Q119 20 113 8 Q97 6 100 25Z" fill="#2F7957"/><path d="M99 25 L101 10" stroke="#E8F1CD" stroke-width="1"/></g>'
s+='<path d="M84 176 L82 198 L100 190 L118 198 L116 176Z" fill="#2F7957"/>'+star(100,180,9,'#F3D592');save('frame_leaf',s)
s=ring('#A94326','#F4C56F')
for i in range(28):
 a=i*2*pi/28;x=100+92*cos(a);y=100+92*sin(a);xx=100+98*cos(a);yy=100+98*sin(a)
 s+=f'<path d="M{x:.2f} {y:.2f} L{xx:.2f} {yy:.2f}" stroke="#D9A456" stroke-width="2" stroke-linecap="round"/>'
s+='<circle cx="100" cy="20" r="13" fill="#F1B75C"/><path d="M87 20 H113 M100 7 V33" stroke="#FFF1CA" stroke-width="1.5"/>'+star(100,180,14,'#BE5733');save('frame_sunset',s)
s=ring('#42416D','#C8B9ED');s+='<ellipse cx="100" cy="100" rx="96" ry="77" transform="rotate(-30 100 100)" fill="none" stroke="#AEA0CE" stroke-width="2"/>'
for x,y,r in [(35,42,9),(157,29,12),(176,142,9),(55,177,7)]:s+=star(x,y,r,'#DDD2FB')
s+='<circle cx="163" cy="163" r="10" fill="#5D5689"/><circle cx="160" cy="160" r="3" fill="#BDB1E2"/>';save('frame_galaxy',s)
# Quiet, light backgrounds preserve text contrast on profiles.
s='<rect width="600" height="360" fill="#F5EDE0"/><circle cx="480" cy="72" r="58" fill="#E7CBA2"/><path d="M0 260 Q200 210 600 260 V360 H0Z" fill="#E7D7C1"/>'
for x in [20,470]:
 s+=f'<rect x="{x}" y="110" width="110" height="170" rx="8" fill="#D0B796"/>'
 for y in [130,193,256]:
  s+=f'<path d="M{x} {y+34} H{x+110}" stroke="#A88B6A" stroke-width="5"/>'
  for k,c in enumerate(['#8F9F8C','#B47C61','#D9BD8A','#788C99']):s+=f'<rect x="{x+10+k*23}" y="{y}" width="17" height="33" rx="2" fill="{c}"/>'
s+='<path d="M246 258 Q273 239 300 256 Q327 239 354 258 V290 Q327 271 300 287 Q273 271 246 290Z" fill="#FFFBF0" stroke="#B6A080" stroke-width="2"/>';save('bg_library',s,'0 0 600 360')
s='<rect width="600" height="360" fill="#E7EEF5"/><circle cx="479" cy="70" r="28" fill="#B3BFD6"/><circle cx="490" cy="61" r="26" fill="#E7EEF5"/>'
for x,y in [(35,50),(150,85),(540,125),(370,35),(230,40)]:s+=star(x,y,4,'#8094B5')
for y,c in [(245,'#C1D4E0'),(275,'#A8C4D3'),(315,'#8FAFBE')]:s+=f'<path d="M0 {y} Q75 {y-25} 150 {y} T300 {y} T450 {y} T600 {y} V360 H0Z" fill="{c}"/>'
s+='<path d="M442 278 L474 278 L466 289 L450 289Z" fill="#496679"/><path d="M458 278 V246 L474 272 H458" fill="#F8F5E9"/>';save('bg_night_sea',s,'0 0 600 360')
s='<rect width="600" height="360" fill="#EAF1EB"/><circle cx="470" cy="70" r="42" fill="#DFE7D0"/>'
for x,y,h,c in [(20,250,150,'#B1C7BB'),(100,280,180,'#C2D2C7'),(500,260,170,'#B1C7BB'),(560,310,200,'#98B4A5'),(65,330,155,'#8FAB9C')]:s+=f'<path d="M{x} {y-h} L{x-42} {y} H{x+42}Z" fill="{c}"/><path d="M{x} {y-30} V{y+20}" stroke="{c}" stroke-width="6"/>'
s+='<path d="M0 275 Q210 230 600 280 V360 H0Z" fill="#D4E1D8" opacity=".7"/><path d="M0 320 Q300 270 600 320" fill="none" stroke="#F7FAF5" stroke-width="26" opacity=".7"/>';save('bg_misty_forest',s,'0 0 600 360')
s='<path d="M20 66 L8 95 L39 87 L50 100 L61 87 L92 95 L80 66Z" fill="#655D91"/><path d="M50 3 L87 18 V49 Q87 74 50 88 Q13 74 13 49 V18Z" fill="#34334F" stroke="#C7B99B" stroke-width="3"/><path d="M30 29 L35 18 L45 28 H57 L67 18 L71 37 L68 59 L50 72 L32 59Z" fill="#B7AAD5"/><circle cx="40" cy="43" r="9" fill="#F4E7C9"/><circle cx="61" cy="43" r="9" fill="#F4E7C9"/><circle cx="41" cy="43" r="4" fill="#34334F"/><circle cx="60" cy="43" r="4" fill="#34334F"/><path d="M46 50 L55 50 L50 58Z" fill="#D9AB68"/>';save('title_night_owl',s,'0 0 100 100')
s='<path d="M20 66 L8 95 L39 87 L50 100 L61 87 L92 95 L80 66Z" fill="#BF653F"/><path d="M50 3 L87 18 V49 Q87 74 50 88 Q13 74 13 49 V18Z" fill="#F7E4BC" stroke="#B87A43" stroke-width="3"/><circle cx="50" cy="46" r="18" fill="#D98D43"/><path d="M50 17 V23 M24 46 H18 M76 46 H82 M29 25 L33 30 M71 25 L67 30" stroke="#B87A43" stroke-width="3"/><path d="M23 58 Q50 44 77 58 M23 65 H77 M32 72 H68" stroke="#F9F1D8" stroke-width="4" fill="none"/>';save('title_early_bird',s,'0 0 100 100')
print('8 original SVG assets generated')
# Achievement medals: shared families, increasingly ornate milestones.
for family,levels in [('STREAK',[3,7,14,30,60,100]),('SESS',[10,50,100,500]),('HOURS',[10,50,100])]:
 for tier,n in enumerate(levels):
  dark,light,edge={'STREAK':('#AC4A2B','#FFF0CF','#DDB16A'),'SESS':('#276B58','#E4F1D8','#B6CC86'),'HOURS':('#4F527D','#EBE7F6','#B8ADD8')}[family]
  s=f'<defs><linearGradient id="medal" x2="1" y2="1"><stop stop-color="{light}"/><stop offset="1" stop-color="{edge}"/></linearGradient></defs>'
  s+=f'<path d="M54 128 L42 191 L81 171 L100 192 L119 171 L158 191 L146 128Z" fill="{dark}"/><path d="M66 141 L58 173 L81 160 M134 141 L142 173 L119 160" fill="none" stroke="{edge}" stroke-width="3"/>'
  s+=f'<path d="M100 9 L165 32 V91 Q165 137 100 164 Q35 137 35 91 V32Z" fill="url(#medal)" stroke="{dark}" stroke-width="4"/><path d="M100 19 L155 40 V91 Q155 128 100 153 Q45 128 45 91 V40Z" fill="{light}" stroke="{edge}" stroke-width="2"/>'
  if family=='STREAK':
   s+=f'<path d="M103 39 Q118 65 109 74 Q124 70 122 56 Q151 94 118 111 Q87 126 72 101 Q58 77 85 59 Q79 77 89 78 Q106 64 103 39Z" fill="{dark}"/><path d="M101 79 Q119 97 103 107 Q87 108 88 96Z" fill="{edge}"/>'
  elif family=='SESS':
   s+=f'<circle cx="100" cy="77" r="32" fill="{dark}"/><path d="M82 77 L94 89 L119 64" stroke="{light}" fill="none" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>'
  else:
   s+=f'<path d="M79 44 H121 M79 106 H121 M82 46 Q81 64 100 75 Q119 86 118 104 M118 46 Q119 64 100 75 Q81 86 82 104" fill="none" stroke="{dark}" stroke-width="6" stroke-linecap="round"/><path d="M87 99 L100 85 L113 99Z" fill="{edge}"/>'
  # Laurel branches added at later milestones.
  if tier>=1:
   for angle in range(0, min(tier+2,7)):
    for mirror in [False,True]:
     x=27+angle*1.8 if not mirror else 173-angle*1.8;y=57+angle*12
     s+=f'<ellipse cx="{x}" cy="{y}" rx="5" ry="9" transform="rotate({-30 if not mirror else 30} {x} {y})" fill="{edge}"/>'
  for k in range(min(tier+1,5)):
   s+=star(100+(k-min(tier,4)/2)*13,26,4,dark)
  save(f'badge_{family.lower()}_{n}',s)
print('13 achievement medals generated')
