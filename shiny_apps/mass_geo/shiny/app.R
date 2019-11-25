library(shiny)
library(leaflet)
library(leaflet.extras)
library(jsonlite)
library(futile.logger)
library(collexScrubber)
library(countrycode)
library(parallel)
library(RPostgres)
library(shinyWidgets)
library(rgdal)
library(shinycssloaders)
library(dplyr)


#Settings----
app_name <- "Mass Georeferencing GBIF Data Service - DPO"
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
                    h2("Mass Georeferencing Service", id = "title_main"),
                    #uiOutput("map_head"),
                    uiOutput("main"),
                    uiOutput("maingroup"),
                    uiOutput("species"),
                    hr(),
                    shinycssloaders::withSpinner(DT::dataTableOutput("records"))
            ),
            column(width = 3,
                   uiOutput("record_selected"),
                   uiOutput("res1"),
                   uiOutput("candidatematches_h"),
                   DT::dataTableOutput("candidatematches")
            ),
            column(width = 6,
                   #uiOutput("candidate_matches_info")
                   leafletOutput("map", width = "100%", height = "600px"),
                   fluidRow(
                     column(width = 6,
                            uiOutput("candidate_matches_info_h")
                     ),
                     column(width = 6,
                            uiOutput("marker_info")
                     )
                   )
            )
          ),
               
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
    query <- parseQueryString(session$clientData$url_search)
    group <- query['group']
    
    if (group == "NULL"){
      shinyWidgets::panel(
        p("To use this app, select a group to see the list of species available for georeferencing."),
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
                  <h4>", group, ":</h4>"))
    }else{
      HTML(paste0("<p>Select group:
                  <ul>
                    <li><a href=\"./?group=All\">All</a></li>
                    <li><a href=\"./?group=Plants\">Plants</a></li>
                    <li><a href=\"./?group=Birds\">Birds</a></li>
                    <li><a href=\"./?group=Mammals\">Mammals</a></li>
                    <li><a href=\"./?group=Reptiles\">Reptiles</a></li>
                    <li><a href=\"./?group=Amphibians\">Amphibians</a></li>
                </ul></p>"))
    }
  })
  
  
  
  # species ----
  output$species <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    group <- query['group']

    if (group == "NULL"){req(FALSE)}
    
    if (group == "All"){
      group_query <- ""
    }else if (group == "Plants"){
      group_query <- "phylum = 'Tracheophyta' AND "
    }else if (group == "Birds"){
      group_query <- "class = 'Aves' AND "
    }else if (group == "Mammals"){
      group_query <- "class = 'Mammalia' AND "
    }else if (group == "Reptiles"){
      group_query <- "class = 'Reptilia' AND "
    }else if (group == "Amphibians"){
      group_query <- "class = 'Amphibia' AND "
    }
    
    species_query <- paste0("SELECT species FROM gbif_si WHERE ", group_query, " species IN (SELECT DISTINCT species FROM gbif_si_matches) ORDER BY random() LIMIT 100")
    species <- dbGetQuery(db, species_query)
    
    tagList(
      selectInput("species", "Select a species:", species),
      actionButton("submit_species", "Submit")
    )
  })
  
  
    
  # submit_species react ----
  observeEvent(input$submit_species, {
    
    query <- parseQueryString(session$clientData$url_search)
    group <- query['group']
    
    output$main <- renderUI({
      HTML(paste0("<script>$(location).attr('href', './?group=", group, "&species=", input$species, "')</script>"))
    })
    
  })
    
    #records----
    output$records <- DT::renderDataTable({
      
      query <- parseQueryString(session$clientData$url_search)
      species <- query['species']
      
      req(species != "NULL")
      
      records_query <- paste0("SELECT scientificname, species, max(gbifid)::text as gbifid, max(occurrenceid) as occurrenceid, stateprovince, countrycode, locality, count(*)::int as no_records FROM gbif_si WHERE species = '", species, "' AND locality != '' AND decimallatitude IS NULL AND decimallongitude IS NULL AND gbifid IN (SELECT gbifid from gbif_si_matches WHERE species = '", species, "') GROUP BY scientificname, species, countrycode, stateprovince, locality ORDER BY no_records DESC LIMIT 100")
      records <<- dbGetQuery(db, records_query)
      
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
                                 pageLength = 15,
                                 paging = TRUE,
                                 language = list(zeroRecords = "No matches found"),
                                 scrollY = "400px"
                  ),
                  rownames = FALSE,
                  selection = 'single',
                  caption = "Select a locality to show candidate matches")
    })

  
  
  
  #record_selected----
  output$record_selected <- renderUI({
    req(input$records_rows_selected)
    
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
          <dt>gbifid</dt><dd>", this_row$gbifid, "</dd>
          <dt>Species</dt><dd>", this_row$species, "</dd>
          <dt>Occurrence ID</dt><dd><a href=\"", this_row$occurrenceid, "\" target = _blank>", this_row$occurrenceid, "</a></dd>
          <dt>Locality</dt><dd>", this_row$locality, "</dd>
          <dt>Located at</dt><dd>", located_at, "</dd>
          <dt>No. of records</dt><dd>", this_row$no_records, "</dd>
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
      
      gbifid <- records[input$records_rows_selected,]$gbifid
      species <- records[input$records_rows_selected,]$species
      
      matches_query <- paste0("SELECT
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  m.name_0 as name,
                                  g.located_at
                                FROM 
                                  gbif_si_matches g,
                                  gadm0 m
                                WHERE 
                                  g.gbifid = '", gbifid, "' AND
                                  g.match::uuid = m.uid AND
                                  g.source = 'gadm0'
                                
                                UNION
                                
                                SELECT
                                  g.gbifid,
                                  g.source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  m.name_1 as name,
                                  g.located_at
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
                                  m.name_2 as name,
                                  g.located_at
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
                                  m.name_3 as name,
                                  g.located_at
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
                                  m.name_4 as name,
                                  g.located_at
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
                                  m.name_5 as name,
                                  g.located_at
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
                                  m.name as name,
                                  g.located_at
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
                                  m.name as name,
                                  g.located_at
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
                                  max(g.source) as source,
                                  g.score,
                                  g.no_records,
                                  g.match,
                                  m.locality as name,
                                  g.located_at
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
                                  g.located_at
                            ORDER BY score DESC, no_records DESC")
      cat(matches_query)
      results <- dbGetQuery(db, matches_query)
      
       if (dim(results)[1] == 0){

         output$res1 <- renderUI({
           tagList(
             tags$br(),tags$br(),
             tags$em("No results found.")
           )
         })

       }else{

         results <<- results %>% 
           dplyr::arrange(match(source, c("gbif.species", "gbif.genus", "wdpa_polygons", "wdpa_points", "gadm5", "gadm4", "gadm3", "gadm2", "gadm1", "gadm0"))) %>%
           dplyr::arrange(dplyr::desc(score)) 
         
         output$res1 <- renderUI({

         })
       }
       
       #if (dim(results)[1] > 0){
         results <- results %>% dplyr::select(-gbifid) %>% 
           dplyr::select(-match) %>% 
           dplyr::select(-no_records) %>% 
           dplyr::select(-source)
         #Reorder cols
         results <- results[c("name", "located_at", "score")]
         names(results) <- c("Locality", "Located at", "Score")
       #}
       
       if (dim(results)[1]==1){
         DT::datatable(results,
                       escape = FALSE,
                       options = list(searching = FALSE,
                                      ordering = TRUE,
                                      pageLength = 100,
                                      paging = FALSE,
                                      language = list(zeroRecords = "No matches found"),
                                      scrollY = "380px"
                       ),
                       rownames = FALSE,
                       selection = list(mode = 'single', selected = c(1)),
                       caption = "Select a locality to show on the map")
       }else{
         DT::datatable(results,
                       escape = FALSE,
                       options = list(searching = FALSE,
                                      ordering = TRUE,
                                      pageLength = 100,
                                      paging = FALSE,
                                      language = list(zeroRecords = "No matches found"),
                                      scrollY = "380px"
                       ),
                       rownames = FALSE,
                       selection = list(mode = 'single'),
                       caption = "Select a locality to show on the map")
       }
     }
  })

  
  
  #map----
  output$map <- renderLeaflet({
    
    query <- parseQueryString(session$clientData$url_search)
    species <<- query['species']
    print(species)
    if (species == "NULL"){
      print("SPP FALSE")
      req(FALSE)
    }
    
    #req(input$records_rows_selected)
    #print(req(input$records_rows_selected))
    if (is.null(input$candidatematches_rows_selected)){
      #Only species dist----
      source("species_range.R")
      
      if (xmin == xmax || ymin == ymax){
        xmin <- xmin - 0.05
        xmax <- xmax + 0.05
        ymin <- ymin - 0.05
        ymax <- ymax + 0.05
      }
      
      leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
        htmlwidgets::onRender("function(el, x) {
                L.control.zoom({ position: 'topright' }).addTo(this)
            }") %>%
        addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
        addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
        addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
        addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
        addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
        addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = "Species Range") %>%
        addScaleBar(position = "bottomleft") %>%
        fitBounds(xmin, ymin, xmax, ymax) %>%
        addLayersControl(
          baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
          overlayGroups = c("Species Range"),
          options = layersControlOptions(collapsed = FALSE)
        )
    }else{
      this_row <- results[input$candidatematches_rows_selected, ]
      
      geom_layer <- this_row$source
      geom_uid <- this_row$match
      geom_name <- this_row$name
      geom_located_at <- this_row$located_at
      gbifid <- this_row$match
      
      #if geom from GBIF----
      if (geom_layer == "gbif.species" || geom_layer == "gbif.genus"){
        
        match_query <- paste0("SELECT 
                              *
                          FROM 
                              gbif
                          WHERE 
                              species = '", species, "' AND 
                              gbifid = '", gbifid, "'")
        cat(match_query)
        the_feature <- dbGetQuery(db, match_query)
        
        #candidate_matches_info_h----
        output$candidate_matches_info_h <- renderUI({
          
          # observeEvent(input$map_click, { 
          #   p <- input$map_click
          #   print(p)
          #   output$marker_info <- renderUI({
          #     addCircleMarkers(map = "map", lng = p$lng, lat = p$lat, layerId = "custom")
          #     HTML(paste0("Click on ", p$lng, "/", p$lat))
          #   })
          # })
          
          HTML(paste0("<br><div class=\"panel panel-success\">
                <div class=\"panel-heading\">
                <h3 class=\"panel-title\">Match Selected</h3>
                </div>
                <div class=\"panel-body\">
                    <dl class=\"dl-horizontal\">
                        <dt>Name</dt><dd>", this_row$name, "</dd>
                        <dt>Located in</dt><dd>", this_row$located_at, "</dd>
                        <dt>Source</dt><dd><a href=\"https://www.gbif.org/occurrence/", the_feature$gbifid, "\" target=_blank>GBIF record (", the_feature$gbifid, ")</a></dd>
                        <dt>Score</dt><dd>", this_row$score, "</dd>
                        <dt>No. of records</dt><dd>", this_row$no_records, "</dd>
                        <dt>Record issues</dt><dd>", the_feature$issue, "</dd>
                      </dl>
              </div>
              </div>"))
        })
        
        #convexhull
        source("species_range.R")
        
        x <- ""
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
        
        leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
          htmlwidgets::onRender("function(el, x) {
              L.control.zoom({ position: 'topright' }).addTo(this)
          }") %>%
          addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
          addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
          addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
          addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
          addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = "Species Range") %>%
          addAwesomeMarkers(data = cbind(feat_long, feat_lat), popup = paste0('Name: ', feat_name, '<br>Country: ', feat_country, '<br>Lon: ', sitelon, '<br>Lat: ', sitelat, '<br>Layer: ', feat_layer, '<br>Type: ', feat_type)) %>%
          addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
          fitBounds(xmin, ymin, xmax, ymax) %>%
          addScaleBar(position = "bottomleft") %>%
          # Layers control
          addLayersControl(
            baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
            overlayGroups = c("Species Range"),
            options = layersControlOptions(collapsed = FALSE)
          ) %>% 
          addEasyButton(easyButton(
            icon="fa-search", title="Zoom to Species Range",
            onClick=JS("function(btn, map){ map.fitBounds([", spp_geom_bounds, "]);}")))
        
      }else{
        #If geom from other----
        
        #candidate_matches_info_h----
        output$candidate_matches_info_h <- renderUI({

          # observeEvent(input$map_click, { 
          #   p <- input$map_click
          #   print(p)
          #   output$marker_info <- renderUI({
          #     HTML(paste0("Click on ", p$lng, "/", p$lat))
          #   })
          # })
          
          HTML(paste0("<br><div class=\"panel panel-success\">
              <div class=\"panel-heading\">
              <h3 class=\"panel-title\">Match Selected</h3>
              </div>
              <div class=\"panel-body\">
                 <dl class=\"dl-horizontal\">
                    <dt>Name</dt><dd>", this_row$name, "</dd>
                    <dt>Located in</dt><dd>", this_row$located_at, "</dd>
                    <dt>Source</dt><dd>", this_row$source, "</dd>
                    <dt>Score</dt><dd>", this_row$score, "</dd>
                  </dl>
            </div>
            </div>"))
        })
        
        #Feature
        url_get <- paste0(api_detail_url, geom_uid, "&layer=", geom_layer)
        
        print(url_get)
        
        api_req <- httr::GET(url = URLencode(url_get),
                             httr::add_headers(
                               "X-Api-Key" = app_api_key
                             )
        )
        
        print(api_req)
        
        the_feature <<- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
        
        #Geometry
        url_get <- paste0(api_geom_url, geom_uid, "&layer=", geom_layer)
        
        print(url_get)
        
        api_req <- httr::GET(url = URLencode(url_get),
                             httr::add_headers(
                               "X-Api-Key" = app_api_key
                             )
        )
        
        print(api_req)
        
        the_geom <<- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
        
        #from https://gis.stackexchange.com/a/252992
        y <- paste0('{\"type\":\"Feature\",\"properties\":{},\"geometry\":', the_geom$the_geom, '}')
        y2 <- paste(y, collapse=',')
        x <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
        print(x)
        
        #convexhull
        source("species_range.R")
        
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
        
        leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
          htmlwidgets::onRender("function(el, x) {
              L.control.zoom({ position: 'topright' }).addTo(this)
          }") %>%
          addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
          addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
          addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
          addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
          addGeoJSON(x) %>%
          addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = "Species Range") %>%
          addAwesomeMarkers(data = cbind(feat_long, feat_lat), popup = paste0('Name: ', feat_name, '<br>Country: ', feat_country, '<br>Lon: ', sitelon, '<br>Lat: ', sitelat, '<br>Layer: ', feat_layer, '<br>Type: ', feat_type)) %>%
          addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
          fitBounds(xmin, ymin, xmax, ymax) %>%
          addScaleBar(position = "bottomleft") %>%
          # Layers control
          addLayersControl(
            baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
            overlayGroups = c("Species Range"),
            options = layersControlOptions(collapsed = FALSE)
          ) %>% 
          addEasyButton(easyButton(
            icon="fa-search", title="Zoom to Species Range",
            onClick=JS("function(btn, map){ map.fitBounds([", spp_geom_bounds, "]);}")))
      }
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