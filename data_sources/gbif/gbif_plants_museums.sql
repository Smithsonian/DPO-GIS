
--gbif_plants_museums
DROP TABLE IF EXISTS gbif_plants_museums CASCADE;

CREATE TABLE gbif_plants_museums AS 
    SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_00
    WHERE
        phylum = 'Tracheophyta' AND
        basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}');

ALTER TABLE gbif_plants_museums ADD COLUMN ID SERIAL;

--Insert
INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_01
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_02
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_03
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_04
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_05
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_06
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_07
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_08
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_09
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_10
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_11
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_12
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_13
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_14
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_15
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_16
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_17
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_18
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom, the_geom_webmercator
    FROM
        gbif_19
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));



DELETE
FROM
    gbif_plants_museums a
        USING gbif_plants_museums b
WHERE
    a.id < b.id
    AND a.locality = b.locality AND
    a.datasetKey = b.datasetKey AND
    a.decimalLatitude = b.decimalLatitude AND
    a.decimalLongitude = b.decimalLongitude;


CREATE INDEX gbif_plants_museums_locality_trgm_idx ON gbif_plants_museums USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_plants_museums_geom_idx ON gbif_plants_museums USING GIST(the_geom);
CREATE INDEX gbif_plants_museums_geomw_idx ON gbif_plants_museums USING GIST(the_geom_webmercator);


