shinyUI(
    dashboardPage(
        dashboardHeader(title = "Graphic Grammers"),
        dashboardSidebar(    
            sidebarMenu(
                menuItem("About", tabName = "About", icon = icon("at")),
                menuItem("Investment Profiles", tabName = "LoansAnalysis",icon = icon("chart-line")),
                # menuItem("Portfolio Recommendation", tabName = "PortfolioRecommendation", icon = icon("th")),
                menuItem("Loan Data", tabName = "RawLoanData", icon = icon("th")),
                menuItem("Contact",tabName="Bio",icon=icon("address-card")),
                # hr(),
                # HTML("<h4>&nbsp; Portfolio Characteristic </h4>"),
                # selectInput("Objective", 
                #             label = h5("Objective"), 
                #             width='100%',
                #             choices = list("Risky" = 'Risky', 'Neutral',"Safe" = 'Safe'),
                #             selected = 1),
                # numericInput("budget", 
                #              label = h5("Budget"), 
                #              value = 1000,
                #              width='100%',
                #              step=1),
                # hr(),
                # 
                # HTML("<h4>&nbsp; Table Filter </h4>"),
                sliderInput("Loan_Amount", h4("Loan Amount:"),
                            min = 0, max = 40,
                            value = c(0,40)),
                sliderInput("Int_Rate", h4("Interest Rate %:"),
                            min = 0, max = 40,
                            value = c(0,40)),
                checkboxGroupInput("Grade", 
                                   label = h4("Loan Grade"), 
                                   choices = list("A" = "A", "B" = "B", 
                                                  "C" = "C","D" = "D",
                                                  "E" = "E",'F'='F',
                                                  'G'='G'),
                                   selected = c('A','B','C','D','E','F','G'),
                                   inline = FALSE),
                checkboxGroupInput("Term", 
                                   label = h4("Term"), 
                                   choices = list("3 years" = 36, "5 years" = 60),
                                   selected = c(36,60),
                                   inline = FALSE)
                
            )
        ),
        dashboardBody(
            tabItems(
                ############################ About #######################################
                tabItem(tabName = "About",
                        fluidRow(
                            HTML('<center><img src="basketball_logo.png" width="200" height="100"></center>'),
                            HTML("<h1>&nbsp; Haven for Fantasy Basketball Statistics</h1>"),
                            box(h4("XXX"),
                                width=12),
                            HTML("<h2>&nbsp; What is fantasy basketball?</h2>"),
                            box(h4("XXX"),
                                width=12),
                            HTML("<h2>&nbsp; Which scoring and drafting system is considered?</h2>"),
                            box(h4("XXX"),
                                width=12),
                            HTML("<h2>&nbsp; More on Fantasy Sports as a whole:</h2>"),
                            box(h4("XXX[1][2]"),
                                width=12),
                            HTML("<h2>&nbsp; Uhh.. What is the NBA?</h2>"),
                            box(h4("XXX"),
                                width=12),
                            HTML("<h2>&nbsp; Data Source and References:</h2>"),
                            box(h4("XXX"),
                                h4("[1] https://thefsga.org/industry-demographics/"),
                                h4("[2] https://www.reuters.com/brandfeatures/venture-capital/article?id=78816"),
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
                            box(title = "Your Portfolio:", width = 6, 
                                DT::dataTableOutput("LoanTableSelected"),
                                br(),
                                DT::dataTableOutput("LoanTable")),
                            
                            box(plotOutput("AmortizationPlot",
                                            height = 580,
                                            dblclick = "AmortizationPlot_dblclick",
                                            brush = brushOpts(
                                               id = "AmortizationPlot_brush",
                                               resetOnNew = TRUE
                                           )
                                ),
                                width=6
                            )
                        ),
                        fluidRow(
                            box("XXX
                                ",
                                width =12
                            )
                        )
                ),
                ############################ Portfolio Recommendation #######################################
                # tabItem(tabName = "PortfolioRecommendation",
                #         titlePanel('Portfolio Recommendation'),
                #         fluidRow(infoBoxOutput("Rec_returnBox"),
                #                  infoBoxOutput("Rec_defProbBox"),
                #                  infoBoxOutput("Rec_timeBox")),
                #         fluidRow(
                #             box(title = "Recommended Portfolio:", width = 6, 
                #                 DT::dataTableOutput("RecommendedPortfolio")),
                #             
                #             box(plotOutput("RecommendedPortfolioPlot",
                #                            height = 580,
                #                            dblclick = "RecommendedPortfolioPlot_dblclick",
                #                            brush = brushOpts(
                #                                id = "RecommendedPortfolioPlot_brush",
                #                                resetOnNew = TRUE
                #                            )
                #             ),
                #             width=6
                #             )
                #         ),
                #         fluidRow(
                #             box("XXX
                #                 ",
                #                 width =12
                #             )
                #         )
                # ),
                # 
                ############## Data #######################
                tabItem(tabName = "RawLoanData",
                        fluidRow(
                            box(title = "Data from Lending Club", 
                                width=12,
                                dataTableOutput('rawLoanTable'),
                                br(),
                                "This data was acquired from Kaggle.com"
                            )
                        )
                ),
                ############## Contact #######################
                tabItem(tabName = "Bio",
                        fluidRow(
                            box("XXXX",
                                br(),br(),
                               "XXXn",
                                br(),br(),
                                "XXX",
                                width=12
                                
                            )
                        )
                )
            )
        )
    )
)