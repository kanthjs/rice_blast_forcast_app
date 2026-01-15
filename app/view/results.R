# app/view/results.R

box::use(
  shiny[
    NS,
    div,
    p,
    h1,
    h3,
    h4,
    h5,
    h6,
    span,
    tags,
    actionButton,
    icon,
    moduleServer,
    observeEvent,
    reactive,
    uiOutput,
    renderUI,
    req,
    textOutput,
    renderText,
    conditionalPanel,
    numericInput,
    selectInput,
    withProgress,
    showNotification,
    radioButtons
  ],
  bslib[card, card_header, card_body],
  plotly[plotlyOutput, renderPlotly, ggplotly],
  ggplot2[
    ggplot,
    aes,
    geom_col,
    scale_fill_manual,
    theme_minimal,
    theme,
    element_blank
  ],
  dplyr[`%>%`, filter],
  app / logic / weather_api[get_weather_forecast],
  app /
    logic /
    models[
      calculate_rice_blast_risk,
      calculate_rice_blast_risk_advanced,
      calculate_rice_blast_risk_bus,
      calculate_rice_blast_risk_blastam,
      calculate_rice_blast_risk_epibla
    ],
  utils[tail]
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  div(
    class = "mt-3",
    p(
      class = "small text-muted",
      "Risk models are only valid when the crop is present and in a vulnerable growth stage."
    ),
    h6("Crop type:"),
    div(
      class = "btn-group-toggle",
      actionButton(
        ns("crop_rice"),
        "Rice",
        class = "btn-primary btn-sm"
      )
    ),
    h6("Risk model:", class = "mt-3"),
    uiOutput(ns("model_selection_ui")),
    div(class = "mt-3"),
    conditionalPanel(
      condition = "input.model_selected == 'EDRM'",
      ns = ns,
      numericInput(
        ns("rice_age"),
        "Rice Age (Days After Sowing):",
        value = 30,
        min = 1,
        max = 120
      )
    ),
    conditionalPanel(
      condition = "input.model_selected == 'EPIBLA'",
      ns = ns,
      selectInput(
        ns("resistance_level"),
        "Rice Resistance Level:",
        choices = c(
          "Susceptible Breed" = "susceptible",
          "Resistant Breed" = "resistant"
        )
      )
    ),
    conditionalPanel(
      condition = "input.model_selected == 'BUS'",
      ns = ns,
      numericInput(
        ns("bus_threshold"),
        "BUS Score Threshold:",
        value = 2.25,
        min = 0,
        max = 10,
        step = 0.25
      )
    ),
    shiny::hr(),
    div(
      class = "alert alert-info py-2 px-3 small",
      icon("info-circle"),
      uiOutput(ns("model_desc_text")),
      uiOutput(ns("model_link_ui"))
    ),
    card(
      card_header(uiOutput(ns("results_header"))),
      card_body(
        uiOutput(ns("dynamic_result_view"))
      )
    )
  )
}

