source("D:/Github/rice_blast_forcast_app/R/get_data.R")
source("D:/Github/rice_blast_forcast_app/R/model.R")

#load sample data
weather_df <- get_weather_forecast(lat = 13.75 , lon = 100.35)

# 1. Classic
# --- Original Model (FIST - Legacy) ---
#calculate_rice_blast_risk <- function(weather_df) {
  # Add hourly risk flag - vectorized
  weather_df <- weather_df %>%
    mutate(
      is_favorable = (temp >= 20 & temp <= 30) & (humidity >= 90),
      date = as.Date(time, tz = "Asia/Bangkok")
    )
(weather_df)

  # Calculate daily risk
  daily_risk <- weather_df %>%
    group_by(date) %>%
    summarise(
      favorable_hours = sum(is_favorable, na.rm = TRUE),
      avg_temp = mean(temp, na.rm = TRUE),
      avg_humidity = mean(humidity, na.rm = TRUE),
      total_rain = sum(rain, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      risk_level = case_when(
        favorable_hours >= 10 ~ "High",
        favorable_hours >= 5 ~ "Medium",
        TRUE ~ "Low"
      ),
      risk_score = favorable_hours / 24 * 100
    )

  return(list(hourly = weather_df, daily = daily_risk))
}


# --- 2 EDRM - Beta Function Based ---

#' Temperature Factor (RcT) - Vectorized
#' @param temp Numeric vector of temperatures
#' @return Numeric vector of RcT values (0-1)
calculate_RcT <- function(temp) {
  Tmin <- 9
  Topt <- 26
  Tmax <- 35

  # Vectorized calculation
  result <- numeric(length(temp))
  valid <- temp > Tmin & temp < Tmax

  result[valid] <- {
    t <- temp[valid]
    part1 <- (t - Tmin) / (Topt - Tmin)
    part2 <- (Tmax - t) / (Tmax - Topt)
    exponent <- (Tmax - Topt) / (Topt - Tmin)
    part1 * (part2^exponent)
  }

  return(result)
}

#' Wetness Factor (RcW) - Vectorized
#' @param rain Numeric vector of rainfall
#' @param rh90_hrs Numeric vector of hours with RH >= 90%
#' @return Numeric vector of RcW values (0-1)
calculate_RcW <- function(rain, rh90_hrs) {
  result <- pmin(rh90_hrs / 12, 1.0) # Base: wetness hours
  result[rain > 100] <- 0 # Wash-off effect
  result[rain >= 1 & rain <= 50] <- 1.0 # Optimal rain
  return(result)
}

#' Plant Age Factor (RcA) - Vectorized
#' @param dat Numeric vector of days after transplanting
#' @return Numeric vector of RcA values (0.1-1)
calculate_RcA <- function(dat) {
  result <- ifelse(
    dat <= 40,
    1.0,
    ifelse(dat > 70, 0.1, 1.0 - (0.9 * (dat - 40) / 30))
  )
  return(result)
}

 calculate_rice_blast_risk_advanced <- function(weather_df, start_dat = 30) {
    # 1. Aggregate to Daily
    daily_data <- weather_df %>%
        mutate(date = as.Date(time, tz = "Asia/Bangkok")) %>%
        group_by(date) %>%
        summarise(
            Tmean = mean(temp, na.rm = TRUE),
            RHmean = mean(humidity, na.rm = TRUE),
            RainSum = sum(rain, na.rm = TRUE),
            RH90_hours = sum(humidity >= 90, na.rm = TRUE),
            .groups = "drop"
        )

    # 2. Calculate daily risk components - NOW FULLY VECTORIZED (no rowwise!)
    min_date <- min(daily_data$date)

    daily_results <- daily_data %>%
        mutate(
            RcT = calculate_RcT(Tmean),
            RcW = calculate_RcW(RainSum, RH90_hours),
            current_dat = start_dat + as.numeric(date - min_date),
            RcA = calculate_RcA(current_dat),
            risk_score = (RcT * RcW * RcA) * 100,
            risk_level = case_when(
                risk_score >= 60 ~ "High",
                risk_score >= 30 ~ "Medium",
                TRUE ~ "Low"
            )
        )

    # Calculate Severity Projection
    high_risk_days <- sum(daily_results$risk_score >= 60, na.rm = TRUE)
    peak_severity <- 0.6467 * high_risk_days + 0.6128

    hourly_df <- weather_df %>%
        mutate(date = as.Date(time, tz = "Asia/Bangkok"))

    return(list(
        daily = daily_results,
        hourly = hourly_df,
        severity_projection = peak_severity,
        high_risk_days = high_risk_days
    ))
}

# --- BUS Model ---

