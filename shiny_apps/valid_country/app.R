library(shiny)
library(leaflet)
library(jsonlite)
library(futile.logger)
library(dplyr)
library(countrycode)
library(parallel)
library(DT)
library(WriteXLS)
library(openxlsx)


#Settings----
app_name <- "Valid Country Check"
app_ver <- "0.2.0"
github_link <- "https://github.com/Smithsonian/DPO-GIS"

options(stringsAsFactors = FALSE)
options(encoding = 'UTF-8')
#Logfile
logfile <- paste0("logs/", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")

#Larger size for input file
options(shiny.maxRequestSize=100*1024^2)


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
     column(width = 7,
           DT::dataTableOutput("ccv_table"),
           br(),
           br()
     ),
     column(width = 5, 
            uiOutput("ccv_mapgiven"),
            br(),
            uiOutput("ccv_mapfixed"),
            br(),
            uiOutput("downloadData"),
            br(),
            br()
     )
  ),
  #hr(),
  #footer ----
  HTML(paste0("<br><br><br><br><div class=\"footer navbar-fixed-bottom\" style = \"background: white;\"><br><p>&nbsp;&nbsp;<a href=\"http://dpo.si.edu\" target = _blank><img src=\"DPO_logo_300.png\"></a> | ", app_name, ", ver. ", app_ver, " | <a href=\"", github_link, "\" target = _blank>Source code</a></p></div>"))
  
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
             </ul><p>The coordinates must be in decimal format and using the WGS84 datum. Filesize is limited to 100MB.</p>
             <p>The unit information will used only for generating statistics about this tool.</p>"),
        heading = "Welcome",
        status = "primary"
      )
    }
  })
  
  
  
  #ccv_uploadcsv ----
  output$ccv_uploadcsv <- renderUI({
    if (is.null(input$ccv_csvinput)){
      tagList(
        textInput("unit", "SI Unit and Department"),
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
      
    #Save unit
    flog.info("Unit: %s", input$unit, name='spatial')
    ccv_csvdata <- read_inputfile(input$ccv_csvinput$name, input$ccv_csvinput$datapath)
    
    results_table <- data.frame(matrix(nrow = 0, ncol = 8, data = NA))
    
    progress_val <- 0.01
    progress0 <- shiny::Progress$new()
    progress0$set(message = "Initializing. Please wait...", value = progress_val)
    on.exit(progress0$close())
    
    no_rows <- dim(ccv_csvdata)[1]
    flog.info("no_rows: %s", no_rows, name='spatial')
    #Parallel
    
    # Initiate cluster
    cl <- makeCluster(no_cores)
    
    #Export data to cluster
    clusterExport(cl=cl, varlist=c("ccv_csvdata", "countrycheck", "query_api", "api_url", "apikey", "country_code"), envir=environment())
    
    countrycheck_data <- function(i){
      library(jsonlite)
      library(futile.logger)
      library(countrycode)
      
      #Settings
      source("settings.R")
      
      res <- countrycheck(as.integer(ccv_csvdata$id[i]), ccv_csvdata$decimallatitude[i], ccv_csvdata$decimallongitude[i], ccv_csvdata$country[i], country_code, apikey)
      return(res)
    }
    
    #Divide into steps
    step_grouping <- no_cores * 3
    steps <- ceiling(no_rows / step_grouping)
    
    progress_steps <- round(((0.9) / steps), 4)
    progress_val <- 0.1
    progress0$set(value = progress_val, message = "Checking rows...")
    
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
      cat(paste0("Checking rows (", round(((s/steps) * 100), 1), "% completed)\n"))
      
      res <- parLapply(cl, seq(from_row, to_row), countrycheck_data)
      progress_val <- (s * progress_steps) + 0.1
      progress0$set(value = progress_val, message = paste0("Checking rows (", round(((s/steps) * 100), 1), "% completed)"))
      results_p <- c(results_p, res)
    }
    
    #stop cluster
    stopCluster(cl)
    
    for (i in seq(1, length(results_p))){
      
      progress_val <- round((i/length(results_p)) * 100, 2)
      
      progress0$set(value = progress_val, message = "Saving results")
      
      results_table <- rbind(results_table, cbind(results_p[[i]]$id, results_p[[i]]$country, results_p[[i]]$decimallongitude, results_p[[i]]$decimallatitude, results_p[[i]]$country_match, results_p[[i]]$longitude_match, results_p[[i]]$latitude_match, results_p[[i]]$note))
    }
    
    progress0$set(message = "Done!", value = 1)
    
    names(results_table) <- c('id', 'country', 'decimallongitude', 'decimallatitude', 'matched_country', 'matched_longitude', 'matched_latitude', 'notes')
    
    session$userData$results_table <- results_table
    
    write.csv(results_table, paste0("results/results_countrycheck_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"), quote = TRUE, na = "", row.names = FALSE)
    
    results_table_2fix <- dplyr::distinct(dplyr::filter(results_table, notes != 'Coordinates match'))
    # results_table_2fix <- results_table %>% 
    #         dplyr::filter(notes != 'Coordinates match') %>% 
    #         dplyr::distinct()

    session$userData$results_table_2fix <- results_table_2fix
    
    #results_table1 <- dplyr::select(results_table_2fix, -notes)
    results_table1 <- dplyr::select(results_table_2fix, -matched_longitude)
    results_table1 <- dplyr::select(results_table1, -matched_latitude)
    
    no_errors <- dim(results_table1)[1]
    
    DT::datatable(results_table1,
                  escape = FALSE,
                  options = list(searching = TRUE,
                                 ordering = TRUE,
                                 pageLength = 15,
                                 paging = TRUE,
                                 language = list(zeroRecords = "Coordinates match the country in all rows")),
                  rownames = FALSE,
                  selection = 'single',
                  caption = paste0('Found ', no_errors, ' rows with problems (of ', no_rows, ', ', round((no_errors/no_rows) * 100, 2), '%). Click on a record to see the details.')) %>%
      formatStyle(c('id', 'country', 'decimallatitude', 'decimallongitude'),  color = 'grey')
  })
  
  
  
  
  #ccv_mapgiven ----
  output$ccv_mapgiven <- renderUI({
    req(input$ccv_table_rows_selected)
    
    #Print selected row
    print(input$ccv_table_rows_selected)
    
    results_table_2fix <- session$userData$results_table_2fix
    
    this_row <- results_table_2fix[input$ccv_table_rows_selected, ]
    
    lng_dd <- this_row$decimallongitude
    lat_dd <- this_row$decimallatitude
    notes <- this_row$notes
    
    if (!is.na(lng_dd) && !is.na(lat_dd)){
      
      shinyWidgets::panel(heading = "Map with input coordinates", status = "warning",
        HTML(paste0('<dl class="dl-horizontal"><dt>Longitude</dt><dd>', lng_dd, '</dd><dt>Latitude</dt><dd>', lat_dd, '</dd><dt>Notes</dt><dd class="text-danger">', notes, '</dd></dl>')),
        leafletOutput("ccv_leafletgiven", height = "300px")
      )
    }
  })
  
  
  #ccv_leafletgiven----
  output$ccv_leafletgiven <- renderLeaflet({
    req(input$ccv_table_rows_selected)
    
    results_table_2fix <- session$userData$results_table_2fix
    
    this_row <- results_table_2fix[input$ccv_table_rows_selected, ]
    
    lng_dd <- as.numeric(this_row$decimallongitude)
    lat_dd <- as.numeric(this_row$decimallatitude)

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
    
    results_table_2fix <- session$userData$results_table_2fix
    
    this_row <- results_table_2fix[input$ccv_table_rows_selected, ]
    print(this_row)
    lng_dd <- this_row$matched_longitude
    lat_dd <- this_row$matched_latitude
    lng_dd1 <- this_row$decimallongitude
    lat_dd1 <- this_row$decimallatitude
    
    if (!is.na(lng_dd) && !is.na(lat_dd) && (lng_dd != lng_dd1 || lat_dd != lat_dd1)){
      
      shinyWidgets::panel(heading = "Map with corrected coordinates", status = "success", 
        HTML(paste0('<dl class="dl-horizontal"><dt>Longitude</dt><dd>', lng_dd, '</dd><dt>Latitude</dt><dd>', lat_dd, '</dd></dl>')),
        leafletOutput("ccv_leafletfixed", height = "300px")
      )
    }
  })
  
  #ccv_leafletfixed----
  output$ccv_leafletfixed <- renderLeaflet({
    req(input$ccv_table_rows_selected)
    
    this_row <- results_table_2fix[input$ccv_table_rows_selected, ]
    
    lng_dd <- this_row$matched_longitude
    lat_dd <- this_row$matched_latitude
    lng_dd1 <- this_row$decimallongitude
    lat_dd1 <- this_row$decimallatitude
    
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
  
  
  
  #download CSV----
  #Download CSV
  output$downloadcsv1 <- downloadHandler(
    
    #Downloadable csv of results
    filename = function() {
      paste0("results_countrycheck_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      write.csv(session$userData$results_table, file, quote = TRUE, na = "", row.names = FALSE)
    }
  )
  
  
  #download XLSX----
  #Download XLSX
  output$downloadcsv2 <- downloadHandler(
    filename = function(){paste0("results_countrycheck_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".xlsx")},
    
    content = function(file){
      WriteXLS::WriteXLS(x = session$userData$results_table, ExcelFileName = file, AdjWidth = TRUE, BoldHeaderRow = TRUE, Encoding = "UTF-8", row.names = FALSE, FreezeRow = 1, SheetNames = c("results_aat"))
    },
    contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  )
  
  
  #downloadData ----
  output$downloadData <- renderUI({
    req(input$ccv_csvinput)
    #req(results)
    tagList(
      shinyWidgets::panel(
        HTML("<p>Download the results as a Comma Separated Values file (.csv) or an Excel file (.xlsx).</p><p>The results file contains these columns:</p>"),
        HTML('<dl class="dl-horizontal">
                  <dt>id</dt><dd>The original ID in the input file</dd>
                  <dt>country</dt><dd>Country value in the input file</dd>
                  <dt>decimallongitude</dt><dd>The original decimallongitude in the input file</dd>
                  <dt>decimallatitude</dt><dd>The original decimallatitude in the input file</dd>
                  <dt>matched_country</dt><dd>The country the corrected coordinated matched (if any)</dd>
                  <dt>matched_longitude</dt><dd> The corrected longitude (if applicable)</dd>
                  <dt>matched_latitude</dt><dd>The corrected latitude (if applicable)</dd>
                  <dt>notes</dt><dd>The specific issue with the coordinates</dd></dl>'),
        br(),
        HTML("<div class=\"btn-toolbar\">"),
        downloadButton("downloadcsv1", "CSV (.csv)", class = "btn-success"),
        downloadButton("downloadcsv2", "Excel (.xlsx)", class = "btn-primary"),
        HTML("</div>"),
        heading = "Download Results",
        status = "primary"
      )
    )
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