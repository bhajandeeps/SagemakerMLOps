import pandas as pd
import json
import glob
#path = r'/opt/ml/processing/input' # Input path
path='/opt/ml/processing/input/data'
all_files = glob.glob(path + "/*",recursive=True)
# all_files=['s3://ds-mlops-s3/data/scoreoutput/lr/2022/02/17/18/batchscoring.csv.out']
counter = 0
print(all_files)
for filename in all_files:
    print("hi")
    df = pd.read_csv(filename,header=None)
    df = df.sample(frac=.25)
    df=df.iloc[: ,3:].drop([4],axis = 1)
    # Create a multiline json
    json_list = json.loads(df.to_json(orient = "records"))
    output_path = "/opt/ml/processing/xgb/datacapture.jsonl" #path to the linear learner
    print(output_path)
    counter = counter + 1
    data = {}
    data["captureData"]={
            "endpointInput": {
                "observedContentType": "text/csv",
                "mode": "INPUT",
                "data": "132,25,113.2,96,269.9,107,229.1,87,7.1,7,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,1",
                "encoding": "CSV"
            },
            "endpointOutput": {
                "observedContentType": "text/csv; charset=utf-8",
                "mode": "OUTPUT",
                "data": "6295.23876953125",
                "encoding": "CSV"
            }
        }
    data["eventMetadata"] = {
            "eventId": "",
            "inferenceTime": "2"
        }
    data["eventVersion"] = "0"
    i=0
    with open(output_path, 'w') as f:
        print(output_path)
        for item in json_list:
            i=i+1
            if item['5'][0:3]!='col':
                item = list(item.values())
                inpitem = ','.join([str(elem) for elem in item[1:-1]])
                #outitem = ','.join([str(elem) for elem in item[-1]])
                outitem=str(item[-1])
                data["captureData"]["endpointInput"]["data"] = inpitem
                data["captureData"]["endpointOutput"]["data"] =outitem
                data["eventMetadata"]["eventId"]=str(item[0])
                if i==len(json_list):
                    f.write("%s" % data)
                else:
                    f.write("%s\n" % data)
# Data push
