# app/view/about_modal.R

box::use(
  shiny[
    NS,
    modalDialog,
    p,
    a,
    h4,
    div,
    icon,
    tagList
  ],
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  # This UI is just a placeholder for the modal content
  # The modal is shown from the server
}

#' @export
show_about_modal <- function() {
  modalDialog(
    title = tagList(
      icon("info-circle"),
      "About the Rice Disease Risk Tool"
    ),
    h4("Purpose"),
    p("This tool provides forecasts for rice blast disease risk based on weather data from the Open-Meteo API. It is intended to be a decision support tool for farmers and agricultural professionals."),
    h4("Data Source"),
    p(
      "Weather data is sourced from the ",
      a("Open-Meteo API", href = "https://open-meteo.com/", target = "_blank"),
      ". Forecasts are available for up to 14 days."
    ),
    h4("Risk Models"),
    p("The tool includes several risk models for rice blast. Each model uses different parameters and has its own strengths and weaknesses. Please refer to the model descriptions for more information."),
    h4("Disclaimer"),
    p("This tool is for informational purposes only and should not be used as the sole basis for making agricultural decisions. The creators of this tool are not responsible for any losses or damages resulting from its use."),
    footer = "Developed with the Rhino framework.",
    easyClose = TRUE
  )
}