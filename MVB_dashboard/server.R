#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
source("data_filters.R")

# Define server logic required to draw a histogram
function(input, output, session) {
  # load data
  data <- read_parquet("all_games_silver.parquet")
  # add season and date
  data = add_season_date(data)
  
  # Retrieve list of seasons and teams for the drop downs as soon as 
  # the app is launched
  observe({
    season_choices <- season_list(data)$season
    team_choices <- team_list(data)$team
    
    updateSelectInput(
      session,
      inputId = "season_overview_season",
      choices = season_choices,
      selected = season_choices[1]  # optional: preselect the first one
    )
    
    updateSelectInput(
      session,
      inputId = "season_overview_team",
      choices = team_choices,
      selected = "M-WATERLOO WARRIORS"  # optional: preselect the first one
    )
  })
  
  # Summary Statistics table--------------------------------------------------
  
  season_game_count = reactive({
    team_season_summary_table(data, input$season_overview_team, input$season_overview_season)
  })
  wins = reactive({
    season_game_count()$games_won
  })
  losses = reactive({
    season_game_count()$games_lost
  })
  
  # win loss
  output$win_loss <- renderText({
    paste("W:", wins(), " - L:", losses())
  })
  
  season_summary_stat = reactive({
    team_season_stat_table(data, input$season_overview_team, input$season_overview_season)
  })
  
  # Summary table
  output$summary_table <- renderTable({
    season_summary_stat()
  }, bordered = TRUE, align = "c", digits = 1)
  
  # Season Top Player table----------------------------------------------------
  season_top_players = reactive({
    req(input$season_overview_team, input$season_overview_season, input$top_players_skill)
    team_season_top_players(data, input$season_overview_team, input$season_overview_season, input$top_players_skill)
  })
  
  output$top_players_table <- renderTable({
    season_top_players()
  }, bordered = TRUE, align = "c", digits = 1)
  
  # Serve and Reception zone frequency-----------------------------------------
  season_serve_zone_freq = reactive({
    req(input$season_overview_team, input$season_overview_season)
    zone_frequency(data, input$season_overview_team, input$season_overview_season, "Serve", input$serve_rotation)
  })
  season_reception_zone_freq = reactive({
    req(input$season_overview_team, input$season_overview_season)
    zone_frequency(data, input$season_overview_team, input$season_overview_season, "Reception", input$reception_rotation)
  })
  output$serve_zone_plot <- renderPlot({
    season_serve_zone_freq()
  })
  output$reception_zone_plot <- renderPlot({
    season_reception_zone_freq()
  })
  
  
  # Best and Worst Rotation text-----------------------------------------------
  best_rotation <- list(rot = 3, points = 18)
  worst_rotation <- list(rot = 6, points = 22)
  
  
  # Bottom text
  output$rotation_text <- renderUI({
    tagList(
      p(strong("Best Rotation:"), paste0("(", best_rotation$rot, ") with ", best_rotation$points, " points won/set")),
      p(strong("Worst Rotation:"), paste0("(", worst_rotation$rot, ") with ", worst_rotation$points, " points lost/set"))
    )
  })
}
