#!/bin/bash
#
# Load the segments to the occurrence table, then import to the final, and simplified, gbif table
#

for file in gbif*; do
    echo $file
    start_time=`date +%s`
    psql -U gisuser -h localhost gis -c "\copy gbif_occ FROM '$file';"
    psql -U gisuser -h localhost gis -c "INSERT INTO gbif (gbifID, eventDate, basisOfRecord, occurrenceID, locationID, continent, waterBody, islandGroup, island, countryCode, stateProvince, county, municipality, locality, verbatimLocality, locationAccordingTo, locationRemarks, decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters, coordinatePrecision, pointRadiusSpatialFit, georeferencedBy, georeferencedDate, georeferenceProtocol, georeferenceSources, georeferenceVerificationStatus, georeferenceRemarks, taxonConceptID, scientificName, higherClassification, kingdom, phylum, class, _order, family, genus, subgenus, specificEpithet, infraspecificEpithet, taxonRank, vernacularName, nomenclaturalCode, taxonomicStatus, nomenclaturalStatus, taxonRemarks, datasetKey, issue, hasGeospatialIssues, taxonKey, acceptedTaxonKey, species, genericName, acceptedScientificName, the_geom) (SELECT gbifID, eventDate, basisOfRecord, occurrenceID, locationID, continent, waterBody, islandGroup, island, countryCode, stateProvince, county, municipality, locality, verbatimLocality, locationAccordingTo, locationRemarks, decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters, coordinatePrecision, pointRadiusSpatialFit, georeferencedBy, georeferencedDate, georeferenceProtocol, georeferenceSources, georeferenceVerificationStatus, georeferenceRemarks, taxonConceptID, scientificName, higherClassification, kingdom, phylum, class, _order, family, genus, subgenus, specificEpithet, infraspecificEpithet, taxonRank, vernacularName, nomenclaturalCode, taxonomicStatus, nomenclaturalStatus, taxonRemarks, datasetKey, issue, hasGeospatialIssues, taxonKey, acceptedTaxonKey, species, genericName, acceptedScientificName, ST_SETSRID(ST_POINT(decimalLongitude, decimalLatitude), 4326) as the_geom FROM gbif_occ WHERE locality != '' AND species != '' AND decimalLongitude != 0 AND decimalLatitude != 0 AND decimalLongitude IS NOT NULL AND decimalLatitude IS NOT NULL);"
    psql -U gisuser -h localhost gis -c "TRUNCATE gbif_occ;"
	end_time=`date +%s`
	echo execution time was `expr $end_time - $start_time` s.
    rm $file
done
