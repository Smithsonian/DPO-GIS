
alter table gnis add column the_geom geometry;
update gnis set the_geom = st_setsrid(st_point(prim_long_dec, prim_lat_dec), 4326);

alter table gnis add column uid uuid DEFAULT uuid_generate_v4();

CREATE INDEX gnis_feature_name_idx ON gnis USING btree (feature_name);
CREATE INDEX gnis_the_geom_idx ON gnis USING gist (the_geom);
CREATE INDEX gnis_uid_idx ON gnis USING btree (uid);
CREATE INDEX gnis_feature_name_trgm_idx ON gnis USING gin (feature_name gin_trgm_ops);

alter table gnis add column the_geom_webmercator geometry;
update gnis set the_geom_webmercator = st_transform(the_geom, 3857);
CREATE INDEX gnis_the_geomw_idx ON gnis USING gist (the_geom_webmercator);
