#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(shinydashboard)

# Define UI for application that draws a histogram

dashboardPage(
  dashboardHeader(title = "Waterloo Warriors MVB Dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Season Overview", tabName = "season_overview", icon = icon("dashboard"))
    )
  ),
  dashboardBody(
    tabItems(
      # Season Overview tab
      tabItem(tabName = "season_overview",
              fluidRow(
                box(title = "Filters", status = "primary", solidHeader = TRUE, width = 4,
                    selectInput("season_overview_season", "Select Season:", choices = NULL),
                    selectInput("season_overview_team", "Select Team:", choices = NULL)
                ),
                # box(title = "Win/Loss Record", status = "info", solidHeader = TRUE, width = 4,
                #     textOutput("win_loss")
                # ),
                box(title = "Summary Statistics", status = "info", solidHeader = TRUE, width = 4,
                    div(style = 'text-align: center', textOutput("win_loss")),
                    br(),
                    tableOutput("summary_table"),
                    br(),
                    div(p("We define Success as an attempt that earns a point (for attack, block, and serve) or 
                                 results in a good pass (for reception and dig), and Error as an attempt that loses a point."))
                )
              ),
              fluidRow(
                box(title = "Best Rotation", status = "success", solidHeader = TRUE, width = 6,
                    textOutput("best_rotation")
                ),
                box(title = "Worst Rotation", status = "danger", solidHeader = TRUE, width = 6,
                    textOutput("worst_rotation")
                )
              )
      )
    ),
    tabItem(tabName = "comp",
            h3("Competition Analysis (placeholder)")
    ),
    tabItem(tabName = "game",
            h3("Game Analysis (placeholder)")
    ),
    tabItem(tabName = "player",
            h3("Player Analysis (placeholder)")
    )
  )
)