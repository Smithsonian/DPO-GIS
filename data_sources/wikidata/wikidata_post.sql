
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

CREATE INDEX wikidata_uid_idx ON wikidata_records USING BTREE(uid);







--View
CREATE MATERIALIZED VIEW wikidata AS
    WITH data AS (
        SELECT 
            uid, name, gadm2 AS stateprovince, 'wikidata' AS data_source, the_geom
        FROM 
            wikidata_records
        UNION
        SELECT 
            r.uid, n.name, r.gadm2 AS stateprovince, 'wikidata' AS data_source, r.the_geom
        FROM 
            wikidata_records r, wikidata_names n 
        WHERE 
            r.source_id = n.source_id
        )
    SELECT uid, name, stateprovince, data_source, the_geom FROM data GROUP BY uid, name, stateprovince, data_source, the_geom;
CREATE INDEX wikidata_v_uid_idx ON wikidata USING BTREE(uid);
CREATE INDEX wikidata_v_name_idx ON wikidata USING gin (name gin_trgm_ops);
CREATE INDEX wikidata_v_gadm2_idx ON wikidata USING gin (gadm2 gin_trgm_ops);
CREATE INDEX wikidata_v_geom_idx ON wikidata USING GIST(the_geom);
