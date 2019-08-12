-----------------------------
--Post insert indexing
-----------------------------

CREATE INDEX gbif_00_species_trgm_idx ON gbif_00 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_00_species_idx ON gbif_00 USING BTREE(species);
CREATE INDEX gbif_00_genus_idx ON gbif_00 USING BTREE(genus);
CREATE INDEX gbif_00_locality_trgm_idx ON gbif_00 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_00_thegeom_idx ON gbif_00 USING gist (the_geom);
CREATE INDEX gbif_00_lon_idx ON gbif_00 USING btree(decimalLongitude);
CREATE INDEX gbif_00_lat_idx ON gbif_00 USING btree(decimalLatitude);
CLUSTER gbif_00 USING gbif_00_species_idx;

CREATE INDEX gbif_01_species_trgm_idx ON gbif_01 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_01_species_idx ON gbif_01 USING BTREE(species);
CREATE INDEX gbif_01_genus_idx ON gbif_01 USING BTREE(genus);
CREATE INDEX gbif_01_locality_trgm_idx ON gbif_01 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_01_thegeom_idx ON gbif_01 USING gist (the_geom);
CREATE INDEX gbif_01_lon_idx ON gbif_01 USING btree(decimalLongitude);
CREATE INDEX gbif_01_lat_idx ON gbif_01 USING btree(decimalLatitude);
CLUSTER gbif_01 USING gbif_01_species_idx;

CREATE INDEX gbif_02_species_trgm_idx ON gbif_02 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_02_species_idx ON gbif_02 USING BTREE(species);
CREATE INDEX gbif_02_genus_idx ON gbif_02 USING BTREE(genus);
CREATE INDEX gbif_02_locality_trgm_idx ON gbif_02 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_02_thegeom_idx ON gbif_02 USING gist (the_geom);
CREATE INDEX gbif_02_lon_idx ON gbif_02 USING btree(decimalLongitude);
CREATE INDEX gbif_02_lat_idx ON gbif_02 USING btree(decimalLatitude);
CLUSTER gbif_02 USING gbif_02_species_idx;

CREATE INDEX gbif_03_species_trgm_idx ON gbif_03 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_03_species_idx ON gbif_03 USING BTREE(species);
CREATE INDEX gbif_03_genus_idx ON gbif_03 USING BTREE(genus);
CREATE INDEX gbif_03_locality_trgm_idx ON gbif_03 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_03_thegeom_idx ON gbif_03 USING gist (the_geom);
CREATE INDEX gbif_03_lon_idx ON gbif_03 USING btree(decimalLongitude);
CREATE INDEX gbif_03_lat_idx ON gbif_03 USING btree(decimalLatitude);
CLUSTER gbif_03 USING gbif_03_species_idx;

CREATE INDEX gbif_04_species_trgm_idx ON gbif_04 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_04_species_idx ON gbif_04 USING BTREE(species);
CREATE INDEX gbif_04_genus_idx ON gbif_04 USING BTREE(genus);
CREATE INDEX gbif_04_locality_trgm_idx ON gbif_04 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_04_thegeom_idx ON gbif_04 USING gist (the_geom);
CREATE INDEX gbif_04_lon_idx ON gbif_04 USING btree(decimalLongitude);
CREATE INDEX gbif_04_lat_idx ON gbif_04 USING btree(decimalLatitude);
CLUSTER gbif_04 USING gbif_04_species_idx;

CREATE INDEX gbif_05_species_trgm_idx ON gbif_05 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_05_species_idx ON gbif_05 USING BTREE(species);
CREATE INDEX gbif_05_genus_idx ON gbif_05 USING BTREE(genus);
CREATE INDEX gbif_05_locality_trgm_idx ON gbif_05 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_05_thegeom_idx ON gbif_05 USING gist (the_geom);
CREATE INDEX gbif_05_lon_idx ON gbif_05 USING btree(decimalLongitude);
CREATE INDEX gbif_05_lat_idx ON gbif_05 USING btree(decimalLatitude);
CLUSTER gbif_05 USING gbif_05_species_idx;

