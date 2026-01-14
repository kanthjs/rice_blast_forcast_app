# Verification Script for BLASTAM Model Rule

source("R/model.R")

# Helper to create synthetic weather data
create_synthetic_data <- function(hours, temp_val, rh_val) {
    start_time <- as.POSIXct("2025-01-01 00:00:00", tz = "Asia/Bangkok")
    times <- seq(start_time, by = "hour", length.out = hours)

    data.frame(
        time = times,
        temp = rep(temp_val, hours),
        humidity = rep(rh_val, hours),
        rain = rep(0, hours),
        wind_speed = rep(5, hours)
    )
}

print("=== Test 1: 9 Hours Wetness (Should FAIL) ===")
# 9 hours wet, temp OK
df1 <- create_synthetic_data(24, 25, 60) # Dry day
df1$humidity[1:9] <- 95 # 9 hours wet
res1 <- calculate_rice_blast_risk_blastam(df1)
print(paste("Infection Days:", res1$high_risk_days))
if (res1$high_risk_days == 0) {
    print("PASS")
} else {
    print("FAIL")
}

print("=== Test 2: 10 Hours Wetness, Low Temp (Should FAIL) ===")
# 10 hours wet, temp too low (15C)
df2 <- create_synthetic_data(24, 15, 60)
df2$humidity[1:10] <- 95
res2 <- calculate_rice_blast_risk_blastam(df2)
print(paste("Infection Days:", res2$high_risk_days))
if (res2$high_risk_days == 0) {
    print("PASS")
} else {
    print("FAIL")
}

print("=== Test 3: 10 Hours Wetness, OK Temp (Should PASS) ===")
# 10 hours wet, temp OK (18C)
# We need enough days to see the outbreak projection (10 days later)
df3 <- create_synthetic_data(24 * 15, 18, 60) # 15 days
df3$humidity[1:10] <- 95 # Infection on Day 1
res3 <- calculate_rice_blast_risk_blastam(df3)
print(paste("Infection Days:", res3$high_risk_days))

# Check Outbreak Projection
# Infection on Jan 1 -> High Risk on Jan 11?
high_risk_dates <- res3$daily %>% filter(risk_level == "High") %>% pull(date)
print(paste("High Risk Dates:", high_risk_dates))
expected_date <- as.Date("2025-01-11")

if (
    res3$high_risk_days == 1 &&
        length(high_risk_dates) > 0 &&
        high_risk_dates[1] == expected_date
) {
    print("PASS")
} else {
    print("FAIL")
}
