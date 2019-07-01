library(shiny)
library(leaflet)
library(jsonlite)
library(futile.logger)
library(collexScrubber)
library(countrycode)
library(parallel)


#Settings----
app_name <- "Valid Country Coordinates Check Service"
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
  tabsetPanel(type = "tabs",
              tabPanel("Welcome",
                       br(),
                       fluidRow(
                         column(width = 4,
                                uiOutput("main")
                         )
                       )
              ),
              tabPanel("Country-Coordinates Validation",
                       br(),
                       fluidRow(
                         column(width = 8,
                                uiOutput("ccv_uploadcsv"),
                                DT::dataTableOutput("ccv_table")
                         ),
                         column(width = 4, 
                                uiOutput("ccv_mapgiven"),
                                leafletOutput("ccv_leafletgiven"),
                                br(),
                                uiOutput("ccv_mapfixed"),
                                leafletOutput("ccv_leafletfixed")
                         )
                       )
              )
  ),
  hr(),
  #footer ----
  HTML(paste0("<br><br><br><div class=\"footer navbar-fixed-bottom\" style=\"background: #FFFFFF;\"><br><p>&nbsp;&nbsp;<a href=\"http://dpo.si.edu\" target = _blank><img src=\"dpologo.jpg\"></a> | ", app_name, ", ver. ", app_ver, " | <a href=\"", github_link, "\" target = _blank>Source code</a></p></div>"))
)