#' @export
server <- function(id, location_rv, dates_rv, refresh_trigger) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    rv <- shiny::reactiveValues(
      weather_data = NULL,
      risk_data = NULL,
      severity = 0,
      high_risk_days = 0,
      selected_model = "Classic"
    )

    observeEvent(
      refresh_trigger(),
      {
        req(location_rv$lat(), location_rv$long())

        withProgress(message = "Calculating Risk...", value = 0.5, {
          result <- tryCatch(
            {
              w_data <- get_weather_forecast(
                location_rv$lat(),
                location_rv$long(),
                days = 14
              )

              model <- input$model_selected
              if (is.null(model)) {
                model <- "Classic"
              }
              rv$selected_model <- model # Store the model used for calculation

              res <- switch(
                model,
                "Classic" = calculate_rice_blast_risk(w_data),
                "EDRM" = calculate_rice_blast_risk_advanced(
                  w_data,
                  start_dat = input$rice_age
                ),
                "BUS" = calculate_rice_blast_risk_bus(
                  w_data,
                  threshold = input$bus_threshold
                ),
                "BLASTAM" = calculate_rice_blast_risk_blastam(w_data),
                "EPIBLA" = calculate_rice_blast_risk_epibla(
                  w_data,
                  resistance_level = input$resistance_level
                ),
                calculate_rice_blast_risk(w_data) # Default
              )

              rv$severity <- res$severity_projection
              rv$high_risk_days <- res$high_risk_days
              rv$weather_data <- res$hourly %>%
                filter(
                  date >= dates_rv$start_date() &
                    date <= dates_rv$end_date()
                )
              rv$risk_data <- res$daily %>%
                filter(
                  date >= dates_rv$start_date() &
                    date <= dates_rv$end_date()
                )

              list(success = TRUE)
            },
            error = function(e) {
              list(success = FALSE, message = e$message)
            }
          )

          if (!result$success) {
            showNotification(
              paste("Error:", result$message),
              type = "error",
              duration = 5
            )
          }
        })
      },
      ignoreNULL = FALSE
    )

    output$model_selection_ui <- renderUI({
      div(
        class = "btn-group btn-group-toggle d-flex",
        radioButtons(
          ns("model_selected"),
          NULL,
          choices = c("Classic", "EDRM", "BUS", "BLASTAM", "EPIBLA"),
          selected = rv$selected_model,
          inline = TRUE
        )
      )
    })

    output$dynamic_result_view <- renderUI({
      req(rv$risk_data, rv$selected_model)

      # Get data for "Today" or the latest available date
      latest_data <- tail(rv$risk_data, 1)
      today_data <- rv$risk_data %>% filter(date == Sys.Date())
      if (nrow(today_data) == 0) {
        today_data <- latest_data
      } # Fallback

      # Helper for color
      get_risk_color <- function(level) {
        switch(
          as.character(level),
          "High" = "danger",
          "Medium" = "warning",
          "Low" = "success",
          "Infection (Latent)" = "info",
          "secondary"
        )
      }

      switch(
        rv$selected_model,
        "BLASTAM" = {
          # BLASTAM Special View
          # Actually, models.R logic for risk_level handles the specific naming
          future_outbreaks <- rv$risk_data %>% filter(risk_level == "High")
          latent_infections <- rv$risk_data %>%
            filter(risk_level == "Infection (Latent)")

          div(
            h4("BLASTAM Analysis"),
            div(
              class = "d-flex justify-content-between",
              div(
                class = "p-2 bg-light rounded text-center flex-fill me-1",
                h6("Infection Events", class = "text-muted mb-1"),
                h3(nrow(latent_infections), class = "text-info")
              ),
              div(
                class = "p-2 bg-light rounded text-center flex-fill ms-1",
                h6("High Risk Days", class = "text-muted mb-1"),
                h3(nrow(future_outbreaks), class = "text-danger")
              )
            ),
            if (nrow(future_outbreaks) > 0) {
              div(
                class = "alert alert-danger mt-3 mb-0",
                icon("exclamation-triangle"),
                tags$b("Warning: "),
                "Outbreak predicted on: ",
                paste(format(future_outbreaks$date, "%d %b"), collapse = ", ")
              )
            } else if (nrow(latent_infections) > 0) {
              div(
                class = "alert alert-info mt-3 mb-0",
                icon("info-circle"),
                "Latent infection detected. Monitor closely."
              )
            } else {
              div(
                class = "alert alert-success mt-3 mb-0",
                icon("check-circle"),
                "No infection conditions detected."
              )
            },
            plotlyOutput(ns("risk_plot_small"), height = "200px")
          )
        },
        "BUS" = {
          # BUS Special View with 7-day window analysis

          # Get BUS threshold from user input (must match the value used in calculation)
          threshold <- input$bus_threshold
          if (is.null(threshold)) {
            threshold <- 2.25
          } # Fallback to default
          # Today's BUS score
          today_score <- round(today_data$risk_score[1], 2)

          # Get next 7 days data (including today)
          future_7_days <- rv$risk_data %>%
            filter(date >= Sys.Date() & date <= (Sys.Date() + 6))

          # Calculate accumulated BUS for 7 days
          accumulated_bus <- sum(future_7_days$risk_score, na.rm = TRUE)

          # Count days exceeding threshold in 7-day window
          high_bus_days <- future_7_days %>%
            filter(risk_score > threshold)

          num_high_days <- nrow(high_bus_days)

          # Check for consecutive days using run-length encoding (rle)
          exceeds_threshold <- future_7_days$risk_score > threshold
          rle_result <- rle(exceeds_threshold)

          # Find maximum consecutive TRUE streak
          max_consecutive <- 0
          if (any(rle_result$values)) {
            consecutive_streaks <- rle_result$lengths[rle_result$values]
            max_consecutive <- max(consecutive_streaks, na.rm = TRUE)
          }

          # Determine Summary Risk Level based on 7-day window
          summary_risk_level <- if (num_high_days < 3) {
            "Low"
          } else if (max_consecutive >= 3) {
            "Medium" # Has 3 consecutive days
          } else if (num_high_days > 3) {
            "High" # More than 3 days (but not consecutive)
          } else {
            "Low" # Fallback
          }

          summary_color <- get_risk_color(summary_risk_level)

          div(
            h4("BUS Analysis (7-Day Window)"),
            div(
              class = "d-flex justify-content-between",
              div(
                class = "p-2 bg-light rounded text-center flex-fill me-1",
                h6("Today's BUS", class = "text-muted mb-1"),
                h3(today_score, class = "text-primary")
              ),
              div(
                class = "p-2 bg-light rounded text-center flex-fill ms-1",
                h6("7-Day Accumulated", class = "text-muted mb-1"),
                h3(round(accumulated_bus, 1), class = "text-info")
              )
            ),
            div(
              class = paste0("alert alert-", summary_color, " mt-3 mb-2"),
              tags$b("Summary Risk Level: "),
              span(
                class = paste0("badge bg-", summary_color),
                summary_risk_level
              ),
              tags$br(),
              tags$small(
                if (summary_risk_level == "High") {
                  shiny::tagList(
                    icon("exclamation-triangle"),
                    paste0(
                      " ",
                      num_high_days,
                      " days exceed threshold (",
                      threshold,
                      ") in next 7 days."
                    )
                  )
                } else if (summary_risk_level == "Medium") {
                  shiny::tagList(
                    icon("exclamation-circle"),
                    paste0(
                      " ",
                      max_consecutive,
                      " consecutive days exceed threshold detected."
                    )
                  )
                } else {
                  shiny::tagList(
                    icon("check-circle"),
                    " Fewer than 3 high-risk days. Conditions Unfavorable."
                  )
                }
              )
            ),
            plotlyOutput(ns("risk_plot_small"), height = "200px")
          )
        },
        "Classic" = {
          # Classic View with 7-day window analysis

          # Today's data
          today_hours <- round(today_data$risk_score[1] / 100 * 24, 1)
          today_level <- today_data$risk_level[1]
          today_color <- get_risk_color(today_level)

          # 7-day window
          future_7_days <- rv$risk_data %>%
            filter(date >= Sys.Date() & date <= (Sys.Date() + 6))

          # Count "Favorable Days" (Days with Medium or High risk, i.e., >= 5 favorable hours)
          favorable_days_count <- future_7_days %>%
            filter(risk_level %in% c("Medium", "High")) %>%
            nrow()

          # Determine 7-day Summary Risk based on user rules
          # 1-2 days: Low (implied 0 is also Low)
          # 3-5 days: Medium
          # > 5 days: High
          summary_risk <- if (favorable_days_count > 5) {
            "High"
          } else if (favorable_days_count >= 3) {
            "Medium"
          } else {
            "Low"
          }

          summary_color <- get_risk_color(summary_risk)

          div(
            h4("Classic Analysis (7-Day Outlook)"),
            div(
              class = "d-flex justify-content-between",
              div(
                class = "p-2 bg-light rounded text-center flex-fill me-1",
                h6("Today's Fav. Hours", class = "text-muted mb-1"),
                h3(
                  paste0(today_hours, " h"),
                  class = paste0("text-", today_color)
                ),
                span(class = paste0("badge bg-", today_color), today_level)
              ),
              div(
                class = "p-2 bg-light rounded text-center flex-fill ms-1",
                h6("7-Day Fav. Days", class = "text-muted mb-1"),
                h3(paste0(favorable_days_count, " / 7"), class = "text-info")
              )
            ),
            div(
              class = paste0("alert alert-", summary_color, " mt-3 mb-2"),
              tags$b("7-Day Risk Level: "),
              span(class = paste0("badge bg-", summary_color), summary_risk),
              tags$br(),
              tags$small(
                shiny::tagList(
                  icon(ifelse(
                    summary_risk == "Low",
                    "check-circle",
                    "exclamation-triangle"
                  )),
                  paste0(
                    " Forecasts ",
                    favorable_days_count,
                    " favorable days in the next week. ",
                    ifelse(
                      summary_risk == "Low",
                      "Conditions Unfavorable.",
                      ifelse(
                        summary_risk == "High",
                        "High probability of disease development.",
                        "Moderate risk detected."
                      )
                    )
                  )
                )
              )
            ),
            plotlyOutput(ns("risk_plot_small"), height = "200px")
          )
        },
        "EDRM" = {
          # EDRM Special View

          # 1. Today's Risk Score ("วันนี้อันตรายไหม")
          today_score <- round(today_data$risk_score[1], 1)
          today_level <- today_data$risk_level[1]
          today_color <- get_risk_color(today_level)

          # 2. Severity Projection for next 7 days ("โรคไหม้จะรุนแรงเพิ่มขึ้นกี่เปอร์เซ็นต์")
          # The logic already calculates 'severity_projection' based on high risk days
          # rv$severity comes from models.R: peak_severity = 0.6467 * high_risk_days + 0.6128
          sev_proj <- round(rv$severity, 0)

          # Interpret Severity
          # Usually severity is a small number (0-5, or percentage).
          # Assuming models.R returns existing logic results.

          div(
            h4("EDRM Analysis"),
            div(
              class = "d-flex justify-content-between",
              div(
                class = "p-2 bg-light rounded text-center flex-fill me-1",
                h6("Today's Risk Score", class = "text-muted mb-1"),
                h3(
                  paste0(today_score, "%"),
                  class = paste0("text-", today_color)
                ),
                span(class = paste0("badge bg-", today_color), today_level)
              ),
              div(
                class = "p-2 bg-light rounded text-center flex-fill ms-1",
                h6("7-Day Severity Incr.", class = "text-muted mb-1"),
                h3(paste0("+", sev_proj, "%"), class = "text-danger"),
                tags$small(class = "text-muted", "Projected increase")
              )
            ),
            div(
              class = "alert alert-light mt-3 mb-2 border",
              tags$b("Interpretation: "),
              "The model predicts the disease severity could increase by ",
              tags$b(paste0(sev_proj, "%")),
              " over the next period based on accumulation of high-risk days."
            ),
            plotlyOutput(ns("risk_plot_small"), height = "200px")
          )
        },
        "EPIBLA" = {
          # EPIBLA Special View

          # 1. Today's Risk
          today_score <- round(today_data$risk_score[1], 1)
          today_level <- today_data$risk_level[1]
          today_color <- get_risk_color(today_level)

          # 2. 7-Day Forecast Analysis
          future_7_days <- rv$risk_data %>%
            filter(date >= Sys.Date() & date <= (Sys.Date() + 6))

          # Determine "High Risk Days" based on model threshold (assuming score >= 10 is high/risk per models.R)
          # EPIBLA models.R: risk_score >= 10 ~ "High"
          is_high_risk_day <- future_7_days$risk_score >= 10

          # Calculate Max Consecutive Days
          rle_res <- rle(is_high_risk_day)
          max_consecutive_days <- 0
          if (any(rle_res$values)) {
            max_consecutive_days <- max(
              rle_res$lengths[rle_res$values],
              na.rm = TRUE
            )
          } else {
            # If no TRUE values (no high risk days at all)
            max_consecutive_days <- 0
          }

          # Determine Summary Risk Level based on consecutive days
          # > 3 days continuous: High
          # > 0 but <= 3 days: Medium
          # 0 days: Low
          summary_risk_level <- if (max_consecutive_days > 3) {
            "High"
          } else if (max_consecutive_days > 0) {
            "Medium"
          } else {
            "Low"
          }

          summary_color <- get_risk_color(summary_risk_level)

          # Max Risk Score in 7 days
          max_score_7d <- max(future_7_days$risk_score, na.rm = TRUE)

          # Lead Time Logic
          lead_time_msg <- NULL
          if (summary_risk_level == "High") {
            action_date <- format(Sys.Date() + 2, "%d %b")
            lead_time_msg <- div(
              class = "alert alert-warning mt-2 mb-0",
              icon("stopwatch"),
              tags$b("Action Required: "),
              "Apply fungicide before ",
              tags$b(action_date),
              " (Lead Time: +2 days)"
            )
          }

          div(
            h4("EPIBLA Analysis (7-Day Forecast)"),
            div(
              class = "d-flex justify-content-between",
              div(
                class = "p-2 bg-light rounded text-center flex-fill me-1",
                h6("Today's Risk", class = "text-muted mb-1"),
                h3(today_score, class = paste0("text-", today_color)),
                span(class = paste0("badge bg-", today_color), today_level)
              ),
              div(
                class = "p-2 bg-light rounded text-center flex-fill ms-1",
                h6("7-Day Max Score", class = "text-muted mb-1"),
                h3(round(max_score_7d, 1), class = "text-danger"),
                tags$small(
                  class = "text-muted",
                  paste(max_consecutive_days, "consecutive high risk days")
                )
              )
            ),
            div(
              class = paste0("alert alert-", summary_color, " mt-3 mb-2"),
              tags$b("7-Day Forecast Risk: "),
              span(
                class = paste0("badge bg-", summary_color),
                summary_risk_level
              ),
              tags$br(),
              tags$small(
                if (summary_risk_level == "Low") {
                  shiny::tagList(
                    icon("check-circle"),
                    " No continuous high risk periods detected."
                  )
                } else {
                  shiny::tagList(
                    icon("exclamation-triangle"),
                    " Extended high risk period predicted."
                  )
                }
              ),
              # Show Lead Time Action if High
              lead_time_msg
            ),
            plotlyOutput(ns("risk_plot_small"), height = "200px")
          )
        },
        {
          # Fallback Default
          div(
            class = "alert alert-secondary",
            "Please select a model."
          )
        }
      )
    })

    # Generic Plot (Updated to handle NULLs gratefully)
    output$risk_plot_small <- renderPlotly({
      req(rv$risk_data)
      colors <- c(
        "Low" = "#2ecc71",
        "Medium" = "#f39c12",
        "High" = "#e74c3c",
        "Infection (Latent)" = "#3498db"
      )

      # Ensure dates are Date objects
      plot_data <- rv$risk_data

      p <- ggplot(
        plot_data,
        aes(x = date, y = risk_score, fill = risk_level)
      ) +
        geom_col() +
        scale_fill_manual(values = colors) +
        theme_minimal() +
        theme(
          legend.position = "none",
          axis.title = element_blank(),
          panel.grid.minor = element_blank()
        )
      ggplotly(p) %>% plotly::config(displayModeBar = FALSE)
    })

    output$model_desc_text <- renderUI({
      req(input$model_selected)
      switch(
        input$model_selected,
        "EDRM" = "EDRM: Advanced Model considering temperature (RcT), wetness (RcW), and plant age (RcA).",
        "BLASTAM" = "BLASTAM: Predicts outbreak 4 days after infection. Infection = 10+ consecutive wet hours + Min Temp > 16°C.",
        "EPIBLA" = "EPIBLA: Predicts severity 7 days ahead based on spore estimation, dew and resistance.",
        "BUS" = "BUS: Calculating based on wet hours, humidity > 16h, and temperature conditions.",
        "Classic" = "Classic: Indicates favorable environmental conditions for blast disease."
      )
    })

    return(
      list(
        weather_data = reactive({
          rv$weather_data
        }),
        risk_data = reactive({
          rv$risk_data
        })
      )
    )
  })
}
