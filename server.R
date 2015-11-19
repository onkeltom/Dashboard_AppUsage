library(shiny)
library(dplyr)
library(jsonlite)
library(ggplot2)


appdata <- readRDS("app.rds")

appdata $stop_timestamp <- NULL
appdata $start_timestamp <- NULL

appdata <- filter(appdata, grepl("themeapp", app_url) == FALSE)
appdata <- filter(appdata, grepl("app://addon", app_url) == FALSE)

# appdata <- filter(appdata, date > "2015-06-17")
appdata <- filter(appdata, date < Sys.Date()) 

appdata $deviceID <- as.character(appdata$deviceID)

details <- readRDS("info.rds")

details <- group_by(details, deviceID)
details <- filter(details, stop_timestamp == max(stop_timestamp))
details <- ungroup(details)

details <- select(details, deviceID, os, country, device, locale, language)
details $deviceID <- as.character(details$deviceID)

combined <- left_join(appdata, details, by="deviceID")

marketplace <- read.csv("MP_Lookup.csv", stringsAsFactors = FALSE, sep=";")
gaia <- read.csv("gaiaapps.csv", stringsAsFactors = FALSE, sep=";")

lookup <- bind_rows(marketplace, gaia)

combined <- left_join(combined, lookup, by = "app_url")

Foxfooders <- filter(combined, is_dogfood == "True")
Production <- filter(combined, is_dogfood == "False")

shinyServer(function(input, output, session) { 
  
  output$dateText  <- renderText({
    paste("input$date is", as.character(input$startDate))
  })
  
  output$dateText  <- renderText({
    paste("input$date is", as.character(input$stopDate))
  })

  
  output$os <- renderUI({ 
    selectInput("osversion", "OS", c("All", unique(sort(combined$os))), selected = "All", multiple = TRUE, selectize = FALSE)
  })
  
  output$apps <- renderUI({ 
    selectInput("app", "App", c("All", unique(sort(combined$title))), selected = "All", multiple = TRUE, selectize = FALSE)
  })
  
  output$device <- renderUI({ 
    selectInput("devices", "Device", c("All", unique(sort(combined$device))), selected = "All", multiple = TRUE, selectize = FALSE)
  })
  
  output$country <- renderUI({ 
    selectInput("countries", "Country", c("All", unique(sort(combined$country))), selected = "All", multiple = TRUE, selectize = FALSE)
  })
  
  selectdata <- reactive({
    if (input$dataset == "Foxfood") {
      DT <- Foxfooders
    } else if (input$dataset == "Others") {
      DT <- Production
    } else {
      DT <- bind_rows(Foxfooders, Production)
    }
    DT
  })
  
  toBeDrawn <- reactive({
    DT <- selectdata()
    
    if(is.element("All", input$osversion) == FALSE) {
      DT <- filter(DT, os == input$osversion)
    }
    
    if(is.element("All", input$app) == FALSE) {
      DT <- filter(DT, title == input$app)
    }
    
    if(is.element("All", input$countries) == FALSE) {
      DT <- filter(DT, country == input$countries)
    }
    
    if(is.element("All", input$devices) == FALSE) {
      DT <- filter(DT, device == input$devices)
    }
    
    {
    DT <- filter(DT, date >= input$daterange[1])
    }
    
    {
    DT <- filter(DT, date <= input$daterange[2])
    }

    DT
  })

  output$total <- renderText({
    DT = summarise(toBeDrawn(), total = sum(usage_time))
    print(DT$total)
  })
  
  output$hover_result <- renderText({
    print(paste0("Date: ", as.Date(floor(as.numeric(input$plot_hover$x)), origin = "1970-01-01"),
                 ", Value: ", floor(as.numeric(input$plot_hover$y))))
  })
  
  output$gaia <- renderPlot({
    DT <- toBeDrawn()
    DT <- group_by(DT, date)
    if(input$option == "Invocations"){
      DT = summarise(DT, total = sum(invocations))
    } else if (input$option == "Usage_time"){
      DT = summarise(DT, total = sum(usage_time))
    } else if (input$option == "Installs"){
      DT = summarise(DT, total = sum(installs))
    } else if (input$option == "Uninstalls"){
      DT = summarise(DT, total = sum(uninstalls))
    } else if (input$option == "Users")
      DT = summarise(DT, total = n_distinct(deviceID))
    DT <- ungroup(DT)
    
#     g <- ggplot(data = DT, aes(x = as.Date(date), y = total)) + geom_line()
#     g <- g + theme_bw()
#     print(g)
#     plot(as.Date(DT$date), DT$total)
#     lines(as.Date(DT$date), DT$total, type = "l")
    qplot(as.Date(DT$date), DT$total, geom = "line")
  })
  
})
