library(shiny)
library(leaflet)
library(leaflet.extras)
library(jsonlite)
library(futile.logger)
#library(collexScrubber)
library(countrycode)
library(parallel)
library(RPostgres)
library(shinyWidgets)
library(rgdal)
library(shinycssloaders)
library(dplyr)
library(taxize)
library(sp)
library(rgbif)
library(DT)


#Settings----
app_name <- "Mass Georeferencing Tool - DPO"
app_ver <- "0.1.0"
github_link <- "https://github.com/Smithsonian/"
options(stringsAsFactors = FALSE)
options(encoding = 'UTF-8')
#Logfile
logfile <- paste0("logs/", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")


#Settings
source("settings.R")



#Connect to the database ----
if (Sys.info()["nodename"] == "shiny.si.edu"){
  #For RHEL7 odbc driver
  pg_driver = "PostgreSQL"
}else if (Sys.info()["nodename"] == "OCIO-2SJKVD22"){
  #For RHEL7 odbc driver
  pg_driver = "PostgreSQL Unicode(x64)"
}else{
  pg_driver = "PostgreSQL Unicode"
}

db <- dbConnect(odbc::odbc(),
                driver = pg_driver,
                database = pg_db,
                uid = pg_user,
                pwd = pg_pass,
                server = pg_host,
                port = 5432)


#UI----
ui <- fluidPage(
          title = app_name, 
          fluidRow(
            column(width = 3,
                   h2("Mass Georeferencing Tool", id = "title_main"),
                   uiOutput("main"),
                   uiOutput("maingroup"),
                   uiOutput("species"),
                   hr(),
                   uiOutput("records_h"),
                   #shinycssloaders::withSpinner(
                   div(DT::dataTableOutput("records"), style = "font-size:80%"),
                   uiOutput("record_selected")
                     #)
            ),
            column(width = 3,
                   uiOutput("candidatematches_h"),
                   div(DT::dataTableOutput("candidatematches"), style = "font-size:80%"),
                   uiOutput("res1")
            ),
            column(width = 6,
                   uiOutput("map_header"),
                   leafletOutput("map", width = "100%", height = "460px"),
                   fluidRow(
                     column(width = 6,
                            div(uiOutput("candidate_matches_info_h"), style = "font-size:80%")
                     ),
                     column(width = 6,
                            div(uiOutput("marker_info"), style = "font-size:80%")
                     )
                   )
            )
          ),
               
         #footer ----
         uiOutput("footer")
         
)


#Server----
server <- function(input, output, session) {
  
  source("functions.R")
  
  #Setup Logging
  dir.create('logs', showWarnings = FALSE)
  flog.logger("spatial", INFO, appender=appender.file(logfile))
  
  #main----
  output$main <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    group <- query['group']
    
    if (group == "NULL"){
      shinyWidgets::panel(
        p("To use this app, select a group to see the list of species available for georeferencing."),
        p("This is a test system and does not contain all the species in each group."),
        p("This app was made by the Digitization Program Office, OCIO."),
        heading = "Welcome",
        status = "primary"
      )
    }
  })
  
  
  #maingroup ----
  output$maingroup <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    group <- query['group']
    
    if (group != "NULL"){
      HTML(paste0("<p><a href=\"./\"><span class=\"glyphicon glyphicon-home\" aria-hidden=\"true\"></span> Home</a></p>
                  <h4><a href = \"./?group=", group, "\">", group, "</a></h4>"))
    }else{
      HTML(paste0("<p>Select group (rank in parenthesis is how the group is selected):
                  <ul>
                    <li><a href=\"./?group=Plants\">Plants (phylum Tracheophyta)</a></li>
                    
                    <li>Invertebrates:</li>
                      <ul>
                        <li><a href=\"./?group=Unionidae\">Unionidae (family Unionidae)</a></li>
                      </ul>
                    <li>Vertebrates:</li>
                      <ul>
                        <li><a href=\"./?group=Birds\">Birds (class Aves)</a></li>
                        <li><a href=\"./?group=Mammals\">Mammals (class Mammalia)</a></li>
                        <li><a href=\"./?group=Reptiles\">Reptiles (class Reptilia)</a></li>
                        <li><a href=\"./?group=Amphibians\">Amphibians (class Amphibia)</a></li>
                      </ul>
                </ul></p>"))
      # <li>Fossils:</li>
      #   <ul>
      #   <li><a href=\"./?group=Bivalves\">Bivalves (class Bivalvia)</a></li>
      #                   <li><a href=\"./?group=Gastropods\">Gastropods (class Gastropoda)</a></li>
      #                   <li><a href=\"./?group=Crabs\">Crabs (class Malacostraca)</a></li>
      #                   <li><a href=\"./?group=Echinoids\">Echinoids (class Echinoidea)</a></li>
      #                 </ul>
    }
  })
  
  
  
  # species ----
  output$species <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    group <- query['group']
    species <- query['species']

    if (group == "NULL"){req(FALSE)}
    if (species != "NULL"){req(FALSE)}
    
    if (group == "All"){
      group_query <- ""
    }else if (group == "Plants"){
      group_query <- "phylum = 'Tracheophyta'"
    }else if (group == "Birds"){
      group_query <- "class = 'Aves'"
    }else if (group == "Mammals"){
      group_query <- "class = 'Mammalia'"
    }else if (group == "Reptiles"){
      group_query <- "class = 'Reptilia'"
    }else if (group == "Amphibians"){
      group_query <- "class = 'Amphibia'"
    }else if (group == "Bivalves"){
      group_query <- "basisofrecord = 'FOSSIL_SPECIMEN' AND class = 'Bivalvia'"
    }else if (group == "Gastropods"){
      group_query <- "basisofrecord = 'FOSSIL_SPECIMEN' AND class = 'Gastropoda'"
    }else if (group == "Crabs"){
      group_query <- "basisofrecord = 'FOSSIL_SPECIMEN' AND class = 'Malacostraca'"
    }else if (group == "Echinoids"){
      group_query <- "basisofrecord = 'FOSSIL_SPECIMEN' AND class = 'Echinoidea'"
    }else if (group == "Unionidae"){
      group_query <- "family = 'Unionidae'"
    }
    
    #Encoding
    species <- dbGetQuery(db, "SET CLIENT_ENCODING TO 'UTF-8';")
    
    species_query <- paste0("SELECT species FROM gbif_si_summary WHERE ", group_query, " AND no_records IS NOT NULL ORDER BY species")
    species <- dbGetQuery(db, species_query)
    tagList(
      selectInput("species", "Select a species:", species),
      actionButton("submit_species", "Submit")
    )
  })
  
  
  
  # submit_species react ----
  observeEvent(input$submit_species, {
  
    req(input$species)
    query <- parseQueryString(session$clientData$url_search)
    group <- query['group']
    
    output$main <- renderUI({
      HTML(paste0("<script>$(location).attr('href', './?group=", group, "&species=", input$species, "')</script>"))
    })
  })
    
  
  
  #records_header----
  output$records_h <- renderUI({
    
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    
    session$userData$species <- species
    
    req(species != "NULL")
    
    vernacular <- try(sci2comm(scinames = species$species, db = "ncbi", simplify = TRUE), silent = TRUE)
    
    if (class(vernacular) == "try-error" || vernacular[1] == "character(0)"){
      vernacular_name <- ""
    }else{
      vernacular_name <- as.character(vernacular[1])
      #From https://stackoverflow.com/a/32758968
      vernacular_name <- paste0("<p>Common name: ", toupper(substr(vernacular_name, 1, 1)), substr(vernacular_name, 2, nchar(vernacular_name)), "</p>")
    }
    
    HTML(paste0("<h3>Species: <em>", species$species, "</em></h3>", vernacular_name))
  })
  
  
  #records----
  output$records <- DT::renderDataTable({
    species <- session$userData$species
    
    req(species != "NULL")
    
    #records_query <- paste0("SELECT scientificname, species, max(gbifid)::text as gbifid, max(occurrenceid) as occurrenceid, stateprovince, countrycode, locality, count(*)::int as no_records FROM gbif_si WHERE gbifid IN (SELECT gbifid from gbif_si_matches WHERE species = '", species, "') GROUP BY scientificname, species, countrycode, stateprovince, locality ORDER BY no_records DESC")
    records_query <- paste0("WITH data AS (SELECT scientificname, species, max(gbifid) as gbifid, max(occurrenceid) as occurrenceid, null as eventdate, stateprovince, countrycode, locality, count(*)::int as no_records FROM gbif_si WHERE species = '", species, "' GROUP BY scientificname, species, countrycode, stateprovince, locality) SELECT * FROM data WHERE gbifid IN (SELECT gbifid FROM gbif_si_matches WHERE species = '", species, "') ORDER BY no_records DESC")
    #records_query <- paste0("WITH data AS (SELECT scientificname, species, max(gbifid) as gbifid, max(occurrenceid) as occurrenceid, to_char(max(eventdate)::date, 'YYYY-MM-DD') as eventdate, stateprovince, countrycode, locality, count(*)::int as no_records FROM gbif_si WHERE species = '", species, "' GROUP BY scientificname, species, countrycode, stateprovince, locality) SELECT * FROM data WHERE gbifid IN (SELECT gbifid FROM gbif_si_matches WHERE species = '", species, "') ORDER BY no_records DESC")
    records <- dbGetQuery(db, records_query)
    
    session$userData$records <- records
    
    data <- dplyr::select(records, -occurrenceid) %>%
      dplyr::select(-scientificname) %>%
      dplyr::select(-species) %>%
      dplyr::select(-gbifid) %>%
      dplyr::select(-stateprovince)

    data <- data[c("locality", "countrycode", "no_records")]
    names(data) <- c("Locality", "Country", "No. records") 
    
    DT::datatable(data, 
                escape = FALSE,
                options = list(searching = FALSE,
                               ordering = TRUE,
                               pageLength = 5,
                               paging = TRUE,
                               language = list(zeroRecords = "No matches found"),
                               #scrollY = "480px",
                               lengthChange = FALSE
                ),
                rownames = FALSE,
                selection = 'single',
                caption = "Records grouped by locality. Select a record to show candidate matches")
  })

  
  
  #record_selected----
  output$record_selected <- renderUI({
    req(input$records_rows_selected)
    
    records <- session$userData$records
    this_row <- records[input$records_rows_selected,]
    
    if (this_row$stateprovince == ""){
      located_at <- countrycode::countrycode(this_row$countrycode, origin = "iso2c", destination = "country.name")
    }else{
      located_at <- paste0(this_row$stateprovince, ", ", countrycode::countrycode(this_row$countrycode, origin = "iso2c", destination = "country.name"))
    }

    HTML(paste0("<br><div class=\"panel panel-primary\">
      <div class=\"panel-heading\">
      <h3 class=\"panel-title\">Record Selected</h3>
      </div>
      <div class=\"panel-body\">
          <dl class=\"dl-horizontal\">
          <dt><strong>Locality</strong></dt><dd><strong>", this_row$locality, "</strong></dd>
          <dt><strong>Located at</strong></dt><dd><strong>", located_at, "</strong></dd>
          <dt>No. of records</dt><dd>", this_row$no_records, "</dd>
          <dt>Sample Record</dt><dd><a href=\"https://www.gbif.org/occurrence/", this_row$gbifid, "\" target = _blank>", this_row$gbifid, "</a></dd>
          <dt>Date</dt><dd>", this_row$eventdate, "</dd>
          <dt>Occurrence ID</dt><dd><a href=\"", this_row$occurrenceid, "\" target = _blank>", this_row$occurrenceid, "</a></dd>
        </dl>
    </div>
    </div>"))
    
  })
  
  
  #candidatematches_h----
  output$candidatematches_h <- renderUI({
    req(input$records_rows_selected)
    h3("Candidate Matches:")
  })
  
  #candidatematches----
  output$candidatematches <- DT::renderDataTable({
    
    if (!is.null(input$records_rows_selected)){
      search_url <- api_searchfuzzy_url
      
      records <- session$userData$records
      
      gbifid <- records[input$records_rows_selected,]$gbifid
      species <- records[input$records_rows_selected,]$species
      
      matches_query <- paste0("WITH data AS (
                            
                                SELECT
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  null as eventdate,
                                  m.name_1 as name,
                                  g.located_at,
                                  m.engtype_1 as type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  gbif_si_matches g,
                                  gadm1 m
                                WHERE 
                                  g.gbifid = '", gbifid, "' AND
                                  g.match::uuid = m.uid AND
                                  g.source = 'gadm1'
                                
                                UNION
                                
                                SELECT
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  null as eventdate,
                                  m.name_2 as name,
                                  g.located_at,
                                  m.engtype_2 as type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  gbif_si_matches g,
                                  gadm2 m
                                WHERE 
                                  g.gbifid = '", gbifid, "' AND
                                  g.match::uuid = m.uid AND
                                  g.source = 'gadm2'
                                
                                UNION
                                
                                SELECT
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  null as eventdate,
                                  m.name_3 as name,
                                  g.located_at,
                                  m.engtype_3 as type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  gbif_si_matches g,
                                  gadm3 m
                                WHERE 
                                  g.gbifid = '", gbifid, "' AND
                                  g.match::uuid = m.uid AND
                                  g.source = 'gadm3'
                                
                                UNION
                                
                                SELECT
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  null as eventdate,
                                  m.name_4 as name,
                                  g.located_at,
                                  m.engtype_4 as type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  gbif_si_matches g,
                                  gadm4 m
                                WHERE 
                                  g.gbifid = '", gbifid, "' AND
                                  g.match::uuid = m.uid AND
                                  g.source = 'gadm4'
                                
                                UNION
                                
                                SELECT
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  null as eventdate,
                                  m.name_5 as name,
                                  g.located_at,
                                  m.engtype_5 as type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  gbif_si_matches g,
                                  gadm5 m
                                WHERE 
                                  g.gbifid = '", gbifid, "' AND
                                  g.match::uuid = m.uid AND
                                  g.source = 'gadm5'
                                
                                 UNION
                                
                                SELECT 
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  null as eventdate,
                                  m.name as name,
                                  g.located_at,
                                  m.desig_eng as type,
                                  round(st_x(m.the_geom)::numeric, 5) as longitude,
                                  round(st_y(m.the_geom)::numeric, 5) as latitude
                                FROM 
                                  gbif_si_matches g,
                                  wdpa_points m
                                WHERE 
                                  g.gbifid = '", gbifid, "' AND
                                  g.match::uuid = m.uid AND
                                  g.source = 'wdpa_points'
                                
                                
                                UNION
                                
                                SELECT 
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  null as eventdate,
                                  m.name as name,
                                  g.located_at,
                                  m.desig_eng as type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  gbif_si_matches g,
                                  wdpa_polygons m
                                WHERE 
                                  g.gbifid = '", gbifid, "' AND
                                  g.match::uuid = m.uid AND
                                  g.source = 'wdpa_polygons'
                                  
                                  
                                  UNION
                                
                                SELECT 
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  null as eventdate,
                                  m.name as name,
                                  g.located_at,
                                  mfc.name as type,
                                  round(st_x(m.the_geom)::numeric, 5) as longitude,
                                  round(st_y(m.the_geom)::numeric, 5) as latitude
                                FROM 
                                  gbif_si_matches g,
                                  geonames m,
                                  geonames_fc mfc
                                WHERE 
                                  g.gbifid = '", gbifid, "' AND
                                  g.match::uuid = m.uid AND
                                  m.feature_code = mfc.code AND
                                  g.source = 'geonames'
                                GROUP BY 
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  m.name,
                                  g.located_at,
                                  mfc.name,
                                  m.the_geom
                                
                                UNION
                                
                                SELECT 
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  null as eventdate,
                                  m.lake_name as name,
                                  m.gadm2 as located_at,
                                  m.type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  gbif_si_matches g,
                                  global_lakes m
                                WHERE 
                                  g.gbifid = '", gbifid, "' AND
                                  g.match::uuid = m.uid AND 
                                  g.source = 'global_lakes'
                                GROUP BY 
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  m.lake_name,
                                  m.gadm2,
                                  m.type,
                                  m.centroid
                                
                                UNION
                                
                                SELECT 
                                  g.gbifid,
                                  max(g.source) as source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  null as eventdate,
                                  m.locality as name,
                                  g.located_at,
                                  'locality' as type,
                                  m.decimallongitude as longitude,
                                  m.decimallatitude as latitude
                                FROM 
                                  gbif_si_matches g,
                                  gbif m
                                WHERE 
                                  g.gbifid = '", gbifid, "' AND
                                  m.species = '", species, "' AND
                                  g.match = m.gbifid AND
                                  (g.source = 'gbif.species' OR
                                  g.source = 'gbif.genus')
                                GROUP BY 
                                  g.gbifid,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  m.locality,
                                  g.located_at,
                                  m.decimallongitude,
                                  m.decimallatitude
                              )
                            SELECT 
                                  gbifid,
                                  source,
                                  score,
                                  no_records,
                                  match,
                                  eventdate,
                                  name,
                                  located_at,
                                  UPPER(left(type, 1)) || right(type, -1) as type,
                                  latitude,
                                  longitude
                            FROM 
                                  data
                            WHERE 
                                  CHAR_LENGTH(name) > 3
                            ORDER BY 
                                  score DESC,
                                  CASE WHEN source = 'gbif.species' THEN 1
                                  WHEN source = 'gbif.genus' THEN 2
                                  WHEN source = 'wdpa_polygons' THEN 3
                                  WHEN source = 'wdpa_points' THEN 4
                                  WHEN source = 'gadm5' THEN 5
                                  WHEN source = 'gadm4' THEN 6
                                  WHEN source = 'gadm3' THEN 7
                                  WHEN source = 'gadm2' THEN 8
                                  WHEN source = 'gadm1' THEN 9
                                  WHEN source = 'gadm0' THEN 10
                                  END ASC")
      cat(matches_query)
      results <- dbGetQuery(db, matches_query)
      
       if (dim(results)[1] == 0){

         results_table <- results
         
         output$res1 <- renderUI({
           tagList(
             tags$br(),tags$br(),
             tags$em("No results found.")
           )
         })

       }else{

         results <- results %>%
           dplyr::arrange(match(source, c("gbif.species", "gbif.genus", "wdpa_polygons", "wdpa_points", "global_lakes", "geonames", "gadm5", "gadm4", "gadm3", "gadm2", "gadm1", "gadm0"))) %>% 
           dplyr::arrange(dplyr::desc(score))
           
         session$userData$results <- results
         
         gadm_layers <- c("gadm", "gadm0", "gadm1", "gadm2", "gadm3", "gadm4", "gadm5")
         gbif_layers <- c("gbif.species", "gbif.genus", "gbif.family")
         wdpa_layers <- c("wdpa_polygons", "wdpa_points", "wdpa")
         
         for (i in seq(1, dim(results)[1])){
           if (results$source[i] %in% gadm_layers){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-flag pull-right\" aria-hidden=\"true\" title = \"Political locality from GADM\"></span>")
           }else if (results$source[i] == "gbif.species"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-map-marker pull-right\" aria-hidden=\"true\" title = \"Locality from a GBIF record for the species\"></span>")
           }else if (results$source[i] == "gbif.genus"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-map-marker pull-right\" aria-hidden=\"true\" title = \"Locality from a GBIF record for the genus\"></span>")
           }else if (results$source[i] == "gbif.family"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-map-marker pull-right\" aria-hidden=\"true\" title = \"Locality from a GBIF record for the family\"></span>")
           }else if (results$source[i] %in% wdpa_layers){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-leaf pull-right\" aria-hidden=\"true\" title = \"Protected Area\"></span>")
           }else if (results$source[i] == "geonames"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-pushpin pull-right\" aria-hidden=\"true\" title = \"Locality from Geonames\"></span>")
           }else if (results$source[i] == "global_lakes"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-tint pull-right\" aria-hidden=\"true\" title = \"Locality from Global Lakes\"></span>")
           }
           
         }
         
         #if (dim(results)[1] > 0){
         results_table <- results %>% dplyr::select(-gbifid) %>% 
           dplyr::select(-match) %>% 
           dplyr::select(-no_records) %>% 
           dplyr::select(-eventdate)
         
         #Convert type to factor for filtering
         results$type <- as.factor(results$type)
         
         #Reorder cols
         #results_table <- results[c("source", "name", "located_at", "score")]
         results_table <- results[c("name", "located_at", "score")]
         Encoding(results_table$name) <- "ASCII"
         Encoding(results_table$located_at) <- "ASCII"
         #names(results_table) <- c("Source", "Locality", "Located at", "Score")
         names(results_table) <- c("Locality", "Located at", "Score")
         #}
         
         output$res1 <- renderUI({

         })
       }
       
      if (dim(results_table)[1]==0){
        DT::datatable(NULL,
                      escape = FALSE,
                      options = list(searching = FALSE,
                                     ordering = TRUE,
                                     pageLength = 15,
                                     paging = FALSE,
                                     language = list(zeroRecords = "No matches found"),
                                     scrollY = "380px"
                      ),
                      rownames = FALSE,
                      selection = list(mode = 'single', selected = c(1)),
                      caption = "Select a locality to show on the map")
      }else if (dim(results_table)[1]==1){
         DT::datatable(results_table,
                       escape = FALSE,
                       options = list(searching = FALSE,
                                      ordering = TRUE,
                                      pageLength = 15,
                                      paging = FALSE,
                                      scrollY = "680px"
                       ),
                       rownames = FALSE,
                       selection = list(mode = 'single', selected = c(1)),
                       caption = "Select a locality to show on the map")
       }else{
         DT::datatable(results_table,
                       escape = FALSE,
                       options = list(searching = FALSE,
                                      ordering = TRUE,
                                      pageLength = 15,
                                      paging = TRUE,
                                      scrollY = "680px"#,
                                      # dom = 'Pfrtip', columnDefs = list(list(
                                      #   searchPanes = list(show = FALSE), targets = 3:4
                                      # ))
                       ),
                       #extensions = c('Select', 'SearchPanes'),
                       rownames = FALSE,
                       selection = list(mode = 'single'),
                       caption = "Select a locality to show on the map") %>% 
                                        formatStyle(c('Score'),
                                         background = styleColorBar(range(50, 100), 'lightblue'),
                                         backgroundSize = '98% 88%',
                                         backgroundRepeat = 'no-repeat',
                                         backgroundPosition = 'center')
       }
     }
  })

  
  
  #map----
  output$map <- renderLeaflet({
    species <- session$userData$species
    
    if (species == "NULL"){
      req(FALSE)
    }
      
    if (is.null(input$records_rows_selected)){
      #species only----
      
      api_convex_url <- "http://dpogis.si.edu/api/0.1/species_range?scientificname="
      
      url_get <- paste0(api_convex_url, species)
      
      #print(url_get)
      
      api_req <- httr::GET(url = URLencode(url_get),
                           httr::add_headers(
                             "X-Api-Key" = app_api_key
                           )
      )
      
      #print(api_req)
      
      convex_geom <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      
      #from https://gis.stackexchange.com/a/252992
      y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Species\": \"', convex_geom$type, ' of ', species, '\"},\"geometry\":', convex_geom$the_geom, '}')
      y2 <- paste(y, collapse=',')
      spp_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
      print(spp_geom)
      
      spp_geom_bounds <- paste0("[
                          [", convex_geom$ymax, ", ", convex_geom$xmax, "],
                          [", convex_geom$ymin, ", ", convex_geom$xmin, "]
                      ]")
      
      #bounds
      xmin <- convex_geom$xmin
      ymin <- convex_geom$ymin
      xmax <- convex_geom$xmax
      ymax <- convex_geom$ymax
      
      if (xmin == xmax || ymin == ymax){
        xmin <- xmin - 0.05
        xmax <- xmax + 0.05
        ymin <- ymin - 0.05
        ymax <- ymax + 0.05
      }
      
      #species_geom_layer <- paste0(convex_geom$type, ' of\n', species)
      species_geom_layer <- "Species Dist"
      
      leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
        htmlwidgets::onRender("function(el, x) {
              L.control.zoom({ position: 'topright' }).addTo(this)
          }") %>%
        addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
        addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
        addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
        addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
        addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) %>%
        addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
        fitBounds(xmin, ymin, xmax, ymax) %>%
        addScaleBar(position = "bottomleft") %>%
        # Layers control
        addLayersControl(
          baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
          overlayGroups = species_geom_layer,
          options = layersControlOptions(collapsed = FALSE)
        ) %>% 
        addEasyButton(easyButton(
          icon="fa-search", title="Zoom to Species Range",
          onClick=JS("function(btn, map){ map.fitBounds([", spp_geom_bounds, "]);}"))
        ) %>% 
        addMeasure(primaryLengthUnit="kilometers", secondaryLengthUnit="miles", primaryAreaUnit = "sqkilometers", position = "topleft")
      
  }else{
      req(input$records_rows_selected)

      if (is.null(input$candidatematches_rows_selected)){
        
        #Only species dist----
        api_convex_url <- "http://dpogis.si.edu/api/0.1/species_range?scientificname="
        
        #convexhull
        url_get <- paste0(api_convex_url, species)
        
        #print(url_get)
        
        api_req <- httr::GET(url = URLencode(url_get),
                             httr::add_headers(
                               "X-Api-Key" = app_api_key
                             )
        )
        
        #print(api_req)
        
        if (api_req$status_code == 200){
          convex_geom <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
          
          #from https://gis.stackexchange.com/a/252992
          y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Species\": \"', convex_geom$type, ' of ', species, '\"},\"geometry\":', convex_geom$the_geom, '}')
          y2 <- paste(y, collapse=',')
          spp_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
          print(spp_geom)
          
          spp_geom_bounds <- paste0("[
                            [", convex_geom$ymax, ", ", convex_geom$xmax, "],
                            [", convex_geom$ymin, ", ", convex_geom$xmin, "]
                        ]")
          
          #bounds
          xmin <- convex_geom$xmin
          ymin <- convex_geom$ymin
          xmax <- convex_geom$xmax
          ymax <- convex_geom$ymax
        }else{
          convex_geom <- "{\"type\":\"FeatureCollection\",\"features\":[]}"
          xmin <- 0
          ymin <- 0
          xmax <- 0
          ymax <- 0
        }
        
        if (xmin == xmax || ymin == ymax){
          xmin <- xmin - 0.05
          xmax <- xmax + 0.05
          ymin <- ymin - 0.05
          ymax <- ymax + 0.05
        }
        
        #Draw all candidates
        results <- session$userData$results

        coords <- SpatialPoints(coords = data.frame(lng = as.numeric(results$longitude), lat = as.numeric(results$latitude)), proj4string = CRS("+proj=longlat +datum=WGS84"))
        print(coords)
        data <- as.data.frame(results$name)
        #print(data)

        icons <- awesomeIcons(icon = "whatever",
                              iconColor = "red",
                              library = "ion")
        
        species_geom_layer <- "Species Dist"
        
        leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
          htmlwidgets::onRender("function(el, x) {
                  L.control.zoom({ position: 'topright' }).addTo(this)
              }") %>%
          addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
          addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
          addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
          addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
          addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
          addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) %>%
          addScaleBar(position = "bottomleft") %>%
          fitBounds(xmin, ymin, xmax, ymax) %>%
          addLayersControl(
            baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
            overlayGroups = species_geom_layer,
            options = layersControlOptions(collapsed = FALSE)
          ) %>% 
          addMeasure(primaryLengthUnit="kilometers", secondaryLengthUnit="miles", primaryAreaUnit = "sqkilometers", position = "topleft") %>% 
          addAwesomeMarkers(data = coords, popup = results$name, clusterOptions = markerClusterOptions())
          
      }else{
          results <- session$userData$results
          this_row <- results[input$candidatematches_rows_selected, ]
          
          Encoding(this_row$name) <- "ASCII"
          Encoding(this_row$located_at) <- "ASCII"
          
          print(this_row)
          
          geom_layer <- this_row$source
          geom_uid <- this_row$match
          geom_name <- this_row$name
          geom_located_at <- this_row$located_at
          gbifid <- this_row$match
          
          #if geom from GBIF----
          if (geom_layer == "gbif.species" || geom_layer == "gbif.genus"){
            
            match_query <- paste0("SELECT 
                                  g.*,
                                  CASE WHEN d.organizationname = '' 
                                      THEN d.title
                                      ELSE CONCAT(d.title, ', ', d.organizationname) END AS dataset,
                                  d.datasetkey
                              FROM 
                                  gbif g,
                                  gbif_datasets d
                              WHERE 
                                  g.species = '", species, "' AND 
                                  g.gbifid = '", gbifid, "' AND
                                  g.datasetkey::uuid = d.datasetkey")
            cat(match_query)
            the_feature <- dbGetQuery(db, match_query)
            
            #candidate_matches_info_h----
            output$candidate_matches_info_h <- renderUI({
              
              observeEvent(input$map_click, {
                p <- input$map_click
                output$marker_info <- renderUI({
                  req(p)
    
                  click_lat <- format(round(as.numeric(p["lat"]), digits = 5), nsmall = 5)
                  click_lng <- format(round(as.numeric(p["lng"]), digits = 5), nsmall = 5)
                  
                  print(paste0("Click at: ", click_lat, "/", click_lng))
    
                  icons <- awesomeIcons(icon = "whatever",
                                        iconColor = "red",
                                        library = "ion")
                  leafletProxy('map') %>%
                    removeMarker(layerId = "newm") %>% 
                    addAwesomeMarkers(lng = as.numeric(click_lng), lat = as.numeric(click_lat), layerId = "newm", icon = icons)
                  
                  HTML(paste0("<br><div class=\"panel panel-success\">
                    <div class=\"panel-heading\">
                    <h3 class=\"panel-title\">Click on Map</h3>
                    </div>
                    <div class=\"panel-body\">
                        <dl class=\"dl-horizontal\">
                            <dt>Longitude</dt><dd>", click_lng, "</dd>
                            <dt>Latitude</dt><dd>", click_lat, "</dd>
                            <dt>Uncertainty</dt><dd>", 
                              
                            "</dd>
                            </dl>",
                            sliderInput("integer", "Set the value in m:",
                                        min = 10, max = 10000,
                                        value = 500),
                            actionButton("rec_save", "Save location for the records", style='font-size:80%'),
                  "</div>
                  </div>"))
                })
              })
              
              uncert <- the_feature$coordinateuncertaintyinmeters
              if (uncert == ""){
                uncert <- "NA"
              }else{
                uncert <- paste0(uncert, " m")
              }
                
              
              html_to_print <- paste0("<br><div class=\"panel panel-success\">
                    <div class=\"panel-heading\">
                    <h3 class=\"panel-title\">Match Selected</h3>
                    </div>
                    <div class=\"panel-body\">
                        <dl class=\"dl-horizontal\">
                            <dt>Name</dt><dd>", this_row$name, "</dd>
                            <dt>Located in</dt><dd>", this_row$located_at, "</dd>
                            <dt>Locality uncertainty</dt><dd>", uncert, "</dd>
                            <dt>Source</dt><dd><a href=\"https://www.gbif.org/occurrence/", the_feature$gbifid, "\" target=_blank title=\"Open record in GBIF\">GBIF record (", the_feature$gbifid, ")</a></dd>
                            <dt>Dataset</dt><dd><a href=\"https://www.gbif.org/dataset/", the_feature$datasetkey, "\" target=_blank title=\"View dataset in GBIF\">", the_feature$dataset, "</a></dd>
                            <dt>Date</dt><dd>", this_row$eventdate, "</dd>
                            <dt>Score</dt><dd>", this_row$score, "</dd>
                            <dt>No. of records</dt><dd>", this_row$no_records, "</dd>
                            <dt>Lat/Lon</dt><dd>", this_row$latitude, " / ", this_row$longitude, "</dd>
                            <dt>Record issues</dt><dd><small>")
              
              
              cat(the_feature$issue)
              if (the_feature$issue != ''){
                record_issues <- stringr::str_split(the_feature$issue, ";")[[1]]
                
                for (i in seq(1, length(record_issues))){
                  if (i > 1){
                    html_to_print <- paste0(html_to_print, "<br>")
                  }
                  
                  html_to_print <- paste0(html_to_print, "<abbr title=\"", gbif_issues_lookup(issue = record_issues[i])$description, "\">", record_issues[i], "</abbr>")
                }
              }
              
              html_to_print <- paste0(html_to_print, "</small></dd></dl>", 
                                      actionButton("gbif_rec_save", "Save location for the records", style='font-size:80%'),
                                      "</div></div>")
              
              HTML(html_to_print)
            })
            
            #convexhull
            api_convex_url <- "http://dpogis.si.edu/api/0.1/species_range?scientificname="
            
            url_get <- paste0(api_convex_url, species)
            
            #print(url_get)
            
            api_req <- httr::GET(url = URLencode(url_get),
                                 httr::add_headers(
                                   "X-Api-Key" = app_api_key
                                 )
            )
            
            #print(api_req)
            
            convex_geom <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
            
            #from https://gis.stackexchange.com/a/252992
            y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Species\": \"', convex_geom$type, ' of ', species, '\"},\"geometry\":', convex_geom$the_geom, '}')
            y2 <- paste(y, collapse=',')
            spp_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
            print(spp_geom)
            
            spp_geom_bounds <- paste0("[
                              [", convex_geom$ymax, ", ", convex_geom$xmax, "],
                              [", convex_geom$ymin, ", ", convex_geom$xmin, "]
                          ]")
            
            #bounds
            xmin <- convex_geom$xmin
            ymin <- convex_geom$ymin
            xmax <- convex_geom$xmax
            ymax <- convex_geom$ymax
            
            sitelon <- the_feature$decimallongitude
            sitelat <- the_feature$decimallatitude
            
            feat_long <- the_feature$decimallongitude
            feat_lat <- the_feature$decimallatitude
            feat_name <- the_feature$locality
            feat_country <- the_feature$countrycode
            feat_layer <- "GBIF"
            feat_type <- "Point"
            
            #bounds
            xmin <- the_feature$decimallongitude
            ymin <- the_feature$decimallatitude
            xmax <- the_feature$decimallongitude
            ymax <- the_feature$decimallatitude
            
            if (xmin == xmax || ymin == ymax){
              xmin <- xmin - 0.05
              xmax <- xmax + 0.05
              ymin <- ymin - 0.05
              ymax <- ymax + 0.05
            }
            
            #species_geom_layer <- paste0(convex_geom$type, ' of ', species)
            species_geom_layer <- "Species Dist"
            
            # %>% 
            #   addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) #Uncertainty buffer
            # 
            # #from https://gis.stackexchange.com/a/252992
            # y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Uncertainty of location\": ', the_feature$coordinateuncertaintym, '},\"geometry\":', convex_geom$the_geom, '}')
            # y2 <- paste(y, collapse=',')
            # spp_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
            # print(spp_geom)
            
            
            leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
              htmlwidgets::onRender("function(el, x) {
                  L.control.zoom({ position: 'topright' }).addTo(this)
              }") %>%
              addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
              addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
              addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
              addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
              addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) %>%
              addAwesomeMarkers(data = cbind(feat_long, feat_lat), popup = paste0('Name: ', feat_name, '<br>Country: ', feat_country, '<br>Lon: ', sitelon, '<br>Lat: ', sitelat, '<br>Layer: ', feat_layer, '<br>Type: ', feat_type)) %>%
              addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
              fitBounds(xmin, ymin, xmax, ymax) %>%
              addScaleBar(position = "bottomleft") %>%
              addCircles(lng = feat_long, lat = feat_lat, weight = 1,
                         radius = as.numeric(the_feature$coordinateuncertaintyinmeters), popup = paste0("Uncertainty of the locality: ", the_feature$coordinateuncertaintyinmeters)) %>% 
              # Layers control
              addLayersControl(
                baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
                overlayGroups = species_geom_layer,
                options = layersControlOptions(collapsed = FALSE)
              ) %>% 
              addEasyButton(easyButton(
                icon="fa-search", title="Zoom to Species Range",
                onClick=JS("function(btn, map){ map.fitBounds([", spp_geom_bounds, "]);}"))
                ) %>% 
              addMeasure(primaryLengthUnit="kilometers", secondaryLengthUnit="miles", primaryAreaUnit = "sqkilometers", position = "topleft")
          }else{
            #If geom from other----
            
            #Feature
            url_get <- paste0(api_detail_url, geom_uid, "&layer=", geom_layer)
            
            #print(url_get)
            
            api_req <- httr::GET(url = URLencode(url_get),
                                 httr::add_headers(
                                   "X-Api-Key" = app_api_key
                                 )
            )
            
            #print(api_req)
            
            the_feature <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
            
            #Geometry
            url_get <- paste0(api_geom_url, geom_uid, "&layer=", geom_layer)
            
            #print(url_get)
            
            api_req <- httr::GET(url = URLencode(url_get),
                                 httr::add_headers(
                                   "X-Api-Key" = app_api_key
                                 )
            )
            
            #print(api_req)
            
            the_geom <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
            
            #candidate_matches_info_h----
            output$candidate_matches_info_h <- renderUI({
    
              observeEvent(input$map_click, {
                p <- input$map_click
                output$marker_info <- renderUI({
                  req(p)
    
                  click_lat <- format(round(as.numeric(p["lat"]), digits = 5), nsmall = 5)
                  click_lng <- format(round(as.numeric(p["lng"]), digits = 5), nsmall = 5)
                  
                  print(paste0(click_lat, "/", click_lng))
                  
                  #click = input$map_click
                  icons <- awesomeIcons(icon = "whatever",
                                        iconColor = "red",
                                        library = "ion")
                  leafletProxy('map') %>%
                    removeMarker(layerId = "newm") %>% 
                    addAwesomeMarkers(lng = as.numeric(click_lng), lat = as.numeric(click_lat), layerId = "newm", icon = icons)
                  
                  #HTML(paste0("Click on ", p$lng, "/", p$lat))
                  tagList(
                    HTML(paste0("<br><div class=\"panel panel-success\">
                    <div class=\"panel-heading\">
                    <h3 class=\"panel-title\">Click on Map</h3>
                    </div>
                    <div class=\"panel-body\">
                        <dl class=\"dl-horizontal\">
                            <dt>Longitude</dt><dd>", click_lng, "</dd>
                            <dt>Latitude</dt><dd>", click_lat, "</dd>
                            </dl>", 
                                
                                "
                  </div>")), 
                    #uiOutput("uncert_slider"),
                    
                    #uncert_slider----
                    #output$uncert_slider <- renderUI({
                      sliderInput("uncert_slider", "Uncertainty in m:", min = 5, max = 10000, value = 50),
                    actionButton("gbif_rec_save", "Save location for the records", style='font-size:80%'),
                    #})
                    HTML("</div>")
                  )
                  
                })
              })
                
              
              HTML(paste0("<br><div class=\"panel panel-success\">
                  <div class=\"panel-heading\">
                  <h3 class=\"panel-title\">Match Selected</h3>
                  </div>
                  <div class=\"panel-body\">
                     <dl class=\"dl-horizontal\">
                        <dt>Name</dt><dd>", this_row$name, "</dd>
                        <dt>Located in</dt><dd>", this_row$located_at, "</dd>
                        <dt>Uncertainty from<br> polygon area</dt><dd><br>", the_geom$min_bound_radius_m, " m</dd>
                        <dt>Type</dt><dd>", this_row$type, "</dd>
                        <dt>Source</dt><dd>", this_row$source, "</dd>
                        <dt>Score</dt><dd>", this_row$score, "</dd>
                      </dl>
                      ",
                          actionButton("button", "Georeference using point and uncertainty", style='font-size:80%'),
                          "<br><br>",
                          actionButton("button", "Georeference using polygon", style='font-size:80%'),
                          "<br><br>",
                          actionButton("button", "Georeference using both", style='font-size:80%'),
                      "
                </div>
                </div>"))
            })
            
            
            #from https://gis.stackexchange.com/a/252992
            y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Polygon\": \"Name: ', the_geom$name, '<br>Located at: ', the_geom$parent, '<br>Type: ', the_geom$type, '<br>Layer: ', the_geom$layer, '\"},\"geometry\":', the_geom$the_geom, '}')
            y2 <- paste(y, collapse=',')
            x <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
            print(x)
            
            #convexhull
            
            api_convex_url <- "http://dpogis.si.edu/api/0.1/species_range?scientificname="
            
            url_get <- paste0(api_convex_url, species)
            
            #print(url_get)
            
            api_req <- httr::GET(url = URLencode(url_get),
                                 httr::add_headers(
                                   "X-Api-Key" = app_api_key
                                 )
            )
            
            #print(api_req)
            
            convex_geom <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
            
            #from https://gis.stackexchange.com/a/252992
            y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Species\": \"', convex_geom$type, ' of ', species, '\"},\"geometry\":', convex_geom$the_geom, '}')
            y2 <- paste(y, collapse=',')
            spp_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
            print(spp_geom)
            
            spp_geom_bounds <- paste0("[
                              [", convex_geom$ymax, ", ", convex_geom$xmax, "],
                              [", convex_geom$ymin, ", ", convex_geom$xmin, "]
                          ]")
            
            #bounds
            xmin <- convex_geom$xmin
            ymin <- convex_geom$ymin
            xmax <- convex_geom$xmax
            ymax <- convex_geom$ymax
            
            if (the_feature$geom_type == 'polygon'){
              sitelon <- paste0(round(the_feature$longitude, 5), " (centroid)")
              sitelat <- paste0(round(the_feature$latitude, 5), " (centroid)")
            }else{
              sitelon <- the_feature$longitude
              sitelat <- the_feature$latitude
            }
            
            feat_long <- the_feature$longitude
            feat_lat <- the_feature$latitude
            feat_name <- the_feature$name
            feat_country <- the_feature$parent
            feat_layer <- the_feature$layer
            feat_type <- the_feature$type
            
            #bounds
            xmin <- the_geom$xmin
            ymin <- the_geom$ymin
            xmax <- the_geom$xmax
            ymax <- the_geom$ymax
            
            if (xmin == xmax || ymin == ymax){
              xmin <- xmin - 0.05
              xmax <- xmax + 0.05
              ymin <- ymin - 0.05
              ymax <- ymax + 0.05
            }
            
            species_geom_layer <- paste0(convex_geom$type, ' of ', species)
            #species_geom_layer <- "Species Dist"
            
            #polygon uncertainty
            if (the_geom$geom_type == 'polygon'){
              y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Extent\": \"Extent of the polygon for ', feat_name, '\"},\"geometry\":', the_geom$the_geom_extent, '}')
              y2 <- paste(y, collapse=',')
              extent_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
              
              leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
                htmlwidgets::onRender("function(el, x) {
                  L.control.zoom({ position: 'topright' }).addTo(this)
              }") %>%
                addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
                addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
                addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
                addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
                addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) %>%
                addGeoJSONv2(extent_geom, popupProperty='Extent', color = "#E1E134", opacity = 0.2) %>%
                addGeoJSONv2(x, popupProperty='Polygon') %>%
                addAwesomeMarkers(data = cbind(feat_long, feat_lat), popup = paste0('Name: ', feat_name, '<br>Country: ', feat_country, '<br>Lon: ', sitelon, '<br>Lat: ', sitelat, '<br>Type: ', feat_type, '<br>Layer: ', feat_layer)) %>%
                addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
                fitBounds(xmin, ymin, xmax, ymax) %>%
                addScaleBar(position = "bottomleft") %>%
                # Layers control
                addLayersControl(
                  baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
                  overlayGroups = species_geom_layer,
                  options = layersControlOptions(collapsed = FALSE)
                ) %>% 
                addEasyButton(easyButton(
                  icon="fa-search", title="Zoom to Species Range",
                  onClick=JS("function(btn, map){ map.fitBounds([", spp_geom_bounds, "]);}"))
                ) %>% 
                addMeasure(primaryLengthUnit="kilometers", secondaryLengthUnit="miles", primaryAreaUnit = "sqkilometers", position = "topleft")
            }else{
              poly_uncert <- NA
              poly_uncert_lon <- NA
              poly_uncert_lat <- NA
              
              leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
                htmlwidgets::onRender("function(el, x) {
                  L.control.zoom({ position: 'topright' }).addTo(this)
              }") %>%
                addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
                addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
                addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
                addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
                addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) %>%
                addGeoJSONv2(x, popupProperty='Polygon') %>%
                addAwesomeMarkers(data = cbind(feat_long, feat_lat), popup = paste0('Name: ', feat_name, '<br>Country: ', feat_country, '<br>Lon: ', sitelon, '<br>Lat: ', sitelat, '<br>Type: ', feat_type, '<br>Layer: ', feat_layer)) %>%
                addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
                fitBounds(xmin, ymin, xmax, ymax) %>%
                addScaleBar(position = "bottomleft") %>%
                # Layers control
                addLayersControl(
                  baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
                  overlayGroups = species_geom_layer,
                  options = layersControlOptions(collapsed = FALSE)
                ) %>% 
                addEasyButton(easyButton(
                  icon="fa-search", title="Zoom to Species Range",
                  onClick=JS("function(btn, map){ map.fitBounds([", spp_geom_bounds, "]);}"))
                ) %>% 
                addMeasure(primaryLengthUnit="kilometers", secondaryLengthUnit="miles", primaryAreaUnit = "sqkilometers", position = "topleft")
            }
            
            
        }
      }
    }
  })
  
  
  
  
  # footer ----
  output$footer <- renderUI({
    HTML(paste0("<br><br><br><div class=\"footer navbar-fixed-bottom\"><br><p>&nbsp;&nbsp;<a href=\"http://dpo.si.edu\" target = _blank><img src=\"dpologo.jpg\"></a> | ", app_name, ", ver. ", app_ver, " | ", actionLink("help", label = "Help"), " | <a href=\"", github_link, "\" target = _blank>Source code</a></p></div>"))
  })
  
  
  
  #Folder progress----
  observeEvent(input$help, {
    
    api_req <- httr::GET(url = URLencode(api_sources_url),
                         httr::add_headers(
                           "X-Api-Key" = app_api_key
                         )
    )
    
    data_sources <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
    
    data_sources <- data_sources %>% filter(is_online == TRUE) %>% 
      select(-datasource_id, -source_notes, -source_date, -source_refresh, -is_online) %>% 
      mutate("No. of features" = prettyNum(no_features, big.mark = ",", scientific = FALSE)) %>% 
      select(-no_features) %>% 
      mutate("URL" = paste0("<a href=\"", source_url, "\" target=_blank title = \"Open link to source\">", source_url, "</a>")) %>% 
      arrange(source_title) %>% 
      rename("Source" = source_title) %>% 
      select(-source_url)
    
    
    showModal(modalDialog(
      size = "l",
      title = "Help",
      br(),
      p("This application is a demo on an approach to georeference records on a massive scale. The georeferencing clusters records by species that share similar localities. Then, the system will display possible matches based on similar localities in GBIF, as well as locations from other databases."),
      DT::renderDataTable(DT::datatable(data_sources, 
                    escape = FALSE,
                    options = list(searching = FALSE,
                                   ordering = FALSE,
                                   pageLength = 30,
                                   paging = FALSE
                    ),
                    rownames = FALSE,
                    selection = 'none')),
      easyClose = TRUE
    ))
  })
  
  
  
  
  
  # map_header ----
  output$map_header <- renderUI({
    
    query <- parseQueryString(session$clientData$url_search)
    group <- query['group']
    species <- query['species']
    
    if (group == "NULL"){req(FALSE)}
    if (species == "NULL"){req(FALSE)}
    
    if (is.null(input$records_rows_selected)){
      h4("Map of the species distribution:")
    }else{
      h4("Map of the species distribution and candidate matches:")
    }
  })
    
  
}



#Run app----
shinyApp(ui = ui, server = server, onStart = function() {
  cat("Loading\n")
  #Cleanup on closing
  onStop(function() {
    cat("Closing\n")
    #Close db connection
    dbDisconnect(db)
  })
})