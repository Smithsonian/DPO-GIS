#!/bin/bash
#
#Get the OSM extracts from geofabrik.de and refresh the PostGIS database
# using osm2pgsql (https://wiki.openstreetmap.org/wiki/Osm2pgsql)
#

#Today's date
date +'%m/%d/%Y'
script_date=$(date +'%Y-%m-%d')

#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE source_id = 'osm';"

#Delete tables in database
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_line CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_nodes CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_point CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_polygon CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_rels CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_roads CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE planet_osm_ways CASCADE;"



#Load first, and smallest, download to prepare tables
# antarctica-latest.osm.pbf
echo ""
echo "Working on file antarctica-latest.osm.pbf..."
echo ""
#Download using wget
wget -a osm.log https://download.geofabrik.de/antarctica-latest.osm.pbf
osm2pgsql --latlong --slim --username gisuser --host localhost --database gis --multi-geometry --verbose antarctica-latest.osm.pbf >> osm.log

#Delete file
rm antarctica-latest.osm.pbf


#List of files that geofabrik makes available
osm_files=(central-america-latest.osm.pbf north-america-latest.osm.pbf south-america-latest.osm.pbf africa-latest.osm.pbf asia-latest.osm.pbf australia-oceania-latest.osm.pbf europe-latest.osm.pbf)


#Download each file and load it to psql using osm2pgsql
for i in ${!osm_files[@]}; do
    echo ""
    echo "Working on file ${osm_files[$i]}..."
    echo ""
    #Download using wget
    wget -a osm.log https://download.geofabrik.de/${osm_files[$i]}
    #Append to existing tables
    osm2pgsql --append --latlong --slim --username gisuser --host localhost --database gis --multi-geometry --verbose ${osm_files[$i]} >> osm.log
    rm ${osm_files[$i]}
done


#Set back online and update date
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date' WHERE source_id = 'osm';"
