from datetime import datetime
import os
import sys
import glob 
from multiprocessing.pool import ThreadPool 

import boto3
from boto3.s3.transfer import TransferConfig
import bpy
from concurrent.futures.thread import ThreadPoolExecutor

argv = sys.argv
argv = argv[argv.index("--") + 1:]


config = TransferConfig(max_concurrency=50, use_threads=True)

s3 = boto3.resource("s3")


BUCKET_NAME = "blender-bucket-dh"
filename = f"output"

s3.Bucket(BUCKET_NAME).download_file("scenes/scene.blend", "/tmp/scene.blend")
s3.Bucket(BUCKET_NAME).download_file("scenes/input.mp4", "/tmp/input.mp4")

bpy.ops.wm.open_mainfile(filepath="/tmp/scene.blend", load_ui=False)
bpy.context.scene.render.filepath = f"/tmp/output/{filename}"
bpy.context.scene.render.resolution_x = int(argv[0])
bpy.context.scene.render.resolution_y = int(argv[1])
bpy.ops.render.render(animation = True)

# Subir una sola imagen a S3
#s3.Bucket(BUCKET_NAME).upload_file(f"/tmp/{filename}", f"renders/{filename}")


# Subir todas las imágenes procesadas a S3
# Source location of files on local system 
DATA_FILES_LOCATION   = '/tmp/output/*.png'

# The list of files we're uploading to S3 
filenames =  glob.glob(DATA_FILES_LOCATION) 


def upload(myfile): 
    s3_file = f"proyecto/{os.path.basename(myfile)}" 
    s3.Bucket(BUCKET_NAME).upload_file(myfile, s3_file)
    print(os.path.basename(myfile))


# Number of pool processes is a guestimate - I've set 
# it to twice number of files to be processed 

#pool = ThreadPool(processes=len(filenames)*2) 
#pool.map(upload, filenames) 

# with ThreadPoolExecutor() as tpex:
#    tpex.map(upload, filenames)

for obj in filenames:
    upload(obj)