CREATE INDEX gbif_06_species_trgm_idx ON gbif_06 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_06_species_idx ON gbif_06 USING BTREE(species);
CREATE INDEX gbif_06_genus_idx ON gbif_06 USING BTREE(genus);
CREATE INDEX gbif_06_locality_trgm_idx ON gbif_06 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_06_thegeom_idx ON gbif_06 USING gist (the_geom);
CREATE INDEX gbif_06_lon_idx ON gbif_06 USING btree(decimalLongitude);
CREATE INDEX gbif_06_lat_idx ON gbif_06 USING btree(decimalLatitude);
CLUSTER gbif_06 USING gbif_06_species_idx;

CREATE INDEX gbif_07_species_trgm_idx ON gbif_07 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_07_species_idx ON gbif_07 USING BTREE(species);
CREATE INDEX gbif_07_genus_idx ON gbif_07 USING BTREE(genus);
CREATE INDEX gbif_07_locality_trgm_idx ON gbif_07 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_07_thegeom_idx ON gbif_07 USING gist (the_geom);
CREATE INDEX gbif_07_lon_idx ON gbif_07 USING btree(decimalLongitude);
CREATE INDEX gbif_07_lat_idx ON gbif_07 USING btree(decimalLatitude);
CLUSTER gbif_07 USING gbif_07_species_idx;

CREATE INDEX gbif_08_species_trgm_idx ON gbif_08 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_08_species_idx ON gbif_08 USING BTREE(species);
CREATE INDEX gbif_08_genus_idx ON gbif_08 USING BTREE(genus);
CREATE INDEX gbif_08_locality_trgm_idx ON gbif_08 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_08_thegeom_idx ON gbif_08 USING gist (the_geom);
CREATE INDEX gbif_08_lon_idx ON gbif_08 USING btree(decimalLongitude);
CREATE INDEX gbif_08_lat_idx ON gbif_08 USING btree(decimalLatitude);
CLUSTER gbif_08 USING gbif_08_species_idx;

CREATE INDEX gbif_09_species_trgm_idx ON gbif_09 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_09_species_idx ON gbif_09 USING BTREE(species);
CREATE INDEX gbif_09_genus_idx ON gbif_09 USING BTREE(genus);
CREATE INDEX gbif_09_locality_trgm_idx ON gbif_09 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_09_thegeom_idx ON gbif_09 USING gist (the_geom);
CREATE INDEX gbif_09_lon_idx ON gbif_09 USING btree(decimalLongitude);
CREATE INDEX gbif_09_lat_idx ON gbif_09 USING btree(decimalLatitude);
CLUSTER gbif_09 USING gbif_09_species_idx;

CREATE INDEX gbif_10_species_trgm_idx ON gbif_10 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_10_species_idx ON gbif_10 USING BTREE(species);
CREATE INDEX gbif_10_genus_idx ON gbif_10 USING BTREE(genus);
CREATE INDEX gbif_10_locality_trgm_idx ON gbif_10 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_10_thegeom_idx ON gbif_10 USING gist (the_geom);
CREATE INDEX gbif_10_lon_idx ON gbif_10 USING btree(decimalLongitude);
CREATE INDEX gbif_10_lat_idx ON gbif_10 USING btree(decimalLatitude);
CLUSTER gbif_10 USING gbif_10_species_idx;

CREATE INDEX gbif_11_species_trgm_idx ON gbif_11 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_11_species_idx ON gbif_11 USING BTREE(species);
CREATE INDEX gbif_11_genus_idx ON gbif_11 USING BTREE(genus);
CREATE INDEX gbif_11_locality_trgm_idx ON gbif_11 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_11_thegeom_idx ON gbif_11 USING gist (the_geom);
CREATE INDEX gbif_11_lon_idx ON gbif_11 USING btree(decimalLongitude);
CREATE INDEX gbif_11_lat_idx ON gbif_11 USING btree(decimalLatitude);
CLUSTER gbif_11 USING gbif_11_species_idx;

CREATE INDEX gbif_12_species_trgm_idx ON gbif_12 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_12_species_idx ON gbif_12 USING BTREE(species);
CREATE INDEX gbif_12_genus_idx ON gbif_12 USING BTREE(genus);
CREATE INDEX gbif_12_locality_trgm_idx ON gbif_12 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_12_thegeom_idx ON gbif_12 USING gist (the_geom);
CREATE INDEX gbif_12_lon_idx ON gbif_12 USING btree(decimalLongitude);
CREATE INDEX gbif_12_lat_idx ON gbif_12 USING btree(decimalLatitude);
CLUSTER gbif_12 USING gbif_12_species_idx;

