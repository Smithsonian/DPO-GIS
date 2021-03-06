

query_api <- function(url, apikey){
  api_req <- httr::GET(url = URLencode(url), httr::add_headers("X-Api-Key" = apikey))
  results <- httr::content(api_req, as = "text", encoding = "UTF-8")
  return(results)
}
  


countrycheck <- function(id, latitude, longitude, country, countryformat = "iso2c", apikey){
  #Check if the coordinates match the country
  # country is in the format countryformat, using ?codelist from package countrycode
  # latitude and longitude are in decimal degrees
  library(httr)
  set_config(config(ssl_verifypeer = 0L))
  
  if (is.na(latitude) || is.na(longitude) || is.na(country)){
    country_match <- NA
    latitude_match <- NA
    longitude_match <- NA
    note <- NA
  }else if (latitude == "" || longitude == "" || country == ""){
    country_match <- NA
    latitude_match <- NA
    longitude_match <- NA
    note <- NA
  }else if (latitude == "0" && longitude == "0"){
    country_match <- NA
    latitude_match <- NA
    longitude_match <- NA
    note <- "Both latitude and longitude are zero. This is, most probably, an error."
  }else if ((latitude == "90" || latitude == "-90") && (longitude == "180" || longitude == "-180")){
    country_match <- NA
    latitude_match <- NA
    longitude_match <- NA
    note <- "Latitude and longitude are on the edge of the WGS84 datum. This is, most probably, an error."
  }else if (as.numeric(latitude) > 90 || as.numeric(latitude) < -90){
    country_match <- NA
    latitude_match <- NA
    longitude_match <- NA
    note <- "Latitude is outside the valid range of the WGS84 datum."
  }else if (as.numeric(longitude) > 180 || as.numeric(longitude) < -180){
    country_match <- NA
    latitude_match <- NA
    longitude_match <- NA
    note <- "Longitude is outside the valid range of the WGS84 datum."
  }else{
    lng_dd <- longitude
    lat_dd <- latitude
    if (countryformat != "iso3c"){
      country_check <- countrycode(country, origin = countryformat, destination = "iso3c")
    }
    
    api_req <- httr::POST(URLencode(paste0(api_url, "api/intersection")),
                          body = list(lat = lat_dd,
                                      lng = lng_dd,
                                      layer = 'gadm'),
                          httr::add_headers(
                            "X-Api-Key" = apikey
                          ),
                          encode = "form"
    )
    
    if (api_req$status_code != 200){
      error_msg = fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"))
      stop(error_msg['error'])
    }else{
      country_query <- as.data.frame(fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8")), stringsAsFactors = FALSE)
    }

    cntr_match <- country_query[country_query$intersection.layer == "gadm0",]
    
    if (dim(cntr_match)[1] > 0){
      country_match <- countrycode(cntr_match$intersection.name, origin = "country.name", destination = "iso3c") 
    }else{
      country_match <- NA
    }
    
    if (!is.na(country_match)){
      if (country_check == country_match){
        latitude_match <- lat_dd
        longitude_match <- lng_dd
        note <- 'Coordinates match'
      }else{
        country_match <- NA
      }
    }
    
    #Check for latitude sign
    if (!exists("note")){
      api_req <- httr::POST(URLencode(paste0(api_url, "api/intersection")),
                            body = list(lat = lat_dd,
                                        lng = lng_dd,
                                        layer = 'gadm'),
                            httr::add_headers(
                              "X-Api-Key" = apikey
                            ),
                            encode = "form"
      )
      
      if (api_req$status_code != 200){
        error_msg = fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"))
        stop(error_msg['error'])
      }else{
        country_query <- as.data.frame(fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8")), stringsAsFactors = FALSE)
      }
      
      cntr_match <- country_query[country_query$intersection.layer == "gadm0",]
      
      if (dim(cntr_match)[1] > 0){
        country_match <- countrycode(cntr_match$intersection.name, origin = "country.name", destination = "iso3c") 
        if (!is.na(country_match)){
          if (country_check == country_match){
            note <- paste0('Latitude has the wrong sign, should be ', -lat_dd)
            latitude_match <- -lat_dd
            longitude_match <- lng_dd
          }
        }
      }
      
      #Check for longitude sign
      if (!exists("note")){
        api_req <- httr::POST(URLencode(paste0(api_url, "api/intersection")),
                              body = list(lat = lat_dd,
                                          lng = lng_dd,
                                          layer = 'gadm'),
                              httr::add_headers(
                                "X-Api-Key" = apikey
                              ),
                              encode = "form"
        )
        
        if (api_req$status_code != 200){
          error_msg = fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"))
          stop(error_msg['error'])
        }else{
          country_query <- as.data.frame(fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8")), stringsAsFactors = FALSE)
        }
        
        cntr_match <- country_query[country_query$intersection.layer == "gadm0",]
        
        if (dim(cntr_match)[1] > 0){
          country_match <- countrycode(cntr_match$intersection.name, origin = "country.name", destination = "iso3c") 
          if (!is.na(country_match)){
            if (country_check == country_match){
              note <- paste0('Longitude has the wrong sign, should be ', -lng_dd)
              latitude_match <- lat_dd
              longitude_match <- -lng_dd
            }
          }
        }
      }
      
      #Check for latitude and longitude sign
      if (!exists("note")){
        api_req <- httr::POST(URLencode(paste0(api_url, "api/intersection")),
                              body = list(lat = lat_dd,
                                          lng = lng_dd,
                                          layer = 'gadm'),
                              httr::add_headers(
                                "X-Api-Key" = apikey
                              ),
                              encode = "form"
        )
        
        if (api_req$status_code != 200){
          error_msg = fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"))
          stop(error_msg['error'])
        }else{
          country_query <- as.data.frame(fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8")), stringsAsFactors = FALSE)
        }
        cntr_match <- country_query[country_query$intersection.layer == "gadm0",]
        
        if (dim(cntr_match)[1] > 0){
          country_match <- countrycode(cntr_match$intersection.name, origin = "country.name", destination = "iso3c") 
          if (!is.na(country_match)){
            if (country_check == country_match){
              note <- paste0('Latitude and longitude have the wrong sign, Latitude should be ', -lat_dd, ' and Longitude should be ', -lng_dd)
              latitude_match <- -lat_dd
              longitude_match <- -lng_dd
            }
          }
        }
      }
      
      
      #Check nearest country
      if (!exists("note")){
        
        api_req <- httr::POST(URLencode(paste0(api_url, "api/intersection")),
                              body = list(lat = lat_dd,
                                          lng = lng_dd,
                                          radius = 25000,
                                          layer = 'gadm'),
                              httr::add_headers(
                                "X-Api-Key" = apikey
                              ),
                              encode = "form"
        )
        
        if (api_req$status_code != 200){
          error_msg = fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"))
          stop(error_msg['error'])
        }else{
          country_query <- as.data.frame(fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8")), stringsAsFactors = FALSE)
        }
        
        cntr_match <- country_query[country_query$intersection.layer == "gadm0",]
        
        if (dim(cntr_match)[1] > 0){
          country_match <- countrycode(cntr_match$intersection.name, origin = "country.name", destination = "iso3c") 
          
          w <- which(countrycode(cntr_match$intersection.name, origin = "country.name", destination = "iso3c") == country_check)
          
          country_match <- countrycode(cntr_match$intersection.name[w], origin = "country.name", destination = "iso3c")
          
          if (length(country_match) > 0){
            if (country_check == country_match){
              note <- paste0('Spatial error, distance from ', country, ': ', round(country_query$results.distance_km[w], 2), 'km')
              latitude_match <- lat_dd
              longitude_match <- lng_dd
            }
          }
        }
      }
      
      
      #Else, report which country the coords match
      if (!exists("note")){
        api_req <- httr::POST(URLencode(paste0(api_url, "api/intersection")),
                              body = list(lat = lat_dd,
                                          lng = lng_dd,
                                          layer = 'gadm'),
                              httr::add_headers(
                                "X-Api-Key" = apikey
                              ),
                              encode = "form"
        )
        
        
        if (api_req$status_code != 200){
          error_msg = fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"))
          stop(error_msg['error'])
        }else{
          country_query <- as.data.frame(fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8")), stringsAsFactors = FALSE)
        }
        
        cntr_match <- country_query[country_query$intersection.layer == "gadm0",]
        
        if (dim(cntr_match)[1] > 0){
          country_match <- countrycode(cntr_match$intersection.name, origin = "country.name", destination = "iso3c") 
          latitude_match <- lat_dd
          longitude_match <- lng_dd
          note <- paste0('Coordinates do not match ', country, ', they match ', country_match, ' (', countrycode(country_match, origin = "iso3c", destination = "country.name"), ')')
        }else{
          #nothing found
          country_match <- NA
          latitude_match <- NA
          longitude_match <- NA
          note <- paste('Coordinates do not match ', country)
        }
      }
    }
  }
  
  if (!is.na(country_match)){
    country_match = countrycode(country_match, origin = "iso3c", destination = "country.name")
  }else{
    country_match = NA
  }
  
  #Check if coord values have too many decimal places
  #longitude
  if (!is.na(longitude)){
    if (length(strsplit(as.character(longitude), "\\.")[[1]]) == 2){
      long_length <- nchar(strsplit(as.character(longitude), "\\.")[[1]][2])
      if (long_length > 5){
        lng_note <- paste0("The longitude value has more decimal places (", long_length, ") than usual (5), this may be due to a conversion that did not keep the appropriate precision.")
        if (!exists("note")){
          note <- lng_note
        }else{
          note <- paste0(note, "; ", lng_note)
        }
      }
    }
  }
  #latitude
  if (!is.na(latitude)){
    if (length(strsplit(as.character(latitude), "\\.")[[1]]) == 2){
      lat_length <- nchar(strsplit(as.character(latitude), "\\.")[[1]][2])
      if (lat_length > 5){
        lat_note <- paste0("The latitude value has more decimal places (", lat_length, ") than usual (5), this may be due to a conversion that did not keep the appropriate precision.")
        if (!exists("note")){
          note <- lat_note
        }else{
          note <- paste0(note, "; ", lat_note)
        }
      }
    }
  }
  
  return(list(id = id, decimallatitude = latitude, decimallongitude = longitude, country = country, country_match = country_match, latitude_match = latitude_match, longitude_match = longitude_match, note = note))
}







wikidata_geo <- function(country, stateprovince, instance = NA){
  
  countries_query <- "SELECT ?item ?itemLabel 
                        WHERE {
                          ?item wdt:P31 wd:Q6256.
                          SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }
                        }"
  
  countries_wikidata <- WikidataQueryServiceR::query_wikidata(countries_query)
  
  country_code <- str_replace(countries_wikidata[countries_wikidata$itemLabel == "United States of America",]$item, "http://www.wikidata.org/entity/", "")
  
  
    
  limit <- 10
  
  if (instance == "river"){
    instance_of_query <- "?item wdt:P31 wd:Q4022"
  }else{
    instance_of_query <- ""
  }
  
  query <- paste0("select ?item ?coords_ ?lon ?lat ?itemLabel where {
            ?item wdt:P17 wd:", country_code, " .
            ?item p:P625/psv:P625 ?coords .
            ?coords wikibase:geoLatitude ?lat ;
            wikibase:geoLongitude ?lon .
            
            SERVICE wikibase:label { bd:serviceParam wikibase:language
            \"[AUTO_LANGUAGE],en\". }",
            instance_of_query,
            "} limit ", limit)
  
  locations <- WikidataQueryServiceR::query_wikidata(query)
  
}




read_inputfile <- function(filename, file_location){
  #Read Upload
  ext_to_check <- stringr::str_split(filename, '[.]')[[1]]
  ext_to_check <- ext_to_check[length(ext_to_check)]
  
  if (ext_to_check == "csv"){
    #Read CSV file----
    input_data <- read.csv(file_location, header = TRUE, stringsAsFactors = FALSE, colClasses = "character")
    
    # Process any error messages
    if (class(input_data) == "try-error"){
      stop("The file does not appear to be a valid. Please reload the application and try again.")
    }
  }else if (ext_to_check == "xlsx"){
    #Read XLSX file----
    options("openxlsx.numFmt" = "TEXT")
    
    try(input_data <- openxlsx::read.xlsx(file_location, sheet = 1, check.names = TRUE), silent = TRUE)
    
    if (exists("input_data") == FALSE){
      stop("The file does not appear to be a valid. Please reload the application and try again.")
    }
  }else{
    stop("The file must be a valid CSV or Excel file and have the extension .csv or .xlsx. Please reload the application and try again.")
  }
  
  #Check if required input columns are present
  if(!"country" %in% colnames(input_data)){
    stop("The file must include the column 'country'. Please reload the application and try again.")
  }
  if(!"decimallatitude" %in% colnames(input_data)){
    stop("The file must include the column 'decimallatitude'. Please reload the application and try again.")
  }
  if(!"decimallongitude" %in% colnames(input_data)){
    stop("The file must include the column 'decimallongitude'. Please reload the application and try again.")
  }
  if(!"id" %in% colnames(input_data)){
    stop("The file must include the column 'id'. Please reload the application and try again.")
  }
  
  return(input_data)
}
