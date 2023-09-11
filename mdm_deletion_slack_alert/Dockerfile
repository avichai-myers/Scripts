FROM python:3.9.6-slim-buster
RUN apt-get update && \
    apt-get install -y curl jq awscli
COPY . /app

WORKDIR /app
COPY requirements.txt /app
RUN pip install -r requirements.txt

CMD ["./mdm_device_deletion_workflow.sh"]
