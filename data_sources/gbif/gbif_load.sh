#!/bin/bash
#
# Load the records with locality and coordinates from a full GBIF dump to a PostGIS database.
#
# First, download the latest full DarwinCore data dump from:
#    https://gbif.org
# 
# Then, unzip the files
#    unzip 000##########.zip
# 

#Today's date
script_date=$(date +'%Y-%m-%d')

#remove unused files
rm meta.xml
rm *.zip
rm verbatim.txt
rm citations.txt
rm multimedia.txt
rm rights.txt

#Replace backslashes in some text fields
sed -i 's.\\./.g' occurrence.txt

#Break into smaller pieces, each with 5M rows
split -l 5000000 occurrence.txt gbifdwc
rm occurrence.txt

#Remove first line (header) in the first file
sed -i '1d' gbifdwcaa

#Delete old tables
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS gbif_occ CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS gbif CASCADE;"
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'gbif';"

psql -U gisuser -h localhost gis < gbif_tables.sql


# Load the segments to the occurrence table, then import to the final, and simplified, gbif table
for file in gbifdwc*; do
    echo $file
    psql -U gisuser -h localhost gis -c "\copy gbif_occ FROM '$file';"
    psql -U gisuser -h localhost gis -c "INSERT INTO gbif (gbifID, eventDate, basisOfRecord, occurrenceID, locationID, continent, waterBody, islandGroup, island, countryCode, stateProvince, county, municipality, locality, verbatimLocality, locationAccordingTo, locationRemarks, decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters, coordinatePrecision, pointRadiusSpatialFit, georeferencedBy, georeferencedDate, georeferenceProtocol, georeferenceSources, georeferenceVerificationStatus, georeferenceRemarks, taxonConceptID, scientificName, higherClassification, kingdom, phylum, class, _order, family, genus, subgenus, specificEpithet, infraspecificEpithet, taxonRank, vernacularName, nomenclaturalCode, taxonomicStatus, nomenclaturalStatus, taxonRemarks, datasetKey, issue, hasGeospatialIssues, taxonKey, acceptedTaxonKey, species, genericName, acceptedScientificName, the_geom, the_geom_webmercator) (SELECT gbifID, eventDate, basisOfRecord, occurrenceID, locationID, continent, waterBody, islandGroup, island, countryCode, stateProvince, county, municipality, locality, verbatimLocality, locationAccordingTo, locationRemarks, decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters, coordinatePrecision, pointRadiusSpatialFit, georeferencedBy, georeferencedDate, georeferenceProtocol, georeferenceSources, georeferenceVerificationStatus, georeferenceRemarks, taxonConceptID, scientificName, higherClassification, kingdom, phylum, class, _order, family, genus, subgenus, specificEpithet, infraspecificEpithet, taxonRank, vernacularName, nomenclaturalCode, taxonomicStatus, nomenclaturalStatus, taxonRemarks, datasetKey, issue, hasGeospatialIssues, taxonKey, acceptedTaxonKey, species, genericName, acceptedScientificName, ST_SETSRID(ST_POINT(decimalLongitude, decimalLatitude), 4326) as the_geom, ST_TRANSFORM(ST_SETSRID(ST_POINT(decimalLongitude, decimalLatitude), 4326), 3857) as the_geom_webmercator FROM gbif_occ WHERE locality != '' AND species != '' AND decimalLongitude != 0 AND decimalLatitude != 0 AND decimalLongitude IS NOT NULL AND decimalLatitude IS NOT NULL);"
    psql -U gisuser -h localhost gis -c "TRUNCATE gbif_occ;"
    rm $file
done

rm gbifdwc*

#Delete temp table
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS gbif_occ CASCADE;"

#Create indices
psql -U gisuser -h localhost gis < post_insert_indices.sql

#Extract dataset info
cp gbifdatasets.py dataset/
cd dataset/
python3 gbifdatasets.py
mv gbifdatasets.csv ../
cd ../
psql -U gisuser -h localhost gis < gbifdatasets_table.sql
rm gbifdatasets.csv
rm -r dataset

#Extract doi from DwC download using xpath
title_doi=`xpath -q -e '//dataset/title/text()' metadata.xml`

rm metadata.xml

#Turn datasource online
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', source_title = '$title_doi' WHERE datasource_id = 'gbif';"
