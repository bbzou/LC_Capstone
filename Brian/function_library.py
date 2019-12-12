### This is the function library Brian defined for multiple usage ###

## import libraries
from sklearn import preprocessing
from sklearn import ensemble
import matplotlib.pyplot as plt

## define a label encoder function
def label_encoder(df_input):
#     from sklearn import preprocessing
    
    df = df_input.copy()
    
    # get the list of categorical features in the dataframe
    lst = df.select_dtypes(include = 'O').columns.tolist()
    
    # initiate a label encoder from sklearn
    le = preprocessing.LabelEncoder()
    
    # label endoce each feature column
    for l in lst:
        df[l] = le.fit_transform(df[l])
        
    return df

################################################################################

## Define a feature importance selector using random forest

def feature_selector_rf(x, y, class_or_reg, random_col_name, threshold = None,\
                        leaf_size = 30, n_estimators = 100, random_state = 10, plot = True):
    
#     from sklearn import ensemble
#     import matplotlib.pyplot as plt
    
    # initiate the model as a classifier or a regressor
    if 'class' in str.lower(class_or_reg):
        rf = ensemble.RandomForestClassifier()
    elif 'regress' in str.lower(class_or_reg):
        rf = ensemble.RandomForestRegressor()
    else:
        raise TypeError('class_or_reg has to be either class(*) or regress(*)')
    
    # change param settings - default: all CPUs, warm start, oob score
    rf.set_params(n_estimators = n_estimators, random_state = random_state, min_samples_leaf = leaf_size,\
                  oob_score = True, n_jobs = -1, warm_start = True)
    
    # fit the rf model
    rf.fit(x, y)
    
    # create a dataframe for feature importances
    df_fi = pd.DataFrame(rf.feature_importances_, index = x.columns, columns = ['Importance']).sort_values(by = 'Importance', ascending = False)
    
    # the cutoff feature importance is the larger of random column or defined threshold
    fi_random_col = df_fi.loc[random_col_name].Importance
    fi_threshold = 0 if threshold == None else threshold
    fi_cutoff = max(fi_random_col, fi_threshold)
    
    # selected features with feature importance >= the random column or the defined threshold if given
    df_selected = df_fi[df_fi.Importance >= fi_cutoff]
    df_dropped = df_fi[df_fi.Importance < fi_cutoff]
    
    lst_selected = df_selected.index.tolist()
    lst_dropped = df_dropped.index.tolist()

    # print RF oob & score
    print('RF score: %.4f'%rf.score(x, y))
    print('RF oob score: %.4f'%rf.oob_score_)
    print('-' * 88)    
    print('Important features by FI over cutoff or threshold:', lst_selected)
    
    if plot:
        # plot features with FI > Perc (1% by default)
        plt.figure(figsize = (10, 5))
        plt.barh(df_selected.index, df_selected.Importance, color = 'crimson', alpha = 0.5)
        plt.title('Top {} Feature Importances (>= {}%) - {}'.format(df_selected.shape[0], np.round(fi_cutoff * 100, 2), y.columns[0]))    
    
    # return list of selected features
    return lst_selected, lst_dropped

################################################################################

## define a time series function to apply feature_selector_rf function on a moving window basis
def fs_rf_moving_window(df, time_col, df_tgt_class = None, df_tgt_regress = None, time_window = 12, time_increment = 3):
    
    # get the list of time (dates, months, quarters etc.) 
    lst_time = df[time_col].unique().tolist()
    
    # set the time column as the index column for time window slicing and drop the column
    # in case it is treated as an important feature (this will be misleading as we already sliced upon time)
    df.set_index(time_col, drop = True, inplace = True)
    
    # add a column of randomly generated numbers to dataframe as the benchmark
    np.random.seed(10)
    df['random'] = np.random.random(df.shape[0])

    ## label encode categorical features
    df = label_encoder(df)
    
    # initiate an empty list and scores for final output
    lst_important = []
    score_c = 0
    score_r = 0
    oob_c = 0
    oob_r = 0
    
    # loop through each time window to perform feature selection using random forest ("feature_selector_rf")
    for i in range(0, len(lst_time) - time_window + 1, time_increment):
        # get the list of periods for this time window
        lst_window = lst_time[i : i + time_window]
        # slice out the dataframe for each time window
        df_window = df.loc[lst_window]
        
        if not df_tgt_class is None:
            df_tgt_class_window = df_tgt_class.loc[lst_window]
            lst_selected_rf, lst_dropped_rf, score, oob = feature_selector_rf(df_window, label_encoder(df_tgt_class_window), 'class', 'random', plot = False)
            lst_important += lst_selected_rf
            score_c = max(score_c, score)
            oob_c = max(oob_c, oob)
            print('{} to {} is done for classifier.'.format(lst_window[0], lst_window[-1]))
            
        if not df_tgt_regress is None:
            df_tgt_regress_window = df_tgt_regress.loc[lst_window]
            lst_selected_rf, lst_dropped_rf, score, oob = feature_selector_rf(df_window, df_tgt_regress_window, 'regress', 'random', plot = False)
            lst_important += lst_selected_rf
            score_r = min(score_r, score)
            oob_r = min(oob_r, oob)
            print('{} to {} is done for regressor.'.format(lst_window[0], lst_window[-1]))
            print('-' * 55)
    
    return list(set(lst_important)), score_c, score_r, oob_c, oob_r
