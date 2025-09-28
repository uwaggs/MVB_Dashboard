library(dplyr)
library(arrow)
library(ggplot2)


add_season_date <- function(data) {
  # this function adds a season and date column to the perfbook data
  data %>%
    mutate(date = as.Date(substr(time, 1, 10))) %>%
    mutate(season = ifelse(as.numeric(substr(time, 6, 7)) < 8,
                           paste0(as.numeric(substr(time, 1, 4)) - 1, "-",
                                  substr(time, 1, 4)),
                           paste0(substr(time, 1, 4), "-",
                                  as.numeric(substr(time, 1, 4)) + 1)))
}

#--------------------------

team_season_list <- function(data) {
  # this function reads in the perfbook data, and returns a dataframe of 
  # matches, which is defined by home_team, visiting_team, and date
  # home team is listed before visiting team
  # list is sorted by date
  # it requires that date and season columns are already added to data
  
  data %>%
    select(home_team, visiting_team, date) %>%
    unique() %>%
    arrange(desc(date)) %>%
    mutate(match = paste0(date, ": ", home_team, " vs ", visiting_team)) %>%
    select(match)
}

#--------------------------

team_list <- function(data) {
  # this function reads in the perfbook data, and returns a dataframe of 
  # teams (append home and visiting teams into the same column)
  # it requires that date and season columns are already added to data
  

  home_lst = data %>%
    select(home_team) %>%
    unique() %>%
    rename(team = home_team)
  visit_lst = data %>%
    select(visiting_team) %>%
    unique() %>%
    rename(team = visiting_team)
  res = rbind(home_lst, visit_lst) %>%
    unique() %>%
    arrange(team)
  row.names(res) <- NULL
  res
}

#--------------------------

season_list <- function(data) {
  # this function reads in the perfbook data, and returns a dataframe of 
  # seasons
  # it requires that date and season columns are already added to data
  
  data %>%
    select(season) %>%
    unique() %>%
    arrange(desc(season))
}

#--------------------------

team_season_summary_table <- function(data, select_team, select_season) {
  # this function reads in the perfbook data, and filters for selected team and season
  # the data is then processed to create a summary table
  # it requires that date and season columns are already added to data
  
  # win-loss summary
  # calculate how many games the selected team won in the selected season
  data %>%
    filter((home_team == select_team | visiting_team == select_team) & season == select_season) %>%
    select(home_team, visiting_team, match_won_by) %>%
    unique() %>%
    summarise(games_won = sum(match_won_by == select_team),
             games_lost = sum(match_won_by != select_team))
}

#--------------------------

team_season_stat_table <- function(data, select_team, select_season) {
  # this function provides a summary of key stats for the selected team and season.
  # each skill (Attack, Block, Serve, Receive) is evaluated into 3 groups
  # Attack: Winning Attack (#), Error (=), Other
  # Block: Winning Block (#), Error (=), Other
  # Dig: Perfect or Good dig (# or +), Error (=), Other
  # Reception: Perfect or Positive Reception (# or +), Error (=), Other
  # Serve: Ace (#), Error (=), Other
  # evaluation code can be retrieved by looking at all unique combinations of skill, evaluation_code, and evaluation in the data
  # it requires that date and season columns are already added to data
  
  data %>%
    filter(team == select_team & season == select_season) %>%
    filter(skill %in% c("Attack", "Block", "Serve", "Reception","Dig")) %>%
    group_by(skill) %>%
    summarise(
      attempts = n(),
      success = sum((skill == "Attack" & evaluation_code == "#") |
                      (skill == "Block" & evaluation_code == "#") |
                      (skill == "Serve" & evaluation_code == "#") |
                      (skill == "Reception" & evaluation_code %in% c("+", "#")) |
                      (skill == "Dig" & evaluation_code %in% c("+", "#"))
      ),
      errors = sum(evaluation_code == "="),
      success_pct = round(100 * success / attempts, 1),
      error_pct = round(100 * errors / attempts, 1)
    ) %>%
    select(skill, attempts, success, success_pct, errors, error_pct) %>%
    # add other # and other %
    mutate(other = attempts - success - errors,
           other_pct = round(100 * other / attempts, 1)) %>%
    # for now, we only want percentages
    select(skill, success_pct, error_pct, other_pct) %>%
    rename(Metric = skill,
           #`Attempts` = attempts,
           #`Success #` = success,
           `Success %` = success_pct,
           #`Error #` = errors,
           `Error %` = error_pct,
           #`Other #` = other,
           `Other %` = other_pct)
}

#--------------------------

