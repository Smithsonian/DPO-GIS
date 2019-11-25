
api_convex_url <- "http://dpogis.si.edu/api/0.1/species_range?species="

#convexhull
url_get <- paste0(api_convex_url, species)

print(url_get)

api_req <- httr::GET(url = URLencode(url_get),
                     httr::add_headers(
                       "X-Api-Key" = app_api_key
                     )
)

print(api_req)

convex_geom <<- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)

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

