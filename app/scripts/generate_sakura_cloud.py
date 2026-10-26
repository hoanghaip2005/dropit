"""One AI sample through the existing authenticated Krita cloud connection.
No credentials are copied into the project. No purchases or automatic retries.
"""
import os,json,urllib.request,urllib.error,time,base64,io
from pathlib import Path
from PIL import Image

out=Path(__file__).resolve().parents[1]/'design/sakura_ai'
out.mkdir(parents=True,exist_ok=True)
settings=json.loads((Path(os.environ['APPDATA'])/'krita/ai_diffusion/settings.json').read_text(encoding='utf-8'))
token=settings.get('access_token','')
if not token:raise SystemExit('Krita cloud access token missing')
def request(route,data=None):
    req=urllib.request.Request('https://api.interstice.cloud/'+route,
        data=None if data is None else json.dumps(data).encode(),
        headers={'Authorization':'Bearer '+token,'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(req,timeout=90) as r:return json.loads(r.read())
    except urllib.error.HTTPError as e:
        # Never log request headers or credentials.
        raise RuntimeError(f'Cloud HTTP {e.code}: {e.read().decode()[:600]}') from None
user=request('user?plugin_version=1.53.0')
print('Available cloud credits:',user.get('credits'),flush=True)
if user.get('credits',0)<=0:raise SystemExit('No cloud credits; no generation submitted')
prompt=('A single exquisite circular cherry blossom avatar frame, premium 2D fantasy mobile game UI asset, '
    'front view, centered perfect circular empty white opening, thin elegant rose gold circular border, '
    'asymmetric hand painted sakura branches curling around the OUTSIDE of the ring, '
    'lush clusters of delicate five petal blush pink and ivory cherry blossoms at upper right and lower left, '
    'fine golden stamens, dark plum twigs, tiny sage leaves, a few floating petals, '
    'delicate luminous gold filigree, beautiful confident painterly linework, refined illustrated shading, '
    'high quality anime fantasy inventory art, readable silhouette, restrained luxurious detail, '
    'frame occupies 85 percent of square canvas, large blank circular center occupies 63 percent of canvas width, '
    'isolated on pure solid white background, white empty center, no person, no portrait, no text, no letters')
extent={k:[1024,1024] for k in ['input','initial','desired','target']}
workflow={'kind':'generate','images':{'extent':extent},
 'models':{'checkpoint':'zavychromaxl_v80.safetensors','version':'sdxl'},
 'sampling':{'sampler':'dpmpp_2m','scheduler':'karras','cfg_scale':6.0,'total_steps':28,'seed':2141026},
 'conditioning':{'positive':prompt,'negative':'3d render, plastic, photorealistic, thick bulky ring, portrait, face, person, text, watermark, logo, square frame, scene, background scenery, filled center, blurry, low quality'},
 'batch_count':1}
(out/'prompt.json').write_text(json.dumps(workflow,ensure_ascii=False,indent=2),encoding='utf-8')
job=request('generate',{'input':{'workflow':workflow,'clientInfo':'krita-ai-diffusion 1.53.0','options':{'useWebpCompression':False}}})
print('Generation submitted:',job.get('status'),flush=True)
deadline=time.monotonic()+300
while job['status'].lower() in ['in_queue','in_progress']:
    if time.monotonic()>deadline:raise SystemExit('Generation still running; check cloud job')
    time.sleep(2)
    job=request('status/'+job['id'],{})
if job['status'].lower()!='completed':raise SystemExit('Generation failed: '+str(job.get('error',job['status'])))
images=job['output']['images']
blob=base64.b64decode(images['base64']) if 'base64' in images else urllib.request.urlopen(images['url'],timeout=90).read()
offsets=images['offsets'];start=offsets[0];end=offsets[1] if len(offsets)>1 else len(blob)
im=Image.open(io.BytesIO(blob[start:end]));im.save(out/'sakura-ai-original.png')
print('Saved:',out/'sakura-ai-original.png',flush=True)
print('Remaining cloud credits:',job.get('user',{}).get('credits','See Krita'),flush=True)
