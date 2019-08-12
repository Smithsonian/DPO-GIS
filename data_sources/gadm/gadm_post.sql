


--Make sure all the geoms are multipolygons and that they are valid
UPDATE gadm0 SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));
UPDATE gadm0 SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE gadm1 SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));
UPDATE gadm1 SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE gadm2 SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));
UPDATE gadm2 SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE gadm3 SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));
UPDATE gadm3 SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE gadm4 SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));
UPDATE gadm4 SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE gadm5 SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));
UPDATE gadm5 SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';

--Set SRID of geom column
CREATE INDEX gadm0_name0_idx ON gadm0 USING btree (name_0);
CREATE INDEX gadm0_the_geom_idx ON gadm0 USING gist (the_geom);

CREATE INDEX gadm1_name1_idx ON gadm1 USING btree (name_1);
CREATE INDEX gadm1_name0_idx ON gadm1 USING btree (name_0);
CREATE INDEX gadm1_the_geom_idx ON gadm1 USING gist (the_geom);

CREATE INDEX gadm2_name0_idx ON gadm2 USING btree (name_0);
CREATE INDEX gadm2_name1_idx ON gadm2 USING btree (name_1);
CREATE INDEX gadm2_name2_idx ON gadm2 USING btree (name_2);
CREATE INDEX gadm2_the_geom_idx ON gadm2 USING gist (the_geom);

CREATE INDEX gadm3_name3_idx ON gadm3 USING btree (name_3);
CREATE INDEX gadm3_name2_idx ON gadm3 USING btree (name_2);
CREATE INDEX gadm3_name1_idx ON gadm3 USING btree (name_1);
CREATE INDEX gadm3_name0_idx ON gadm3 USING btree (name_0);
CREATE INDEX gadm3_the_geom_idx ON gadm3 USING gist (the_geom);

CREATE INDEX gadm4_name4_idx ON gadm4 USING btree (name_4);
CREATE INDEX gadm4_name3_idx ON gadm4 USING btree (name_3);
CREATE INDEX gadm4_name2_idx ON gadm4 USING btree (name_2);
CREATE INDEX gadm4_name1_idx ON gadm4 USING btree (name_1);
CREATE INDEX gadm4_name0_idx ON gadm4 USING btree (name_0);
CREATE INDEX gadm4_the_geom_idx ON gadm4 USING gist (the_geom);

CREATE INDEX gadm5_name5_idx ON gadm5 USING btree (name_5);
CREATE INDEX gadm5_name4_idx ON gadm5 USING btree (name_4);
CREATE INDEX gadm5_name3_idx ON gadm5 USING btree (name_3);
CREATE INDEX gadm5_name2_idx ON gadm5 USING btree (name_2);
CREATE INDEX gadm5_name1_idx ON gadm5 USING btree (name_1);
CREATE INDEX gadm5_name0_idx ON gadm5 USING btree (name_0);
CREATE INDEX gadm5_the_geom_idx ON gadm5 USING gist (the_geom);


--Add unique IDs
alter table gadm0 add column uid uuid DEFAULT uuid_generate_v4();
alter table gadm1 add column uid uuid DEFAULT uuid_generate_v4();
alter table gadm2 add column uid uuid DEFAULT uuid_generate_v4();
alter table gadm3 add column uid uuid DEFAULT uuid_generate_v4();
alter table gadm4 add column uid uuid DEFAULT uuid_generate_v4();
alter table gadm5 add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX gadm0_uid_idx ON gadm0 USING btree (uid);
CREATE INDEX gadm1_uid_idx ON gadm1 USING btree (uid);
CREATE INDEX gadm2_uid_idx ON gadm2 USING btree (uid);
CREATE INDEX gadm3_uid_idx ON gadm3 USING btree (uid);
CREATE INDEX gadm4_uid_idx ON gadm4 USING btree (uid);
CREATE INDEX gadm5_uid_idx ON gadm5 USING btree (uid);



--For ILIKE queries
CREATE INDEX gadm0_name0_trgm_idx ON gadm0 USING gin (name_0 gin_trgm_ops);
CREATE INDEX gadm1_name1_trgm_idx ON gadm1 USING gin (name_1 gin_trgm_ops);
CREATE INDEX gadm2_name2_trgm_idx ON gadm2 USING gin (name_2 gin_trgm_ops);
CREATE INDEX gadm3_name3_trgm_idx ON gadm3 USING gin (name_3 gin_trgm_ops);
CREATE INDEX gadm4_name4_trgm_idx ON gadm4 USING gin (name_4 gin_trgm_ops);
CREATE INDEX gadm5_name5_trgm_idx ON gadm5 USING gin (name_5 gin_trgm_ops);


