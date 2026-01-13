library(httr)
library(jsonlite)
library(dplyr)
library(lubridate)

get_weather_forecast <- function(lat, long, days = 7) {
  base_url <- "https://api.open-meteo.com/v1/forecast"
  
  response <- GET(base_url, query = list(
    latitude = lat,
    longitude = long,
    hourly = "temperature_2m,relative_humidity_2m,rain,wind_speed_10m",
    forecast_days = days,
    past_days = 2, # Get some history for context
    timezone = "Asia/Bangkok"
  ))
  
  if (status_code(response) == 200) {
    data <- fromJSON(content(response, "text"))
    
    # Process hourly data
    hourly_data <- data$hourly
    df <- data.frame(
      time = as.POSIXct(hourly_data$time, format = "%Y-%m-%dT%H:%M", tz = "Asia/Bangkok"),
      temp = hourly_data$temperature_2m,
      humidity = hourly_data$relative_humidity_2m,
      rain = hourly_data$rain,
      wind_speed = hourly_data$wind_speed_10m
    )
    return(df)
  } else {
    stop("Failed to fetch data from Open-Meteo API")
  }
}
