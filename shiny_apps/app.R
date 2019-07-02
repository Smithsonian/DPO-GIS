library(shiny)


#Settings----
app_name <- "DPO GIS Services"
app_ver <- "0.1.0"
github_link <- "https://github.com/Smithsonian/DPO-GIS"

options(stringsAsFactors = FALSE)
options(encoding = 'UTF-8')


#UI----
ui <- fluidPage(
  # App title
  titlePanel(app_name),
  br(),
  fluidRow(
    column(width = 4,
           uiOutput("main")
    )),
  #footer ----
  HTML(paste0("<br><br><br><div class=\"footer navbar-fixed-bottom\"><br><p>&nbsp;&nbsp;<a href=\"http://dpo.si.edu\" target = _blank><img src=\"dpologo.jpg\"></a> | ", app_name, ", ver. ", app_ver, " | <a href=\"", github_link, "\" target = _blank>Source code</a></p></div>"))
  
)


#Server----
server <- function(input, output, session) {
  
  #main----
  output$main <- renderUI({
    if (is.null(input$ccv_csvinput)){
      shinyWidgets::panel(
        HTML("<p>These services are currently available:</p>"),
        HTML("<ul>
              <li><a href=\"valid_country/\">Country Coordinates Check</a> - Service to verify if a set of coordinates match the country in the row</li>
              </ul>"),
        heading = "DPO GIS Services",
        status = "primary"
      )
    }
  })
  
}



#Run app----
shinyApp(ui = ui, server = server, onStart = function() {
  cat("Loading\n")
  #Cleanup on closing
  onStop(function() {
    cat("Closing\n")
  })
})