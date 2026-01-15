box::use(
  magrittr[`%>%`],

  shiny[
    NS,
    div,
    p,
    h6,
    actionButton,
    icon,
    moduleServer,
    reactiveValues,
    uiOutput,
    renderUI,
    req,
    selectizeInput,
    downloadButton,
    downloadHandler,
    observeEvent
  ],
  bslib[card, card_body, layout_columns],
  plotly[
    plotlyOutput,
    renderPlotly,
    plot_ly,
    add_lines,
    add_segments,
    add_annotations,
    layout
  ],
  shinyWidgets[awesomeCheckboxGroup],
  app / logic / constants[DEFAULT_LAT, DEFAULT_LONG],
  DT[renderDT, datatable]
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  div(
    class = "mt-2 px-3",
    p(
      class = "text-muted small italic",
      "Most values may be shown in either metric or imperial units. 14-day forecasts from Open-Meteo."
    ),
    awesomeCheckboxGroup(
      inputId = ns("chart_options"),
      label = "Chart Options",
      choices = c("Use Metric" = "metric", "Show Forecast" = "forecast"),
      selected = c("metric", "forecast"),
      inline = TRUE
    ),
    h6("Dataset", class = "fw-bold"),
    uiOutput(ns("dataset_buttons")),
    h6("Data to display", class = "fw-bold"),
    div(
      class = "d-flex gap-2 align-items-center mb-4",
      selectizeInput(
        ns("data_var"),
        NULL,
        choices = c(
          "Temperature",
          "Relative Humidity",
          "Rain",
          "Wind Speed"
        ),
        selected = "Temperature",
        width = "100%"
      ),
      actionButton(
        ns("refresh_chart"),
        icon("sync-alt"),
        class = "btn-outline-secondary btn-sm",
        style = "height: 38px;"
      )
    ),
    card(
      card_body(
        plotlyOutput(
          ns("weather_plot_full"),
          height = "500px"
        )
      )
    ),
    div(
      class = "d-flex justify-content-end mt-3 mb-4",
      downloadButton(
        ns("download_dataset"),
        "Download dataset",
        icon = icon("download"),
        class = "btn btn-secondary btn-sm"
      )
    ),
    DT::DTOutput(ns("raw_data_table"))
  )
}

#' @export
server <- function(id, weather_data_rv, risk_data_rv, location_rv) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    rv <- reactiveValues(dataset_type = "hourly")

    output$dataset_buttons <- renderUI({
      div(
        class = "btn-group mb-3",
        actionButton(
          ns("ds_hourly"),
          "Hourly",
          class = paste0(
            "btn btn-sm ",
            if (rv$dataset_type == "hourly") {
              "btn-secondary"
            } else {
              "btn-outline-secondary"
            }
          )
        ),
        actionButton(
          ns("ds_daily"),
          "Daily",
          class = paste0(
            "btn btn-sm ",
            if (rv$dataset_type == "daily") {
              "btn-secondary"
            } else {
              "btn-outline-secondary"
            }
          )
        )
      )
    })

    observeEvent(input$ds_hourly, {
      rv$dataset_type <- "hourly"
    })
    observeEvent(input$ds_daily, {
      rv$dataset_type <- "daily"
    })

    output$weather_plot_full <- renderPlotly({
      req(input$data_var)

      use_metric <- "metric" %in% input$chart_options

      if (rv$dataset_type == "daily") {
        df <- risk_data_rv()
        req(df)
        df$time <- as.POSIXct(df$date)
        col_map <- c(
          "Temperature" = "Tmean",
          "Relative Humidity" = "RHmean",
          "Rain" = "RainSum",
          "Wind Speed" = "Tmean"
        )
      } else {
        df <- weather_data_rv()
        req(df)
        col_map <- c(
          "Temperature" = "temp",
          "Relative Humidity" = "humidity",
          "Rain" = "rain",
          "Wind Speed" = "wind_speed"
        )
      }

      var_name <- input$data_var
      col_to_plot <- col_map[var_name]
      y_val <- df[[col_to_plot]]
      y_label <- var_name

      # Unit Conversions
      if (!use_metric) {
        if (var_name == "Temperature") {
          y_val <- y_val * 9 / 5 + 32
          y_label <- paste(var_name, "(°F)")
        } else if (var_name == "Rain") {
          y_val <- y_val / 25.4
          y_label <- paste(var_name, "(in)")
        } else if (var_name == "Wind Speed") {
          y_val <- y_val * 0.621371
          y_label <- paste(var_name, "(mph)")
        }
      } else {
        y_label <- switch(
          var_name,
          "Temperature" = paste(var_name, "(°C)"),
          "Rain" = paste(var_name, "(mm)"),
          "Wind Speed" = paste(var_name, "(km/h)"),
          "Relative Humidity" = paste(var_name, "(%)")
        )
      }

      p <- plot_ly(df, x = ~time) %>%
        add_lines(
          y = y_val,
          name = var_name,
          line = list(color = "#4682B4", width = 2)
        )

      now <- as.POSIXct(Sys.time())
      y_range <- range(y_val, na.rm = TRUE)

      p <- p %>%
        add_segments(
          x = now,
          xend = now,
          y = y_range[1],
          yend = y_range[2],
          line = list(
            color = "rgba(128,128,128,0.5)",
            dash = "dash",
            width = 1.5
          ),
          name = "Now",
          showlegend = FALSE
        ) %>%
        add_annotations(
          x = now,
          y = y_range[2],
          text = "Now",
          showarrow = FALSE,
          xanchor = "center",
          yanchor = "bottom",
          font = list(color = "grey", size = 10)
        )

      if ("forecast" %in% input$chart_options) {
        p <- p %>%
          layout(
            shapes = list(list(
              type = "rect",
              fillcolor = "rgba(0,0,0,0.03)",
              line = list(width = 0),
              x0 = now,
              x1 = max(df$time),
              y0 = y_range[1],
              y1 = y_range[2],
              layer = "below"
            ))
          )
      }

      p %>%
        layout(
          title = list(
            text = paste0(
              rv$dataset_type,
              " data for ",
              round(location_rv$lat(), 3),
              "°N, ",
              round(location_rv$long(), 3),
              "°E"
            ),
            font = list(size = 14, color = "#666")
          ),
          xaxis = list(title = "", gridcolor = "#f0f0f0"),
          yaxis = list(title = y_label, gridcolor = "#f0f0f0"),
          plot_bgcolor = "white",
          paper_bgcolor = "white",
          legend = list(orientation = 'h', x = 0, y = -0.2),
          margin = list(t = 50)
        )
    })

    output$download_dataset <- downloadHandler(
      filename = function() {
        paste0("weather_data_", Sys.Date(), ".csv")
      },
      content = function(file) {
        data_to_save <- if (rv$dataset_type == "daily") {
          risk_data_rv()
        } else {
          weather_data_rv()
        }
        utils::write.csv(data_to_save, file, row.names = FALSE)
      }
    )

    output$raw_data_table <- renderDT({
      df <- if (rv$dataset_type == "daily") {
        risk_data_rv()
      } else {
        weather_data_rv()
      }
      req(df)
      datatable(
        df,
        options = list(pageLength = 5, scrollX = TRUE, searching = FALSE)
      )
    })
  })
}
