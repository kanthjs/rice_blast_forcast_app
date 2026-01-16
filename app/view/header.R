# app/view/header.R

box::use(
  shiny[
    NS,
    div,
    icon,
    h3,
    actionLink,
    moduleServer,
    observeEvent
  ],
  app / view / about_modal[show_about_modal]
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  div(
    class = "d-flex align-items-center justify-content-between bg-primary text-white px-3 py-2",
    style = "height: 60px;",
    div(
      class = "d-flex align-items-center",
      icon("leaf", class = "fa-2x me-2"),
      h3("ระบบพยากรณ์เตือนภัยการเกิดโรคไหม้ของข้าว", class = "mb-0")
    ),
    actionLink(
      ns("app_info"),
      label = NULL,
      icon = icon("info-circle", class = "fa-lg text-white"),
      style = "cursor: pointer; text-decoration: none;"
    )
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$app_info, {
      shiny::showModal(show_about_modal())
    })
  })
}
