# app/main.R - Main Application Entry Point

box::use(
  shiny[
    NS,
    div,
    moduleServer,
    observeEvent,
    reactive,
    req,
    tags
  ],
  bslib[
    page_fillable,
    bs_theme,
    layout_columns,
    navset_pill,
    nav_panel
  ],
  shinyjs[useShinyjs],
  app/logic/constants[
    DEFAULT_LAT,
    DEFAULT_LONG,
    APP_THEME_PRIMARY,
    APP_THEME_SECONDARY
  ],
  app/view/header,
  app/view/sidebar,
  app/view/map,
  app/view/results,
  app/view/charts
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  page_fillable(
    theme = bs_theme(
      version = 5,
      bootswatch = "flatly",
      primary = APP_THEME_PRIMARY,
      secondary = APP_THEME_SECONDARY,
      "navbar-bg" = APP_THEME_PRIMARY
    ),
    useShinyjs(),
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "static/css/main.css"),
      tags$script(src = "static/js/index.js")
    ),
    header$ui(ns("header")),
    layout_columns(
      col_widths = c(3, 5, 4),
      gap = "0px",
      sidebar$ui(ns("sidebar")),
      map$ui(ns("map")),
      div(
        class = "results-panel",
        navset_pill(
          nav_panel(
            "Crop risk models",
            results$ui(ns("results"))
          ),
          nav_panel(
            "Charts and data",
            charts$ui(ns("charts"))
          )
        )
      )
    )
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    header$server("header")
    
    map_outputs <- map$server("map")
    
    sidebar_outputs <- sidebar$server("sidebar", map_rv = map_outputs)

    observeEvent(input$geolocation_lat, {
      req(input$geolocation_lat, input$geolocation_long)
      new_lat <- as.numeric(input$geolocation_lat)
      new_long <- as.numeric(input$geolocation_long)
      map_outputs$update_location(new_lat, new_long, zoom = 12)
    })

    location_rv <- list(
      lat = sidebar_outputs$lat,
      long = sidebar_outputs$long
    )
    
    dates_rv <- list(
        start_date = sidebar_outputs$start_date,
        end_date = sidebar_outputs$end_date
    )

    refresh_trigger <- reactive({
      list(
        sidebar_outputs$refresh(),
        sidebar_outputs$past_3_days(),
        map_outputs$go_loc()
      )
    })

    results_outputs <- results$server(
      "results",
      location_rv = location_rv,
      dates_rv = dates_rv,
      refresh_trigger = refresh_trigger
    )

    charts$server(
      "charts",
      weather_data_rv = results_outputs$weather_data,
      risk_data_rv = results_outputs$risk_data,
      location_rv = location_rv
    )
  })
}