library(shiny)
library(shinyFiles)
library(data.table)
library(tidyverse)
library(DT)

ui <- fluidPage(
  
  titlePanel("DA Numbers!"),
  
  sidebarLayout(
    sidebarPanel(
      shinyDirButton("dir", "Choose a folder" ,
      title = "Please select a folder:",
      buttonType = "default", class = NULL)),
      
  mainPanel(textOutput("directory"),
            #textOutput("files"),
            tabsetPanel(type = "tabs",
                        tabPanel("test table", dataTableOutput("tab"))
                        )
)))

server <- function(input,output, session){
  
  roots = c(wd = 'A:/BioRad CFX Processing/BioRad Generated Files/Reports')
  
  observe({
    shinyDirChoose(input, 'dir', roots=roots, filetypes=c('', 'txt'), session = session)
    })
  
  dir_path <- reactive({
    parseDirPath(roots, input$dir)
  })

  
  output$directory <- renderText(dir_path())
  
  files <- reactive({
    list.files(path = dir_path(), pattern = '*.txt', full.names = T)
  })
  
  #output$files <- renderText(files())
  
  raw_data <- reactive({
    as.data.frame(do.call(rbind, lapply(files(), fread, sep="\t", na.strings="NaN"))) 
  })  
  
 data <- reactive({
     raw_data() %>%
     spread(`Analysys Name`, `Crossing Point`) %>%
     mutate(Call = ifelse(is.na(FAM) & is.na(CY5) & is.na(HEX), "Invalid",
                   ifelse(is.na(FAM) & is.na(CY5) & HEX > 0, "Negative",
                   ifelse(is.na(FAM) & CY5 >= 30 | FAM >= 30 & is.na(CY5), "Presumptive",
                   ifelse(FAM < 30 & CY5 < 30 | FAM < 30 & is.na(CY5) | is.na(FAM) & CY5 < 30 | FAM < 30 & CY5 > 30 | FAM > 30 & CY5 < 30, "Positive",
                   ifelse(FAM > 30 & CY5 > 30, "Presumptive", NA))))))
 })
  
  tab1 <- reactive({
    head(raw_data(), n = 5)
  })
  
  output$tab <- renderDataTable(tab1())
  
#  raw_table <- reactive({
#    data.frame(sum(sum(sum(data$Call == "Positive"), sum(data$Call == "Presumptive")),sum(data$Call == "Negative"),sum(data$Call == "Invalid")),
#                        sum(sum(data$Call == "Positive"), sum(data$Call == "Presumptive")),
#                        sum(data$Call == "Negative"),
#                        sum(data$Call == "Invalid"),
#                        (sum(sum(data$Call == "Positive"), sum(data$Call == "Presumptive")) * 100 / sum(sum(sum(data$Call == "Positive"), sum(data$Call == "Presumptive")),sum(data$Call == "Negative"),sum(data$Call == "Invalid"))))
#  })
  
#  a <- reactive({
#    sum(sum(sum(data()$Call == "Positive"), sum(data()$Call == "Presumptive")),sum(data()$Call == "Negative"),sum(data()$Call == "Invalid"))
#  })
#  b <- reactive({
#    sum(sum(data()$Call == "Positive"), sum(data()$Call == "Presumptive"))
#  })
#  c <- reactive({
#    sum(data()$Call == "Negative")
#  })
#  d <- reactive({
#    sum(data()$Call == "Invalid")
#  })
#  e <- reactive({
#    (sum(sum(data()$Call == "Positive"), sum(data()$Call == "Presumptive")) * 100 / sum(sum(sum(data()$Call == "Positive"), sum(data()$Call == "Presumptive")),sum(data()$Call == "Negative"),sum(data()$Call == "Invalid")))
#  })
  
#  tibble <- reactive({
#    data.frame(a(), b(), c(), d(), e()) %>% rename(a = "Total Samples", b = "Total Positive", c = "Negative", d = "Invalid", e = "Percentage Positive")
    
#  })
  
#  output$table <- renderDataTable(tibble())

}
shinyApp(ui = ui, server = server)