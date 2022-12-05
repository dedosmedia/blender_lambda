'''
Comandos utiles para agregar contenido dinámicamente

https://b3d.interplanety.org/en/adding-strips-to-the-blender-video-sequencer-editor/

'''

import bpy, os, logging

bpy.ops.wm.open_mainfile(filepath="/tmp/scene.blend", load_ui=False)
filename = f'render'
bpy.context.scene.render.filepath = f"/tmp/output/{filename}"
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene.frame_start = 1


# Agrega un strip de sonido al canal 1
'''
sound_strip = bpy.context.scene.sequence_editor.sequences.new_sound(
    name='sound',
    filepath='_PATH_/sound.wav',
    channel=1,
    frame_start=1
)
'''

# Agrega un strip de imagen al canal 1
'''
image_strip = bpy.context.scene.sequence_editor.sequences.new_image(
    name='image',
    filepath='_PATH_/image.png',
    channel=3,
    frame_start=1
)
'''

# Agrega una secuencia de imágenes como strip, seleccionando primero el contexto correcto
'''
override_context = bpy.context.copy()
area = [area for area in bpy.context.screen.areas if area.type == "SEQUENCE_EDITOR"][0]
override_context['window'] = bpy.context.window
override_context['screen'] = bpy.context.screen
override_context['area'] = area
override_context['region'] = area.regions[-1]
override_context['scene'] = bpy.context.scene
override_context['space_data'] = area.spaces.active
 
bpy.ops.sequencer.image_strip_add(
    override_context,
    directory='_DIRECTORY_PATH_',
    files=[{"name": 'image001.png'}, {"name": 'image002.png'}, {"name": 'image003.png'}],
    frame_start=1,
    channel=4
)
'''


# Obtiene una secuencia con los nombres de las imágenes de una carpeta pasada como parámetro
'''
def get_sequence(dir = '/tmp/imgs'):
    file=[]
    for i in os.listdir(dir):
        frame = { "name": i }
        file.append(frame)
    return file
'''



# Agrega vídeo como strip en canal 1
video_strip = bpy.context.scene.sequence_editor.sequences.new_movie(
    name='video',
    filepath='/tmp/input30.mp4',
    channel=1,
    frame_start=1
)

# Setea el frame final de la renderización
bpy.ops.sequencer.set_range_to_strips()


# Guarda una copia del archivo de blender editado
bpy.ops.wm.save_as_mainfile(filepath="/tmp/segundo.blend")

# Renderiza las imágenes
bpy.ops.render.render( animation=True )


# Obtiene información sobre los strips
'''
context = bpy.context
scene = context.scene
vse = scene.sequence_editor
for strip in vse.sequences_all:
    # Edit Strip Panel
    print("-" * 72)
    print(strip.name)
    print(strip.type)
    # extend for other strip types.
    if strip.type in ['MOVIE']:
        print(strip.filepath)
        end_frame = strip.frame_final_duration
    elif strip.type in ['SOUND']:
        print(strip.sound.filepath)
    print(strip.channel)
    print(strip.frame_start)
    print(strip.frame_final_duration)
    # Trim Duration (soft)
    print(strip.frame_offset_start)
    print(strip.frame_offset_end)
'''
    



