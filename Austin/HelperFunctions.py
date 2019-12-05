import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import scipy.stats as stats
import datetime

def missingValuesInfo(df):
    total = df.isnull().sum().sort_values(ascending = False)
    percent = round(df.isnull().sum().sort_values(ascending = False)/len(df)*100, 2)
    temp = pd.concat([total, percent], axis = 1,keys= ['Total', 'Percent'])
    return temp.loc[(temp['Total'] > 0)]

def dummify_columns(dataframe,column_name):
    '''
    - dataframe takes the entire dataframe you are working on
    - column_name takes a list of strings, where the strings are the column names
    - in the form of ['col'] for one column or ['col1','col2',...] for multiple columns
    '''
    dummified_df=dataframe.copy()
    for feature in column_name:
        dummified_feature = pd.get_dummies(dataframe.loc[:,feature], prefix=feature, prefix_sep='__',drop_first=True)
        dummified_df = pd.concat([dummified_df.drop(feature,axis=1),dummified_feature],axis=1,sort='False')
    return dummified_df

def undummify(dataframe):
    tot_col=dataframe.columns
    cat_col=list(tot_col[tot_col.str.contains('__')])
    cat_col_split=set(map(lambda x:x.split('__')[0],cat_col))
    cat_dict={}
    for col in cat_col_split:
        sub_df=dataframe[cat_col].loc[:,list(map(lambda x:col in x, dataframe[cat_col].columns))]
        for i in sub_df.columns:
            label_num=int(i.split('__')[1])
            sub_df.loc[:,i]=np.array(sub_df.loc[:,i])*label_num
        cat_dict[col]=sub_df.sum(axis=1)+1
    df1=dataframe.drop(cat_col,axis=1)
    df2=pd.DataFrame(cat_dict)
    return pd.concat([df1,df2],axis=1)

def plot_corr(df,threshold=0.7,size=30):
    df_number = df.select_dtypes(include = 'number')

    corr = df_number.corr(method="pearson")
    big_corr=corr[abs(corr)>threshold]
    big_corr.dropna(axis=0,how='all')
    np.fill_diagonal(big_corr.values, np.nan)
    big_corr=big_corr.dropna(axis=0,how='all')
    big_corr=big_corr.dropna(axis=1,how='all')
    plt.subplots(figsize=(size, size))
    cmap = sns.diverging_palette(150, 250, as_cmap=True)
    sns.heatmap(big_corr, cmap="Blues", annot = True);
    
def subcategoryANOVA(df,col,target):
    cat=list(df.loc[:,col].unique())
    compute_list=[]
    for subcat in cat:
        newlist=df.loc[df.loc[:,col]==subcat,target].values
        compute_list.append(newlist)
    fig,ax=plt.subplots(figsize=(10,8))
    df.boxplot(column=[target],by=col,ax=ax)
    return(stats.f_oneway(*compute_list))   

def subcategoryttest(df,col,subcat1,subcat2,target):
    compute_list=[]
    for subcat in [subcat1,subcat2]:
        newlist=df.loc[df.loc[:,col]==subcat,target]
        compute_list.append(newlist)
    return(stats.ttest_ind(*compute_list))
       
class minibatch(object):
    def __init__(self,df):
        df.issue_d=pd.to_datetime(df.issue_d)
        self.original=df.copy()
        self.remain_df=df.copy()
        self.return_df=pd.DataFrame()
    def takeout(self,starttime,endtime):
        initial_takeout_index=self.remain_df[(self.remain_df.issue_d>=starttime)&(self.remain_df.issue_d<endtime)].index
        temp_df=self.remain_df.loc[initial_takeout_index,:]       
        self.return_df=temp_df.loc[temp_df.loc[:,'loan_status']!='Current',:]
        final_takeout_index=self.return_df.index
        self.remain_df=self.remain_df.drop(final_takeout_index,axis=0)
        return self.return_df
    def restart(self):
        self.remain_df=self.original
        self.return_df=pd.DataFrame()
        
def down_sample(df,percent=0.1):
    '''
    dataframe needs to have:
    loan_status != CURRENT
    grade =  A B C D E F G
    loan_status = Fully Paid, Default
    '''
    month_grouped=df.groupby('issue_d',as_index=False)
    month_sampled_df=month_grouped.apply(lambda x: x.sample(frac=1,random_state=0))
    month_sampled_df.index=month_sampled_df.index.droplevel()
    default_rate_df=pd.DataFrame(month_sampled_df.groupby('grade').apply(lambda x:(x['loan_status']=='Default').sum()/x['loan_status'].count()),columns=['Default_Rate'])
    np.random.seed(0)
    down_sampled_df=pd.DataFrame()
    for grade in ['A','B','C','D','E','F','G']:
