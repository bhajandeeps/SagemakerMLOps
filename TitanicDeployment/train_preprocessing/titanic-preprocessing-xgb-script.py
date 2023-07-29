# Importing required library
import pandas as pd
import numpy as np
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler
scale = StandardScaler()
import glob
# you can put any value here according to your situation
chunksize = 10000
from sklearn import preprocessing
path = r'/opt/ml/processing/input' # Input path
all_files = glob.glob(path + "/*.csv")
#all_files=["/home/ec2-user/SageMaker/WipCoe/Notebooks_LatestCode/WiproFormat/train.csv"]
#read them into pandas
df_list = [pd.read_csv(filename) for filename in all_files]
data = pd.concat(df_list)
df = data.copy()
#change this as per the data set
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
all_dummies = pd.get_dummies(df[['PassengerId','Survived','Pclass','Sex','Age','SibSp','Parch','norm_fare','Embarked','cabin_adv','cabin_multiple','numeric_ticket','name_title']])
#scaling
encoded_df = all_dummies.copy()
encoded_df[['Age','SibSp','Parch','norm_fare']]= scale.fit_transform(encoded_df[['Age','SibSp','Parch','norm_fare']])
encoded_df
#Split to train test again
#split train test , change if diff split is requiredn
train_data, validation_data, test_data = np.split(encoded_df.sample(frac=1, random_state=1729), [int(0.7 * len(encoded_df)), int(0.9*len(encoded_df))]) # Splitting dataset 
train_data=train_data.drop(columns=['PassengerId'])#id is used for ground truth, if there is no id column in data create custom and use that
#workflow path
train_data.to_csv('/opt/ml/processing/train/train.csv', index=False, header=False) # train data
train_data.to_csv('/opt/ml/processing/trainbase/train_baseline.csv', index=False, header=True) # baseline data
#local path
# train_data.to_csv('titanic/train.csv', index=False, header=False) # xtrain data
# train_data.to_csv('titanic/train_baseline.csv', index=False, header=True) # baseline data
validbsline_data=validation_data.copy()
validation_data=validation_data.drop(columns=['PassengerId'])#id is used for ground truth, if there is no id column in data create custom and use that
validation_data.to_csv('/opt/ml/processing/validation/validation_data.csv', index=False, header=False) # validation data
#validation_data.to_csv('titanic/validation_data.csv', index=False, header=False) # validation data
validbsline= validbsline_data.drop(columns=['Survived']) # removing cloumn where we have to do predictions
validbsline.to_csv('/opt/ml/processing/baselinemodeldrift/baselinemodeldrift.csv', index=False, header=False)
#validbsline.to_csv('titanic/baselinemodeldrift.csv', index=False, header=False)
#validation data without label---one set
groundtrth=validbsline_data[['PassengerId','Survived']]#ground truth data should/only have Id,TargetVal colmun to corelate ground truth with predicted values 
groundtrth.to_csv('/opt/ml/processing/groundtruth/groundtruth.csv', index=False, header=True)
#groundtrth.to_csv('titanic/groundtruth.csv', index=False, header=True)
#ground truth (only label and ID)--2nd set
test_data = test_data.iloc[:,1:] # removing cloumn where we have to do predictions
test_data.to_csv('/opt/ml/processing/test/test.csv', index=False, header=False) # test data 
#test_data.to_csv('titanic/test.csv', index=False, header=False) # test data 
