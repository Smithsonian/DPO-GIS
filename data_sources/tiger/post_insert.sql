
CREATE INDEX tiger_arealm_name_idx ON tiger_arealm USING gin (fullname gin_trgm_ops);
CREATE INDEX tiger_areawater_name_idx ON tiger_areawater USING gin (fullname gin_trgm_ops);
CREATE INDEX tiger_counties_name_idx ON tiger_counties USING gin (name gin_trgm_ops);
CREATE INDEX tiger_roads_name_idx ON tiger_roads USING gin (fullname gin_trgm_ops);

CREATE INDEX tiger_arealm_geom_idx ON tiger_arealm USING gist (the_geom);
CREATE INDEX tiger_areawater_geom_idx ON tiger_areawater USING gist (the_geom);
CREATE INDEX tiger_counties_geom_idx ON tiger_counties USING gist (the_geom);
CREATE INDEX tiger_roads_geom_idx ON tiger_roads USING gist (the_geom);




--tiger_arealm
--Add UUID
ALTER TABLE tiger_arealm add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX tiger_arealm_uid_idx ON tiger_arealm USING btree(uid);

--Add SRID
UPDATE tiger_arealm SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE tiger_arealm SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));

ALTER TABLE tiger_arealm ADD COLUMN centroid geometry;
UPDATE tiger_arealm SET centroid = ST_Centroid(the_geom);

ALTER TABLE tiger_arealm ADD COLUMN the_geom_webmercator geometry;
UPDATE tiger_arealm SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX tiger_arealm_the_geomw_idx ON tiger_arealm USING gist (the_geom_webmercator);



--tiger_areawater
--Add UUID
ALTER TABLE tiger_areawater add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX tiger_areawater_uid_idx ON tiger_areawater USING btree(uid);

--Add SRID
UPDATE tiger_areawater SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE tiger_areawater SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));

ALTER TABLE tiger_areawater ADD COLUMN centroid geometry;
UPDATE tiger_areawater SET centroid = ST_Centroid(the_geom);

ALTER TABLE tiger_areawater ADD COLUMN the_geom_webmercator geometry;
UPDATE tiger_areawater SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX tiger_areawater_the_geomw_idx ON tiger_areawater USING gist (the_geom_webmercator);



--tiger_counties
ALTER TABLE tiger_counties add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX tiger_counties_uid_idx ON tiger_counties USING btree(uid);

--Add SRID
UPDATE tiger_counties SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE tiger_counties SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));

ALTER TABLE tiger_counties ADD COLUMN centroid geometry;
UPDATE tiger_counties SET centroid = ST_Centroid(the_geom);

ALTER TABLE tiger_counties ADD COLUMN the_geom_webmercator geometry;
UPDATE tiger_counties SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX tiger_counties_the_geomw_idx ON tiger_counties USING gist (the_geom_webmercator);


--tiger_roads
ALTER TABLE tiger_roads add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX tiger_roads_uid_idx ON tiger_roads USING btree(uid);

--Add SRID
UPDATE tiger_roads SET the_geom = ST_SETSRID(the_geom, 4326);
UPDATE tiger_roads SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';

ALTER TABLE tiger_roads ADD COLUMN centroid geometry;
UPDATE tiger_roads SET centroid = ST_Centroid(the_geom);

ALTER TABLE tiger_roads ADD COLUMN the_geom_webmercator geometry;
UPDATE tiger_roads SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX tiger_roads_the_geomw_idx ON tiger_roads USING gist (the_geom_webmercator);





--Add gamd2
ALTER TABLE tiger_arealm ADD COLUMN gadm2 text;
ALTER TABLE tiger_areawater ADD COLUMN gadm2 text;
ALTER TABLE tiger_counties ADD COLUMN gadm2 text;
ALTER TABLE tiger_roads ADD COLUMN gadm2 text;

--tiger_arealm
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        tiger_arealm w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE tiger_arealm g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;

--tiger_areawater
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        tiger_areawater w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE tiger_areawater g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;

--tiger_counties
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        tiger_counties w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE tiger_counties g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;

--tiger_roads
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        tiger_roads w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE tiger_roads g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;