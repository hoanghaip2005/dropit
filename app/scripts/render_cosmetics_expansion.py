"""Original 3D cosmetics, executed in Blender with MCP."""
from pathlib import Path
exec(Path('D:/DropIt!/app/scripts/render_blender_frames.py').read_text(encoding='utf-8').split("for key in ['frame_galaxy'")[0])
scene.name = 'DropIt Expansion Studio'
scene.cycles.samples = 40
ice=material('Glacier crystal',(.12,.63,.88),.5,.19)
fire=material('Ruby enamel',(.64,.035,.025),.5,.2)
ocean=material('Ocean turquoise',(.025,.48,.5),.5)
steel=material('Gunmetal',(.06,.10,.16),.85)
pink=material('Rose quartz',(.88,.24,.43),.35)
pearl=material('Pearlescent ivory',(.94,.82,.61),.45,.19)

def clear():
    for o in list(scene.objects):
        if o.type=='MESH': bpy.data.objects.remove(o,do_unlink=True)

def petal(x,y,z,length,width,angle,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=(x,y,z))
    o=finish(bpy.context.object,'Sculpted petal',mat)
    o.scale=(width,length,.045); o.rotation_euler[2]=angle
    for p in o.data.polygons:p.use_smooth=True

def crystal(x,y,scale,mat,angle=0):
    bpy.ops.mesh.primitive_cone_add(vertices=5,radius1=scale*.4,radius2=0,depth=scale*2,location=(x,y,.09))
    o=finish(bpy.context.object,'Prismatic shard',mat)
    o.rotation_euler=(-math.pi/2,angle,0)
    o.rotation_euler[2]=angle

def crown(y,scale=1):
    for i in range(5):
        x=(i-2)*.12*scale; height=(.18 if i%2 else .26)*scale
        crystal(x,y+height/2,height,gold)
        gem(x,y+height,.15,.045*scale,fire)
    bpy.ops.mesh.primitive_cube_add(size=1,location=(0,y,.08))
    o=finish(bpy.context.object,'Crown band',gold);o.scale=(.57*scale,.10*scale,.10)
    b=o.modifiers.new('Soft metal edges','BEVEL');b.width=.035;b.segments=3

frames=['frame_frost','frame_phoenix','frame_tidal','frame_cyber','frame_sakura','frame_royal']
for key in frames:
    clear()
    mat={'frame_frost':ice,'frame_phoenix':fire,'frame_tidal':ocean,'frame_cyber':steel,'frame_sakura':pink,'frame_royal':gold}[key]
    ring(1.055,.062,0,mat);ring(.985,.02,.04,silver if key in ['frame_frost','frame_cyber'] else gold)
    if key=='frame_frost':
        for i in range(16):
            a=i*math.tau/16
            gem(1.14*math.cos(a),1.14*math.sin(a),.07,.19 if i%4==0 else .105,ice)
            gem(1.03*math.cos(a),1.03*math.sin(a),.12,.04,silver)
    elif key=='frame_phoenix':
        for side in [-1,1]:
            for i in range(10):
                a=.2+i*.25;x=side*1.1*math.sin(a);y=-1.1*math.cos(a)
                petal(x,y,.06,.19,.065,side*(-a+.65),gold if i%3==0 else fire)
        gem(0,-1.13,.15,.22,amber)
    elif key=='frame_tidal':
        ring(1.14,.022,.025,silver)
        for i in range(12):
            a=i*math.tau/12
            gem(1.12*math.cos(a),1.12*math.sin(a),.06,.07,pearl)
        for side in [-1,1]:
            for i in range(5):petal(side*(.12+i*.13),-1.12+i*.04,.08,.18,.05,side*(.3+i*.17),ocean)
        gem(0,-1.12,.15,.17,pearl)
    elif key=='frame_cyber':
        for i in range(12):
            a=i*math.tau/12
            bpy.ops.mesh.primitive_cube_add(size=1,location=(1.11*math.cos(a),1.11*math.sin(a),.055))
            o=finish(bpy.context.object,'Armor segment',steel);o.scale=(.14,.095,.075);o.rotation_euler[2]=a
            b=o.modifiers.new('Machined edges','BEVEL');b.width=.025;b.segments=2
            gem(1.12*math.cos(a),1.12*math.sin(a),.16,.05,ice)
    elif key=='frame_sakura':
        for a in [.45,1.8,2.8,4.15,5.4]:
            x=1.09*math.cos(a);y=1.09*math.sin(a)
            for j in range(5):
                b=j*math.tau/5
                petal(x+.075*math.cos(b),y+.075*math.sin(b),.09,.095,.06,b-math.pi/2,pink)
            gem(x,y,.15,.045,gold)
    else:
        ring(1.14,.025,0,gold)
        crown(1.07,.9)
        for side in [-1,1]:
            for i in range(6):petal(side*(.37+i*.12),-1.1+i*.085,.04,.12,.045,side*(.4+i*.12),gold)
        gem(0,-1.09,.12,.17,fire)
    scene.render.filepath=OUT+'/'+key+'.png';bpy.ops.render.render(write_still=True)

camera.ortho_scale=2.3
for key,mat in [('title_ice_guardian',ice),('title_flame_keeper',fire),('title_ocean_soul',ocean),('title_crowned',gold)]:
    clear()
    # Faceted medal with a sculpted insignia; independent artwork, no baked text.
    bpy.ops.mesh.primitive_cylinder_add(vertices=6,radius=.73,depth=.13,location=(0,0,0))
    finish(bpy.context.object,'Hexagonal metal medal',gold if mat!=ice else silver)
    bpy.ops.mesh.primitive_cylinder_add(vertices=6,radius=.64,depth=.16,location=(0,0,.06))
    finish(bpy.context.object,'Enamel inset',steel)
    if key=='title_crowned':crown(-.12,1.5)
    elif key=='title_ice_guardian':
        for i in range(6):
            a=i*math.tau/6
            petal(.2*math.cos(a),.2*math.sin(a),.19,.27,.04,a-math.pi/2,ice)
        gem(0,0,.26,.17,pearl)
    elif key=='title_flame_keeper':
        for x,y,s in [(-.18,-.05,.25),(.15,-.04,.3),(0,.14,.4)]:gem(x,y,.2,s,fire)
        gem(0,-.15,.3,.21,amber)
    else:
        for i in range(3):
            for j in range(6):
                x=-.38+j*.15;y=(i-1)*.2+.07*math.sin(j)
                petal(x,y,.19,.12,.05,math.pi/2,ocean)
    for side in [-1,1]:
        for i in range(4):petal(side*(.57+i*.07),-.45+i*.14,.02,.15,.055,side*(-.5-i*.2),gold)
    scene.render.filepath=OUT+'/'+key+'.png';bpy.ops.render.render(write_still=True)
os.makedirs('D:/DropIt!/app/design',exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath='D:/DropIt!/app/design/cosmetics_expansion.blend')
