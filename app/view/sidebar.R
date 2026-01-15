# app/view/sidebar.R

box::use(
  shiny[
    NS,
    div,
    p,
    h5,
    actionButton,
    icon,
    moduleServer,
    observeEvent,
    reactive,
    reactiveValues,
    uiOutput,
    renderUI,
    req,
    dateInput,
    updateDateInput
  ],
  bslib[card, card_body, layout_columns],
  shinyjs[runjs]
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  div(
    class = "sidebar-panel p-3",
    h5("Site selection"),
    p(
      "Click on the map or use the search box to add a location.",
      class = "text-muted small"
    ),
    actionButton(
      ns("btn_current_loc"),
      "Use Current Location",
      icon = icon("location-arrow"),
      class = "btn-primary w-100 mb-3"
    ),
    card(
      card_body(
        div(
          class = "d-flex justify-content-between mb-2",
          shiny::span(shiny::strong("Name")),
          shiny::span(shiny::strong("GPS"))
        ),
        uiOutput(ns("current_site_info"))
      )
    ),
    div(class = "mt-4"),
    h5("Dates"),
    layout_columns(
      col_widths = c(6, 6),
      dateInput(ns("start_date"), "Start date:", value = Sys.Date() - 2),
      dateInput(ns("end_date"), "End date:", value = Sys.Date() + 14)
    ),
    div(
      class = "btn-group-toggle d-flex flex-wrap mt-2",
      actionButton(
        ns("past_3_days"),
        "Past 3 days",
        class = "btn-sm btn-light"
      )
    ),
    shiny::hr(),
    actionButton(
      ns("refresh"),
      "Get Forecast",
      class = "btn-success w-100 mt-3",
      icon = icon("sync-alt")
    )
  )
}

#' @export
server <- function(id, map_rv) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    rv <- reactiveValues(
        lat = NULL,
        long = NULL,
        site_name = "Selected Site"
    )

    observeEvent(map_rv$lat(), {
        req(map_rv$lat())
        rv$lat <- map_rv$lat()
    })

    observeEvent(map_rv$long(), {
        req(map_rv$long())
        rv$long <- map_rv$long()
    })

    observeEvent(input$btn_current_loc, {
        runjs("app.geolocate();")
    })

    observeEvent(input$past_3_days, {
        updateDateInput(session, "start_date", value = Sys.Date() - 3)
        updateDateInput(session, "end_date", value = Sys.Date())
    })

    output$current_site_info <- renderUI({
        div(
            class = "d-flex justify-content-between small text-secondary",
            shiny::span(rv$site_name),
            shiny::span(paste0(round(rv$lat, 2), ", ", round(rv$long, 2)))
        )
    })

    return(
        list(
            lat = reactive({ rv$lat }),
            long = reactive({ rv$long }),
            start_date = reactive({ input$start_date }),
            end_date = reactive({ input$end_date }),
            refresh = reactive({ input$refresh }),
            past_3_days = reactive({ input$past_3_days })
        )
    )
  })
}