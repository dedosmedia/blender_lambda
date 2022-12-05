FROM public.ecr.aws/lambda/python:3.9

WORKDIR $LAMBDA_TASK_ROOT

COPY requirements.txt  .
RUN pip install -r requirements.txt

COPY index.py .

RUN find . -type d -exec chmod 755 {} \;
RUN find . -type f -exec chmod 644 {} \;

CMD [ "index.handler" ]