--Add centroids
ALTER TABLE gadm0 ADD COLUMN centroid geometry;
UPDATE gadm0 SET centroid = ST_Centroid(the_geom);
ALTER TABLE gadm1 ADD COLUMN centroid geometry;
UPDATE gadm1 SET centroid = ST_Centroid(the_geom);
ALTER TABLE gadm2 ADD COLUMN centroid geometry;
UPDATE gadm2 SET centroid = ST_Centroid(the_geom);
ALTER TABLE gadm3 ADD COLUMN centroid geometry;
UPDATE gadm3 SET centroid = ST_Centroid(the_geom);
ALTER TABLE gadm4 ADD COLUMN centroid geometry;
UPDATE gadm4 SET centroid = ST_Centroid(the_geom);
ALTER TABLE gadm5 ADD COLUMN centroid geometry;
UPDATE gadm5 SET centroid = ST_Centroid(the_geom);



--Simplified geoms
ALTER TABLE gadm0 ADD COLUMN the_geom_simp geometry;
UPDATE gadm0 SET the_geom_simp = ST_SIMPLIFY(the_geom, 0.001);
CREATE INDEX gadm0_the_geom_simp_idx ON gadm0 USING GIST(the_geom_simp);

ALTER TABLE gadm1 ADD COLUMN the_geom_simp geometry;
UPDATE gadm1 SET the_geom_simp = ST_SIMPLIFY(the_geom, 0.0001);
CREATE INDEX gadm1_the_geom_simp_idx ON gadm1 USING GIST(the_geom_simp);

ALTER TABLE gadm2 ADD COLUMN the_geom_simp geometry;
UPDATE gadm2 SET the_geom_simp = ST_SIMPLIFY(the_geom, 0.0001);
CREATE INDEX gadm2_the_geom_simp_idx ON gadm2 USING GIST(the_geom_simp);

ALTER TABLE gadm3 ADD COLUMN the_geom_simp geometry;
UPDATE gadm3 SET the_geom_simp = ST_SIMPLIFY(the_geom, 0.0001);
CREATE INDEX gadm3_the_geom_simp_idx ON gadm3 USING GIST(the_geom_simp);

ALTER TABLE gadm4 ADD COLUMN the_geom_simp geometry;
UPDATE gadm4 SET the_geom_simp = ST_SIMPLIFY(the_geom, 0.0001);
CREATE INDEX gadm4_the_geom_simp_idx ON gadm4 USING GIST(the_geom_simp);

ALTER TABLE gadm5 ADD COLUMN the_geom_simp geometry;
UPDATE gadm5 SET the_geom_simp = ST_SIMPLIFY(the_geom, 0.0001);
CREATE INDEX gadm5_the_geom_simp_idx ON gadm5 USING GIST(the_geom_simp);



--Add geom_webmercator
ALTER TABLE gadm0 ADD COLUMN the_geom_webmercator geometry;
--Issues with Antarctica at the edge of (180 90), clip just inside
UPDATE gadm0 SET the_geom = ST_INTERSECTION(the_geom, ST_SETSRID(ST_GeomFromText('POLYGON((-179.999999 -89.999999, 179.999999 -89.999999, 179.999999 89.999999, -179.999999 89.999999, -179.999999 -89.999999))'), 4326)) WHERE name_0 = 'Antarctica';

UPDATE gadm0 SET the_geom_webmercator = st_transform(the_geom, 3857);
CREATE INDEX gadm0_tgeomw_idx ON gadm0 USING GIST(the_geom_webmercator);

ALTER TABLE gadm1 ADD COLUMN the_geom_webmercator geometry;
UPDATE gadm1 SET the_geom_webmercator = st_transform(the_geom, 3857);
CREATE INDEX gadm1_tgeomw_idx ON gadm1 USING GIST(the_geom_webmercator);

ALTER TABLE gadm2 ADD COLUMN the_geom_webmercator geometry;
UPDATE gadm2 SET the_geom_webmercator = st_transform(the_geom, 3857);
CREATE INDEX gadm2_tgeomw_idx ON gadm2 USING GIST(the_geom_webmercator);

ALTER TABLE gadm3 ADD COLUMN the_geom_webmercator geometry;
UPDATE gadm3 SET the_geom_webmercator = st_transform(the_geom, 3857);
CREATE INDEX gadm3_tgeomw_idx ON gadm3 USING GIST(the_geom_webmercator);

ALTER TABLE gadm4 ADD COLUMN the_geom_webmercator geometry;
UPDATE gadm4 SET the_geom_webmercator = st_transform(the_geom, 3857);
CREATE INDEX gadm4_tgeomw_idx ON gadm4 USING GIST(the_geom_webmercator);

ALTER TABLE gadm5 ADD COLUMN the_geom_webmercator geometry;
UPDATE gadm5 SET the_geom_webmercator = st_transform(the_geom, 3857);
CREATE INDEX gadm5_tgeomw_idx ON gadm5 USING GIST(the_geom_webmercator);

