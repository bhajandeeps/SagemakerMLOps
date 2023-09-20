import json
import base64
import boto3
import email
import time
import os

"""
Use Case Name: Audio Sentiment Analysis
Function Names: lambda_handler()
Author: Sharath YD
Date: 16/06/2020
"""

s3 = boto3.client("s3")
s3_resource = boto3.resource('s3')
clientTr = boto3.client('transcribe')

bucketName = "wipsentanalysis"
outputFilename = "speakerIdent.json"
sentiment="sentiment.json"

def lambda_handler(event, context):
    # decoding form-data into bytes
    #post_data = base64.b64decode(event['body'])
    #print("post data decoded -", post_data)
    print("started ..........")
    jobstatus=0
    respns = clientTr.list_transcription_jobs(Status='COMPLETED',JobNameContains='audio')
    print(respns)
    jobstatus = len(respns['TranscriptionJobSummaries'])
    print('jobstatus - ', jobstatus)
    
    if jobstatus>0 :
        file_name = s3.get_object(Bucket=bucketName,Key=sentiment)
        f = file_name['Body'].read()
        f = f.decode("utf-8")
        json_content = json.loads((f))
        sentm=json_content['Sentiment']
        if sentm=='POSITIVE':
            sentm='&#128522'+'    '+"<p style='color:Green'><b>"+sentm+"</b></p>"
        elif sentm=='NEGATIVE':
            sentm='&#128542'+'    '+"<p style='color:Red'><b>"+sentm+"</b></p>"
        else:
            sentm='&#128528'+'    '+"<p style='color:Brown'><b>"+sentm+"</b></p>"
            
        file_name = s3.get_object(Bucket=bucketName,Key=outputFilename)
        f = file_name['Body'].read()
        f = f.decode("utf-8")
        json_content = json.loads((f))
        strop = json.dumps(json_content)
        print("json content ---- ", json_content)
        print("strop ---", strop)
        #result = "The transcribed text is -- " + json_content['text'] + " <br> The predicted sentiment is " + json_content['sentiment']
        result = strop
        print(result)
        res = clientTr.delete_transcription_job(TranscriptionJobName='audiosentanal')
        response=''
        colrs=['Red','Green']
        #response = "<html><head><title>Audio Processing Result</title></head>"
        for i in range(0,len(json_content)):
            spkr=json_content[str(i)].split(':')
            if spkr[0]=='spk_0':
                response = str(response)+"<br><p style='color:" + colrs[0]+"'>"+ json_content[str(i)]+"</p>"   
            
            else:
                response = str(response)+"<br><p style='color:" + colrs[1]+"'>"+ json_content[str(i)]+"</p>"   
            
        response="<html><head><title>Audio Processing Result</title></head>" +\
        "<body><h3 style='color:blue'>Audio Processing Result</h3>" \
        +"Overall Sentiment :"+ sentm \
        +"<br> Transcribed Conversation" \
        +response+\
        "</body></html>"
        print(response)
        return {
            'statusCode': 200,
            'headers': {
                "Access-Control-Allow-Origin" : "*", 
                'Access-Control-Allow-Credentials' : True,
                'Content-Type': 'text/html',
            },
            'body': response,
            'isBase64Encoded': False
        }
    else:
        # if process is still running
        result = "Audio file is still processing, please wait for a while and try again"
        response = "<html><head><title>Audio Processing Result</title></head>" \
                    + "<body><h3 style='color:blue'>Audio Processing Result</h3> <p style='color:green'>" \
                    + result \
                    + "</p> <br> </body></html>"
        return {
            'statusCode': 200,
            'headers': {
                "Access-Control-Allow-Origin" : "*", 
                'Access-Control-Allow-Credentials' : True,
                'Content-Type': 'text/html',
            },
            'body': response,
            'isBase64Encoded': False
        }
