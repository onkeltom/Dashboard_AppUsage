library(shiny)

shinyUI(bootstrapPage(

  titlePanel("Firefox OS Application Usage Dashboard"),
  
  tagList(
    tags$head(
      tags$link(rel="stylesheet", type="text/css",href="style.css"),
      tags$script(type="text/javascript", src = "busy.js")
    )
  ),
  
  div(class = "busy",  
      p("Calculation in progress.."), 
      img(src="ajaxloaderq.gif")
  ),
  

  sidebarLayout(
    sidebarPanel(
      h2("Control Center"),
      
      h3("Select your user group:"),
      selectInput("dataset", "Select your user group", c("Foxfood", "Others", "All"), selected = "Foxfood"),
      
      h3("Select your filter options:"),
      htmlOutput("os"),
      htmlOutput("apps"),
      htmlOutput("country"),
      htmlOutput("device"),
      textOutput("total")

    ),

    mainPanel(

      plotOutput("gaia"),

      h1("Application Usage"),
      
      dateRangeInput('daterange', label = "Select start and end dates for data to be shown", start = Sys.Date() - 180, end = Sys.Date()), 

#       dateInput('startDate',
#                 label = 'Start Date: yyyy-mm-dd',
#                 value = "2015-06-17"
#       ),
#       
#       dateInput('stopDate',
#                 label = 'Stop Date: yyyy-mm-dd',
#                 value = Sys.Date()
#       ),
#       
      h2("Choose your input"),
      selectInput("option", "Select your option", c("Invocations", "Usage_time", "Installs", "Uninstalls", "Users"), selected = "Users")
      
  )
)))