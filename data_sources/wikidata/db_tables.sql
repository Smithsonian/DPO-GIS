CREATE TABLE wikidata_records (
		id text, 
		type text, 
		name text, 
		latitude float, 
		longitude float, 
		the_geom geometry(Geometry, 4326));


CREATE TABLE wikidata_names (
	id text, 
	language text, 
	name text
	);


CREATE TABLE wikidata_descrip (
	id text, 
	language text, 
	description text);



--post insert indexing
CREATE INDEX wikidata_records_id_idx ON wikidata_records USING BTREE(id);
CREATE INDEX wikidata_records_name_idx ON wikidata_records USING btree (name);
CREATE INDEX wikidata_records_name_trgm_idx ON wikidata_records USING gin (name gin_trgm_ops);
CREATE INDEX wikidata_records_the_geom_idx ON wikidata_records USING gist(the_geom);

CREATE INDEX wikidata_names_name_idx ON wikidata_names USING btree (name);
CREATE INDEX wikidata_names_name_trgm_idx ON wikidata_names USING gin (name gin_trgm_ops);
CREATE INDEX wikidata_names_id_idx ON wikidata_names USING btree (id);
CREATE INDEX wikidata_names_lang_idx ON wikidata_names USING btree (language);

CREATE INDEX wikidata_descrip_descr_idx ON wikidata_descrip USING btree (description);
CREATE INDEX wikidata_descrip_descr_trgm_idx ON wikidata_descrip USING gin (description gin_trgm_ops);
CREATE INDEX wikidata_descrip_id_idx ON wikidata_descrip USING btree (id);
CREATE INDEX wikidata_descrip_lang_idx ON wikidata_descrip USING btree (language);
