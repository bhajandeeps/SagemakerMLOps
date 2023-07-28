import argparse
import logging
import os
import pathlib
import requests
import tempfile
from sklearn import preprocessing
import glob
import boto3
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler, OneHotEncoder
import uuid
import time
import datetime
runtime=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
unqstr=datetime.datetime.now().strftime("%Y%m%d%H%M%S")
logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())
feature_columns_names = [
    "Id",
    "age",
    "sex",
    "bmi",
    "children",
    "smoker",
    "region",
]
feature_columns_dtype = {
    "Id":np.float64,
    "age": np.float64,
    "sex": str,
    "bmi": np.float64,
    "children": np.float64,
    "smoker": str,
    "region": str,
}
chunksize = 10000
path = r'/opt/ml/processing/input' # Input path
all_files = glob.glob(path + "/*.csv")
#read them into pandas
df_list = [pd.read_csv(filename,nrows=100000) for filename in all_files]
data = pd.concat(df_list)
filname=all_files[0].split('/')[-1]
filname=filname.split('.')[0]
df = data.copy()
numeric_features = list(feature_columns_names)
numeric_features.remove("sex")
numeric_features.remove("smoker")
numeric_features.remove("region")
numeric_features.remove("Id")
numeric_transformer = Pipeline(
    steps=[("imputer", SimpleImputer(strategy="median")), ("scaler", StandardScaler())]
)
categorical_features = ["sex", "smoker", "region"]
categorical_transformer = Pipeline(
    steps=[
        ("imputer", SimpleImputer(strategy="constant", fill_value="missing")),
        ("onehot", OneHotEncoder(handle_unknown="ignore")),
    ]
)
preprocess = ColumnTransformer(
    transformers=[
        ("num", numeric_transformer, numeric_features),
        ("cat", categorical_transformer, categorical_features),
    ]
)
prepro_df = preprocess.fit_transform(df)
encoded_df=pd.DataFrame(prepro_df)
encoded_df['runtime']=runtime
encoded_df['modelname']='XGboost'
encoded_df['infertype']='Batch'
encoded_df['id']=df.Id.apply(lambda x:str(x)+unqstr)
encoded_df.insert(0,'runtime',encoded_df.pop('runtime'))
encoded_df.insert(1,'modelname',encoded_df.pop('modelname'))
encoded_df.insert(2,'infertype',encoded_df.pop('infertype'))
encoded_df.insert(3,'id',encoded_df.pop('id'))
#encoded_df.insert(4,'scorefilename',encoded_df.pop('scorefilename'))
df['id']=encoded_df['id']=df.Id.apply(lambda x:str(x)+unqstr)
encoded_df.to_csv("/opt/ml/processing/output/test/"+"batchinferdata.csv", index=False, header=False) # test data
df['Id']=df.Id.apply(lambda x:str(x)+unqstr)
df.to_csv("/opt/ml/processing/output/orig/"+filname+"_{}.csv".format(uuid.uuid1().time_low), index=False, header=True) 
