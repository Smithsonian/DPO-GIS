#!/bin/bash
# 
# Convert GADM shapefiles to Postgres and write them to the database
# 
#

#level0
psql -U gisuser -h localhost -p 5432 gis -c "ALTER TABLE gadm0 RENAME TO gadm0_old;"
shp2pgsql -g the_geom -D gadm36_0.shp gadm0 > gadm0.sql
psql -U gisuser -h localhost -p 5432 gis < gadm0.sql
rm gadm0.sql

#level1
psql -U gisuser -h localhost -p 5432 gis -c "ALTER TABLE gadm1 RENAME TO gadm1_old;"
shp2pgsql -g the_geom -D gadm36_1.shp gadm1 > gadm1.sql
psql -U gisuser -h localhost -p 5432 gis < gadm1.sql
rm gadm1.sql

#level2
psql -U gisuser -h localhost -p 5432 gis -c "ALTER TABLE gadm2 RENAME TO gadm2_old;"
shp2pgsql -g the_geom -D gadm36_2.shp gadm2 > gadm2.sql
psql -U gisuser -h localhost -p 5432 gis < gadm2.sql
rm gadm2.sql

#level3
psql -U gisuser -h localhost -p 5432 gis -c "ALTER TABLE gadm3 RENAME TO gadm3_old;"
shp2pgsql -g the_geom -D gadm36_3.shp gadm3 > gadm3.sql
psql -U gisuser -h localhost -p 5432 gis < gadm3.sql
rm gadm3.sql

#level4
psql -U gisuser -h localhost -p 5432 gis -c "ALTER TABLE gadm4 RENAME TO gadm4_old;"
shp2pgsql -g the_geom -D gadm36_4.shp gadm4 > gadm4.sql
psql -U gisuser -h localhost -p 5432 gis < gadm4.sql
rm gadm4.sql

#level5
psql -U gisuser -h localhost -p 5432 gis -c "ALTER TABLE gadm5 RENAME TO gadm5_old;"
shp2pgsql -g the_geom -D gadm36_5.shp gadm5 > gadm5.sql
psql -U gisuser -h localhost -p 5432 gis < gadm5.sql
rm gadm5.sql


#Add indices and run data checks
psql -U gisuser -h localhost -p 5432 gis < gadm.sql
