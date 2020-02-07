
UPDATE species_rangemaps SET kingdom = UPPER(left(kingdom, 1)) || LOWER(right(kingdom, -1));
UPDATE species_rangemaps SET phylum = UPPER(left(phylum, 1)) || LOWER(right(phylum, -1));        
UPDATE species_rangemaps SET class = UPPER(left(class, 1)) || LOWER(right(class, -1));
UPDATE species_rangemaps SET order_ = UPPER(left(order_, 1)) || LOWER(right(order_, -1));
UPDATE species_rangemaps SET family = UPPER(left(family, 1)) || LOWER(right(family, -1));
UPDATE species_rangemaps SET genus = UPPER(left(genus, 1)) || LOWER(right(genus, -1));

UPDATE species_rangemaps SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE species_rangemaps SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));

--For ILIKE queries
--CREATE EXTENSION pg_trgm;
CREATE INDEX species_rangemaps_sciname_trgm_idx ON species_rangemaps USING gin (sciname gin_trgm_ops);
CREATE INDEX species_rangemaps_kingdom_idx ON species_rangemaps USING btree(kingdom);
CREATE INDEX species_rangemaps_phylum_idx ON species_rangemaps USING btree(phylum);
CREATE INDEX species_rangemaps_class_idx ON species_rangemaps USING btree(class);
CREATE INDEX species_rangemaps_order_idx ON species_rangemaps USING btree(order_);
CREATE INDEX species_rangemaps_family_idx ON species_rangemaps USING btree(family);
CREATE INDEX species_rangemaps_genus_idx ON species_rangemaps USING btree(genus);