#' Calculate BUS Score for a single day
#' @param temp Average daily temperature
#' @param wet_hours Hours of leaf wetness (using RH >= 90% as proxy)
#' @param humid_hours Hours of high humidity (using RH >= 90% as proxy)
#' @return BUS score (0 to ~6)
calculate_bus_score <- function(temp, wet_hours, humid_hours) {
    # Temperature check
    if (temp < 15 || temp > 38) {
        return(0)
    }

    # Wetness check
    if (wet_hours <= 9) {
        return(0)
    }

    # Base BUS from wet hours
    bus <- 0
    if (wet_hours > 9 && wet_hours <= 15) {
        bus <- 1
    } else if (wet_hours > 15 && wet_hours <= 21) {
        bus <- 2
    } else if (wet_hours > 21) {
        bus <- 3
    }

    # Adjustments
    if (temp >= 19 && temp <= 29) {
        bus <- bus + 1
    }
    if (temp >= 23 && temp <= 26) {
        bus <- bus + 1
    }
    if (humid_hours > 16) {
        bus <- bus + 1
    }

    return(bus)
}

#

calculate_rice_blast_risk_bus <- function(weather_df) {
    # 1. Aggregate to Daily
    daily_data <- weather_df %>%
        mutate(date = as.Date(time, tz = "Asia/Bangkok"),
               dp = humidity.to.dewpoint(temp, humidity),
               dpd = temp - dp,
               wet = ifelse(dpd < 3.7 & humidity > 87, 1, 0)) %>%
        group_by(date) %>%
        summarise(
            Tmean = mean(temp, na.rm = TRUE),
            RHmean = mean(humidity, na.rm = TRUE),
            RainSum = sum(rain, na.rm = TRUE),
            # Using RH >= 90 as proxy for both wetness and high humidity hours
            RH90_hours = sum(humidity >= 90, na.rm = TRUE),
            wetSum = sum(wet, na.rm = TRUE),
            .groups = "drop"
        )

    # 2. Calculate BUS Score
    daily_data$bus_score <- mapply(
        calculate_bus_score,
        daily_data$Tmean,
        daily_data$wetSum,
        daily_data$RH90_hours
    )

    daily_results <- daily_data %>%
        mutate(
            risk_score = bus_score, # Use raw score for plot
            risk_level = case_when(
                bus_score > 2.25 ~ "High",
                TRUE ~ "Low"
            )
        )

    hourly_df <- weather_df %>%
        mutate(date = as.Date(time, tz = "Asia/Bangkok"))

    return(list(
        daily = daily_results,
        hourly = hourly_df,
        severity_projection = max(daily_results$bus_score, na.rm = TRUE), # Just show max score
        high_risk_days = sum(daily_results$bus_score > 2.25, na.rm = TRUE)
    ))
}




# --- BLASTAM Model ---

#' Calculate BLASTAM Risk
#' @param weather_df Data frame with 'temp', 'humidity', 'time' columns
#' @return List with 'daily' (risk data), 'hourly' (processed hourly data),
#'         'severity_projection' (number of high risk days predicted),
#'         'high_risk_days' (count of infection days detected)
calculate_rice_blast_risk_blastam <- function(weather_df) {

# 1. Process Hourly Data to find Infection Events
    # Rules:
    # - Wet period (RH >= 90%) >= 10 consecutive hours
    # - Min Temp during wet period > 16 C

    # We need to preserve order
    weather_df <- weather_df %>% arrange(time)

    # Use run-length encoding (rle) to find consecutive blocks
    wet_rle <- rle(weather_df$humidity >= 90)

    # Create an index to map back to original rows
    end_indices <- cumsum(wet_rle$lengths)
    start_indices <- c(1, head(end_indices, -1) + 1)

    # Identify valid infection periods
    is_long_wetness <- wet_rle$values & (wet_rle$lengths >= 10)

    # Initialize infection flag in hourly data
    weather_df$is_infection_period <- FALSE
    weather_df$infection_event_id <- NA

    infection_dates <- c()

    # Iterate through valid wet periods to check temperature
    if (any(is_long_wetness)) {
        valid_indices <- which(is_long_wetness)
        event_counter <- 1

        for (idx in valid_indices) {
            start_row <- start_indices[idx]
            end_row <- end_indices[idx]

            temps_in_period <- weather_df$temp[start_row:end_row]

            # Criteria 2: Min Temp > 16 C
            if (min(temps_in_period, na.rm = TRUE) > 16) {
                weather_df$is_infection_period[start_row:end_row] <- TRUE
                weather_df$infection_event_id[
                    start_row:end_row
                ] <- event_counter

                # Record the date(s) of this event
                dates_involved <- unique(as.Date(
                    weather_df$time[start_row:end_row],
                    tz = 'Asia/Bangkok'
                ))
                infection_dates <- unique(c(infection_dates, dates_involved))

                event_counter <- event_counter + 1
            }
        }
    }

    # 2. Generate Daily Risk Table
    infection_dates_num <- as.numeric(infection_dates)
    high_risk_dates_num <- infection_dates_num + 4 # 10 days later

    daily_results <- weather_df %>%
        mutate(date = as.Date(time, tz = 'Asia/Bangkok')) %>%
        group_by(date) %>%
        summarise(
            Tmean = mean(temp, na.rm = TRUE),
            RHmean = mean(humidity, na.rm = TRUE),
            RainSum = sum(rain, na.rm = TRUE),
            RH90_hours = sum(humidity >= 90, na.rm = TRUE),
            infection_detected = any(is_infection_period, na.rm = TRUE),
            .groups = 'drop'
        ) %>%
        mutate(
            date_num = as.numeric(date),
            risk_level = case_when(
                date_num %in% high_risk_dates_num ~ 'High',
                infection_detected ~ 'Infection (Latent)',
                TRUE ~ 'Low'
            ),
            risk_score = case_when(
                risk_level == 'High' ~ 100,
                risk_level == 'Infection (Latent)' ~ 50,
                TRUE ~ 0
            )
        )

    hourly_df <- weather_df %>%
        mutate(date = as.Date(time, tz = 'Asia/Bangkok'))

    return(list(
        daily = daily_results,
        hourly = hourly_df,
        severity_projection = length(unique(high_risk_dates_num)),
        high_risk_days = length(infection_dates)
    ))
}

