#!/bin/bash
#
#Get the OSM extracts from geofabrik.de and refresh the PostGIS database
# using osm2pgsql (https://wiki.openstreetmap.org/wiki/Osm2pgsql)
# 


#Today's date
script_date=$(date +'%Y-%m-%d')


#Delete unused tables
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_line CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_nodes CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_point CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_rels CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_roads CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_polygon CASCADE;"

#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'osm';"

#Drop indices before bulk loading
psql -U gisuser -h localhost osm -c "DROP INDEX IF EXISTS osm_name_idx;"
psql -U gisuser -h localhost osm -c "DROP INDEX IF EXISTS osm_thegeom_idx;"
psql -U gisuser -h localhost osm -c "DROP INDEX IF EXISTS osm_thegeomw_idx;"
psql -U gisuser -h localhost osm -c "DROP INDEX IF EXISTS osm_centroid_idx;"

#Empty table
psql -U gisuser -h localhost osm -c "TRUNCATE osm;"
psql -U gisuser -h localhost osm -c "VACUUM osm;"


#Columns to get the type
cols=(amenity barrier bridge building embankment harbour highway historic landuse leisure lock man_made military motorcar natural office place public_transport railway religion service shop sport surface toll tourism tunnel water waterway wetland wood)

#List of files that geofabrik makes available
osm_files=(north-america-latest.osm.pbf antarctica-latest.osm.pbf central-america-latest.osm.pbf south-america-latest.osm.pbf africa-latest.osm.pbf asia-latest.osm.pbf australia-oceania-latest.osm.pbf europe-latest.osm.pbf)

#Download each file and load it to psql using osm2pgsql
for i in ${!osm_files[@]}; do
    echo ""
    echo "Working on file ${osm_files[$i]}..."
    echo ""
    #Download using wget
    wget -c -a osm.log https://download.geofabrik.de/${osm_files[$i]}
    #Append to existing tables
    osm2pgsql --latlong --username gisuser --host localhost --database osm -C 22000 --create --number-processes 8 --multi-geometry --verbose --flat-nodes /mnt/fastdisk/tmp/mycache.bin ${osm_files[$i]} >> osm.log
    #rm ${osm_files[$i]}


    #Execute for each column
    for i in ${!cols[@]}; do
        echo "Working on column ${cols[$i]}..."
        psql -U gisuser -h localhost osm -c "CREATE INDEX osmplanet_${cols[$i]}_idx ON planet_osm_polygon USING BTREE(\"${cols[$i]}\") WHERE \"${cols[$i]}\" IS NOT NULL;"
        psql -U gisuser -h localhost osm -c "with data as ( 
                                                select 
                                                    osm_id as osm_id, 
                                                    name,
                                                    \"${cols[$i]}\",
                                                    way
                                                from 
                                                    planet_osm_polygon 
                                                where 
                                                    \"${cols[$i]}\" IS NOT NULL
                                            )
                                        INSERT INTO osm 
                                            (source_id, name, type, attributes, centroid, the_geom, the_geom_webmercator) 
                                            select 
                                                d.osm_id::text, 
                                                d.name, 
                                                coalesce(replace(\"${cols[$i]}\", 'yes', NULL), \"${cols[$i]}\"),
                                                tags::hstore,
                                                st_centroid(st_multi(way)),
                                                st_multi(way) as the_geom,
                                                st_transform(st_multi(way), 3857) as the_geom_webmercator
                                            from 
                                                data d LEFT JOIN 
                                                    planet_osm_ways r ON 
                                                    (d.osm_id = r.id);"
        done
        #psql -U gisuser -h localhost osm -c "DROP INDEX osmplanet_${cols[$i]}_idx;"
    done
done




#Recreate indices
psql -U gisuser -h localhost osm -c "CREATE INDEX osm_name_idx ON osm USING BTREE(name);"
psql -U gisuser -h localhost osm -c "CREATE INDEX osm_thegeom_idx ON osm USING GIST(the_geom);"
psql -U gisuser -h localhost osm -c "CREATE INDEX osm_thegeomw_idx ON osm USING GIST(the_geom_webmercator);"
psql -U gisuser -h localhost osm -c "CREATE INDEX osm_centroid_idx ON osm USING GIST(centroid);"

#Move table between dbs
#####
#####

#Turn datasource online
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date' WHERE datasource_id = 'osm';"

#Delete last tables
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_line CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_nodes CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_point CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_rels CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_roads CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_polygon CASCADE;"

