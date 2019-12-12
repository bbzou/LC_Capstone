library(ggplot2)
library(plotly)
library(dplyr)
library(tidyr)
library(data.table)
library(shiny)
library(shinydashboard)
library(corrplot)
library(DT)
library(shinydashboard)
library(lpSolve)
# library(knapsack)
# library(adagio)

############# Rounding function to perform on dataframe ############################################
round_df <- function(x, digits) {
  # round all numeric variables
  # x: data frame 
  # digits: number of digits to round
  numeric_columns <- sapply(x, mode) == 'numeric'
  x[numeric_columns] <-  round(x[numeric_columns], digits)
  return(x)
}
################### Reading Data #########################################################
# path <- file.path("~/Desktop/CapstoneProject_LendingClubApp/Data/Demo_Table_Completed_Loans.csv")
# df<-read.csv(path, header = TRUE, stringsAsFactors = FALSE,na.strings=c('NA','NaN','',' ')) 

path <- file.path("./Data/safe_df.csv")
safe_df<-read.csv(path, header = TRUE, stringsAsFactors = FALSE,na.strings=c('NA','NaN','',' ')) 
path <- file.path("./Data/neutral_df.csv")
neutral_df<-read.csv(path, header = TRUE, stringsAsFactors = FALSE,na.strings=c('NA','NaN','',' ')) 
path <- file.path("./Data/risky_df.csv")
risky_df<-read.csv(path, header = TRUE, stringsAsFactors = FALSE,na.strings=c('NA','NaN','',' ')) 

safe_df[safe_df==-999]='N/A'
safe_df$expected_duration<-safe_df$expected_duration*12
safe_df<-round_df(safe_df,4)
neutral_df[neutral_df==-999]='N/A'
neutral_df$expected_duration<-neutral_df$expected_duration*12
neutral_df<-round_df(neutral_df,4)
risky_df[risky_df==-999]='N/A'
risky_df$expected_duration<-risky_df$expected_duration*12
risky_df<-round_df(risky_df,4)

setnames(safe_df, old=c('funded_amnt','fico_score','term','return_rate','int_rate','expected_duration','grade','purpose','annual_inc','actual_prob','loan_variance'),
         new=c('Loan_Amount','FICO','Term','Total_Return_Rate','Interest_Rate','Duration','Grade','Purpose','Annual_Inc','Default_Probability','Variance'))
safe_df<-safe_df[,c('Loan_Amount','Total_Return_Rate','Interest_Rate','Duration','Grade','FICO','Term','Purpose','Annual_Inc','Default_Probability','Variance')]

setnames(neutral_df, old=c('funded_amnt','fico_score','term','return_rate','int_rate','expected_duration','grade','purpose','annual_inc','actual_prob','loan_variance'),
         new=c('Loan_Amount','FICO','Term','Total_Return_Rate','Interest_Rate','Duration','Grade','Purpose','Annual_Inc','Default_Probability','Variance'))
neutral_df<-neutral_df[,c('Loan_Amount','Total_Return_Rate','Interest_Rate','Duration','Grade','FICO','Term','Purpose','Annual_Inc','Default_Probability','Variance')]

setnames(risky_df, old=c('funded_amnt','fico_score','term','return_rate','int_rate','expected_duration','grade','purpose','annual_inc','actual_prob','loan_variance'),
         new=c('Loan_Amount','FICO','Term','Total_Return_Rate','Interest_Rate','Duration','Grade','Purpose','Annual_Inc','Default_Probability','Variance'))
risky_df<-risky_df[,c('Loan_Amount','Total_Return_Rate','Interest_Rate','Duration','Grade','FICO','Term','Purpose','Annual_Inc','Default_Probability','Variance')]