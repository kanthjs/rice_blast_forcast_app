library(dplyr)
library(lubridate)

# --- Original Model (Legacy) ---
calculate_rice_blast_risk <- function(weather_df) {
    # Add hourly risk flag
    weather_df <- weather_df %>%
        mutate(
            is_favorable = (temp >= 20 & temp <= 30) & (humidity >= 90),
            date = as.Date(time, tz = "Asia/Bangkok")
        )

    # Calculate daily risk
    daily_risk <- weather_df %>%
        group_by(date) %>%
        summarise(
            favorable_hours = sum(is_favorable, na.rm = TRUE),
            avg_temp = mean(temp, na.rm = TRUE),
            avg_humidity = mean(humidity, na.rm = TRUE),
            total_rain = sum(rain, na.rm = TRUE)
        ) %>%
        mutate(
            risk_level = case_when(
                favorable_hours >= 10 ~ "High",
                favorable_hours >= 5 ~ "Medium",
                TRUE ~ "Low"
            ),
            risk_score = favorable_hours / 24 * 100 # Normalize to 0-100 scale roughly
        )

    return(list(hourly = weather_df, daily = daily_risk))
}

# --- Advanced Model (Beta Function Based) ---

# 1. Temperature Factor (RcT)
calculate_RcT <- function(temp) {
    Tmin <- 9
    Topt <- 26
    Tmax <- 35

    if (temp <= Tmin | temp >= Tmax) {
        return(0)
    }

    part1 <- (temp - Tmin) / (Topt - Tmin)
    part2 <- (Tmax - temp) / (Tmax - Topt)
    exponent <- (Tmax - Topt) / (Topt - Tmin)

    rc_t <- part1 * (part2^exponent)
    return(rc_t)
}

# 2. Wetness Factor (RcW)
calculate_RcW <- function(rain, rh90_hrs) {
    if (rain > 100) {
        return(0)
    } # Wash-off
    if (rain >= 1 & rain <= 50) {
        return(1.0)
    }
    rc_w <- min(rh90_hrs / 12, 1.0)
    return(rc_w)
}

# 3. Plant Age Factor (RcA)
calculate_RcA <- function(dat) {
    if (dat <= 40) {
        return(1.0)
    }
    if (dat > 70) {
        return(0.1)
    }
    return(1.0 - (0.9 * (dat - 40) / 30))
}

# Advanced Rice Blast Model Execution
calculate_rice_blast_risk_advanced <- function(weather_df, start_dat = 30) {
    # 1. Aggregate to Daily
    daily_data <- weather_df %>%
        mutate(date = as.Date(time, tz = "Asia/Bangkok")) %>%
        group_by(date) %>%
        summarise(
            Tmean = mean(temp, na.rm = TRUE),
            RHmean = mean(humidity, na.rm = TRUE),
            RainSum = sum(rain, na.rm = TRUE),
            RH90_hours = sum(humidity >= 90, na.rm = TRUE)
        )

    # 2. Calculate daily risk components
    daily_results <- daily_data %>%
        rowwise() %>%
        mutate(
            RcT = calculate_RcT(Tmean),
            RcW = calculate_RcW(RainSum, RH90_hours),
            # Calculate current age based on days from min(date)
            current_dat = start_dat + as.numeric(date - min(daily_data$date)),
            RcA = calculate_RcA(current_dat),
            risk_score = (RcT * RcW * RcA) * 100, # Convert to 0-100 scale
            risk_level = case_when(
                risk_score >= 60 ~ "High",
                risk_score >= 30 ~ "Medium",
                TRUE ~ "Low"
            )
        ) %>%
        ungroup()

    # Calculate Severity Projection
    # x = count of days where risk_score >= 60 (Rc >= 0.6)
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
