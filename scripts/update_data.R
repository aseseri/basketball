# scripts/update_data.R

# 1. Install/Load Packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(wehoop, dplyr, jsonlite, lubridate, janitor)

# 2. Fetch Data (2026 Season)
# We use tryCatch to ensure the website doesn't crash if ESPN is down
tryCatch({
  print("Fetching data from wehoop...")
  df <- wehoop::load_wbb_player_box(seasons = 2026) %>% 
    janitor::clean_names() # Standardizes names to snake_case (e.g., 'Points' -> 'points')

  # CRITICAL CHECK: Ensure data exists
  if (nrow(df) == 0) {
    stop("No data found. The season might not have started or the API is down.")
  }

  # 3. Calculate SEASON AVERAGES (The "Cool" Analytics)
  # We want players who score a lot but also grab rebounds (PPG vs RPG)
  season_stats <- df %>%
    filter(minutes > 0) %>%
    group_by(athlete_display_name, team_short_display_name) %>%
    summarise(
      games_played = n(),
      ppg = round(mean(points, na.rm = TRUE), 1),
      rpg = round(mean(rebounds, na.rm = TRUE), 1),
      apg = round(mean(assists, na.rm = TRUE), 1),
      total_pts = sum(points, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(games_played >= 5) %>% # Remove noise (players with < 5 games)
    arrange(desc(ppg)) %>%
    head(50) # Top 50 scorers

  # 4. Get YESTERDAY'S Leaders (The "Fresh" Content)
  latest_date <- max(as.Date(df$game_date))
  
  daily_leaders <- df %>% 
    filter(as.Date(game_date) == latest_date) %>%
    arrange(desc(points)) %>%
    head(10) %>% # Top 10 from yesterday
    select(athlete_display_name, team_short_display_name, points, rebounds, assists, game_date)

  # 5. Build JSON Structure
  export_data <- list(
    metadata = list(
      updated_at = as.character(Sys.time()),
      latest_game_date = as.character(latest_date)
    ),
    season_leaders = season_stats,
    daily_leaders = daily_leaders
  )

  # 6. Save File
  write_json(export_data, "data.json", pretty = TRUE, auto_unbox = TRUE)
  print(paste("Success! data.json created. Latest game:", latest_date))

}, error = function(e) {
  print(paste("Error:", e$message))
  quit(status = 1) # Force GitHub Action to fail so you get an email
})