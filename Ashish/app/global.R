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
path <- file.path("./Data/Demo_Table_Completed_Loans.csv")
df<-read.csv(path, header = TRUE, stringsAsFactors = FALSE,na.strings=c('NA','NaN','',' ')) 
df[df==-999]='N/A'
df['funded_amnt']=df['funded_amnt']/1000
df['annual_inc']=df['annual_inc']/1000
df<-round_df(df,4)
setnames(df, old=c('funded_amnt','fico_score','int_rate'), 
         new=c('loan_amnt','fico','int_rate'))
trimmed_df<-df[,c('loan_amnt','return_rate','fico','int_rate','duration','term','grade','purpose','annual_inc','term')]
