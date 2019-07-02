library(shiny)
library(leaflet)
library(jsonlite)
library(futile.logger)
library(dplyr)
library(countrycode)
library(parallel)
library(DT)


#Settings----
app_name <- "Country Coordinates Check Service"
app_ver <- "0.1.0"
github_link <- "https://github.com/Smithsonian/DPO-GIS"

options(stringsAsFactors = FALSE)
options(encoding = 'UTF-8')
#Logfile
logfile <- paste0("logs/", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")



#Settings
source("settings.R")



#UI----
ui <- fluidPage(
  # App title
  titlePanel(app_name),
  br(),
  fluidRow(
    column(width = 4,
           uiOutput("main"),
           uiOutput("ccv_uploadcsv")
    )),
    fluidRow(
     column(width = 8,
            DT::dataTableOutput("ccv_table")
     ),
     column(width = 4, 
            uiOutput("ccv_mapgiven"),
            leafletOutput("ccv_leafletgiven", height = "300px"),
            br(),
            uiOutput("ccv_mapfixed"),
            leafletOutput("ccv_leafletfixed", height = "300px")
     )
  ),
  #hr(),
  #footer ----
  HTML(paste0("<br><br><br><div class=\"footer navbar-fixed-bottom\"><br><p>&nbsp;&nbsp;<a href=\"http://dpo.si.edu\" target = _blank><img src=\"dpologo.jpg\"></a> | ", app_name, ", ver. ", app_ver, " | <a href=\"", github_link, "\" target = _blank>Source code</a></p></div>"))
  
)


#Server----
server <- function(input, output, session) {
  
  source("functions.R")
  
  #Setup Logging
  dir.create('logs', showWarnings = FALSE)
  flog.logger("spatial", INFO, appender=appender.file(logfile))
  
  
  #main----
  output$main <- renderUI({
    if (is.null(input$ccv_csvinput)){
      shinyWidgets::panel(
        HTML("<p>To use this app, upload a <b>csv</b> or <b>Excel (xlsx)</b> file to check that the country matches the coordinates. The file must have these columns:</p>"),
        HTML("<ul>
              <li>id</li>
              <li>decimallatitude</li>
              <li>decimallongitude</li>
              <li>country</li>
             </ul><p>The coordinates must be in decimal format and using the WGS84 datum."),
        heading = "Welcome",
        status = "primary"
      )
    }
  })
  
  
  
  #ccv_uploadcsv ----
  output$ccv_uploadcsv <- renderUI({
    if (is.null(input$ccv_csvinput)){
      tagList(
        selectInput("countrycode", "Countries are coded using:",
                    list(`ISO-2 character` = "iso2c",
                         `ISO-3 character` = "iso3c",
                         `Full name` = "country.name"), 
        ),
        fileInput("ccv_csvinput", "Upload the input file",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv",
                             "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                             ".xlsx"), 
                  width = "100%")
      )
    }
  })
  
  
  
  #ccv_table ----
  output$ccv_table <- DT::renderDataTable({
    
    req(input$ccv_csvinput)
    country_code <- input$countrycode
      
    ccv_csvdata <<- read_inputfile(input$ccv_csvinput$name, input$ccv_csvinput$datapath)
    
    results_table <- data.frame(matrix(nrow = 0, ncol = 8, data = NA))
    
    progress_val <- 0.01
    progress0 <- shiny::Progress$new()
    progress0$set(message = "Initializing. Please wait...", value = progress_val)
    on.exit(progress0$close())
    
    no_rows <- dim(ccv_csvdata)[1]
    
    #Parallel
    #Calculate the number of cores, if not in settings
    if (!exists("no_cores")){
      no_cores <- detectCores() - 1
    }
    # Initiate cluster
    cl <- makeCluster(no_cores)
    
    #Export data to cluster
    clusterExport(cl=cl, varlist=c("ccv_csvdata", "countrycheck", "api_host", "api_ver", "query_api", "apikey"), envir=environment())
    
    countrycheck_data <- function(i){
      library(jsonlite)
      library(futile.logger)
      library(countrycode)
      
      res <- countrycheck(as.integer(ccv_csvdata$id[i]), ccv_csvdata$decimallatitude[i], ccv_csvdata$decimallongitude[i], ccv_csvdata$country[i], country_code, apikey)
      return(res)
    }
    
    #Divide into steps
    step_grouping <- no_cores * 3
    steps <- ceiling(no_rows / step_grouping)
    
    progress_steps <- round(((0.9) / steps), 4)
    progress_val <- 0.1
    progress0$set(value = progress_val, message = "Querying API...")
    
    results_p <- list()
    
    #Run each batch, let the user know of the progress
    for (s in seq(1, steps)){
      to_row <- s * step_grouping
      from_row <- to_row - step_grouping
      if (to_row > no_rows){
        to_row <- no_rows
      }
      
      if (from_row == 0){
        from_row <- 1
      }
      
      cat(paste(from_row, to_row, '\n'))
      cat(paste0("Querying API (", round(((s/steps) * 100), 1), "% completed)\n"))
      
      res <- parLapply(cl, seq(from_row, to_row), countrycheck_data)
      progress_val <- (s * progress_steps) + 0.1
      progress0$set(value = progress_val, message = paste0("Querying API (", round(((s/steps) * 100), 1), "% completed)"))
      results_p <- c(results_p, res)
    }
    
    #stop cluster
    stopCluster(cl)
    
    for (i in seq(1, length(results_p))){
      
      progress_val <- round((i/length(results_p)) * 100, 2)
      
      progress0$set(value = progress_val, message = "Saving results")
      
      results_table <- rbind(results_table, cbind(results_p[[i]]$id, results_p[[i]]$country, results_p[[i]]$latitude, results_p[[i]]$longitude, results_p[[i]]$country_match, results_p[[i]]$latitude_match, results_p[[i]]$longitude_match, results_p[[i]]$note))
    }
    
    progress0$set(message = "Done!", value = 1)
    
    names(results_table) <- c('id', 'country', 'latitude', 'longitude', 'matched_country', 'matched_latitude', 'matched_longitude', 'notes')
    
    results <<- dplyr::filter(results_table, notes != 'Coordinates match')
    #results <<- results_table
    
    no_errors <- dim(results)[1]
    
    DT::datatable(results,
                  escape = FALSE,
                  options = list(searching = TRUE,
                                 ordering = TRUE,
                                 pageLength = 15,
                                 paging = TRUE,
                                 language = list(zeroRecords = "Coordinates match the country in all rows")),
                  rownames = FALSE,
                  selection = 'single',
                  caption = paste0('Found ', no_errors, ' rows with problems (of ', no_rows, ', ', round((no_errors/no_rows) * 100, 2), '%)')) %>%
      formatStyle(c('id', 'country', 'latitude', 'longitude'),  color = 'grey')
  })
  
  
  
  
  #ccv_mapgiven ----
  output$ccv_mapgiven <- renderUI({
    req(input$ccv_table_rows_selected)
    
    this_row <- results[input$ccv_table_rows_selected, ]
    
    lng_dd <- this_row$longitude
    lat_dd <- this_row$latitude
    
    if (!is.na(lng_dd) && !is.na(lat_dd)){
      
      tagList(
        h3("Map with input coordinates"),
        p(paste0('Lon: ', lng_dd, ' / Lat: ', lat_dd)),
        br()
      )
    }
  })
  
  
  #ccv_leafletgiven----
  output$ccv_leafletgiven <- renderLeaflet({
    req(input$ccv_table_rows_selected)
    
    this_row <- results[input$ccv_table_rows_selected, ]
    
    lng_dd <- as.numeric(this_row$longitude)
    lat_dd <- as.numeric(this_row$latitude)

    if (!is.na(lng_dd) && !is.na(lat_dd)){
      leaflet() %>%
        addProviderTiles(providers$OpenStreetMap.HOT,
                         options = providerTileOptions(noWrap = TRUE)
        ) %>%
        addMarkers(data = cbind(lng_dd, lat_dd)) %>%
        addAwesomeMarkers(data = cbind(lng_dd, lat_dd), popup = paste0('Lon: ', lng_dd, '<br>Lat: ', lat_dd)) %>%
        setView(lng = lng_dd, lat = lat_dd, zoom = 04) %>%
        addScaleBar()
    }
  })
  
  
  
  
  #ccv_mapfixed ----
  output$ccv_mapfixed <- renderUI({
    req(input$ccv_table_rows_selected)
    
    this_row <- results[input$ccv_table_rows_selected, ]
    print(this_row)
    lng_dd <- this_row$matched_longitude
    lat_dd <- this_row$matched_latitude
    lng_dd1 <- this_row$longitude
    lat_dd1 <- this_row$latitude
    
    if (!is.na(lng_dd) && !is.na(lat_dd) && (lng_dd != lng_dd1 || lat_dd != lat_dd1)){
      
      tagList(
        h3("Map with corrected coordinates"),
        p(paste0('Lon: ', lng_dd, ' / Lat: ', lat_dd)),
        br()
      )
    }
  })
  
  #ccv_leafletfixed----
  output$ccv_leafletfixed <- renderLeaflet({
    req(input$ccv_table_rows_selected)
    
    this_row <- results[input$ccv_table_rows_selected, ]
    
    lng_dd <- this_row$matched_longitude
    lat_dd <- this_row$matched_latitude
    lng_dd1 <- this_row$longitude
    lat_dd1 <- this_row$latitude
    
    if (!is.na(lng_dd) && !is.na(lat_dd) && (lng_dd != lng_dd1 || lat_dd != lat_dd1)){
      leaflet() %>%
        addProviderTiles(providers$OpenStreetMap.HOT,
                         options = providerTileOptions(noWrap = TRUE)
        ) %>%
        addAwesomeMarkers(data = cbind(as.numeric(lng_dd), as.numeric(lat_dd)), popup = paste0('Lon: ', lng_dd, '<br>Lat: ', lat_dd)) %>%
        setView(lng = as.numeric(lng_dd), lat = as.numeric(lat_dd), zoom = 04) %>%
        addScaleBar()
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