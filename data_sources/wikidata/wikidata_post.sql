
ALTER TABLE wikidata_records ADD COLUMN gadm2 text;

ALTER TABLE wikidata_records ADD COLUMN country text;

WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc,
        max(g.name_0) as name_0
    FROM 
        wikidata_records w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE wikidata_records g SET gadm2 = d.loc, country = d.name_0 FROM data d WHERE g.uid = d.uid;

CREATE INDEX wikidata_gadm2_trgm_idx ON wikidata_records USING gin (gadm2 gin_trgm_ops);

CREATE INDEX wikidata_country_idx ON wikidata_records USING BTREE(country);
