#!/bin/bash
#
#Get the OSM extracts from geofabrik.de and refresh the PostGIS database
# using osm2pgsql (https://wiki.openstreetmap.org/wiki/Osm2pgsql)
# 


#Today's date
script_date=$(date +'%Y-%m-%d')



#Recreate indices
# psql -U gisuser -h localhost osm -c "CREATE INDEX osm_name_idx ON osm USING BTREE(name);"
# psql -U gisuser -h localhost osm -c "CREATE INDEX osm_thegeom_idx ON osm USING GIST(the_geom);"
# psql -U gisuser -h localhost osm -c "CREATE INDEX osm_thegeomw_idx ON osm USING GIST(the_geom_webmercator);"
# psql -U gisuser -h localhost osm -c "CREATE INDEX osm_centroid_idx ON osm USING GIST(centroid);"

#Move table between dbs
#####
#####

#Turn datasource online
# psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date' WHERE datasource_id = 'osm';"

# #Delete last tables
# psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_line CASCADE;"
# psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_nodes CASCADE;"
# psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_point CASCADE;"
# psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_rels CASCADE;"
# psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_roads CASCADE;"
# psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_polygon CASCADE;"