CREATE INDEX gbif_13_species_trgm_idx ON gbif_13 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_13_species_idx ON gbif_13 USING BTREE(species);
CREATE INDEX gbif_13_genus_idx ON gbif_13 USING BTREE(genus);
CREATE INDEX gbif_13_locality_trgm_idx ON gbif_13 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_13_thegeom_idx ON gbif_13 USING gist (the_geom);
CREATE INDEX gbif_13_lon_idx ON gbif_13 USING btree(decimalLongitude);
CREATE INDEX gbif_13_lat_idx ON gbif_13 USING btree(decimalLatitude);
CLUSTER gbif_13 USING gbif_13_species_idx;

CREATE INDEX gbif_14_species_trgm_idx ON gbif_14 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_14_species_idx ON gbif_14 USING BTREE(species);
CREATE INDEX gbif_14_genus_idx ON gbif_14 USING BTREE(genus);
CREATE INDEX gbif_14_locality_trgm_idx ON gbif_14 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_14_thegeom_idx ON gbif_14 USING gist (the_geom);
CREATE INDEX gbif_14_lon_idx ON gbif_14 USING btree(decimalLongitude);
CREATE INDEX gbif_14_lat_idx ON gbif_14 USING btree(decimalLatitude);
CLUSTER gbif_14 USING gbif_14_species_idx;

CREATE INDEX gbif_15_species_trgm_idx ON gbif_15 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_15_species_idx ON gbif_15 USING BTREE(species);
CREATE INDEX gbif_15_genus_idx ON gbif_15 USING BTREE(genus);
CREATE INDEX gbif_15_locality_trgm_idx ON gbif_15 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_15_thegeom_idx ON gbif_15 USING gist (the_geom);
CREATE INDEX gbif_15_lon_idx ON gbif_15 USING btree(decimalLongitude);
CREATE INDEX gbif_15_lat_idx ON gbif_15 USING btree(decimalLatitude);
CLUSTER gbif_15 USING gbif_15_species_idx;

CREATE INDEX gbif_16_species_trgm_idx ON gbif_16 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_16_species_idx ON gbif_16 USING BTREE(species);
CREATE INDEX gbif_16_genus_idx ON gbif_16 USING BTREE(genus);
CREATE INDEX gbif_16_locality_trgm_idx ON gbif_16 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_16_thegeom_idx ON gbif_16 USING gist (the_geom);
CREATE INDEX gbif_16_lon_idx ON gbif_16 USING btree(decimalLongitude);
CREATE INDEX gbif_16_lat_idx ON gbif_16 USING btree(decimalLatitude);
CLUSTER gbif_16 USING gbif_16_species_idx;

CREATE INDEX gbif_17_species_trgm_idx ON gbif_17 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_17_species_idx ON gbif_17 USING BTREE(species);
CREATE INDEX gbif_17_genus_idx ON gbif_17 USING BTREE(genus);
CREATE INDEX gbif_17_locality_trgm_idx ON gbif_17 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_17_thegeom_idx ON gbif_17 USING gist (the_geom);
CREATE INDEX gbif_17_lon_idx ON gbif_17 USING btree(decimalLongitude);
CREATE INDEX gbif_17_lat_idx ON gbif_17 USING btree(decimalLatitude);
CLUSTER gbif_17 USING gbif_17_species_idx;

CREATE INDEX gbif_18_species_trgm_idx ON gbif_18 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_18_species_idx ON gbif_18 USING BTREE(species);
CREATE INDEX gbif_18_genus_idx ON gbif_18 USING BTREE(genus);
CREATE INDEX gbif_18_locality_trgm_idx ON gbif_18 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_18_thegeom_idx ON gbif_18 USING gist (the_geom);
CREATE INDEX gbif_18_lon_idx ON gbif_18 USING btree(decimalLongitude);
CREATE INDEX gbif_18_lat_idx ON gbif_18 USING btree(decimalLatitude);
CLUSTER gbif_18 USING gbif_18_species_idx;

CREATE INDEX gbif_19_species_trgm_idx ON gbif_19 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_19_species_idx ON gbif_19 USING BTREE(species);
CREATE INDEX gbif_19_genus_idx ON gbif_19 USING BTREE(genus);
CREATE INDEX gbif_19_locality_trgm_idx ON gbif_19 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_19_thegeom_idx ON gbif_19 USING gist (the_geom);
CREATE INDEX gbif_19_lon_idx ON gbif_19 USING btree(decimalLongitude);
CREATE INDEX gbif_19_lat_idx ON gbif_19 USING btree(decimalLatitude);
CLUSTER gbif_19 USING gbif_19_species_idx;





