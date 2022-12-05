from datetime import datetime
import os
import sys
import logging

import bpy


filename = f"imagen"
logging.warning('Watch out! %s', filename)  
bpy.ops.wm.open_mainfile(filepath="/tmp/scene.blend", load_ui=False)
bpy.context.scene.render.filepath = f"/tmp/{filename}"
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene.frame_start = 1

bpy.ops.sequencer.movie_strip_add(filepath="/tmp/input.mp4", directory="/tmp/", files=[{"name":"input.mp4", "name":"input.mp4"}], show_multiview=False, frame_start=1, channel=1, fit_method='FIT', set_view_transform=False, adjust_playback_rate=True, use_framerate=False)
bpy.ops.sequencer.set_range_to_strips()
bpy.ops.se


bpy.ops.render.render(animation = True)

