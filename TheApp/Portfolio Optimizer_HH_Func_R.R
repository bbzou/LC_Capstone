library('nloptr')
portfolio_optimizer<-function(muVec,varVec,capVec,investAmount,numPortfolios=3){
  muVec=sort(muVec,decreasing = TRUE)
  # Returns a few mean-variance optimal portfolios of loans.
  
  # [Input]
  # muVec: SORTED expected return vector of each loan
  # varVec: corresponding variance vector
  # capVec: cap of investment in each loan
  # investAmount: total amount of investment
  # numPortfolios: number of recommended portfolios
  
  # [Output]
  # listPortfolio: a list of optimal portfolios
  # Returns a few mean-variance optimal portfolios of loans.
  
  # [Input]
  # muVec: SORTED expected return vector of each loan
  # varVec: corresponding variance vector
  # capVec: cap of investment in each loan
  # investAmount: total amount of investment
  # numPortfolios: number of recommended portfolios
  
  # [Output]
  # listPortfolio: a list of optimal portfolios
  
  n=length(muVec)
  invest=investAmount
  maxSum=0
  i=1
  while (invest>0){
    maxSum=maxSum+min(invest,capVec[i])*muVec[i]
    i=i+1
    invest=invest-min(invest,capVec[i])
  }
  
  r_max=maxSum/investAmount*100
  r_1=floor(r_max)
  r_2=min(floor(r_max*0.8),r_1-1)
  r_3=min(floor(r_max*0.6),r_2-1)
  
  if (r_3 >= min(muVec)*100){
    rVec=c(r_1,r_2,r_3)
  } else {
    rVec=c(r_1,r_2)
  }
  
  listPortfolio=vector()
  
  for (r_exp in rVec){
    # constraint1=1-sum(w)
    # constraint2=sum(w*muVec)-r_exp/100
    # var_portfolio=sum(w^2*varVec)
    
    constraint1<-function(w){
      return(1-sum(w))
    }
    
    constraint2<-function(w,mu_Vec=muVec){
      return(sum(w*mu_Vec)-r_exp/100)
    }
    
    var_portfolio<-function(w,var_Vec=varVec){
      return(sum(w^2*var_Vec))
    }
    
    lowerbounds=rep(0,n)
    upperbounds=capVec/investAmount
    
    x0=rep(1,n)/n
    print(r_exp)
    res=slsqp(x0, var_portfolio, lower = lowerbounds, upper = upperbounds, hin = constraint2, heq = constraint1,control = list(xtol_rel = 1e-7))
    listPortfolio=append(listPortfolio,list(round(res$par*investAmount)))
  }
  resultList <- list("rVec" = rVec, "listPortfolio" = listPortfolio)
  return(resultList)
}

ans=portfolio_optimizer(a[1:100],b[1:100],c[1:100],investAmount=10)
ans$listPortfolio[[1]][as.logical(ans$listPortfolio[[1]])]
