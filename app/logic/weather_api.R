# app/logic/weather_api.R - Weather API functions with caching and retry logic
# Pure R functions for fetching weather data from Open-Meteo API

box::use(
  httr[RETRY, status_code, content, timeout],
  jsonlite[fromJSON],
)

# --- Simple in-memory cache for API responses ---
.weather_cache <- new.env(parent = emptyenv())

#' Clear the weather cache
#' @export
clear_weather_cache <- function() {
  rm(list = ls(envir = .weather_cache), envir = .weather_cache)
  invisible(TRUE)
}

#' Fetch weather forecast from Open-Meteo API
#'
#' @param lat Latitude
#' @param long Longitude
#' @param days Number of forecast days (default 7)
#' @param use_cache Whether to use cached data (default TRUE)
#' @param cache_duration_hours How long cache is valid in hours (default 1)
#' @return Data frame with hourly weather data
#' @export
get_weather_forecast <- function(
  lat,
  long,
  days = 7,
  use_cache = TRUE,
  cache_duration_hours = 1
) {
  # Round coordinates for cache key (nearby locations share cache)
  lat_rounded <- round(lat, 2)
  long_rounded <- round(long, 2)
  cache_key <- paste(lat_rounded, long_rounded, days, sep = "_")

  # Check cache first
  if (use_cache && exists(cache_key, envir = .weather_cache)) {
    cached <- get(cache_key, envir = .weather_cache)
    cache_age_hours <- as.numeric(difftime(
      Sys.time(),
      cached$timestamp,
      units = "hours"
    ))

    if (cache_age_hours < cache_duration_hours) {
      message(
        "Using cached weather data (age: ",
        round(cache_age_hours * 60, 1),
        " minutes)"
      )
      return(cached$data)
    }
  }

  # API call with retry logic
  base_url <- "https://api.open-meteo.com/v1/forecast"

  response <- tryCatch(
    {
      RETRY(
        "GET",
        base_url,
        query = list(
          latitude = lat,
          longitude = long,
          hourly = "temperature_2m,relative_humidity_2m,rain,wind_speed_10m",
          forecast_days = days,
          past_days = 2,
          timezone = "Asia/Bangkok"
        ),
        times = 3, # Retry up to 3 times
        pause_base = 1, # Wait 1 second between retries
        pause_cap = 10, # Max wait 10 seconds
        timeout(30) # 30 second timeout
      )
    },
    error = function(e) {
      stop(
        "Network error: Unable to connect to weather service. Please check your internet connection."
      )
    }
  )

  # Check response status
  if (status_code(response) != 200) {
    if (status_code(response) == 429) {
      stop("Rate limit exceeded. Please wait a moment and try again.")
    } else if (status_code(response) >= 500) {
      stop(
        "Weather service is temporarily unavailable. Please try again later."
      )
    } else {
      stop(paste(
        "API error:",
        status_code(response),
        "-",
        content(response, "text")
      ))
    }
  }

  # Parse response
  data <- tryCatch(
    {
      fromJSON(content(response, "text", encoding = "UTF-8"))
    },
    error = function(e) {
      stop(
        "Failed to parse weather data. The response format may have changed."
      )
    }
  )

  # Validate data structure
  if (is.null(data$hourly) || is.null(data$hourly$time)) {
    stop("Invalid response: Missing hourly data from weather API.")
  }

  # Process hourly data
  hourly_data <- data$hourly
  df <- data.frame(
    time = as.POSIXct(
      hourly_data$time,
      format = "%Y-%m-%dT%H:%M",
      tz = "Asia/Bangkok"
    ),
    temp = as.numeric(hourly_data$temperature_2m),
    humidity = as.numeric(hourly_data$relative_humidity_2m),
    rain = as.numeric(hourly_data$rain),
    wind_speed = as.numeric(hourly_data$wind_speed_10m),
    stringsAsFactors = FALSE
  )

  # Handle missing values
  df$rain[is.na(df$rain)] <- 0
  df$wind_speed[is.na(df$wind_speed)] <- 0

  # Save to cache
  if (use_cache) {
    assign(
      cache_key,
      list(data = df, timestamp = Sys.time()),
      envir = .weather_cache
    )
    message(
      "Weather data cached for location: ",
      lat_rounded,
      ", ",
      long_rounded
    )
  }

  return(df)
}
