import json
import boto3
import os

def speakeridf(json_content):
    transcr=json_content['results']['transcripts'][0]['transcript']
    #print(transcr)
    #print("segment lenght",len(json_content['results']['speaker_labels']['segments']))
    #print("item lenght",len(json_content['results']['items']))
    prespk='spek99'
    contlist=[]
    spkrlbl=''
    innerlp=0
    for spkr in range(0,len(json_content['results']['speaker_labels']['segments'])):
        #print('outerloopindex',spkr,'ineerlp',innerlp)
     #   print("content as of now",contlist)
        segmcont=json_content['results']['speaker_labels']['segments'][spkr]
      #  print(segmcont['start_time'],segmcont['end_time'],segmcont['speaker_label'])
        strttime=float(segmcont['start_time'])
        endttime=float(segmcont['end_time'])
        conten=''
        for i in range(innerlp,len(json_content['results']['items'])):
            if json_content['results']['items'][i]['type']=='pronunciation':
                spkrlbl='yes'
       ##         print(strttime,':',json_content['results']['items'][i]['start_time'])
        #        print(endttime,';',json_content['results']['items'][i]['end_time'])
                if float(json_content['results']['items'][i]['start_time'])>=strttime and float(json_content['results']['items'][i]['end_time'])<=endttime:
         #           print("inside content")
                    conten=conten+' '+json_content['results']['items'][i]['alternatives'][0]['content']
          #          print(conten)
                else:
           #         print('before',spkrlbl,i)
                    spkrlbl='No'
                    innerlp=i
                    break
                #print('after',spkrlbl,i)
            elif json_content['results']['items'][i]['type']=='punctuation' and spkrlbl=='yes':
                conten=conten+json_content['results']['items'][i]['alternatives'][0]['content']
            else:
                print("nothing to be done")
        
        if segmcont['speaker_label']==prespk:#if prev speaker continues...append the content
            contlist[-1]=contlist[-1]+' '+conten
        else:#append new item to the list
            conten=segmcont['speaker_label']+': '+conten
            contlist.append(conten)
    return contlist