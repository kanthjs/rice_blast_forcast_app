# global.R
library(shiny)
library(shinyjs)
library(bslib)
library(leaflet)
library(plotly)
library(dplyr)
library(lubridate)
library(httr)
library(jsonlite)
library(DT)
library(ggplot2)
library(weathermetrics)

# Source helper functions
source("R/get_data.R")
source("R/model.R")

# Default location (Bangkok/Central Thailand Rice Fields)
DEFAULT_LAT <- 14.15
DEFAULT_LONG <- 100.5
