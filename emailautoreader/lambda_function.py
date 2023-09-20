import json
import imaplib
import email
from email.header import decode_header
import webbrowser
import os
import boto3
buckname='mlops-insurance'
def writes3(content,buckname,buckobj):
   # print('inside s3 write fun')
    clnt=boto3.client('s3')
#    print('s3 initialized')
    clnt.put_object(Body=content, Bucket=buckname, Key=buckobj)
 #   print('returning')
    return '1'
def clean(text):
    # clean text for creating a folder
    print("Cleam text")
    return "".join(c if c.isalnum() else "_" for c in text)

def lambda_handler(event, context):
    # TODO implement

# account credentials
    username = "aiml1223@outlook.com"
    password = "aiml@123"
    #username = "ibhajandeep.singh@gmail.com"
    #password = "Dhangurunanak_1"
    
    # use your email provider's IMAP server, you can look for your provider's IMAP server on Google
    # or check this page: https://www.systoolsgroup.com/imap/
    # for office 365, it's this:
    imap_server = "outlook.office365.com"
    #imap_server="imap.gmail.com"
    print("Welcome to Email Reader")
    
    # create an IMAP4 class with SSL 
    imap = imaplib.IMAP4_SSL(imap_server)
    # authenticate
    imap.login(username, password)
    status, messages = imap.select("INBOX")
    print(status)
    # number of top emails to fetch
    N = 3
    # total number of emails
    print(messages)
    messages = int(messages[0])
    print(messages)
    dirop=[]
    loopiter=0
    for i in range(messages, messages-N, -1):
        # fetch the email message by ID
        print(loopiter)
        res, msg = imap.fetch(str(i), "(RFC822)")
        for response in msg:
            if isinstance(response, tuple):
                # parse a bytes email into a message object
                msg = email.message_from_bytes(response[1])
                # decode the email subject
                subject, encoding = decode_header(msg["Subject"])[0]
                if isinstance(subject, bytes):
                    # if it's a bytes, decode to str
                    subject = subject.decode(encoding)
                # decode email sender
                From, encoding = decode_header(msg.get("From"))[0]
                if isinstance(From, bytes):
                    From = From.decode(encoding)
                #dirop[i]["subject"] =subject
                #dirop[i]["From"] =From
                #emailitm={"subject":subject,"From":From}   
                #dirop.insert(i,emailitm)
                print("Subject:", subject)
                print("From:", From)
                #print(dirop)
                # if the email message is multipart
                if msg.is_multipart():
                    # iterate over email parts
                    for part in msg.walk():
                        # extract content type of email
                        content_type = part.get_content_type()
                        content_disposition = str(part.get("Content-Disposition"))
                        try:
                            # get the email body
                            body = part.get_payload(decode=True).decode()
                        except:
                            pass
                        if content_type == "text/plain" and "attachment" not in content_disposition:
                            # print text/plain emails and skip attachments
                            print(body)
                        elif "attachment" in content_disposition:
                            # download attachment
                            filename = part.get_filename()
                            if filename:
                                folder_name = clean(subject)
                                #if not os.path.isdir(folder_name):
                                    # make a folder for this email (named after the subject)
                                #    os.mkdir(folder_name)
                                filepath = os.path.join(folder_name, filename)
                                # download attachment and save it
                                locfilepath='/tmp/'+filename
                                open(locfilepath, "wb").write(part.get_payload(decode=True))
                                writes3(locfilepath,buckname,'emailauto/'+filepath)
                else:
                    # extract content type of email
                    content_type = msg.get_content_type()
                    # get the email body
                    body = msg.get_payload(decode=True).decode()
                    if content_type == "text/plain":
                        # print only text email parts
                        print(body)
                if content_type == "text/html":
                    # if it's HTML, create a new HTML file and open it in browser
                    folder_name = clean(subject)
                    # if not os.path.isdir(folder_name):
                    #     # make a folder for this email (named after the subject)
                    #     os.mkdir(folder_name)
                    filename = "index.html"
                    locfilepath='/tmp/'+filename
                    filepath = os.path.join(folder_name, filename)
                    # write the file
                    open(locfilepath, "w").write(body)
                    writes3(locfilepath,buckname,'emailauto/'+filepath)
                    # open in the default browser
                    webbrowser.open(filepath)
                print("="*100)
        emailitm={"subject":subject,"From":From,"Body":body}   
        dirop.insert(loopiter,emailitm)
        print(dirop[loopiter])
        loopiter+=1
        print(loopiter)
                
    # close the connection and logout
    imap.close()
    imap.logout()    