#!/bin/bash
#
# Download shapefiles from https://www.protectedplanet.net/
#
# wget -O wdpa.zip https://www.protectedplanet.net/downloads/WDPA_Aug2019?type=shapefile 
#

#Today's date
script_date=$(date +'%Y-%m-%d')

unzip wdpa.zip

#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'wdpa_polygons';"
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'wdpa_points';"


#Store old tables
echo "Backing up wdpa_points..."
echo ""
pg_dump -h localhost -U gisuser -t wdpa_points gis > wdpa_points_$script_date.dump.sql
gzip wdpa_points_$script_date.dump.sql &

echo "Backing up wdpa_polygons..."
echo ""
pg_dump -h localhost -U gisuser -t wdpa_polygons gis > wdpa_polygons_$script_date.dump.sql
gzip wdpa_polygons_$script_date.dump.sql &

psql -U gisuser -h localhost gis -c "DROP TABLE wdpa_points CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE wdpa_polygons CASCADE;"

#Convert shapefiles to PostGIS format
pointshp=`ls WDPA*shapefile-points.shp`
shp2pgsql -g the_geom -D $pointshp wdpa_points > wdpa_points.sql
polyshp=`ls WDPA*shapefile-polygons.shp`
shp2pgsql -g the_geom -D $polyshp wdpa_polygons > wdpa_polygons.sql

#Load PostGIS files to database
psql -U gisuser -h localhost gis < wdpa_points.sql
psql -U gisuser -h localhost gis < wdpa_polygons.sql

#indices and new columns
psql -U gisuser -h localhost gis < wdpa_post.sql

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from wdpa_polygons) w WHERE datasource_id = 'wdpa_polygons';"
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from wdpa_points) w WHERE datasource_id = 'wdpa_points';"


UPDATE data_sources SET no_features = w.no_feats FROM (select count(*) as no_feats from wikidata_names) w WHERE datasource_id = 'wikidata'


#del files
rm wdpa_points.sql
rm wdpa_polygons.sql
rm WDPA_*-points.*
rm WDPA_*-polygons.*
rm wdpa.zip
rm -r Res*
rm -r Recursos*