team_season_top_players <- function(data, select_team, select_season, select_skill) {
  # this function provides a list of top 5 players for a given skill and their 
  # success, error and other # for the selected team and season.
  # it requires that date and season columns are already added to data
  data %>%
    filter(team == select_team & season == select_season & skill == select_skill) %>%
    group_by(player_name) %>%
    summarise(
      attempts = n(),
      success = sum((skill == "Attack" & evaluation_code == "#") |
                      (skill == "Block" & evaluation_code == "#") |
                      (skill == "Serve" & evaluation_code == "#") |
                      (skill == "Reception" & evaluation_code %in% c("+", "#")) |
                      (skill == "Dig" & evaluation_code %in% c("+", "#"))
      ),
      errors = sum(evaluation_code == "="),
      success_pct = round(100 * success / attempts, 1),
      error_pct = round(100 * errors / attempts, 1)
    ) %>%
    select(player_name, attempts, success, success_pct, errors, error_pct) %>%
    arrange(desc(success)) %>%
    # add other # and other %
    mutate(other = attempts - success - errors,
           other_pct = round(100 * other / attempts, 1)) %>%
    select(player_name, success, success_pct, errors, error_pct) %>%
    # combine the # and % columns to show % (#)
    mutate(
      success_combined = paste0(success," (", success_pct, "%)"),
      errors_combined = paste0(errors, " (", error_pct, "%)")
    ) %>%
    rename(Player = player_name,
           `Success` = success_combined,
           `Error` = errors_combined) %>%
    select(Player, Success, Error) %>%
    slice_head(n = 5)
}

#--------------------------


#--------------------------

zone_frequency <- function(data, select_team, select_season, select_skill, select_setter_position) {
  # this function provides a heatmap of where the team's ball land
  # for a given skill (Attack, Serve, Reception, Set)
  # can specify by rotation (defined by the setter position).
  # note that one may select more than one setter position for aggregate result. 
  
  zone_coords <- data.frame(
    end_zone = c(4,3,2,7,8,9,5,6,1),
    x = c(1,2,3,1,2,3,1,2,3),   # left=1, center=2, right=3
    y = c(3,3,3,2,2,2,1,1,1)    # top=3, middle=2, bottom=1
  )
  
  serve_coords = data %>%
    filter(team == select_team & season == select_season & skill == select_skill 
           & setter_position %in% select_setter_position) %>%
    group_by(end_zone) %>%
    summarise(attempts = n()) %>%
    mutate(rate = attempts / sum(attempts)) %>%
    right_join(zone_coords, by = "end_zone") %>%
    tidyr::replace_na(list(attempts = 0, rate = 0))  # fill in missing zones with 0
  
  ggplot(serve_coords, aes(x = x, y = y, fill = rate)) +
    geom_tile(color = "black", linewidth = 0.5) +   # draw court squares
    geom_text(aes(label = paste0("Zone ", end_zone, "\n", attempts, " (", round(rate*100,1), "%)")), 
              data = serve_coords, color="black", size=5) +
    scale_fill_gradient(low = "white", high = "red") +
    # Add court outline
    geom_rect(aes(xmin = 0.5, xmax = 3.5, ymin = 0.5, ymax = 3.5),
              fill = NA, color = "black", size = 1) +
    #scale_x_continuous(breaks = 1:3, labels = c("Left", "Center", "Right")) +
    #scale_y_continuous(breaks = 1:3, labels = c("Back", "Middle", "Front")) +
    coord_fixed() +
    labs(fill = NULL, x = NULL, y = NULL) +
    theme_minimal(base_size = 14) + 
    theme(axis.ticks = element_blank(),
          axis.text = element_blank(),
          panel.grid = element_blank()) 
}



#--------------------------
# tests - need to put them here so that they don't run when sourced in server.R
if (sys.nframe() == 0) {
  
  df = read_parquet("MVB_dashboard/all_games_silver.parquet")
  df = add_season_date(df)
  
  add_season_date(df)
  
  team_season_list(df)
  
  team_list(df)
  
  season_list(df)
  
  team_season_summary_table(df, "M-WATERLOO WARRIORS", "2024-2025")
  
  team_season_stat_table(df, "M-WATERLOO WARRIORS", "2024-2025")
  
  team_season_top_players(df, "M-WATERLOO WARRIORS", "2024-2025", "Block")
  
  # plot for set is bit off - too much in the middle. is this normal? 
  zone_frequency(df, "W-WATERLOO WARRIORS", "2024-2025", "Set", c(1,5,6))
  
  
  zone_frequency(df, "W-WATERLOO WARRIORS", "2024-2025", "Serve", c(1,5,6))
  
}
#-------------------------

