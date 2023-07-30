# Importing required library
import pandas as pd
import numpy as np
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler
scale = StandardScaler()

# you can put any value here according to your situation
chunksize = 10000
from sklearn import preprocessing
import glob
import time
import uuid
import datetime
runtime=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
unqstr=datetime.datetime.now().strftime("%Y%m%d%H%M%S")
path = r'/opt/ml/processing/input' # Input path
all_files = glob.glob(path + "/*.csv")
#read them into pandas
filname=all_files[0].split('/')[-1]
filname=filname.split('.')[0]
df_list = [pd.read_csv(filename,nrows=100000) for filename in all_files]
data = pd.concat(df_list)
df = data.copy()
df_list = [pd.read_csv(filename) for filename in all_files]
data = pd.concat(df_list)
df = data.copy()
#change this as per the preprocesing used for training
#create all categorical variables that we did above for both training and test sets 
df['cabin_multiple'] = df.Cabin.apply(lambda x: 0 if pd.isna(x) else len(x.split(' ')))
df['cabin_adv'] = df.Cabin.apply(lambda x: str(x)[0])
df['numeric_ticket'] = df.Ticket.apply(lambda x: 1 if x.isnumeric() else 0)
df['ticket_letters'] = df.Ticket.apply(lambda x: ''.join(x.split(' ')[:-1]).replace('.','').replace('/','').lower() if len(x.split(' ')[:-1]) >0 else 0)
df['name_title'] = df.Name.apply(lambda x: x.split(',')[1].split('.')[0].strip())
#impute nulls for continuous data 
#df.Age = df.Age.fillna(training.Age.mean())
df.Age = df.Age.fillna(df.Age.median())
#df.Fare = df.Fare.fillna(training.Fare.mean())
df.Fare = df.Fare.fillna(df.Fare.median())
#drop null 'embarked' rows. Only 2 instances of this in training and 0 in test 
df.dropna(subset=['Embarked'],inplace = True)
#tried log norm of sibsp (not used)
df['norm_sibsp'] = np.log(df.SibSp+1)
# log norm of fare (used)
df['norm_fare'] = np.log(df.Fare+1)
# converted fare to category for pd.get_dummies()
df.Pclass = df.Pclass.astype(str)
#created dummy variables from categories (also can use OneHotEncoder)
all_dummies = pd.get_dummies(df[['PassengerId','Pclass','Sex','Age','SibSp','Parch','norm_fare','Embarked','cabin_adv','cabin_multiple','numeric_ticket','name_title']])
#scaling
encoded_df = all_dummies.copy()
encoded_df[['Age','SibSp','Parch','norm_fare']]= scale.fit_transform(encoded_df[['Age','SibSp','Parch','norm_fare']])
encoded_df['runtime']=runtime
encoded_df['modelname']='Linear Learner'
encoded_df['infertype']='Batch'
encoded_df['PassengerId']=df.PassengerId.apply(lambda x:str(x)+unqstr)
encoded_df.insert(0,'runtime',encoded_df.pop('runtime'))
encoded_df.insert(1,'modelname',encoded_df.pop('modelname'))
encoded_df.insert(2,'infertype',encoded_df.pop('infertype'))
encoded_df.insert(3,'PassengerId',encoded_df.pop('PassengerId'))
encoded_df.insert(4,'scorefilename',encoded_df.pop('scorefilename'))
#encoded_df.to_csv("score_prooutput.csv",index=False,header=False)
encoded_df.to_csv("/opt/ml/processing/output/test/"+filname+"_{}.csv".format(uuid.uuid1().time_low), index=False, header=False) # test data 
