shinyUI(
    dashboardPage(
        dashboardHeader(title = "Graphic Grammers",titleWidth=300),
        dashboardSidebar(
            width=300,
            sidebarMenu(
                menuItem("About", tabName = "About", icon = icon("at")),
                menuItem("Investment Profiles", tabName = "LoansAnalysis",icon = icon("chart-line")),
                menuItem("Portfolio Recommendation", tabName = "PortfolioRecommendation", icon = icon("th")),
                # menuItem("Loan Data", tabName = "RawLoanData", icon = icon("th")),
                menuItem("Contact",tabName="Bio",icon=icon("address-card")),
                hr(),
                HTML("<h3>&nbsp; Portfolio Characteristic </h3>"),
                fluidRow(
                    column(12,
                           selectInput("Objective",
                                       label = h5("Objective"),
                                       width='100%',
                                       choices = list("Risky" = 'Risky', 'Neutral',"Safe" = 'Safe'),
                                       selected = 1))
                ),
                hr(),

                HTML("<h3>&nbsp; Table Filter </h3>"),
                sliderInput("Loan_Amount", h4("Loan Amount:"),
                            min = 0, max = 40,
                            value = c(0,40)),
                sliderInput("Int_Rate", h4("Interest Rate %:"),
                            min = 0, max = 40,
                            value = c(0,40)),
                fluidRow(
                    column(5, offset=1,
                           checkboxGroupInput("Loan_Grade", 
                                              label = h4("Grade"), 
                                              choices = list("A" = "A", "B" = "B", 
                                                             "C" = "C","D" = "D",
                                                             "E" = "E",'F'='F',
                                                             'G'='G'),
                                              selected = c('A','B','C','D','E','F','G'),
                                              inline = FALSE)),
                    column(6, offset=0,
                           checkboxGroupInput("Term", 
                                              label = h4("Term"), 
                                              choices = list("3 years" = 36, "5 years" = 60),
                                              selected = c(36,60),
                                              inline = FALSE))
                )
            )
        ),
        dashboardBody(
            tabItems(
                ############################ About #######################################
                tabItem(tabName = "About",
                        fluidRow(
                            HTML('<center><img src="CoverPic" width="500" height="400"></center>'),
                            HTML("<h1>&nbsp; Investing in Lending Club</h1>"),
                            box(h4("This is an application made to help one make the most profitable investments in Lending Club loans.
                                    The two functionalities included here are: visualiztion of loans performance and a portfolio recommendation system based on 
                                    the user's investment strategy.
                                   "),
                                width=12),
                            HTML("<h2>&nbsp; What is Lending Club?</h2>"),
                            box(h4("Lending Club is a peer to peer lending platform. Borrowers apply for loans and investors can choose
                                   which loans to invest in online. Lending Club utilizes its own grading system and provides portfolios 
                                   to investors."),
                                width=12),
                            HTML("<h2>&nbsp; The methodology</h2>"),
                            box(h4("The ultimate objectives are to predict the total return of any loan and to find the best portfolio given a budget constraint. To tackle this, 
                                   the problem had to be broken into a few stages. The first is to be able to train a classifier that can accurately predict whether a loan defaults or not. 
                                   The second is to predict the loan duration of a loan. The combination of the two predicted results allow us to calculate the total return as well as the variance
                                   of a loan. These information, together with the user-defined budget constraint, are used to identify the best portfolio for the user. This is done by performing
                                   a simultaneous minimization of variance and maximization of return rate. The former is what reduces overall risk."),
                                width=12),
                            HTML("<h2>&nbsp; Our machine learning pipeline</h2>"),
                            box(h4("For our predictive models, we mainly relied on random forests due to its versatility. Logistic regression and various boosting method were used as well. Logistic regression, 
                                   despite its popularity in the financial sector, had limited usage in this dataset due to our imputation methods (imputation of -999). Several boosting algorithms did not perform well
                                   due to the sheer magnitude of the data size with the exception of xgboost which handled the dataset well but we did not see considerable gains relative to random forest.
                                   "),
                                width=12),
                            HTML("<h2>&nbsp; Data Source and References:</h2>"),
                            box(h4("[1] https://www.kaggle.com/wordsforthewise/lending-club"),
                                width=12)
                        )
                ),
                ############################ Loan Performance #######################################
                tabItem(tabName = "LoansAnalysis",
                        titlePanel('Loans Analysis'),
                        fluidRow(infoBoxOutput("returnBox"),
                                 infoBoxOutput("defProbBox"),
                                 infoBoxOutput("timeBox")),
                        fluidRow(
                            box(title = "Your Portfolio:", width = 12, 
                                DT::dataTableOutput("LoanTableSelected"),
                                br(),
                                DT::dataTableOutput("LoanTable"))),
                        fluidRow(    
                            box(plotOutput("AmortizationPlot",
                                            height = 580,
                                            dblclick = "AmortizationPlot_dblclick",
                                            brush = brushOpts(
                                               id = "AmortizationPlot_brush",
                                               resetOnNew = TRUE
                                           )
                                ),
                                width=12
                            )
                        )#,
                        # fluidRow(
                        #     box("XXX
                        #         ",
                        #         width =12
                        #     )
                        # )
                ),
                ############################ Portfolio Recommendation #######################################
                tabItem(tabName = "PortfolioRecommendation",
                        titlePanel('Portfolio Recommendation'),
                        fluidRow(infoBoxOutput("Rec_returnBox"),
                                 infoBoxOutput("Rec_defProbBox"),
                                 infoBoxOutput("Rec_timeBox")),
                        fluidRow(
                            box(title = "Recommended Portfolio:", width = 12,
                                DT::dataTableOutput("bestLoansTable"),
                                numericInput("budget",
                                            label = h5("Budget ($)"),
                                            value = 5000,
                                            width='20%',
                                            step=25),
                                actionButton('calculatePortfolio', 'Find Best Portfolios')
                                )),
                        fluidRow(
                            box(plotOutput("RecommendedPortfolioPlot",
                                           height = 580,
                                           dblclick = "RecommendedPortfolioPlot_dblclick",
                                           brush = brushOpts(
                                               id = "RecommendedPortfolioPlot_brush",
                                               resetOnNew = TRUE
                                           )
                            ),
                            width=12
                            )
                        )#,
                        # fluidRow(
                        #     box("XXX
                        #         ",
                        #         width =12
                        #     )
                        # )
                ),

                # ############## Data #######################
                # tabItem(tabName = "RawLoanData",
                #         fluidRow(
                #             box(title = "Data from Lending Club", 
                #                 width=12,
                #                 dataTableOutput('rawLoanTable'),
                #                 br(),
                #                 "This data was acquired from Kaggle.com"
                #             )
                #         )
                # ),
                ############## Contact #######################
                tabItem(tabName = "Bio",
                        fluidRow(
                            box("We are the Graphic Grammers, a team of five data scientists passionate about 
                            unraveling details hidden in confounding data. We like to be challenged by datasets 
                            that require. For more info about this application, please contact: ",
                                br(),
                                "ashish.sharma.as@gmail.com",
                                br(),
                                "austin.kcon.cheng@g.harvard.edu",
                                br(),
                               "brian.b.zou@outlook.com",
                               br(),
                               "gabriel.corbal@gmail.com",
                               br(),
                               "tnivon@gmail.com",
                                br(),br(),
                                width=12
                                
                            )
                        )
                )
            )
        )
    )
)