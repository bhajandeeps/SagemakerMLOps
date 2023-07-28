# Importing required library
import pandas as pd
import numpy as np
from sklearn.impute import SimpleImputer
import glob
# you can put any value here according to your situation
chunksize = 10000
from sklearn import preprocessing
path = r'/opt/ml/processing/input' # Input path
all_files = glob.glob(path + "/*.csv")
#read them into pandas
df_list = [pd.read_csv(filename) for filename in all_files]
data = pd.concat(df_list)
df = data.copy()
df.drop(columns=['Unnamed: 0', 'id', 'url', 'region', 'region_url', 'VIN', 'size', 'image_url', 'description', 'state', 'lat', 'long','posting_date'], inplace=True)
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
train_data, validation_data, test_data = np.split(encoded_df.sample(frac=1, random_state=1729), [int(0.7 * len(encoded_df)), int(0.9*len(encoded_df))]) # Splitting dataset 
train_data.to_csv('/opt/ml/processing/train/train.csv', index=False, header=False) # train data
train_data.to_csv('/opt/ml/processing/trainbase/train_baseline.csv', index=False, header=True) # baseline data
validation_data.to_csv('/opt/ml/processing/validation/validation_data.csv', index=False, header=False) # validation data
test_data = test_data.iloc[:,1:] # removing cloumn where we have to do predictions
test_data.to_csv('/opt/ml/processing/test/test.csv', index=False, header=False) # test data 