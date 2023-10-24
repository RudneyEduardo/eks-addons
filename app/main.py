import json
from fastapi import FastAPI
import boto3

app = FastAPI()

# Get the service resource

def getQueue(queue: str):
    sqs = boto3.resource('sqs', region_name='us-east-1')
    # Get the queue
    print(queue)
    queue = sqs.get_queue_by_name(QueueName='keda-sqs')
    QMessage = []
    for message in queue.receive_messages():
        QMessage.append(message.body)
        message.delete()
    return QMessage

@app.get("/getQueue")
def root(queue: str):
    returnList = getQueue(queue)
    return {"queue Message list": returnList}

@app.get("/ping")
def ping():
    return {"status": "ok"}