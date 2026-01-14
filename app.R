# Source global constants and functions
if (file.exists("global.R")) {
    source("global.R")
} else {
    # Fallback if global.R is not in the same dir
    library(shiny)
    library(bslib)
    library(leaflet)
    library(plotly)
    library(ggplot2)
    source("R/get_data.R")
    source("R/model.R")
    DEFAULT_LAT <- 14.15
    DEFAULT_LONG <- 100.5
}

# Define Theme
my_theme <- bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#1E4D2B", # Dark Agricultural Green
    secondary = "#4E7D5B",
    "navbar-bg" = "#1E4D2B"
)

# Custom CSS for the specific look
custom_css <- "
  .sidebar-panel { background-color: #f8f9fa; border-right: 1px solid #dee2e6; height: 100vh; overflow-y: auto; }
  .map-panel { height: 100vh; padding: 10px; }
  .results-panel { height: 100vh; overflow-y: auto; padding: 20px; border-left: 1px solid #dee2e6; }
  .nav-pills .nav-link.active { background-color: #1E4D2B !important; }
  .btn-group-toggle .btn { margin-right: 5px; margin-bottom: 5px; border-radius: 4px !important; }
  .card { border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
  .italic { font-style: italic; }
  .fw-bold { font-weight: bold; }
  .btn-group .btn { border-radius: 4px !important; margin-right: 2px; }
"

ui <- page_fillable(
    theme = my_theme,

    useShinyjs(),
    tags$head(
        tags$style(custom_css),
        tags$script(
            "
            function geolocate() {
                if (navigator.geolocation) {
                    navigator.geolocation.getCurrentPosition(
                        function(position) {
                            Shiny.setInputValue('geolocation_lat', position.coords.latitude);
                            Shiny.setInputValue('geolocation_long', position.coords.longitude);
                        },
                        function(error) {
                            alert('Geolocation error: ' + error.message);
                        }
                    );
                } else {
                    alert('Geolocation is not supported by this browser.');
                }
            }
        "
        )
    ),

    # Top Header
    div(
        class = "d-flex align-items-center bg-primary text-white px-3 py-2",
        style = "height: 60px;",
        icon("leaf", class = "fa-2x me-2"),
        h3("Rice Disease Risk Tool", class = "mb-0")
    ),

    layout_columns(
        col_widths = c(3, 5, 4),
        gap = "0px",

        # --- COLUMN 1: SITE SELECTION ---
        div(
            class = "sidebar-panel p-3",
            h5("Site selection"),
            p(
                "Click on the map or use the search box to add a location.",
                class = "text-muted small"
            ),
            actionButton(
                "btn_current_loc",
                "Use Current Location",
                icon = icon("location-arrow"),
                class = "btn-primary w-100 mb-3"
            ),

            card(
                card_body(
                    div(
                        class = "d-flex justify-content-between mb-2",
                        span(strong("Name")),
                        span(strong("GPS"))
                    ),
                    uiOutput("current_site_info")
                )
            ),
            div(class = "mt-4"),
            h5("Dates"),
            layout_columns(
                col_widths = c(6, 6),
                dateInput("start_date", "Start date:", value = Sys.Date() - 2),
                dateInput("end_date", "End date:", value = Sys.Date() + 14)
            ),

            div(
                class = "btn-group-toggle d-flex flex-wrap mt-2",
                actionButton(
                    "past_week",
                    "Past week",
                    class = "btn-sm btn-light"
                ),
                actionButton(
                    "past_month",
                    "Past month",
                    class = "btn-sm btn-light"
                ),
                actionButton(
                    "next_14_days",
                    "Next 14 days",
                    class = "btn-sm btn-light"
                ),
                actionButton(
                    "this_season",
                    "This season",
                    class = "btn-sm btn-light"
                )
            ),
            hr(),
            actionButton(
                "refresh",
                "Everything up to date",
                class = "btn-success w-100 mt-3",
                icon = icon("check-circle")
            )
        ),

        # --- COLUMN 2: MAP ---
        div(
            class = "map-panel d-flex flex-column",
            div(
                class = "flex-grow-1 position-relative",
                leafletOutput("map_input", height = "100%")
            ),
            div(
                class = "bg-white p-2 border-top",
                layout_columns(
                    col_widths = c(8, 4),
                    textInput(
                        "loc_search",
                        NULL,
                        placeholder = "Enter a location",
                        width = "100%"
                    ),
                    div(
                        class = "d-flex gap-1",
                        textInput(
                            "coords_input",
                            NULL,
                            placeholder = "Lat, Long",
                            width = "100%"
                        ),
                        actionButton("go_loc", "Go", class = "btn-secondary")
                    )
                )
            )
        ),

        # --- COLUMN 3: RESULTS/MODELS ---
        div(
            class = "results-panel",
            navset_pill(
                nav_panel(
                    "Crop risk models",
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
                                "crop_rice",
                                "Rice",
                                class = "btn-primary btn-sm"
                            )
                        ),

                        h6("Risk model:", class = "mt-3"),
                        uiOutput("model_selection_ui"),

                        div(class = "mt-3"),
                        conditionalPanel(
                            condition = "input.model_selected == 'EDRM'",
                            numericInput(
                                "rice_age",
                                "Rice Age (Days After Sowing):",
                                value = 30,
                                min = 1,
                                max = 120
                            )
                        ),
                        conditionalPanel(
                            condition = "input.model_selected == 'EPIBLA'",
                            selectInput(
                                "resistance_level",
                                "Rice Resistance Level:",
                                choices = c(
                                    "Susceptible Breed" = "susceptible",
                                    "Resistant Breed" = "resistant"
                                )
                            )
                        ),

                        hr(),

                        div(
                            class = "alert alert-info py-2 px-3 small",
                            icon("info-circle"),
                            uiOutput("model_desc_text"),
                            uiOutput("model_link_ui")
                        ),

                        card(
                            card_header(uiOutput("results_header")),
                            card_body(
                                h4(
                                    textOutput("risk_summary_text"),
                                    class = "mb-1"
                                ),
                                div(
                                    style = "font-size: 0.9em; color: #555;",
                                    uiOutput("severity_info_ui")
                                ),
                                span(
                                    textOutput("risk_subtext"),
                                    class = "text-muted small"
                                ),
                                plotlyOutput(
                                    "risk_plot_small",
                                    height = "200px"
                                )
                            )
                        )
                    )
                ),
                nav_panel(
                    "Charts and data",
                    div(
                        class = "mt-2 px-3",
                        p(
                            class = "text-muted small italic",
                            "Most values may be shown in either metric or imperial units. 14-day forecasts from Open-Meteo. Press the (i) button above for more information."
                        ),

                        div(
                            class = "d-flex gap-4 mb-3",
                            input_switch(
                                "use_metric",
                                "Use metric",
                                value = TRUE
                            ),
                            input_switch(
                                "show_forecast",
                                "Show forecast",
                                value = TRUE
                            )
                        ),

                        h6("Dataset", class = "fw-bold"),
                        uiOutput("dataset_buttons"),

                        h6("Data to display", class = "fw-bold"),
                        div(
                            class = "d-flex gap-2 align-items-center mb-4",
                            selectizeInput(
                                "data_var",
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
                                "refresh_chart",
                                icon("sync-alt"),
                                class = "btn-outline-secondary btn-sm",
                                style = "height: 38px;"
                            )
                        ),

                        card(
                            card_body(
                                plotlyOutput(
                                    "weather_plot_full",
                                    height = "500px"
                                )
                            )
                        ),

                        div(
                            class = "d-flex justify-content-end mt-3 mb-4",
                            downloadButton(
                                "download_dataset",
                                "Download dataset",
                                icon = icon("download"),
                                class = "btn btn-secondary btn-sm"
                            )
                        )
                    )
                ),
                # --- NEW: Model Debugger Tab ---
                nav_panel(
                    "Model Debugger",
                    div(
                        class = "mt-2 px-3",
                        h5("ตรวจสอบโมเดล (Model Verification)", class = "mb-3"),
                        p(
                            class = "text-muted small",
                            "ใส่ข้อมูลสภาพอากาศด้วยตนเอง เพื่อตรวจสอบว่าโมเดลคำนวณถูกต้องหรือไม่"
                        ),

                        # Model Selection for Debugger
                        h6("เลือกโมเดล:", class = "mt-3"),
                        selectInput(
                            "debug_model",
                            NULL,
                            choices = c(
                                "FIST",
                                "EDRM",
                                "BUS",
                                "BLASTAM",
                                "EPIBLA"
                            ),
                            selected = "EDRM",
                            width = "100%"
                        ),

                        conditionalPanel(
                            condition = "input.debug_model == 'EDRM'",
                            numericInput(
                                "debug_rice_age",
                                "อายุข้าว (วัน):",
                                value = 30,
                                min = 1,
                                max = 120
                            )
                        ),
                        conditionalPanel(
                            condition = "input.debug_model == 'EPIBLA'",
                            selectInput(
                                "debug_resistance",
                                "ความต้านทานพันธุ์:",
                                choices = c(
                                    "พันธุ์อ่อนแอ" = "susceptible",
                                    "พันธุ์ต้านทาน" = "resistant"
                                )
                            )
                        ),

                        hr(),
                        h6("ข้อมูลสภาพอากาศ (7 วัน):", class = "mt-3"),
                        p(
                            class = "text-muted small",
                            "ใส่ข้อมูลรายวัน: อุณหภูมิสูงสุด/ต่ำสุด (°C), ความชื้นสูงสุด/ต่ำสุด (%), ฝน (mm), ชั่วโมงที่ RH >= 90%"
                        ),

                        # Simple 7-row input table using fluidRow
                        div(
                            style = "overflow-x: auto;",
                            tags$table(
                                class = "table table-sm table-bordered",
                                tags$thead(
                                    tags$tr(
                                        tags$th("วัน"),
                                        tags$th("Tmax"),
                                        tags$th("Tmin"),
                                        tags$th("RHmax"),
                                        tags$th("RHmin"),
                                        tags$th("Rain"),
                                        tags$th("RH90hrs")
                                    )
                                ),
                                tags$tbody(
                                    lapply(1:7, function(i) {
                                        tags$tr(
                                            tags$td(paste0("Day ", i)),
                                            tags$td(numericInput(
                                                paste0("d", i, "_tmax"),
                                                NULL,
                                                value = 32,
                                                width = "60px"
                                            )),
                                            tags$td(numericInput(
                                                paste0("d", i, "_tmin"),
                                                NULL,
                                                value = 24,
                                                width = "60px"
                                            )),
                                            tags$td(numericInput(
                                                paste0("d", i, "_rhmax"),
                                                NULL,
                                                value = 95,
                                                width = "60px"
                                            )),
                                            tags$td(numericInput(
                                                paste0("d", i, "_rhmin"),
                                                NULL,
                                                value = 60,
                                                width = "60px"
                                            )),
                                            tags$td(numericInput(
                                                paste0("d", i, "_rain"),
                                                NULL,
                                                value = 0,
                                                width = "60px"
                                            )),
                                            tags$td(numericInput(
                                                paste0("d", i, "_rh90"),
                                                NULL,
                                                value = 8,
                                                width = "60px"
                                            ))
                                        )
                                    })
                                )
                            )
                        ),

                        actionButton(
                            "run_debug_model",
                            "คำนวณ (Run Model)",
                            class = "btn-primary w-100 mt-3",
                            icon = icon("calculator")
                        ),

                        hr(),
                        h6("ผลการคำนวณ:", class = "mt-3"),
                        div(
                            class = "alert alert-secondary",
                            uiOutput("debug_result_summary")
                        ),
                        h6("รายละเอียดการคำนวณ:", class = "mt-3"),
                        DT::DTOutput("debug_result_table")
                    )
                )
            )
        )
    )
)

server <- function(input, output, session) {
    # Reactive Values
    rv <- reactiveValues(
        lat = DEFAULT_LAT,
        long = DEFAULT_LONG,
        weather_data = NULL,
        risk_data = NULL,
        site_name = "Selected Site",
        dataset_type = "hourly",
        severity = 0,
        high_risk_days = 0,
        selected_model = "EDRM"
    )

    # Map Initialization - Optimized with lazy loading
    output$map_input <- renderLeaflet({
        leaflet(options = leafletOptions(preferCanvas = TRUE)) %>%
            # Only load default base layer initially
            addProviderTiles(
                providers$Esri.WorldTopoMap,
                group = "ESRI Topo"
            ) %>%
            # Layers Control (other layers load on demand)
            addLayersControl(
                baseGroups = c(
                    "ESRI Topo",
                    "Satellite",
                    "OpenStreetMap",
                    "Grey Canvas"
                ),
                options = layersControlOptions(collapsed = TRUE)
            ) %>%
            # Set view focused on Thailand
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

    # Lazy load additional base layers when selected
    observeEvent(input$map_input_groups, {
        current_group <- input$map_input_groups
        if (!is.null(current_group)) {
            if (current_group == "Satellite") {
                leafletProxy("map_input") %>%
                    addProviderTiles(
                        providers$Esri.WorldImagery,
                        group = "Satellite"
                    )
            } else if (current_group == "OpenStreetMap") {
                leafletProxy("map_input") %>%
                    addProviderTiles(
                        providers$OpenStreetMap.Mapnik,
                        group = "OpenStreetMap"
                    )
            } else if (current_group == "Grey Canvas") {
                leafletProxy("map_input") %>%
                    addProviderTiles(
                        providers$CartoDB.Positron,
                        group = "Grey Canvas"
                    )
            }
        }
    })

    # Sync map click
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

    # Geolocation Logic
    observeEvent(input$btn_current_loc, {
        runjs("geolocate();")
    })

    observeEvent(input$geolocation_lat, {
        req(input$geolocation_lat, input$geolocation_long)
        new_lat <- as.numeric(input$geolocation_lat)
        new_long <- as.numeric(input$geolocation_long)

        rv$lat <- new_lat
        rv$long <- new_long
        rv$site_name <- "Current Location"

        # Update Map
        leafletProxy("map_input") %>%
            clearMarkers() %>%
            setView(lng = new_long, lat = new_lat, zoom = 12) %>%
            addCircleMarkers(
                lng = new_long,
                lat = new_lat,
                layerId = "selected_loc",
                color = "#1E4D2B",
                fillOpacity = 0.8,
                radius = 8,
                stroke = TRUE,
                weight = 2
            )

        # Update Coordinate Input
        updateTextInput(
            session,
            "coords_input",
            value = paste0(round(new_lat, 4), ", ", round(new_long, 4))
        )

        # Trigger refresh if needed, or user can click refresh.
        # But commonly we might want to auto-refresh data.
        # For now, just setting location is safer, user can click 'Everything up to date' or I can trigger it.
        # Let's trigger the refresh button click to auto-load data for new location
        click("refresh")
    })

    # Core Data Logic (Unified)

    observeEvent(
        list(
            input$refresh,
            input$go_loc,
            input$next_14_days,
            input$rice_age,
            input$model_selected
        ),
        {
            req(rv$lat, rv$long)

            withProgress(message = "Calculating Risk...", value = 0.5, {
                # Fetch and Calculate with improved error handling
                result <- tryCatch(
                    {
                        w_data <- get_weather_forecast(
                            rv$lat,
                            rv$long,
                            days = 14
                        )

                        if (
                            is.null(input$model_selected) ||
                                input$model_selected == "EDRM"
                        ) {
                            # Use Advanced Model (EDRM)
                            res <- calculate_rice_blast_risk_advanced(
                                w_data,
                                start_dat = input$rice_age
                            )
                            rv$severity <- res$severity_projection
                            rv$high_risk_days <- res$high_risk_days
                        } else if (input$model_selected == "BUS") {
                            # Use BUS Model
                            res <- calculate_rice_blast_risk_bus(w_data)
                            rv$severity <- res$severity_projection
                            rv$high_risk_days <- res$high_risk_days
                        } else if (input$model_selected == "BLASTAM") {
                            # Use BLASTAM Model
                            res <- calculate_rice_blast_risk_blastam(w_data)
                            rv$severity <- res$severity_projection
                            rv$high_risk_days <- res$high_risk_days
                        } else if (input$model_selected == "EPIBLA") {
                            # Use EPIBLA Model
                            res <- calculate_rice_blast_risk_epibla(
                                w_data,
                                resistance_level = input$resistance_level
                            )
                            rv$severity <- res$severity_projection
                            rv$high_risk_days <- res$high_risk_days
                        } else {
                            # Use Basic Model (FIST)
                            res <- calculate_rice_blast_risk(w_data)
                            rv$severity <- NULL
                            rv$high_risk_days <- NULL
                        }

                        # Filter by selected dates
                        rv$weather_data <- res$hourly %>%
                            filter(
                                date >= input$start_date &
                                    date <= input$end_date
                            )
                        rv$risk_data <- res$daily %>%
                            filter(
                                date >= input$start_date &
                                    date <= input$end_date
                            )

                        list(success = TRUE)
                    },
                    error = function(e) {
                        list(success = FALSE, message = e$message)
                    }
                )

                # Show error notification if failed
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

    # Date range presets
    observeEvent(input$next_14_days, {
        updateDateInput(session, "start_date", value = Sys.Date())
        updateDateInput(session, "end_date", value = Sys.Date() + 14)
    })

    observeEvent(input$past_week, {
        updateDateInput(session, "start_date", value = Sys.Date() - 7)
        updateDateInput(session, "end_date", value = Sys.Date())
    })

    observeEvent(input$past_month, {
        updateDateInput(session, "start_date", value = Sys.Date() - 30)
        updateDateInput(session, "end_date", value = Sys.Date())
    })

    # Dataset Selection Observers
    observeEvent(input$ds_hourly, {
        rv$dataset_type <- "hourly"
    })
    observeEvent(input$ds_daily, {
        rv$dataset_type <- "daily"
    })
    observeEvent(input$ds_moving, {
        rv$dataset_type <- "moving"
    })
    observeEvent(input$ds_gdd, {
        rv$dataset_type <- "gdd"
    })

    output$dataset_buttons <- renderUI({
        div(
            class = "btn-group mb-3",
            actionButton(
                "ds_hourly",
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
                "ds_daily",
                "Daily",
                class = paste0(
                    "btn btn-sm ",
                    if (rv$dataset_type == "daily") {
                        "btn-secondary"
                    } else {
                        "btn-outline-secondary"
                    }
                )
            ),
            actionButton(
                "ds_moving",
                "Moving averages",
                class = paste0(
                    "btn btn-sm ",
                    if (rv$dataset_type == "moving") {
                        "btn-secondary"
                    } else {
                        "btn-outline-secondary"
                    }
                )
            ),
            actionButton(
                "ds_gdd",
                "Growing degree days",
                class = paste0(
                    "btn btn-sm ",
                    if (rv$dataset_type == "gdd") {
                        "btn-secondary"
                    } else {
                        "btn-outline-secondary"
                    }
                )
            )
        )
    })

    # Output: Site Info
    output$current_site_info <- renderUI({
        div(
            class = "d-flex justify-content-between small text-secondary",
            span(rv$site_name),
            span(paste0(round(rv$lat, 2), ", ", round(rv$long, 2)))
        )
    })

    output$results_header <- renderUI({
        paste0("Model Results: ", rv$site_name)
    })

    output$risk_summary_text <- renderText({
        req(rv$risk_data)
        today <- rv$risk_data %>% filter(date == Sys.Date())
        if (nrow(today) > 0) {
            # Special formatting for BUS
            if (
                !is.null(input$model_selected) && input$model_selected == "BUS"
            ) {
                score <- round(today$risk_score[1], 2)
                level <- today$risk_level[1]
                msg <- paste0("Score: ", score)
                if (level == "High") {
                    msg <- paste0(msg, " (WARNING! High Risk)")
                }
                return(msg)
            }

            return(paste0(
                today$risk_score[1],
                "% (",
                today$risk_level[1],
                " risk)"
            ))
        }
        return("N/A")
    })

    output$risk_subtext <- renderText({
        paste0("For ", format(Sys.Date(), "%b %d, %Y"))
    })

    output$severity_info_ui <- renderUI({
        if (input$model_selected == "EDRM") {
            req(rv$severity)
            div(
                paste0(
                    "Predicted Peak Severity: ",
                    round(rv$severity, 2),
                    "% (based on ",
                    rv$high_risk_days,
                    " high-risk days)"
                )
            )
        } else if (input$model_selected == "BUS") {
            div(
                class = if (rv$high_risk_days > 0) {
                    "text-danger fw-bold"
                } else {
                    ""
                },
                paste0(
                    "High Risk Days (> 2.25): ",
                    rv$high_risk_days,
                    " days found in forecast."
                )
            )
        } else if (input$model_selected == "BLASTAM") {
            div(
                class = if (rv$high_risk_days > 0) {
                    "text-danger fw-bold"
                } else {
                    ""
                },
                paste0(
                    "Infection Events Detected: ",
                    rv$high_risk_days,
                    " days. ",
                    "Future Outbreak Candidates: ",
                    rv$severity,
                    " days."
                )
            )
        } else if (input$model_selected == "EPIBLA") {
            div(
                class = if (rv$severity > 10) {
                    "text-danger fw-bold"
                } else {
                    ""
                },
                paste0(
                    "7-Day Predicted Severity: ",
                    round(rv$severity, 2),
                    "%. ",
                    "High Risk Days (> 10%): ",
                    rv$high_risk_days,
                    " days."
                )
            )
        }
    })

    # Link UI for BLASTAM
    output$model_link_ui <- renderUI({
        req(input$model_selected)
        if (input$model_selected == "BLASTAM") {
            a(
                "Read Model Paper",
                href = "https://link.springer.com/article/10.1007/BF02980315",
                target = "_blank",
                class = "alert-link ms-2"
            )
        }
    })

    output$model_selection_ui <- renderUI({
        div(
            class = "btn-group btn-group-toggle d-flex",
            radioButtons(
                "model_selected",
                NULL,
                choices = c("FIST", "EDRM", "BUS", "BLASTAM", "EPIBLA"),
                selected = rv$selected_model,
                inline = TRUE
            )
        )
    })

    # Custom CSS for radioButtons to look like buttons
    output$model_desc_text <- renderUI({
        req(input$model_selected)
        if (input$model_selected == "EDRM") {
            " EDRM: Advanced Model considering temperature (RcT), wetness (RcW), and plant age (RcA). "
        } else if (input$model_selected == "BLASTAM") {
            " BLASTAM: Predicts outbreak ~10 days after infection. Infection = 10+ consecutive wet hours + Min Temp > 16°C. "
        } else if (input$model_selected == "EPIBLA") {
            " EPIBLA: Predicts severity 7 days ahead based on spore estimation, dew and resistance. Helps in fungicide decision making. "
        } else if (input$model_selected == "BUS") {
            " BUS: Calculating based on wet hours, humidity > 16h, and temperature conditions. Score > 2.25 is High Risk. "
        } else {
            " FIST: Basic Model focused on hourly temperature and humidity thresholds. "
        }
    })

    # Plots
    output$risk_plot_small <- renderPlotly({
        req(rv$risk_data)
        colors <- c("Low" = "#2ecc71", "Medium" = "#f39c12", "High" = "#e74c3c")
        p <- ggplot(
            rv$risk_data,
            aes(x = date, y = risk_score, fill = risk_level)
        ) +
            geom_col() +
            scale_fill_manual(values = colors) +
            theme_minimal() +
            theme(legend.position = "none", axis.title = element_blank())
        ggplotly(p)
    })

    output$weather_plot_full <- renderPlotly({
        req(input$data_var)

        # Select data source
        if (rv$dataset_type == "daily") {
            df <- rv$risk_data
            req(df)
            df$time <- as.POSIXct(df$date)
            col_map <- c(
                "Temperature" = "avg_temp",
                "Relative Humidity" = "avg_humidity",
                "Rain" = "total_rain",
                "Wind Speed" = "avg_temp" # Daily wind not calculated, fallback
            )
        } else {
            df <- rv$weather_data
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

        # Conversions
        if (!input$use_metric) {
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
            if (var_name == "Temperature") {
                y_label <- paste(var_name, "(°C)")
            }
            if (var_name == "Rain") {
                y_label <- paste(var_name, "(mm)")
            }
            if (var_name == "Wind Speed") {
                y_label <- paste(var_name, "(km/h)")
            }
            if (var_name == "Relative Humidity") {
                y_label <- paste(var_name, "(%)")
            }
        }

        # Plot
        p <- plot_ly(df, x = ~time) %>%
            add_lines(
                y = y_val,
                name = var_name,
                line = list(color = "#4682B4", width = 2)
            )

        # Add "Now" line
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

        # Shaded forecast region (from now onwards)
        if (input$show_forecast) {
            p <- p %>%
                layout(
                    shapes = list(
                        list(
                            type = "rect",
                            fillcolor = "rgba(0,0,0,0.03)",
                            line = list(width = 0),
                            x0 = now,
                            x1 = max(df$time),
                            y0 = y_range[1],
                            y1 = y_range[2],
                            layer = "below"
                        )
                    )
                )
        }

        p <- p %>%
            layout(
                title = list(
                    text = paste0(
                        rv$dataset_type,
                        " data for ",
                        round(rv$lat, 3),
                        "°N, ",
                        round(rv$long, 3),
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

        p
    })

    # Download Handler
    output$download_dataset <- downloadHandler(
        filename = function() {
            paste0("weather_data_", Sys.Date(), ".csv")
        },
        content = function(file) {
            data_to_save <- if (rv$dataset_type == "daily") {
                rv$risk_data
            } else {
                rv$weather_data
            }
            write.csv(data_to_save, file, row.names = FALSE)
        }
    )

    output$raw_data_table <- renderDT({
        req(rv$risk_data)
        datatable(rv$risk_data, options = list(pageLength = 5, scrollX = TRUE))
    })

    # --- Model Debugger Server Logic ---
    debug_data <- reactiveVal(NULL)

    observeEvent(input$run_debug_model, {
        # Collect 7-day input data
        days_data <- lapply(1:7, function(i) {
            data.frame(
                day = i,
                date = Sys.Date() + i - 1,
                max_temp = input[[paste0("d", i, "_tmax")]],
                min_temp = input[[paste0("d", i, "_tmin")]],
                max_rh = input[[paste0("d", i, "_rhmax")]],
                min_rh = input[[paste0("d", i, "_rhmin")]],
                rain = input[[paste0("d", i, "_rain")]],
                rh90_hrs = input[[paste0("d", i, "_rh90")]]
            )
        })
        daily_df <- do.call(rbind, days_data)

        # Calculate derived values
        daily_df$avg_temp <- (daily_df$max_temp + daily_df$min_temp) / 2
        daily_df$avg_rh <- (daily_df$max_rh + daily_df$min_rh) / 2

        # Run model-specific calculations
        model <- input$debug_model

        if (model == "FIST") {
            # FIST: favorable hours >= 10 -> High
            daily_df$favorable_hours <- ifelse(
                daily_df$avg_temp >= 20 &
                    daily_df$avg_temp <= 30 &
                    daily_df$avg_rh >= 90,
                daily_df$rh90_hrs,
                0
            )
            daily_df$risk_score <- daily_df$favorable_hours / 24 * 100
            daily_df$risk_level <- ifelse(
                daily_df$favorable_hours >= 10,
                "High",
                ifelse(daily_df$favorable_hours >= 5, "Medium", "Low")
            )
        } else if (model == "EDRM") {
            # EDRM: RcT * RcW * RcA
            start_dat <- input$debug_rice_age
            daily_df$RcT <- calculate_RcT(daily_df$avg_temp)
            daily_df$RcW <- calculate_RcW(daily_df$rain, daily_df$rh90_hrs)
            daily_df$current_dat <- start_dat + (daily_df$day - 1)
            daily_df$RcA <- calculate_RcA(daily_df$current_dat)
            daily_df$risk_score <- (daily_df$RcT *
                daily_df$RcW *
                daily_df$RcA) *
                100
            daily_df$risk_level <- ifelse(
                daily_df$risk_score >= 60,
                "High",
                ifelse(daily_df$risk_score >= 30, "Medium", "Low")
            )
        } else if (model == "BUS") {
            # BUS: custom scoring
            daily_df$bus_score <- mapply(
                calculate_bus_score,
                daily_df$avg_temp,
                daily_df$rh90_hrs,
                daily_df$rh90_hrs
            )
            daily_df$risk_score <- daily_df$bus_score
            daily_df$risk_level <- ifelse(
                daily_df$bus_score > 2.25,
                "High",
                "Low"
            )
        } else if (model == "BLASTAM") {
            # BLASTAM: simplified - check if rh90_hrs >= 10 and min_temp > 16
            daily_df$infection <- (daily_df$rh90_hrs >= 10) &
                (daily_df$min_temp > 16)
            daily_df$risk_score <- ifelse(daily_df$infection, 100, 0)
            daily_df$risk_level <- ifelse(
                daily_df$infection,
                "Infection",
                "Low"
            )
            # Note: Full BLASTAM needs hourly data, this is a daily approximation
        } else if (model == "EPIBLA") {
            # EPIBLA: 7-day rolling calculation
            resistance <- input$debug_resistance

            # Estimate spores
            daily_df$est_spores <- 123.068 -
                (3.08 * daily_df$max_temp) +
                (0.321 * daily_df$max_rh) -
                (0.37 * daily_df$min_rh)
            daily_df$est_spores <- pmax(0, daily_df$est_spores)

            # Estimate dew (0-2)
            daily_df$dew <- ifelse(
                daily_df$rh90_hrs > 12,
                2,
                ifelse(daily_df$rh90_hrs > 6, 1, 0)
            )

            # Rolling calculations (use cumsum for first 7 rows)
            daily_df$total_spores <- cumsum(daily_df$est_spores)
            daily_df$avg_dew <- cumsum(daily_df$dew) / daily_df$day
            daily_df$avg_min_temp <- cumsum(daily_df$min_temp) / daily_df$day
            daily_df$avg_max_rh <- cumsum(daily_df$max_rh) / daily_df$day

            if (resistance == "susceptible") {
                daily_df$sev <- 0.5561 -
                    (0.0011 * daily_df$total_spores) +
                    (0.0017 * daily_df$avg_min_temp) +
                    (0.2493 * daily_df$avg_dew)
            } else {
                daily_df$sev <- 1.0428 -
                    (0.00007 * daily_df$total_spores) -
                    (0.0102 * daily_df$avg_max_rh) +
                    (0.0659 * daily_df$avg_dew)
            }

            daily_df$risk_score <- pmax(0, pmin(1, daily_df$sev)) * 100
            daily_df$risk_level <- ifelse(
                daily_df$risk_score >= 10,
                "High",
                ifelse(daily_df$risk_score >= 5, "Medium", "Low")
            )
        }

        debug_data(daily_df)
    })

    output$debug_result_summary <- renderUI({
        req(debug_data())
        df <- debug_data()
        high_days <- sum(df$risk_level == "High", na.rm = TRUE)
        max_score <- max(df$risk_score, na.rm = TRUE)

        div(
            p(strong("สรุปผล:"), class = "mb-1"),
            p(paste0("จำนวนวันเสี่ยงสูง: ", high_days, " วัน")),
            p(paste0("คะแนนความเสี่ยงสูงสุด: ", round(max_score, 2))),
            if (high_days > 0) {
                p(class = "text-danger fw-bold", "⚠ พบความเสี่ยงสูง!")
            }
        )
    })

    output$debug_result_table <- renderDT({
        req(debug_data())
        df <- debug_data()

        # Select columns to display based on model
        display_cols <- c(
            "day",
            "date",
            "avg_temp",
            "avg_rh",
            "rain",
            "rh90_hrs",
            "risk_score",
            "risk_level"
        )
        if ("RcT" %in% names(df)) {
            display_cols <- c(display_cols, "RcT", "RcW", "RcA")
        }
        if ("bus_score" %in% names(df)) {
            display_cols <- c(display_cols, "bus_score")
        }
        if ("est_spores" %in% names(df)) {
            display_cols <- c(display_cols, "est_spores", "dew", "sev")
        }
        if ("infection" %in% names(df)) {
            display_cols <- c(display_cols, "infection")
        }

        # Keep only existing columns
        display_cols <- intersect(display_cols, names(df))

        datatable(
            df[, display_cols, drop = FALSE],
            options = list(
                pageLength = 7,
                scrollX = TRUE,
                dom = 't'
            ),
            rownames = FALSE
        ) %>%
            formatRound(
                columns = which(sapply(df[, display_cols], is.numeric)),
                digits = 2
            )
    })
}

shinyApp(ui, server)
