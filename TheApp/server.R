shinyServer(function(input, output,session) {
   
  
  ############### stats summary above loan table ##############################
  output$returnBox <- renderInfoBox({
    if (is.null(input$LoanTable_rows_selected)) {
      infoBox(paste('Effective Yield (%)'),0)
    } else {
      ids <- input$LoanTable_rows_selected
      infoBox(paste('Effective Yield (%)'),round(mean(user_df()[ids,'return_rate']),4)*100)
    }
  })
  output$defProbBox <- renderInfoBox({
    if (is.null(input$LoanTable_rows_selected)) {
      infoBox(paste('Default Rate (%)'),0)
    } else {
      ids <- input$LoanTable_rows_selected
      infoBox(paste('Default Rate (%)'),round(mean(user_df()[ids,'return_rate']),4)*100)
    }  
  })
  output$timeBox <- renderInfoBox({
    if (is.null(input$LoanTable_rows_selected)) {
      infoBox(paste('Survival Time (mths)'),0)
    } else {
      ids <- input$LoanTable_rows_selected
      infoBox(paste('Survival Time (mths)'),round(mean(user_df()[ids,'return_rate']),4))
    }  
  })
  
  ############### loan table  ##############################
    ####### Fiiltering the loan table #######  
    user_df<-reactive({
      trimmed_df%>%
        filter(loan_amnt>=input$Loan_Amount[1] & loan_amnt<=input$Loan_Amount[2])%>%
        filter(int_rate>=input$Int_Rate[1] & int_rate<=input$Int_Rate[2])%>%
        filter(grade%in%input$Loan_Grade)%>%
        filter(term%in%input$Term)%>%
        ungroup()
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
      
      PV=user_df()[ids,'loan_amnt']
      int_rate=user_df()[ids,'int_rate']
      term=user_df()[ids,'term']
  
        # Remaining_Balance_Formula
        # Remaining Balance = Future Value (FV)
        # Original Balance = Present Value (PV)
      if (60==max(user_df()[ids,'term'])){
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
        coord_cartesian(xlim = ranges$x, ylim = ranges$y, expand = FALSE)+
        xlab('Month')+
        ylab('Balance ($k)')+
        theme(axis.text.x = element_text(color = "grey20", size = 14, angle = 0, hjust = 0, vjust = 0, face = "bold"),
              axis.text.y = element_text(color = "grey20", size = 14, angle = 0, hjust = 0, vjust = 0, face = "bold"),  
              axis.title.x = element_text(color = "grey20", size = 14, angle = 0, hjust = .5, vjust = 0, face = 'bold'),
              axis.title.y = element_text(color = "grey20", size = 14, angle = 90, hjust = .5, vjust = .5, face = 'bold'))+
        scale_y_continuous(sec.axis = sec_axis(~./(scale_ratio/3), name = "Monthly Payment ($k)"))+
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
    bestLoans <- reactive({
      p <- user_df()$return_rate
      w <- matrix(user_df()$loan_amnt,nrow=1,byrow=TRUE)
      cap <- input$budget/1000
      mod <- lp(direction = "max",
                objective.in = p,
                const.mat = w,
                const.dir = c("<=", "="),
                const.rhs = c(cap),
                all.bin = TRUE)
      # Solution
      user_df()[which(mod$solution >= 0.999),]
      #mod$objval
    })
    
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
    
    output$bestLoansTable <- DT::renderDataTable(
      datatable(bestLoans(),
                options = list(scrollX = TRUE,pageLength = 13)
      )
    )   
    
    ############### stats summary above recommended portfolio table ##############################
    output$Rec_returnBox <- renderInfoBox({
      if (is.null(bestLoans()$return_rate)) {
        infoBox(paste('Effective Yield (%)'),0)
      } else {
        ids <- input$LoanTable_rows_selected
        infoBox(paste('Effective Yield (%)'),round(mean(bestLoans()[,'return_rate']),4)*100)
      }
    })
    output$Rec_defProbBox <- renderInfoBox({
      if (is.null(bestLoans()$return_rate)) {
        infoBox(paste('Default Rate (%)'),0)
      } else {
        ids <- input$LoanTable_rows_selected
        infoBox(paste('Default Rate (%)'),round(mean(bestLoans()[,'return_rate']),4)*100)
      }  
    })
    output$Rec_timeBox <- renderInfoBox({
      if (is.null(bestLoans()$return_rate)) {
        infoBox(paste('Survival Time (mths)'),0)
      } else {
        ids <- input$LoanTable_rows_selected
        infoBox(paste('Survival Time (mths)'),round(mean(bestLoans()[,'return_rate']),4))
      }  
    })
    
    
    ################## The Raw Data ###########################
    output$rawLoanTable <- DT::renderDataTable(
        datatable(df,rownames=FALSE,list(pageLength = 25),options = list(scrollX = TRUE,pageLength = 25))%>%
            formatStyle(columns = colnames(df),background="skyblue",fontWeight='bold',fontSize = '100%')
    )
})








  