--More indices, taxonomy and basis of record
CREATE INDEX gbif_00_taxokin_idx ON gbif_00 USING btree(kingdom);
CREATE INDEX gbif_00_taxophy_idx ON gbif_00 USING btree(phylum);
CREATE INDEX gbif_00_taxocla_idx ON gbif_00 USING btree(class);
CREATE INDEX gbif_00_taxoord_idx ON gbif_00 USING btree(_order);
CREATE INDEX gbif_00_taxofam_idx ON gbif_00 USING btree(family);
CREATE INDEX gbif_00_basisrec_idx ON gbif_00 USING btree(basisOfRecord);

CREATE INDEX gbif_01_taxokin_idx ON gbif_01 USING btree(kingdom);
CREATE INDEX gbif_01_taxophy_idx ON gbif_01 USING btree(phylum);
CREATE INDEX gbif_01_taxocla_idx ON gbif_01 USING btree(class);
CREATE INDEX gbif_01_taxoord_idx ON gbif_01 USING btree(_order);
CREATE INDEX gbif_01_taxofam_idx ON gbif_01 USING btree(family);
CREATE INDEX gbif_01_basisrec_idx ON gbif_01 USING btree(basisOfRecord);

CREATE INDEX gbif_02_taxokin_idx ON gbif_02 USING btree(kingdom);
CREATE INDEX gbif_02_taxophy_idx ON gbif_02 USING btree(phylum);
CREATE INDEX gbif_02_taxocla_idx ON gbif_02 USING btree(class);
CREATE INDEX gbif_02_taxoord_idx ON gbif_02 USING btree(_order);
CREATE INDEX gbif_02_taxofam_idx ON gbif_02 USING btree(family);
CREATE INDEX gbif_02_basisrec_idx ON gbif_02 USING btree(basisOfRecord);

CREATE INDEX gbif_03_taxokin_idx ON gbif_03 USING btree(kingdom);
CREATE INDEX gbif_03_taxophy_idx ON gbif_03 USING btree(phylum);
CREATE INDEX gbif_03_taxocla_idx ON gbif_03 USING btree(class);
CREATE INDEX gbif_03_taxoord_idx ON gbif_03 USING btree(_order);
CREATE INDEX gbif_03_taxofam_idx ON gbif_03 USING btree(family);
CREATE INDEX gbif_03_basisrec_idx ON gbif_03 USING btree(basisOfRecord);

CREATE INDEX gbif_04_taxokin_idx ON gbif_04 USING btree(kingdom);
CREATE INDEX gbif_04_taxophy_idx ON gbif_04 USING btree(phylum);
CREATE INDEX gbif_04_taxocla_idx ON gbif_04 USING btree(class);
CREATE INDEX gbif_04_taxoord_idx ON gbif_04 USING btree(_order);
CREATE INDEX gbif_04_taxofam_idx ON gbif_04 USING btree(family);
CREATE INDEX gbif_04_basisrec_idx ON gbif_04 USING btree(basisOfRecord);

CREATE INDEX gbif_05_taxokin_idx ON gbif_05 USING btree(kingdom);
CREATE INDEX gbif_05_taxophy_idx ON gbif_05 USING btree(phylum);
CREATE INDEX gbif_05_taxocla_idx ON gbif_05 USING btree(class);
CREATE INDEX gbif_05_taxoord_idx ON gbif_05 USING btree(_order);
CREATE INDEX gbif_05_taxofam_idx ON gbif_05 USING btree(family);
CREATE INDEX gbif_05_basisrec_idx ON gbif_05 USING btree(basisOfRecord);

CREATE INDEX gbif_06_taxokin_idx ON gbif_06 USING btree(kingdom);
CREATE INDEX gbif_06_taxophy_idx ON gbif_06 USING btree(phylum);
CREATE INDEX gbif_06_taxocla_idx ON gbif_06 USING btree(class);
CREATE INDEX gbif_06_taxoord_idx ON gbif_06 USING btree(_order);
CREATE INDEX gbif_06_taxofam_idx ON gbif_06 USING btree(family);
CREATE INDEX gbif_06_basisrec_idx ON gbif_06 USING btree(basisOfRecord);

