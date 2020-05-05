#!/bin/bash
#

#Today's date
script_date=$(date +'%Y-%m-%d')

# #Delete last tables
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_line CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_nodes CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_point CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_rels CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_roads CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_polygon CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_ways CASCADE;"


#Move to main database
pg_dump -U gisuser -h localhost -t osm osm | psql -U gisuser -h localhost gis 

#Indices
psql -U gisuser -h localhost gis -c "CREATE INDEX osm_uid_idx ON osm USING BTREE(uid);"
psql -U gisuser -h localhost gis -c "CREATE INDEX osm_name_idx ON osm USING gin (name gin_trgm_ops);"
psql -U gisuser -h localhost gis -c "CREATE INDEX osm_thegeom_idx ON osm USING GIST(the_geom);"
psql -U gisuser -h localhost gis -c "CREATE INDEX osm_thegeomw_idx ON osm USING GIST(the_geom_webmercator);"
psql -U gisuser -h localhost gis -c "CREATE INDEX osm_centroid_idx ON osm USING GIST(centroid);"


#Turn datasource online
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from osm) w WHERE datasource_id = 'osm';"

#Drop from osm
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS osm CASCADE;"

psql -U gisuser -h localhost gis -c "ALTER TABLE osm ADD COLUMN gadm2 text;"

psql -U gisuser -h localhost gis -c "ALTER TABLE osm ADD COLUMN country text;"

psql -U gisuser -h localhost gis -c "WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc,
        max(g.name_0) as name_0
    FROM 
        osm w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE osm g SET gadm2 = d.loc, country = d.name_0 FROM data d WHERE g.uid = d.uid;"


psql -U gisuser -h localhost gis -c "CREATE INDEX osm_gadm2_idx ON osm USING gin (gadm2 gin_trgm_ops);"

psql -U gisuser -h localhost gis -c "CREATE INDEX osm_country_idx ON osm USING BTREE(country);"
