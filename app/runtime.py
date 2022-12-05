import bpy
import os, glob


img_dir = '/tmp/imgs'

# set movie render settings
resx = 1920
resy = 1080

bpy.data.scenes["Scene"].render.resolution_x = resx
bpy.data.scenes["Scene"].render.resolution_y = resy
bpy.data.scenes["Scene"].render.resolution_percentage = 100

scene = bpy.data.scenes[0]
editor = scene.sequence_editor_create()

# get image files
image_files = []
for _file in os.listdir(path=img_dir):
    if _file.endswith('.png'):
        image_files.append(_file)

context = bpy.context

# add to sequencer
img_strip = [{'name':i} for i in image_files]
frames = len(image_files)
frame_end = frames - 1  # offset for python counting

a = bpy.ops.sequencer.image_strip_add(directory=img_dir, files=img_strip,
    channel=1, frame_start=0, frame_end=frame_end)

strip_name = file[0].get("name")
bpy.data.scenes["Scene"].frame_end = frames
bpy.data.scenes["Scene"].render.image_settings.file_format = 'AVI_JPEG'
bpy.data.scenes["Scene"].render.filepath = out_dir
bpy.ops.render.render( animation=True )