box::use(
  magrittr[`%>%`],

  shiny[
    NS,
    div,
    moduleServer,
    observeEvent,
    reactive,
    textInput,
    actionButton,
    updateTextInput,
    reactiveValues
  ],
  leaflet[
    leaflet,
    leafletOutput,
    renderLeaflet,
    leafletOptions,
    addProviderTiles,
    providers,
    setView,
    addCircleMarkers,
    leafletProxy,
    clearMarkers,
    addLayersControl,
    layersControlOptions
  ],
  bslib[layout_columns],
  app / logic / constants[DEFAULT_LAT, DEFAULT_LONG]
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  div(
    class = "map-panel d-flex flex-column",
    div(
      class = "flex-grow-1 position-relative",
      leafletOutput(ns("map_input"), height = "100%")
    ),
    div(
      class = "bg-white p-2 border-top",
      layout_columns(
        col_widths = c(8, 4),
        textInput(
          ns("loc_search"),
          NULL,
          placeholder = "Enter a location",
          width = "100%"
        ),
        div(
          class = "d-flex gap-1",
          textInput(
            ns("coords_input"),
            NULL,
            placeholder = "Lat, Long",
            width = "100%"
          ),
          actionButton(ns("go_loc"), "Go", class = "btn-secondary")
        )
      )
    )
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    rv <- reactiveValues(
      lat = DEFAULT_LAT,
      long = DEFAULT_LONG
    )

    output$map_input <- renderLeaflet({
      leaflet(options = leafletOptions(preferCanvas = TRUE)) %>%
        addProviderTiles(providers$Esri.WorldTopoMap, group = "ESRI Topo") %>%
        addLayersControl(
          baseGroups = c(
            "ESRI Topo",
            "Satellite",
            "OpenStreetMap",
            "Grey Canvas"
          ),
          options = layersControlOptions(collapsed = TRUE)
        ) %>%
        setView(lng = rv$long, lat = rv$lat, zoom = 7) %>%
        addCircleMarkers(
          lng = rv$long,
          lat = rv$lat,
          layerId = "selected_loc",
          color = "#1E4D2B",
          fillOpacity = 0.8,
          radius = 8,
          stroke = TRUE,
          weight = 2
        )
    })

    observeEvent(input$map_input_click, {
      click <- input$map_input_click
      rv$lat <- click$lat
      rv$long <- click$lng

      leafletProxy("map_input") %>%
        clearMarkers() %>%
        addCircleMarkers(
          lng = click$lng,
          lat = click$lat,
          layerId = "selected_loc",
          color = "#1E4D2B",
          fillOpacity = 0.8,
          radius = 8,
          stroke = TRUE,
          weight = 2
        )

      updateTextInput(
        session,
        "coords_input",
        value = paste0(round(rv$lat, 4), ", ", round(rv$long, 4))
      )
    })

    # Function to be called from main server to update location
    update_location <- function(lat, long, zoom = 12) {
      rv$lat <- lat
      rv$long <- long
      leafletProxy("map_input") %>%
        clearMarkers() %>%
        setView(lng = long, lat = lat, zoom = zoom) %>%
        addCircleMarkers(
          lng = long,
          lat = lat,
          layerId = "selected_loc",
          color = "#1E4D2B",
          fillOpacity = 0.8,
          radius = 8,
          stroke = TRUE,
          weight = 2
        )
      updateTextInput(
        session,
        "coords_input",
        value = paste0(round(lat, 4), ", ", round(long, 4))
      )
    }

    return(
      list(
        lat = reactive({
          rv$lat
        }),
        long = reactive({
          rv$long
        }),
        go_loc = reactive({
          input$go_loc
        }),
        update_location = update_location
      )
    )
  })
}
