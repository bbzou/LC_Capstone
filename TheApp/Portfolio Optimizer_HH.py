#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Dec 8 21:24:01 2019

@author: hanhao
"""

import numpy as np
import scipy
from scipy.optimize import minimize

def Markowitz_loan_portfolio(muVec, varVec, capVec, investAmount, numPortfolios=3):
    """
    Returns a few mean-variance optimal portfolios of loans.
    
    [Input]
    muVec: SORTED expected return vector of each loan
    varVec: corresponding variance vector
    capVec: cap of investment in each loan
    investAmount: total amount of investment
    numPortfolios: number of recommended portfolios
    
    [Output]
    listPortfolio: a list of optimal portfolios
    """
    n = len(muVec)
    muVec = np.array(muVec)
    varVec = np.array(varVec)
    capVec = np.array(capVec)
    
    invest = investAmount
    maxSum = 0
    i = 0
    while invest>0:
        maxSum = maxSum + min(invest, capVec[i]) * muVec[i]
        i = i + 1
        invest = invest - min(invest, capVec[i])
        
    r_max = maxSum / investAmount * 100
                  
    r_1 = np.floor(r_max)
    r_2 = min(np.floor(r_max*0.8), r_1-1)
    r_3 = min(np.floor(r_max*0.6), r_2-1)
    
    if r_3 >= min(muVec)*100:
        rVec = [r_1, r_2, r_3]
    else:
        rVec = [r_1, r_2]
    
    listPortfolio = []

    for r_exp in rVec:   
    
        def constraint1(w):   # Total investment
            return 1 - sum(w)
        def constraint2(w):   # Expected Return
            return sum(w*muVec) - r_exp / 100.0
        def var_portfolio(w): # Total Variance
            return sum((w**2) * varVec)
        
        cons = ({'type': 'eq', 'fun': constraint1},
                {'type': 'ineq', 'fun': constraint2})
        bds = scipy.optimize.Bounds(np.zeros(n), capVec/investAmount)
        
        x0 = np.ones(n) / n
        res = minimize(var_portfolio, x0 , method="SLSQP", constraints=cons, bounds=bds)
        listPortfolio.append(np.round(res.x*investAmount))
        
    return rVec, listPortfolio

# muVec = [.1,.09,.08,.07]
# varVec= [.16,.09,.04,.01]
# capVec= [100,100,100,100]
# investAmount = 150.0
# Markowitz_loan_portfolio(muVec, varVec, capVec, investAmount)