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
      menuItem("Season Overview", tabName = "season_overview", icon = icon("volleyball")),
      menuItem("Compare Teams", tabName = "comp_teams", icon = icon("down-left-and-up-right-to-center")),
      menuItem("Game Analysis", tabName = "game_analysis", icon = icon("trophy")),
      menuItem("Player Analysis", tabName = "player_analysis", icon = icon("users"))
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
                ),
                box(title = "Top Players", status = "info", solidHeader = TRUE, width = 4,
                    # select input here is NOT WORKING! the table does not change when i change my skill input
                    selectInput("top_players_skill", "Select Skill:", 
                                choices = c("Attack", 
                                            "Block", 
                                            "Serve", 
                                            "Reception", 
                                            "Dig"), 
                                selected = "Attack"),
                    tableOutput("top_players_table"),
                    br(),
                    div(p("The players are ranked by the number of successful attempts of the selected skills."))
                )
              ),
              fluidRow(
                box(title = "Reception Zone", status = "info", solidHeader = TRUE, width = 6,
                    strong("Select Rotation (by Setter Position)"),
                    div(
                      style = "height: 100px; overflow-y: auto; border: 1px solid #ddd; padding: 5px;",
                      checkboxGroupInput("reception_rotation", NULL, 
                                  choices = c(1,2,3,4,5,6), 
                                  selected = c(1,2,3,4,5,6))
                      ),
                    plotOutput("reception_zone_plot"),
                    br(),
                    div(p("The heatmap shows the relative frequency of where the opponent's serves are typically received."))
                ),
                box(title = "Serve Zone", status = "info", solidHeader = TRUE, width = 6,
                    strong("Select Rotation (by Setter Position)"),
                    div(
                      style = "height: 100px; overflow-y: auto; border: 1px solid #ddd; padding: 5px;",
                      checkboxGroupInput("serve_rotation", NULL, 
                                         choices = c(1,2,3,4,5,6), 
                                         selected = c(1,2,3,4,5,6))
                    ),
                    plotOutput("serve_zone_plot"),
                    div(p("The heatmap shows the relative frequency of where serves typically land on the opponent's court."))
                )
              )
      ),
      tabItem(tabName = "comp_teams",
              h2("Compare Team Stats")),
      tabItem(tabName = "game_analysis",
              h2("Game Analysis")),
      tabItem(tabName = "player_analysis",
              h2("Player Analysis"))
    )
  )
)