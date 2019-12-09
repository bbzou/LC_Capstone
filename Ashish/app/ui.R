shinyUI(
    dashboardPage(
        dashboardHeader(title = "Graphic Grammers"),
        dashboardSidebar(
            
            
            # Search for occurrences of "**AS**" to find changes to be made
            # **AS**
            # Start : Search for occurrences of "**AS**" to find changes to be made
            # Add this to extend the sidebar. Needed because 2 selectinput boxes on the same level look
            # very small. 5 digits in budget column does not fit.
            tags$style(HTML("
                .main-sidebar{
                width: 300px;}")),
            # End.
            
            sidebarMenu(
                menuItem("About", tabName = "About", icon = icon("at")),
                menuItem("Investment Profiles", tabName = "LoansAnalysis",icon = icon("chart-line")),
                menuItem("Portfolio Recommendation", tabName = "PortfolioRecommendation", icon = icon("th")),
                menuItem("Loan Data", tabName = "RawLoanData", icon = icon("th")),
                menuItem("Contact",tabName="Bio",icon=icon("address-card")),
                hr(),
                HTML("<h4>&nbsp; Portfolio Characteristic </h4>"),
                
                
                # **AS**
                # Start - Remove below:
                selectInput("Objective",
                            label = h5("Objective"),
                            width='100%',
                            choices = list("Risky" = 'Risky', 'Neutral',"Safe" = 'Safe'),
                            selected = 1),
                numericInput("budget",
                             label = h5("Budget ($)"),
                             value = 5000,
                             width='100%',
                             step=1),
                # End.
                
                
                
                # **AS**
                # Start: The above that should be removed are added below under fluid row
                fluidRow(
                    column(6,
                           selectInput("Objective",
                                       label = h5("Objective"),
                                       width='100%',
                                       choices = list("Risky" = 'Risky', 'Neutral',"Safe" = 'Safe'),
                                       selected = 1)),
                    column(6,
                           numericInput("budget",
                                        label = h5("Budget ($)"),
                                        value = 5000,
                                        width='100%',
                                        step=1))
                ),
                # End.
                
                
                hr(),

                HTML("<h3>&nbsp; Table Filter </h3>"),
                sliderInput("Loan_Amount", h4("Loan Amount:"),
                            min = 0, max = 40,
                            value = c(0,40)),
                sliderInput("Int_Rate", h4("Interest Rate %:"),
                            min = 0, max = 40,
                            value = c(0,40)),
                checkboxGroupInput("Loan_Grade", 
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
            
            
            # **AS**
            # Start - Add the below since for alignment of the rest of content with the extended sidebar menu
            tags$head(tags$style(HTML(' .main-sidebar{ width: 300px; } .main-header > .navbar { margin-left: 300px; } .main-header .logo { width: 300px; } .content-wrapper, .main-footer, .right-side { margin-left: 300px; } '))),
            # End.
            
            
            
            
            
            tabItems(
                ############################ About #######################################
                tabItem(tabName = "About",
                        fluidRow(
                            HTML('<center><img src="basketball_logo.png" width="200" height="100"></center>'),
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
                            HTML("<h2>&nbsp; Our data analysis methodology</h2>"),
                            box(h4("XXX"),
                                width=12),
                            HTML("<h2>&nbsp; Our machine learning pipeline</h2>"),
                            box(h4("XXX[1][2]"),
                                width=12),
                            HTML("<h2>&nbsp; </h2>"),
                            box(h4("XXX"),
                                width=12),
                            HTML("<h2>&nbsp; Data Source and References:</h2>"),
                            box(h4("XXX"),
                                h4("[1] https://kaggle"),
                                h4("[2] https://www."),
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
                tabItem(tabName = "PortfolioRecommendation",
                        titlePanel('Portfolio Recommendation'),
                        fluidRow(infoBoxOutput("Rec_returnBox"),
                                 infoBoxOutput("Rec_defProbBox"),
                                 infoBoxOutput("Rec_timeBox")),
                        fluidRow(
                            box(title = "Recommended Portfolio:", width = 6,
                                DT::dataTableOutput("bestLoansTable")),

                            box(plotOutput("RecommendedPortfolioPlot",
                                           height = 580,
                                           dblclick = "RecommendedPortfolioPlot_dblclick",
                                           brush = brushOpts(
                                               id = "RecommendedPortfolioPlot_brush",
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
                            box("We are the Graphic Grammers, a team of five data scientists passionate about 
                            unraveling details hidden in confounding data. We like to be challenged by datasets 
                            that require. For more info about this application, please contact: ",
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