import json
import boto3
import os
import helper
client = boto3.client('transcribe')
clients3=boto3.client('s3')
s3 = boto3.resource('s3')
def writes3(content,buckname,buckobj):
    clnt=boto3.client('s3')
    clnt.put_object(Body=content, Bucket=buckname, Key=buckobj)
    return '1'


def lambda_handler(event, context):
    print(event)
    notificationMessage = json.loads(json.dumps(event))['Records'][0]['s3']
    print(notificationMessage)
    curS3Bucket = notificationMessage['bucket']['name']
    curS3ObjectName = notificationMessage['object']['key']
    filName = os.path.splitext(curS3ObjectName)[0]
    print("file name",filName)
    print("hi",curS3Bucket,curS3ObjectName)
    file_name=clients3.get_object(Bucket=curS3Bucket,Key=curS3ObjectName)
    objuri='s3://'+curS3Bucket+'/'+curS3ObjectName
    response=client.list_transcription_jobs(Status='COMPLETED',JobNameContains='audio')
    print(response,len(response['TranscriptionJobSummaries']))
    if len(response['TranscriptionJobSummaries'])>0:
        response = client.delete_transcription_job(TranscriptionJobName='audiosentanal')
    response = client.start_transcription_job(TranscriptionJobName='audiosentanal',
    LanguageCode='en-US',
    MediaFormat='mp3',
    Media={
        'MediaFileUri': objuri
    },
    Settings={
        'ShowSpeakerLabels': True,
        'MaxSpeakerLabels': 2
        }
    ,
    OutputBucketName='wipsentanalysis'
    )
    jobstatus=response['TranscriptionJob']['TranscriptionJobStatus']
    if jobstatus=='COMPLETED':
        print("Jobstatus",jobstatus)
    print(jobstatus)
    while (jobstatus!='COMPLETED'):
        #print("inside while loop",jobstatus)
        response=client.get_transcription_job(TranscriptionJobName='audiosentanal')
        jobstatus=response['TranscriptionJob']['TranscriptionJobStatus']
        #print("inside while loop 2",jobstatus)
    print("out while loop jobstatus",jobstatus)
    outputfil=response['TranscriptionJob']['Transcript']['TranscriptFileUri']
    print(outputfil)
    file_name=clients3.get_object(Bucket=curS3Bucket,Key='audiosentanal.json')
    f = file_name['Body'].read()
    f = f.decode("utf-8")
    json_content = json.loads((f))
    #restext=f['results']
    print("json  content",json_content)
    conten=helper.speakeridf(json_content)
#    print('speaker',conten)
    spekdict={}
    for i in range(0,len(conten)):
        spekdict[i]=conten[i]
        
    opspeakdict=json.dumps(spekdict)
    transcr=json_content['results']['transcripts'][0]['transcript']
    #for i in range(0,len(json_content['results']['speaker_labels'][segments])
    #print(transcr)
    #print("segment lenght",len(json_content['results']['speaker_labels']['segments']))
    #print("item lenght",len(json_content['results']['items']))
    comprehend = boto3.client("comprehend")
    sentres = comprehend.detect_sentiment(Text = transcr, LanguageCode = "en")
    opdict={"text":'',"sentiment":''}
    #print(sentres)
    opdict['text']=transcr
    opdict['sentiment']=sentres['Sentiment']
    print(opdict)
    sentop = json.dumps(sentres)
    objName ='sentiment.json'
    s=writes3(sentop,curS3Bucket,objName)    #print(pdfText)
    optxtsent = json.dumps(opdict)
    objName ='opdict_'+filName + '.json'
    s=writes3(optxtsent,curS3Bucket,objName)    #print(pdfText)
    #objName ='speakerIdent_'+filName + '.json'
    objName = 'speakerIdent.json'
    s=writes3(opspeakdict,curS3Bucket,objName)    #print(pdfText)
    
    #response = client.delete_transcription_job(
    #TranscriptionJobName='audiosentanal')
    