CREATE INDEX gbif_07_taxokin_idx ON gbif_07 USING btree(kingdom);
CREATE INDEX gbif_07_taxophy_idx ON gbif_07 USING btree(phylum);
CREATE INDEX gbif_07_taxocla_idx ON gbif_07 USING btree(class);
CREATE INDEX gbif_07_taxoord_idx ON gbif_07 USING btree(_order);
CREATE INDEX gbif_07_taxofam_idx ON gbif_07 USING btree(family);
CREATE INDEX gbif_07_basisrec_idx ON gbif_07 USING btree(basisOfRecord);

CREATE INDEX gbif_08_taxokin_idx ON gbif_08 USING btree(kingdom);
CREATE INDEX gbif_08_taxophy_idx ON gbif_08 USING btree(phylum);
CREATE INDEX gbif_08_taxocla_idx ON gbif_08 USING btree(class);
CREATE INDEX gbif_08_taxoord_idx ON gbif_08 USING btree(_order);
CREATE INDEX gbif_08_taxofam_idx ON gbif_08 USING btree(family);
CREATE INDEX gbif_08_basisrec_idx ON gbif_08 USING btree(basisOfRecord);

CREATE INDEX gbif_09_taxokin_idx ON gbif_09 USING btree(kingdom);
CREATE INDEX gbif_09_taxophy_idx ON gbif_09 USING btree(phylum);
CREATE INDEX gbif_09_taxocla_idx ON gbif_09 USING btree(class);
CREATE INDEX gbif_09_taxoord_idx ON gbif_09 USING btree(_order);
CREATE INDEX gbif_09_taxofam_idx ON gbif_09 USING btree(family);
CREATE INDEX gbif_09_basisrec_idx ON gbif_09 USING btree(basisOfRecord);

CREATE INDEX gbif_10_taxokin_idx ON gbif_10 USING btree(kingdom);
CREATE INDEX gbif_10_taxophy_idx ON gbif_10 USING btree(phylum);
CREATE INDEX gbif_10_taxocla_idx ON gbif_10 USING btree(class);
CREATE INDEX gbif_10_taxoord_idx ON gbif_10 USING btree(_order);
CREATE INDEX gbif_10_taxofam_idx ON gbif_10 USING btree(family);
CREATE INDEX gbif_10_basisrec_idx ON gbif_10 USING btree(basisOfRecord);

CREATE INDEX gbif_11_taxokin_idx ON gbif_11 USING btree(kingdom);
CREATE INDEX gbif_11_taxophy_idx ON gbif_11 USING btree(phylum);
CREATE INDEX gbif_11_taxocla_idx ON gbif_11 USING btree(class);
CREATE INDEX gbif_11_taxoord_idx ON gbif_11 USING btree(_order);
CREATE INDEX gbif_11_taxofam_idx ON gbif_11 USING btree(family);
CREATE INDEX gbif_11_basisrec_idx ON gbif_11 USING btree(basisOfRecord);

CREATE INDEX gbif_12_taxokin_idx ON gbif_12 USING btree(kingdom);
CREATE INDEX gbif_12_taxophy_idx ON gbif_12 USING btree(phylum);
CREATE INDEX gbif_12_taxocla_idx ON gbif_12 USING btree(class);
CREATE INDEX gbif_12_taxoord_idx ON gbif_12 USING btree(_order);
CREATE INDEX gbif_12_taxofam_idx ON gbif_12 USING btree(family);
CREATE INDEX gbif_12_basisrec_idx ON gbif_12 USING btree(basisOfRecord);

CREATE INDEX gbif_13_taxokin_idx ON gbif_13 USING btree(kingdom);
CREATE INDEX gbif_13_taxophy_idx ON gbif_13 USING btree(phylum);
CREATE INDEX gbif_13_taxocla_idx ON gbif_13 USING btree(class);
CREATE INDEX gbif_13_taxoord_idx ON gbif_13 USING btree(_order);
CREATE INDEX gbif_13_taxofam_idx ON gbif_13 USING btree(family);
CREATE INDEX gbif_13_basisrec_idx ON gbif_13 USING btree(basisOfRecord);