#Server----
server <- function(input, output, session) {
  
  source("functions.R")
  
  #Setup Logging
  dir.create('logs', showWarnings = FALSE)
  flog.logger("spatial", INFO, appender=appender.file(logfile))
  
  
  #main----
  output$main <- renderUI({
    if (is.null(input$infiles)){
      shinyWidgets::panel(
        p("To use this app, upload a csv or Excel (xlsx) file to find the spatial matches."),
        p("This app was made by the Digitization Program Office, OCIO."),
        heading = "Welcome",
        status = "primary"
      )
    }
  })
  
  
  
  #ccv_uploadcsv ----
  output$ccv_uploadcsv <- renderUI({
    if (is.null(input$ccv_csvinput)){
      tagList(
        fileInput("ccv_csvinput", "Upload an Input File",
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
    #Read Upload
    filename_to_check <- input$ccv_csvinput$name
    ext_to_check <- stringr::str_split(filename_to_check, '[.]')[[1]]
    ext_to_check <- ext_to_check[length(ext_to_check)]
    
    if (ext_to_check == "csv"){
      #Read CSV file----
      ccv_csvinput <<- read.csv(input$ccv_csvinput$datapath, header = TRUE, stringsAsFactors = FALSE)
      
      # Process any error messages
      if (class(ccv_csvinput) == "try-error"){
        flog.error(paste0("Error reading CSV: ", filename_to_check), name = "csv")
        output$error_msg <- renderUI({
          HTML(paste0("<br><div class=\"alert alert-danger\" role=\"alert\">File ", filename_to_check, " does not appear to be a valid file. Please reload the application and try again.</div>"))
        })
        req(FALSE)
      }
    }else if (ext_to_check == "xlsx"){
      #Read XLSX file----
      try(ccv_csvinput <<- openxlsx::read.xlsx(input$ccv_csvinput$datapath, sheet = 1, check.names = TRUE), silent = TRUE)
      
      if (exists("ccv_csvinput") == FALSE){
        flog.error(paste0("Error reading Excel: ", filename_to_check), name = "xlsx")
        output$error_msg <- renderUI({
          HTML(paste0("<br><div class=\"alert alert-danger\" role=\"alert\">File ", filename_to_check, " does not appear to be a valid file. Please reload the application and try again.</div>"))
        })
        req(FALSE)
      }
    }else{
      #Some other file or there was a problem
      flog.error(paste0("Error reading file: ", filename_to_check), name = "csv")
      output$error_msg <- renderUI({
        HTML("<br><div class=\"alert alert-danger\" role=\"alert\">File must be a valid and have the extension csv or xlsx. Please reload the application and try again.</div>")
      })
      req(FALSE)
    }
    
    ccv_csvdata <<- ccv_csvinput
    
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
    
    countrycheck_gbif <- function(i){
      library(jsonlite)
      library(futile.logger)
      library(countrycode)
      
      res <- countrycheck(as.integer(ccv_csvdata$id[i]), ccv_csvdata$decimalLatitude[i], ccv_csvdata$decimalLongitude[i], ccv_csvdata$countryCode[i], "iso2c", apikey)
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
      
      res <- parLapply(cl, seq(from_row, to_row), countrycheck_gbif)
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
    
    results <<- filter(results_table, notes != 'Coordinates match')
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
                  caption = paste0('Found ', no_errors, ' rows with problems (of ', no_rows, ', ', round((no_errors/no_rows) * 100, 2), '%)'), )
  })
  
  
  
  # #downloadcsv1----
  # output$downloadcsv1 <- downloadHandler(
  #   #Downloadable csv of results
  #   filename = function() {
  #     paste("files_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".md5", sep = "")
  #   },
  #   content = function(file) {
  #     write.table(md5_files, file, row.names = FALSE, col.names = FALSE, quote = FALSE, sep = '\t')
  #   }
  # )
  # 
  
  
  # #downloadData ----
  # output$downloadData <- renderUI({
  #   
  #   req(input$infiles)
  #   
  #   shinyWidgets::panel(
  #     HTML("<p>Download a file with the filenames and MD5 hashes:</p>"),
  #     br(),
  #     HTML("<div class=\"btn-toolbar\">"),
  #     downloadButton("downloadcsv1", "Download md5 file", class = "btn-success"),
  #     HTML("</div>"),
  #     heading = "MD5 file",
  #     status = "primary"
  #   )
  # })
  
  
  
  
  #choose_row----
  # output$choose_row <- renderUI({
  #   req(input$csvinput)
  #   #Read Upload
  #   filename_to_check <- input$csvinput$name
  #   ext_to_check <- stringr::str_split(filename_to_check, '[.]')[[1]]
  #   ext_to_check <- ext_to_check[length(ext_to_check)]
  #   
  #   if (ext_to_check == "csv"){
  #     #Read CSV file----
  #     csvinput <<- read.csv(input$csvinput$datapath, header = TRUE, stringsAsFactors = FALSE)
  #     
  #     # Process any error messages
  #     if (class(csvinput) == "try-error"){
  #       flog.error(paste0("Error reading CSV: ", filename_to_check), name = "csv")
  #       output$error_msg <- renderUI({
  #         HTML(paste0("<br><div class=\"alert alert-danger\" role=\"alert\">File ", filename_to_check, " does not appear to be a valid file. Please reload the application and try again.</div>"))
  #       })
  #       req(FALSE)
  #     }
  #   }else if (ext_to_check == "xlsx"){
  #     #Read XLSX file----
  #     try(csvinput <<- openxlsx::read.xlsx(input$csvinput$datapath, sheet = 1, check.names = TRUE), silent = TRUE)
  #     
  #     if (exists("csvinput") == FALSE){
  #       flog.error(paste0("Error reading Excel: ", filename_to_check), name = "xlsx")
  #       output$error_msg <- renderUI({
  #         HTML(paste0("<br><div class=\"alert alert-danger\" role=\"alert\">File ", filename_to_check, " does not appear to be a valid file. Please reload the application and try again.</div>"))
  #       })
  #       req(FALSE)
  #     }
  #   }else{
  #     #Some other file or there was a problem
  #     flog.error(paste0("Error reading file: ", filename_to_check), name = "csv")
  #     output$error_msg <- renderUI({
  #       HTML("<br><div class=\"alert alert-danger\" role=\"alert\">File must be a valid and have the extension csv or xlsx. Please reload the application and try again.</div>")
  #     })
  #     req(FALSE)
  #   }
  #   
  #   csvdata <<- csvinput
  #   
  #   choices <- data.frame(csvdata$id, paste0(csvdata$locality, ' - ', csvdata$country))
  #   names(choices) <- c("id", "location")
  #   obj_list <- as.list(choices$id)
  #   names(obj_list) <- choices$id
  #   
  #   selectInput(inputId = "row", label = "Select a row:", choices = obj_list, width = "100%", multiple = FALSE, selectize = FALSE)
  # })
  
  
  
  #ccv_mapgiven ----
  output$ccv_mapgiven <- renderUI({
    req(input$ccv_table_rows_selected)
    
    this_row <- results[input$ccv_table_rows_selected, ]
    
    lng_dd <- this_row$longitude
    lat_dd <- this_row$latitude
    
    if (!is.na(lng_dd) && !is.na(lat_dd)){
      
      tagList(
        h3("Map with input coordinates"),
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
        setView(lng = lng_dd, lat = lat_dd, zoom = 08) %>%
        addScaleBar()
    }
  })
  
  
  
  
  #ccv_mapfixed ----
  output$ccv_mapfixed <- renderUI({
    req(input$ccv_table_rows_selected)
    
    this_row <- results[input$ccv_table_rows_selected, ]
    
    lng_dd <- this_row$matched_longitude
    lat_dd <- this_row$matched_latitude
    lng_dd1 <- this_row$longitude
    lat_dd1 <- this_row$latitude
    
    if (!is.na(lng_dd) && !is.na(lat_dd) && (lng_dd != lng_dd1 || lat_dd != lat_dd1)){
      
      tagList(
        h3("Map with corrected coordinates"),
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
        addMarkers(data = cbind(lng_dd, lat_dd)) %>%
        setView(lng = lng_dd, lat = lat_dd, zoom = 08) %>%
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