import json
import base64
import boto3
import email

"""
Use Case Name: Financial Statement Analysis
Function Names: lambda_handler()
Author: Sharath YD
Date: 03/07/2020
"""

s3 = boto3.client("s3")
bucket_name = 'finstmtinput'

def lambda_handler(event, context):
    # decoding form-data into bytes
    post_data = base64.b64decode(event['body'])
    print("post data decoded -", post_data)
    
    # fetching content-type
    content_type = event["headers"]['content-type']
    
    # concate Content-Type: with content_type from event
    ct = "Content-Type: " + content_type + "\n"
    
    # parsing message from bytes
    msg = email.message_from_bytes(ct.encode()+post_data)
    
    # checking if the message is multipart
    print("Multipart check : ", msg.is_multipart())
    #if message is multipart
    if msg.is_multipart():
        multipart_content = {}
        # retrieving form-data
        for part in msg.get_payload():
            multipart_content[part.get_param('name', header='content-disposition')] = part.get_payload(decode=True)
        
        # retrieve file name
        filename = msg.get_payload()[0].get_param('filename',  header='content-disposition')
        print('filename -', filename)
        # uploading file to S3
        print("Uploading file {0} to S3 {1}".format(filename, bucket_name))
        s3_upload = s3.put_object(Bucket=bucket_name, Key=filename, Body=multipart_content["file"])
        
        msg1 = "The job is submitted for processing"
        msg2 = "Please try the below tableau link for the results after 5 min <br> \
                <a href=\"https://eu-west-1a.online.tableau.com/#/site/wiprodaai/views/FinStmtAnalyzer/Dashboard1\">Tableau Result</a>"
        response = "<html><head><title>PDF Processing Result</title></head>" + \
            "<body><br><br><div style='background-color:#aaa;color:blue'><b>PDF Processing Result</b></div> <div style='background-color:#aaa;color:green'>" \
            + msg1 + "<br> <br>" \
            + msg2 + \
            "</div> <br> </body></html>"
            
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
        # on upload failure
        return {
            'statusCode': 500,
            'headers': {
            "Access-Control-Allow-Origin" : "*", 
            'Access-Control-Allow-Credentials' : True,
            'Content-Type': 'text/html',
            },
            'body': json.dumps('PDF file processing is failed')
        }
    