#         print(grade)
        if (default_rate_df.loc[grade,:][0] <=0.5):
            # in the case where we need to down sample fully paid:
            # stratifying by grade
            grade_df=(month_sampled_df.groupby('grade').get_group(grade))
            # Dividing into fully paid and default
            Fully_Paid_grade_df=grade_df[grade_df['loan_status']=='Fully Paid']
            Default_grade_df=grade_df[grade_df['loan_status']=='Default']
            # down sample fully paid sample size into default sample size
            down_sample_size=Default_grade_df.shape[0]
            down_sampled_index=np.random.choice(Fully_Paid_grade_df.index,size=down_sample_size,replace=False)
            down_sampled_Fully_Paid_grade_df=Fully_Paid_grade_df.loc[down_sampled_index,:]
            # Down sizing both fully paid and default loans to a user defined percentage
            down_sized_Fully_Paid_grade_df=down_sampled_Fully_Paid_grade_df.sample(frac=percent,random_state=0)
            down_sized_Default_grade_df=Default_grade_df.sample(frac=percent,random_state=0)
            # Combining the new downsampled dataframes together
            down_sampled_df=pd.concat([down_sampled_df,down_sized_Fully_Paid_grade_df])
            down_sampled_df=pd.concat([down_sampled_df,down_sized_Default_grade_df])
        else: 
            # in the case where we need to down sample default: 
            # stratifying by grade
            grade_df=(month_sampled_df.groupby('grade').get_group(grade))
            # Dividing into fully paid and default
            Fully_Paid_grade_df=grade_df[grade_df['loan_status']=='Fully Paid']
            Default_grade_df=grade_df[grade_df['loan_status']=='Default']
            # down sample fully paid sample size into default sample size
            down_sample_size=Default_grade_df.shape[0]
            down_sampled_index=np.random.choice(Default_grade_df.index,size=down_sample_size,replace=False)
            down_sampled_Default_grade_df=Default_grade_df.loc[down_sampled_index,:]
            # Down sizing both fully paid and default loans to a user defined percentage
            down_sized_Default_grade_df=down_sampled_Default_grade_df.sample(frac=percent,random_state=0)
            down_sized_Fully_Paid_grade_df=Fully_Paid_grade_df.sample(frac=percent,random_state=0)
            # Combining the new downsampled dataframes together
            down_sampled_df=pd.concat([down_sampled_df,down_sized_Default_grade_df])
            down_sampled_df=pd.concat([down_sampled_df,down_sized_Fully_Paid_grade_df])
    return down_sampled_df

def feature_standardize(data,scaleType='standardize'):
    '''
    - Accepts a dataframe column
    '''
    if scaleType not in ['standardize', 'normalize']: 
        raise ValueError('%s is not a valid choice' %(scaleType))
    mean_value=np.mean(data)
    standard_dev=np.std(data)
    min_value=np.min(data)
    max_value=np.max(data)
    if scaleType == 'standardize':
        return((data-mean_value)/standard_dev) 
    elif scaleType == 'normalize':
        return((data-min_value)/(max_value-min_value))
    
def label_encode_column(dataframe,column_name):
    '''
    - dataframe takes the entire dataframe you are working on
    - column_name takes a list of strings, where the strings are the column names
    '''
    from sklearn import preprocessing 
    label_encoder = preprocessing.LabelEncoder() 
    label_encoded_df=dataframe.copy()
    for feature in column_name:
        label_encoded_feature=label_encoder.fit_transform(label_encoded_df.loc[:,feature])
        tempdf=pd.DataFrame(label_encoded_feature,columns=['{}'.format(feature)])
        label_encoded_df = pd.concat([label_encoded_df.drop(feature,axis=1),tempdf],axis=1,sort='False')
    return label_encoded_df   

def columns_of_type(df,type_you_want):
    '''
    type_you_want = accepts a string:
    'number', 'object', 'category', 'bool', 'datetime', 'timedelta' 
    'continuous','string'
    '''
    df_number = df.select_dtypes(include = 'number')
    df_object = df.select_dtypes(include = 'object')
#     df_category = df.select_dtypes(include = 'category')
#     df_boolean = df.select_dtypes(include = 'bool')
#     df_datetime = df.select_dtypes(include = 'datetime')
#     df_timedelta = df.select_dtypes(include = 'timedelta')
    #######################################################
#     nominal_var=list(df_object.columns)
#     ordinal_var=list(df_number.columns)
#     continuous_var=list(df_number.columns)
#     time_var=list(df_datetime.columns)
    if (type_you_want=='number')|(type_you_want=='continuous'):
        return list(df_number.columns)
    elif (type_you_want=='object')|(type_you_want=='category')|(type_you_want=='string'):
        return list(df_object.columns)
    else: 
        raise ValueError('type is not a valid choice')