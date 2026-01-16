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
    tagList,
    tags,
    modalButton,
    hr
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
      "Rice Blast Forecasting Tool"
    ),
    size = "l",
    div(
      class = "markdown-body",
      # Using includeMarkdown to render the content from the file
      shiny::includeMarkdown("app/view/about_content.md")
    ),
    footer = tagList(
      modalButton("Close")
    ),
    easyClose = TRUE
  )
}
