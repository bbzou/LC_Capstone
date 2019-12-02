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