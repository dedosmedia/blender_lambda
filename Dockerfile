FROM nytimes/blender:3.3.1-cpu-ubuntu18.04

ARG FUNCTION_DIR="/home/app/"
RUN mkdir -p ${FUNCTION_DIR}
RUN pip install boto3
RUN pip install awslambdaric --target ${FUNCTION_DIR}
COPY app/* ${FUNCTION_DIR}

WORKDIR ${FUNCTION_DIR}

ENTRYPOINT [ "/bin/3.3/python/bin/python3.10", "-m", "awslambdaric" ]

CMD [ "app.handler" ]