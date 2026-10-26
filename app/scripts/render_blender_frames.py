"""Run inside Blender via its MCP execute_code endpoint. Original scene preserved."""
import bpy, math, os
from mathutils import Vector

OUT = 'D:/DropIt!/app/assets/cosmetics'
scene = bpy.data.scenes.new('DropIt Cosmetics Studio')
bpy.context.window.scene = scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 48
scene.render.resolution_x = scene.render.resolution_y = 768
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.world = bpy.data.worlds.new('Cosmetics soft studio')
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.28,.32,.45,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = .45
scene.view_settings.view_transform = 'AgX'

def material(name, color, metal=0, rough=.27):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color,1)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color,1)
    p.inputs['Metallic'].default_value = metal
    p.inputs['Roughness'].default_value = rough
    return m

def finish(obj, name, mat):
    obj.name = name
    obj.data.materials.append(mat)
    return obj

def ring(radius, thickness, z, mat):
    bpy.ops.mesh.primitive_torus_add(major_radius=radius, minor_radius=thickness, major_segments=128, minor_segments=16, location=(0,0,z))
    o=finish(bpy.context.object,'Sculpted circular bezel',mat)
    for p in o.data.polygons: p.use_smooth=True

def gem(x,y,z,size,mat):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(x,y,z))
    o=finish(bpy.context.object,'Faceted crystal',mat)
    o.scale=(size*.7,size,size*.5)
    o.rotation_euler[2]=math.atan2(y,x)-math.pi/2

def light(location,power,size):
    d=bpy.data.lights.new('Softbox','AREA'); d.energy=power; d.shape='DISK'; d.size=size
    o=bpy.data.objects.new('Softbox',d); scene.collection.objects.link(o); o.location=location
    o.rotation_euler=(Vector((0,0,0))-o.location).to_track_quat('-Z','Y').to_euler()

camera=bpy.data.cameras.new('Product camera'); obj=bpy.data.objects.new('Product camera',camera)
scene.collection.objects.link(obj); obj.location=(0,0,8); camera.type='ORTHO'; camera.ortho_scale=3.15; scene.camera=obj
light((-3,4,5),500,4); light((3,1,3),350,3); light((0,-4,4),250,2)
gold=material('Champagne gold',(.72,.43,.16),.8)
silver=material('Lavender platinum',(.55,.48,.72),.75)
purple=material('Amethyst',(.32,.09,.58),.45,.18)
green=material('Jade enamel',(.07,.38,.22),.35)
mint=material('Mint enamel',(.27,.66,.4),.3)
amber=material('Amber crystal',(.95,.29,.055),.45,.19)

for key in ['frame_galaxy','frame_leaf','frame_sunset']:
    for o in list(scene.objects):
        if o.type=='MESH': bpy.data.objects.remove(o,do_unlink=True)
    metal=silver if key=='frame_galaxy' else gold
    ring(1.06,.068,0,metal); ring(.985,.019,.035,metal); ring(1.14,.018,-.01,metal)
    if key=='frame_galaxy':
        for i in range(12):
            a=2*math.pi*i/12; gem(1.085*math.cos(a),1.085*math.sin(a),.07,.075,purple)
        for a,size in [(math.pi/2,.23),(-math.pi/2,.18),(.25,.13),(math.pi-.25,.13)]:
            gem(1.14*math.cos(a),1.14*math.sin(a),.12,size,purple)
        for x in [-.25,0,.25]: gem(x,1.18-abs(x)*.2,.09,.09,silver)
    elif key=='frame_leaf':
        for side in [-1,1]:
            for i in range(9):
                a=math.pi*.18+i*.23
                x=side*1.12*math.sin(a); y=-1.12*math.cos(a)
                bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=(x,y,.06))
                o=finish(bpy.context.object,'Jade laurel leaf',green if i%2 else mint)
                o.scale=(.085,.18,.055); o.rotation_euler[2]=side*(-a+.5)
                for p in o.data.polygons:p.use_smooth=True
        gem(0,-1.1,.12,.19,green)
    else:
        for i in range(36):
            a=2*math.pi*i/36
            gem(1.18*math.cos(a),1.18*math.sin(a),0,.09 if i%3 else .14,gold)
        for a in [math.pi/2,-math.pi/2,0,math.pi]:gem(1.07*math.cos(a),1.07*math.sin(a),.11,.14,amber)
    scene.render.filepath=os.path.join(OUT,key+'.png')
    bpy.ops.render.render(write_still=True)
os.makedirs('D:/DropIt!/app/design', exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath='D:/DropIt!/app/design/avatar_frames.blend')
