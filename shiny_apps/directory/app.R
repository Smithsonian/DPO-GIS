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
  HTML(paste0("<br><br><br><div class=\"footer navbar-fixed-bottom\"><br><p>&nbsp;&nbsp;<a href=\"http://dpo.si.edu\" target = _blank><img src=\"DPO_logo_300.png\"></a> | ", app_name, ", ver. ", app_ver, " | <a href=\"", github_link, "\" target = _blank>Source code</a></p></div>"))
  
)


#Server----
server <- function(input, output, session) {
  
  #main----
  output$main <- renderUI({
    if (is.null(input$ccv_csvinput)){
      shinyWidgets::panel(
        HTML("<p>These services are currently available:</p>"),
        HTML("<ul>
              <li><a href=\"/villanueval/valid_country/\">Valid Country Check</a> - Service to verify if a set of coordinates match the country in the row.</li>
              <li><a href=\"/villanueval/historical_counties/\">Historical Counties Check</a> - Service to verify if a set of coordinates and year match the historical county in the United States and what the current county+state is.</li>
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