CREATE INDEX gbif_14_taxokin_idx ON gbif_14 USING btree(kingdom);
CREATE INDEX gbif_14_taxophy_idx ON gbif_14 USING btree(phylum);
CREATE INDEX gbif_14_taxocla_idx ON gbif_14 USING btree(class);
CREATE INDEX gbif_14_taxoord_idx ON gbif_14 USING btree(_order);
CREATE INDEX gbif_14_taxofam_idx ON gbif_14 USING btree(family);
CREATE INDEX gbif_14_basisrec_idx ON gbif_14 USING btree(basisOfRecord);

CREATE INDEX gbif_15_taxokin_idx ON gbif_15 USING btree(kingdom);
CREATE INDEX gbif_15_taxophy_idx ON gbif_15 USING btree(phylum);
CREATE INDEX gbif_15_taxocla_idx ON gbif_15 USING btree(class);
CREATE INDEX gbif_15_taxoord_idx ON gbif_15 USING btree(_order);
CREATE INDEX gbif_15_taxofam_idx ON gbif_15 USING btree(family);
CREATE INDEX gbif_15_basisrec_idx ON gbif_15 USING btree(basisOfRecord);

CREATE INDEX gbif_16_taxokin_idx ON gbif_16 USING btree(kingdom);
CREATE INDEX gbif_16_taxophy_idx ON gbif_16 USING btree(phylum);
CREATE INDEX gbif_16_taxocla_idx ON gbif_16 USING btree(class);
CREATE INDEX gbif_16_taxoord_idx ON gbif_16 USING btree(_order);
CREATE INDEX gbif_16_taxofam_idx ON gbif_16 USING btree(family);
CREATE INDEX gbif_16_basisrec_idx ON gbif_16 USING btree(basisOfRecord);

CREATE INDEX gbif_17_taxokin_idx ON gbif_17 USING btree(kingdom);
CREATE INDEX gbif_17_taxophy_idx ON gbif_17 USING btree(phylum);
CREATE INDEX gbif_17_taxocla_idx ON gbif_17 USING btree(class);
CREATE INDEX gbif_17_taxoord_idx ON gbif_17 USING btree(_order);
CREATE INDEX gbif_17_taxofam_idx ON gbif_17 USING btree(family);
CREATE INDEX gbif_17_basisrec_idx ON gbif_17 USING btree(basisOfRecord);

CREATE INDEX gbif_18_taxokin_idx ON gbif_18 USING btree(kingdom);
CREATE INDEX gbif_18_taxophy_idx ON gbif_18 USING btree(phylum);
CREATE INDEX gbif_18_taxocla_idx ON gbif_18 USING btree(class);
CREATE INDEX gbif_18_taxoord_idx ON gbif_18 USING btree(_order);
CREATE INDEX gbif_18_taxofam_idx ON gbif_18 USING btree(family);
CREATE INDEX gbif_18_basisrec_idx ON gbif_18 USING btree(basisOfRecord);

CREATE INDEX gbif_19_taxokin_idx ON gbif_19 USING btree(kingdom);
CREATE INDEX gbif_19_taxophy_idx ON gbif_19 USING btree(phylum);
CREATE INDEX gbif_19_taxocla_idx ON gbif_19 USING btree(class);
CREATE INDEX gbif_19_taxoord_idx ON gbif_19 USING btree(_order);
CREATE INDEX gbif_19_taxofam_idx ON gbif_19 USING btree(family);
CREATE INDEX gbif_19_basisrec_idx ON gbif_19 USING btree(basisOfRecord);




--gbif_plants_museums
DROP TABLE IF EXISTS gbif_plants_museums CASCADE;

CREATE TABLE gbif_plants_museums AS 
    SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_00
    WHERE
        phylum = 'Tracheophyta' AND
        basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}');

ALTER TABLE gbif_plants_museums ADD COLUMN ID SERIAL;

--Insert
INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_00
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_01
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_02
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_03
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_04
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_05
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_06
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_07
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_08
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_09
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_10
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_11
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_12
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_13
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_14
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_15
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_16
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_17
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
    FROM
        gbif_18
    WHERE
        phylum = 'Tracheophyta' AND basisOfRecord = ANY('{PRESERVED_SPECIMEN,FOSSIL_SPECIMEN}'));

INSERT INTO gbif_plants_museums  
    (locality, datasetKey, decimalLatitude, decimalLongitude, the_geom)
    (SELECT
        locality, datasetKey, decimalLatitude, decimalLongitude, the_geom
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

