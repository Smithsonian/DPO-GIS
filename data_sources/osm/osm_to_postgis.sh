#!/bin/bash
#
#Get the OSM extracts from geofabrik and refreshes the PostGIS database
#

#Delete tables in database
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_line CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_nodes CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_point CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_polygon CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_rels CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_roads CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_ways CASCADE;"


#List of files that geofabrik makes available
osm_files=(africa-latest.osm.pbf antarctica-latest.osm.pbf asia-latest.osm.pbf australia-oceania-latest.osm.pbf central-america-latest.osm.pbf europe-latest.osm.pbf north-america-latest.osm.pbf south-america-latest.osm.pbf)


#Download each file and load it to psql using osm2pgsql
for i in ${!osm_files[@]}; do
    echo ""
    echo "Working on file ${osm_files[$i]}..."
    echo ""
    #Download using wget
    wget https://download.geofabrik.de/${osm_files[$i]}
    if [ "$i" -eq "0" ]; then
        #If it is the first one, dont append
        osm2pgsql --latlong --slim --username gisuser --host localhost --database gis --multi-geometry --verbose ${osm_files[$i]}
    else
        #Append to existing tables
        osm2pgsql --append --latlong --slim --username gisuser --host localhost --database gis --multi-geometry --verbose ${osm_files[$i]}
    fi

done

