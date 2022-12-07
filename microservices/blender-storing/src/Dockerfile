FROM public.ecr.aws/lambda/python:3.9

WORKDIR $LAMBDA_TASK_ROOT

COPY app.py .

RUN find . -type d -exec chmod 755 {} \;
RUN find . -type f -exec chmod 644 {} \;

# Command can be overwritten by providing a different command in the template directly.
CMD ["app.handler_s3"]