# --- EPIBLA Model ---

#' Calculate EPIBLA Risk
#' @param weather_df Data frame with 'temp', 'humidity', 'time' columns
#' @param resistance_level "susceptible" or "resistant"
#' @return List with 'daily' (risk data), 'hourly' (processed hourly data),
#'         'severity_projection' (max severity found),
#'         'high_risk_days' (count of days with severity > 0.05)
calculate_rice_blast_risk_epibla <- function(
    weather_df,
    resistance_level = "susceptible"
) {
    # 1. Aggregate to Daily info needed for EPIBLA
    daily_weather <- weather_df %>%
        mutate(date = as.Date(time, tz = "Asia/Bangkok")) %>%
        group_by(date) %>%
        summarise(
            max_temp = max(temp, na.rm = TRUE),
            min_temp = min(temp, na.rm = TRUE),
            max_rh = max(humidity, na.rm = TRUE),
            min_rh = min(humidity, na.rm = TRUE),
            # Estimate "dew" on 0-2 scale based on RH >= 90 hours
            # 0: < 6h, 1: 6-12h, 2: > 12h
            rh90_hrs = sum(humidity >= 90, na.rm = TRUE),
            dew = case_when(
                rh90_hrs > 12 ~ 2,
                rh90_hrs > 6 ~ 1,
                TRUE ~ 0
            ),
            .groups = "drop"
        )

    # 2. Spore Estimation (Y1)
    # Y1 = 123.068 - 3.08*MaxTemp + 0.321*MaxRH - 0.37*MinRH
    daily_weather <- daily_weather %>%
        mutate(
            est_spores = 123.068 -
                (3.08 * max_temp) +
                (0.321 * max_rh) -
                (0.37 * min_rh),
            est_spores = pmax(0, est_spores)
        )

    # 3. Calculate 7-day preceding period components
    # Using window of 7 days (including current day)
    # Use partial = TRUE to compute with available data for first 6 days
    # total_spores (X1), avg_dew (X3), avg_min_temp (X2 for susc), avg_max_rh (X2 for res)

    daily_weather <- daily_weather %>%
        mutate(
            total_spores = rollapply(
                est_spores,
                7,
                FUN = sum,
                na.rm = TRUE,
                align = "right",
                partial = TRUE,
                fill = NA
            ),
            avg_dew = rollapply(
                dew,
                7,
                FUN = mean,
                na.rm = TRUE,
                align = "right",
                partial = TRUE,
                fill = NA
            ),
            avg_min_temp = rollapply(
                min_temp,
                7,
                FUN = mean,
                na.rm = TRUE,
                align = "right",
                partial = TRUE,
                fill = NA
            ),
            avg_max_rh = rollapply(
                max_rh,
                7,
                FUN = mean,
                na.rm = TRUE,
                align = "right",
                partial = TRUE,
                fill = NA
            )
        )

    # 4. Calculate Severity
    if (resistance_level == "susceptible") {
        # Susceptible Equation
        daily_weather <- daily_weather %>%
            mutate(
                sev = 0.5561 -
                    (0.0011 * total_spores) +
                    (0.0017 * avg_min_temp) +
                    (0.2493 * avg_dew)
            )
    } else {
        # Resistant Equation
        daily_weather <- daily_weather %>%
            mutate(
                sev = 1.0428 -
                    (0.00007 * total_spores) -
                    (0.0102 * avg_max_rh) +
                    (0.0659 * avg_dew)
            )
    }

    daily_results <- daily_weather %>%
        mutate(
            risk_score = pmax(0, pmin(1, sev)) * 100, # 0-100 scale
            risk_level = case_when(
                risk_score >= 10 ~ "High", # Severity thresholds can be tuned
                risk_score >= 5 ~ "Medium",
                TRUE ~ "Low"
            )
        )

    hourly_df <- weather_df %>%
        mutate(date = as.Date(time, tz = "Asia/Bangkok"))

    return(list(
        daily = daily_results,
        hourly = hourly_df,
        severity_projection = max(daily_results$risk_score, na.rm = TRUE),
        high_risk_days = sum(daily_results$risk_score >= 10, na.rm = TRUE)
    ))
}
