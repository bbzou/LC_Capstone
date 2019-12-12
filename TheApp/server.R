shinyServer(function(input, output,session) {

  ############### stats summary above loan table ##############################
  output$returnBox <- renderInfoBox({
    if (is.null(input$LoanTable_rows_selected)) {
      infoBox(paste('Total Return (%)'),0,icon = icon("comment-dollar"))
    } else {
      ids <- input$LoanTable_rows_selected
      infoBox(paste('Total Return (%)'),round(mean(user_df()[ids,'Total_Return_Rate']),4)*100,icon = icon("comment-dollar"))
    }
  })
  output$defProbBox <- renderInfoBox({
    if (is.null(input$LoanTable_rows_selected)) {
      infoBox(paste('Default Rate (%)'),0,icon = icon("chart-line"))
    } else {
      ids <- input$LoanTable_rows_selected
      infoBox(paste('Default Rate (%)'),round(mean(user_df()[ids,'Default_Probability']),4)*100,icon = icon("chart-line"))
    }  
  })
  output$timeBox <- renderInfoBox({
    if (is.null(input$LoanTable_rows_selected)) {
      infoBox(paste('Expected Duration (mths)'),0,icon = icon("clock"))
    } else {
      ids <- input$LoanTable_rows_selected
      infoBox(paste('Expected Duration (mths)'),round(mean(user_df()[ids,'Duration']),4),icon = icon("clock"))
    }  
  })
  
  ############### loan table  ##############################
    ####### Fiiltering the loan table #######  
    user_df<-reactive({
      if (input$Objective=='Safe'){
        trimmed_df<-safe_df
      } else if (input$Objective=='Neutral'){
        trimmed_df<-neutral_df
      } else {
        trimmed_df<-risky_df
      }
      
      trimmed_df%>%
        filter(Loan_Amount>=input$Loan_Amount[1]*1000 & Loan_Amount<=input$Loan_Amount[2]*1000)%>%
        filter(Interest_Rate>=input$Int_Rate[1] & Interest_Rate<=input$Int_Rate[2])%>%
        filter(Grade%in%input$Loan_Grade)%>%
        filter(Term%in%input$Term)%>%
        ungroup()%>%
        arrange(-Total_Return_Rate)
    })
    output$LoanTable <- renderDataTable({user_df()%>%
        datatable(., rownames=TRUE, list(pageLength = 15),selection = list(mode = "multiple"),
                  caption = "Pick Your Portolio:",
                  options = list(scrollX = TRUE)
        )
    })
    
    ####### Selecting rows of the loan table #######  
    LoanTable_selected <- reactive({
      ids <- input$LoanTable_rows_selected
      user_df()[ids,]
    })
    output$LoanTableSelected <- DT::renderDataTable({
      datatable(
        LoanTable_selected(),
        selection = list(mode = "none"),
        caption = "Loans",
        options = list(scrollX = TRUE)
      )
    })
    
    ############### loan plot  ##############################
    
    ranges <- reactiveValues(x = NULL, y = NULL)
    
    output$AmortizationPlot <- renderPlot({
      
      ids <- input$LoanTable_rows_selected
      
      PV=user_df()[ids,'Loan_Amount']
      int_rate=user_df()[ids,'Interest_Rate']
      term=user_df()[ids,'Term']
  
        # Remaining_Balance_Formula
        # Remaining Balance = Future Value (FV)
        # Original Balance = Present Value (PV)
      if (60==max(user_df()[ids,'Term'])){
        Month=seq(0, 60, by=1)
      } else {
        Month=seq(0, 36, by=1)
      }
      
      # Initialize the vectors for plotting sums of info
      Total_Payment=rep(0,length(Month))
      Total_int=rep(0,length(Month))
      Total_Balance=rep(0,length(Month))
      
      if (length(ids)!=0){
        for (row in 1:length(ids)){
          # Finding individual loan payments
          installment<-(((int_rate[row]/100)/12)*PV[row])/((1-(1+((int_rate[row]/100)/12))**(-term[row])))
          Balance<-PV[row]*(1+int_rate[row]/100/12)^Month - installment*((1+int_rate[row]/100/12)^Month-1)/(int_rate[row]/100/12)
          Balance[Balance<0]=0
          
          if ((term[row]<40) & (length(Month)>40)){ 
            Payment=append(rep(installment,37),rep(0,24))
          } else {
            Payment=rep(installment,length(Month))
          }
          
          Monthly_Interest=Balance*int_rate[row]/12/100
          
          # Summing the loans
          Total_Payment=Total_Payment+Payment
          Total_int=Total_int+Monthly_Interest
          Total_Balance=Total_Balance+Balance
        } 
      }
      
      # To avoid printing error when no data is selected for plotting
      if (sum(Total_Payment)==0 | sum(Total_Balance)==0){
        plot_df=data.frame()
      } else {
        plot_df=data.frame(Month,Total_Balance,Total_Payment,Total_int)
      }
      # Defining the scale of the second y axis
      scale_ratio=max(Total_Balance)/max(Total_Payment)
      
      if (sum(Total_Payment)==0 | sum(Total_Balance)==0){
        ggplot()
      } else {
        plot_df%>%ggplot()+
        geom_point(aes(x=Month,y=Total_Balance))+
        geom_line(aes(x=Month,y=Total_Balance),color='black')+
        geom_bar(aes(x=Month,y=Total_Payment*scale_ratio/3),stat = "identity",yaxis = "y2",fill=rgb(1, 0, 0, alpha=0.25),color='black')+
        geom_bar(aes(x=Month,y=Total_int*scale_ratio/3),stat = "identity",yaxis = "y2",fill=rgb(0, 0, 1, alpha=0.25),color='black')+
        geom_vline(xintercept = round(mean(user_df()[ids,'Duration']),4))+
        geom_rect(aes(xmin=round(mean(user_df()[ids,'Duration']),4), xmax=Inf, ymin=0, ymax=Inf),color='grey',alpha=0.005)+
        coord_cartesian(xlim = ranges$x, ylim = ranges$y, expand = FALSE)+
        xlab('Month')+
        ylab('Balance ($)')+
        theme(axis.text.x = element_text(color = "grey20", size = 14, angle = 0, hjust = 0, vjust = 0, face = "bold"),
              axis.text.y = element_text(color = "grey20", size = 14, angle = 0, hjust = 0, vjust = 0, face = "bold"),  
              axis.title.x = element_text(color = "grey20", size = 14, angle = 0, hjust = .5, vjust = 0, face = 'bold'),
              axis.title.y = element_text(color = "grey20", size = 14, angle = 90, hjust = .5, vjust = .5, face = 'bold'))+
        scale_y_continuous(sec.axis = sec_axis(~./(scale_ratio/3), name = "Monthly Payment ($)"))+
        theme( axis.line.y.right = element_line(color = "red"), 
               axis.ticks.y.right = element_line(color = "red"),
               axis.text.y.right = element_text(color = "red"),
               axis.title.y.right = element_text(color = "red",face='bold'))
      }
    })
    
    # For zooming into plot
    observeEvent(input$AmortizationPlot_dblclick, {
      brush <- input$AmortizationPlot_brush
      if (!is.null(brush)) {
        ranges$x <- c(brush$xmin, brush$xmax)
        ranges$y <- c(brush$ymin, brush$ymax)

      } else {
        ranges$x <- NULL
        ranges$y <- NULL
      }
    })
    ############### the recommendation system  ##############################
    ############################################################################## 
    ############################################################################## 
    # The knapsack function 
    # knapsack <- function (w, p, cap) {
    #   n <- length(w)
    #   x <- logical(n)
    #   F <- matrix(0, nrow = cap + 1, ncol = n)
    #   G <- matrix(0, nrow = cap + 1, ncol = 1)
    #   for (k in 1:n) {
    #     F[, k] <- G
    #     H <- c(numeric(w[k]), G[1:(cap + 1 - w[k]), 1] + p[k])
    #     G <- pmax(G, H)
    #   }
    #   fmax <- G[cap + 1, 1]
    #   f <- fmax
    #   j <- cap + 1
    #   for (k in n:1) {
    #     if (F[j, k] < f) {
    #       x[k] <- TRUE
    #       j <- j - w[k]
    #       f <- F[j, k]
    #     }
    #   }
    #   inds <- which(x)
    #   wght <- sum(w[inds])
    #   prof <- sum(p[inds])
    #   return(list(capacity = wght, profit = prof, indices = inds))
    # }
    # bestLoans <- reactive({
    #     p <- user_df()$return_rate
    #     w <- user_df()$loan_amnt
    #     cap <- input$budget/1000
    #     is <- knapsack(w,p,cap)
    #     # Solution
    #     print(is$indices)
    #     user_df()[is$indices,]
    #   })
    
    
    ############ 1/0 Knap-sack Problem without constraint to select team with highest value #######################
    # library(knapsack)
    # library(adagio)
    # https://rdrr.io/rforge/knapsack/man/knapsack.html
    # bestLoans <- reactive({
    #   p <- user_df()$return_rate
    #   w <- user_df()$loan_amnt
    #   cap <- input$budget/1000
    #   is <- knapsack(w,p,cap)
    #   # Solution
    #   user_df()[is$indices,]
    # })
    
    ############ 1/0 Knap-sack Problem with constraint to select team with highest value #######################
    #https://stackoverflow.com/questions/34980658/knapsack-algorithm-restricted-to-n-element-solution
    # bestLoans <- reactive({
    #   p <- user_df()$return_rate
    #   w <- matrix(user_df()$loan_amnt,nrow=1,byrow=TRUE)
    #   cap <- input$budget/1000
    #   mod <- lp(direction = "max",
    #             objective.in = p,
    #             const.mat = w,
    #             const.dir = c("<=", "="),
    #             const.rhs = c(cap),
    #             all.bin = TRUE)
    #   # Solution
    #   user_df()[which(mod$solution >= 0.999),]
    #   #mod$objval
    # })
    
    ############ 1/0 Knap-sack Problem with constraint to select team with highest value #######################
    #https://stackoverflow.com/questions/34980658/knapsack-algorithm-restricted-to-n-element-solution
    # library(lpSolve)
    # bestLoans <- reactive({
    #   p <- user_df()$return_rate
    #   w <- user_df()$loan_amnt
    #   cap <- input$budget/1000
    #   exact.num.elt <- 1
    #   mod <- lp(direction = "max",
    #             objective.in = p,
    #             const.mat = rbind(w, rep(1, length(p))),
    #             const.dir = c("<=", "="),
    #             const.rhs = c(cap,exact.num.elt),
    #             all.bin = TRUE)
    #   # Solution
    #   user_df()[which(mod$solution >= 0.999),]
    #   #mod$objval
    # })
    
    # bestLoans <- reactive({
    #   p <- user_df()$return_rate
    #   p_var <- user_df()$return_rate*0.5
    #   w <- user_df()$loan_amnt
    #   cap <- input$budget/1000
    #   ans<-portfolio_optimizer(p,p_var,w,cap,numPortfolios=3)
    #   # Solution
    #   user_df()[as.logical(ans$listPortfolio[[1]]),]
    # })
    ############################################################################## 
    ############################################################################## 
    observeEvent(input$calculatePortfolio,{
      user_df()%>%arrange(-Total_Return_Rate)
      p <- user_df()$Total_Return_Rate
      p_var <- user_df()$Variance
      w <- user_df()$Loan_Amount
      cap <- input$budget
      ans<-portfolio_optimizer(p,p_var,w,cap,numPortfolios=3)
      # Solution
      bestLoans$data<-user_df()[as.logical(ans$listPortfolio[[1]]),]
      bestLoans$data[,'Investment Amount']<-ans$listPortfolio[[1]][as.logical(ans$listPortfolio[[1]])]
      bestLoans$total_return<-ans$rVec[[1]]
    })
    
    bestLoans <- reactiveValues(
      data=NULL,
      total_return=NULL
    )

    output$bestLoansTable <- DT::renderDataTable(
      datatable(
        bestLoans$data,
                options = list(scrollX = TRUE,pageLength = 13)
      )
    )   
    
    ############### stats summary above recommended portfolio table ##############################
    output$Rec_returnBox <- renderInfoBox({
      if (is.null(bestLoans$data)) {
        infoBox(paste('Total Return (%)'),0,icon = icon("comment-dollar"))
      } else {
        ids <- input$LoanTable_rows_selected
        infoBox(paste('Total Return (%)'),bestLoans$total_return,icon = icon("comment-dollar"))
      }
    })
    output$Rec_defProbBox <- renderInfoBox({
      if (is.null(bestLoans$data)) {
        infoBox(paste('Default Rate (%)'),0,icon = icon("chart-line"))
      } else {
        ids <- input$LoanTable_rows_selected
        infoBox(paste('Default Rate (%)'),round(mean(bestLoans$data[,'Default_Probability']),4)*100,icon = icon("chart-line"))
      }  
    })
    output$Rec_timeBox <- renderInfoBox({
      if (is.null(bestLoans$data)) {
        infoBox(paste('Expected Duration (mths)'),0,icon = icon("clock"))
      } else {
        ids <- input$LoanTable_rows_selected
        infoBox(paste('Expected Duration (mths)'),round(mean(bestLoans$data[,'Duration']),4),icon = icon("clock"))
      }  
    })
    
    
    ############### Recommend Portfolio Plot  ##############################
    
    ranges <- reactiveValues(x = NULL, y = NULL)
    
    output$RecommendedPortfolioPlot <- renderPlot({
      
      PV=bestLoans$data[,'Loan_Amount']
      int_rate=bestLoans$data[,'Interest_Rate']
      term=bestLoans$data[,'Term']
      
      # Remaining_Balance_Formula
      # Remaining Balance = Future Value (FV)
      # Original Balance = Present Value (PV)
      if (60==max(bestLoans$data[,'Term'])){
        Month=seq(0, 60, by=1)
      } else {
        Month=seq(0, 36, by=1)
      }
      
      # Initialize the vectors for plotting sums of info
      Total_Payment=rep(0,length(Month))
      Total_int=rep(0,length(Month))
      Total_Balance=rep(0,length(Month))
      
      if (length(dim(bestLoans$data)[1])!=0){
        for (row in 1:length(dim(bestLoans$data)[1])){
          # Finding individual loan payments
          installment<-(((int_rate[row]/100)/12)*PV[row])/((1-(1+((int_rate[row]/100)/12))**(-term[row])))
          Balance<-PV[row]*(1+int_rate[row]/100/12)^Month - installment*((1+int_rate[row]/100/12)^Month-1)/(int_rate[row]/100/12)
          Balance[Balance<0]=0
          
          if ((term[row]<40) & (length(Month)>40)){ 
            Payment=append(rep(installment,37),rep(0,24))
          } else {
            Payment=rep(installment,length(Month))
          }
          
          Monthly_Interest=Balance*int_rate[row]/12/100
          
          # Summing the loans
          Total_Payment=Total_Payment+Payment
          Total_int=Total_int+Monthly_Interest
          Total_Balance=Total_Balance+Balance
        } 
      }
      
      # To avoid printing error when no data is selected for plotting
      if (sum(Total_Payment)==0 | sum(Total_Balance)==0){
        plot_df=data.frame()
      } else {
        plot_df=data.frame(Month,Total_Balance,Total_Payment,Total_int)
      }
      # Defining the scale of the second y axis
      scale_ratio=max(Total_Balance)/max(Total_Payment)
      
      if (sum(Total_Payment)==0 | sum(Total_Balance)==0){
        ggplot()
      } else {
        plot_df%>%ggplot()+
          geom_point(aes(x=Month,y=Total_Balance))+
          geom_line(aes(x=Month,y=Total_Balance),color='black')+
          geom_bar(aes(x=Month,y=Total_Payment*scale_ratio/3),stat = "identity",yaxis = "y2",fill=rgb(1, 0, 0, alpha=0.25),color='black')+
          geom_bar(aes(x=Month,y=Total_int*scale_ratio/3),stat = "identity",yaxis = "y2",fill=rgb(0, 0, 1, alpha=0.25),color='black')+
          geom_vline(xintercept = round(mean(bestLoans$data[,'Duration']),4))+
          geom_rect(aes(xmin=round(mean(bestLoans$data[,'Duration']),4), xmax=Inf, ymin=0, ymax=Inf),color='grey',alpha=0.005)+
          coord_cartesian(xlim = ranges$x, ylim = ranges$y, expand = FALSE)+
          xlab('Month')+
          ylab('Balance ($)')+
          theme(axis.text.x = element_text(color = "grey20", size = 14, angle = 0, hjust = 0, vjust = 0, face = "bold"),
                axis.text.y = element_text(color = "grey20", size = 14, angle = 0, hjust = 0, vjust = 0, face = "bold"),  
                axis.title.x = element_text(color = "grey20", size = 14, angle = 0, hjust = .5, vjust = 0, face = 'bold'),
                axis.title.y = element_text(color = "grey20", size = 14, angle = 90, hjust = .5, vjust = .5, face = 'bold'))+
          scale_y_continuous(sec.axis = sec_axis(~./(scale_ratio/3), name = "Monthly Payment ($)"))+
          theme( axis.line.y.right = element_line(color = "red"), 
                 axis.ticks.y.right = element_line(color = "red"),
                 axis.text.y.right = element_text(color = "red"),
                 axis.title.y.right = element_text(color = "red",face='bold'))
      }
    })
    
    # For zooming into plot
    observeEvent(input$RecommendedPortfolioPlot_dblclick, {
      brush <- input$RecommendedPortfolioPlot_brush
      if (!is.null(brush)) {
        ranges$x <- c(brush$xmin, brush$xmax)
        ranges$y <- c(brush$ymin, brush$ymax)
        
      } else {
        ranges$x <- NULL
        ranges$y <- NULL
      }
    })
    
    ################## The Raw Data ###########################
    output$rawLoanTable <- DT::renderDataTable(
        datatable(df,rownames=FALSE,list(pageLength = 25),options = list(scrollX = TRUE,pageLength = 25))%>%
            formatStyle(columns = colnames(df),background="skyblue",fontWeight='bold',fontSize = '100%')
    )
})

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
  
  withProgress(message = 'Finding best loans', value = 0, {
  
  for (r_exp in rVec){
    # constraint1=1-sum(w)
    # constraint2=sum(w*muVec)-r_exp/100
    # var_portfolio=sum(w^2*varVec)
    incProgress(1/length(rVec), detail = paste("calculating..."))
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
  })
  resultList <- list("rVec" = rVec, "listPortfolio" = listPortfolio)
  return(resultList)
}

  






  