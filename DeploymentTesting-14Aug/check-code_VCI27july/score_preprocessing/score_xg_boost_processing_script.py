# Importing required library
import pandas as pd
import numpy as np
from sklearn.impute import SimpleImputer
# you can put any value here according to your situation
chunksize = 10000
from sklearn import preprocessing
import glob

path = r'/opt/ml/processing/input' # Input path
all_files = glob.glob(path + "/*.csv")
#read them into pandas
df_list = [pd.read_csv(filename,nrows=100000) for filename in all_files]
data = pd.concat(df_list)

df = data.copy()
df.drop(columns=['Unnamed: 0','url', 'region', 'region_url', 'VIN', 'size', 'image_url', 'description', 'state', 'lat', 'long','posting_date'], inplace=True)
imr = SimpleImputer(strategy='mean')
imr = imr.fit(df[['odometer']])
imputed_data = imr.transform(df[['odometer']])
df['odometer'] = pd.DataFrame(imputed_data)
def encode_features(dataframe):
    result = dataframe.copy()
    encoders = {}
    # Importing required library
import pandas as pd
import numpy as np
from sklearn.impute import SimpleImputer
# you can put any value here according to your situation
chunksize = 10000
from sklearn import preprocessing
import glob

path = r'/opt/ml/processing/input' # Input path
all_files = glob.glob(path + "/*.csv")
#read them into pandas
df_list = [pd.read_csv(filename,nrows=100000) for filename in all_files]
data = pd.concat(df_list)

df = data.copy()
df.drop(columns=['Unnamed: 0','url', 'region', 'region_url', 'VIN', 'size', 'image_url', 'description', 'state', 'lat', 'long','posting_date'], inplace=True)
imr = SimpleImputer(strategy='mean')
imr = imr.fit(df[['odometer']])
imputed_data = imr.transform(df[['odometer']])
df['odometer'] = pd.DataFrame(imputed_data)
def encode_features(dataframe):
    result = dataframe.copy()
    encoders = {}
    for column in result.columns:
        if column=='year':
            result[column]=result[column]
            
        elif result.dtypes[column] == np.object:
            encoders[column] = preprocessing.LabelEncoder()
            result[column] = encoders[column].fit_transform(result[column])
    return result, encoders
encoded_df, encoders = encode_features(df.astype(str)) 
encoded_df=encoded_df[encoded_df['year']!='nan']
encoded_df.to_csv('/opt/ml/processing/output/test/batchscoring.csv', index=False, header=False) # test data 
