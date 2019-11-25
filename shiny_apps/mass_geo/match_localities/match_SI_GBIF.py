#!/usr/bin/env python3
#
# Match SI GBIF records without coordinates to other GBIF records for the species/genus
#
import psycopg2, os, logging, sys, locale, psycopg2.extras
import pandas as pd
from time import localtime, strftime
from fuzzywuzzy import fuzz
import pycountry


#Import settings
import settings

#Set locale for number format
locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')



#Get current time
current_time = strftime("%Y%m%d_%H%M%S", localtime())

# Set Logging
if not os.path.exists('logs'):
    os.makedirs('logs')

logfile_name = 'logs/{}.log'.format(current_time)
# from http://stackoverflow.com/a/9321890
logging.basicConfig(level=logging.DEBUG,
                format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
                datefmt='%m-%d %H:%M:%S',
                filename=logfile_name,
                filemode='a')
console = logging.StreamHandler()
console.setLevel(logging.INFO)
formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
console.setFormatter(formatter)
logging.getLogger('').addHandler(console)
logger1 = logging.getLogger("si_georef")




def match_localities(text1, text2):
    score = fuzz.partial_ratio(text1, text2)
    return score



#Connect to the dpogis database
try:
    logger1.info("Connecting to the database.")
    conn = psycopg2.connect(host = settings.pg_host, database = settings.pg_db, user = settings.pg_user, connect_timeout = 60)
except:
    print(" ERROR: Could not connect to server.")
    sys.exit(1)

conn.autocommit = True
cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)


if len(sys.argv) > 1:
    if sys.argv[1] == "restart":
        cur.execute("TRUNCATE gbif_si_matches")
        cur.execute("VACUUM gbif_si_matches")
    else:
        print("Invalid argument")
        sys.exit(1)
else:
    #Continue
    cur.execute("DELETE FROM gbif_si_matches WHERE species IN (SELECT species FROM gbif_si_matches ORDER BY timestamp DESC LIMIT 1)")
    logger1.info(cur.query)







#Select species
cur.execute("SELECT DISTINCT species FROM gbif_si WHERE species != '' AND ((decimallatitude is null and decimallongitude is null) OR (georeferenceprotocol LIKE '%%unknown%%') OR (locality != '')) AND species NOT IN (SELECT DISTINCT species FROM gbif_si_matches)")
logger1.info(cur.query)
scinames = cur.fetchall()



for sciname in scinames:
    sciname = sciname['species']
    logger1.info("sciname: {}".format(sciname))
    cur.execute("SELECT gbifid, countrycode, stateprovince, locality, kingdom, phylum, class, _order, family, genus FROM gbif_si WHERE species = %s AND ((decimallatitude is null and decimallongitude is null) OR (georeferenceprotocol LIKE '%%unknown%%')) AND lower(locality) != 'unknown'", (sciname,))
    logger1.info(cur.query)
    records = cur.fetchall()
    #######
    #SPECIES - GBIF
    #######
    #find all localities from gbif
    cur.execute("SELECT max(gbifid) as gbifid, count(*) as no_records, countrycode, locality, trim(leading ', ' from replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) as located_at, stateprovince FROM gbif WHERE species = %s AND lower(locality) != 'unknown' GROUP BY countrycode, locality, municipality, county, stateprovince", (sciname,))
    logger1.info(cur.query)
    gbif_records = cur.fetchall()
    #Find candidates for each record
    for record in records:
        if record['countrycode'] != "":
            #only look in country
            for gbif_r in gbif_records:
                if gbif_r[2] == record['countrycode']:
                    if gbif_r[5] != "":
                        if gbif_r[5] == record['stateprovince']:
                            locality_match = match_localities(record['locality'], gbif_r[3])
                            if locality_match > settings.min_match:
                                cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, no_records, species, match, score, located_at) VALUES 
                                                    (%s, %s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gbif.species', gbif_r['no_records'], sciname, gbif_r[0], locality_match, gbif_r['located_at']))
                                logger1.debug(cur.query)
                    else:
                        locality_match = match_localities(record['locality'], gbif_r[3])
                        if locality_match > settings.min_match:
                            cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, no_records, species, match, score, located_at) VALUES 
                                                (%s, %s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gbif.species', gbif_r['no_records'], sciname, gbif_r[0], locality_match, gbif_r['located_at']))
                            logger1.debug(cur.query)
        else:
            for gbif_r in gbif_records:
                locality_match = match_localities(record['locality'], gbif_r[3])
                if locality_match > settings.min_match:
                    cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, no_records, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gbif.species', gbif_r['no_records'], sciname, gbif_r[0], locality_match, gbif_r['located_at']))
                    logger1.debug(cur.query)
    #######
    #GENUS
    #######
    #find all localities from other species in the genus from gbif
    cur.execute("SELECT max(gbifid) as gbifid, count(*) as no_records, countrycode, locality, trim(leading ', ' from replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) as located_at, stateprovince FROM gbif WHERE species LIKE '%s %%' AND lower(locality) != 'unknown' GROUP BY countrycode, locality, municipality, county, stateprovince", (psycopg2.extensions.AsIs(sciname.split()[0]),))
    logger1.info(cur.query)
    gbif_records = cur.fetchall()
    #Find candidates for each record
    for record in records:
        if record['countrycode'] != "":
            #only look in country
            for gbif_r in gbif_records:
                if gbif_r[2] == record['countrycode']:
                    if gbif_r[5] != "":
                        if gbif_r[5] == record['stateprovince']:
                            locality_match = match_localities(record['locality'], gbif_r[3])
                            if locality_match > settings.min_match:
                                cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, no_records, species, match, score, located_at) VALUES 
                                                    (%s, %s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gbif.genus', gbif_r['no_records'], sciname, gbif_r[0], locality_match, gbif_r['located_at']))
                                logger1.debug(cur.query)
                    else:
                        locality_match = match_localities(record['locality'], gbif_r[3])
                        if locality_match > settings.min_match:
                            cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, no_records, species, match, score, located_at) VALUES 
                                                (%s, %s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gbif.genus', gbif_r['no_records'], sciname, gbif_r[0], locality_match, gbif_r['located_at']))
                            logger1.debug(cur.query)
        else:
            for gbif_r in gbif_records:
                locality_match = match_localities(record['locality'], gbif_r[3])
                if locality_match > settings.min_match:
                    cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, no_records, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gbif.genus', gbif_r['no_records'], sciname, gbif_r[0], locality_match, gbif_r['located_at']))
                    logger1.debug(cur.query)
    #######
    #GADM
    #######
    #GADM0
    for record in records:
        if record['countrycode'] != "":
            if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
                cur.execute("SELECT uid, name_0 as name, null as located_at FROM gadm0 WHERE name_0 = %s", (pycountry.countries.get(alpha_2 = record['countrycode']).name,))
                logger1.info(cur.query)
                gadm_records = cur.fetchall()
                #Find candidates for each record
                for gadm_r in gadm_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score) VALUES 
                                            (%s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm0', sciname, gadm_r[0], locality_match))
                        logger1.debug(cur.query)
                del(gadm_records)
            else:
                cur.execute("SELECT uid, name_0 as name, null as located_at FROM gadm0")
                logger1.info(cur.query)
                gadm0_records = cur.fetchall()
                for gadm_r in gadm0_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score) VALUES 
                                            (%s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm0', sciname, gadm_r[0], locality_match))
                        logger1.debug(cur.query)
                del(gadm0_records)
        else:
            cur.execute("SELECT uid, name_0 as name, null as located_at FROM gadm0")
            logger1.info(cur.query)
            gadm0_records = cur.fetchall()
            for gadm_r in gadm0_records:
                locality_match = match_localities(record['locality'], gadm_r[1])
                if locality_match > settings.min_match:
                    cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score) VALUES 
                                        (%s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm0', sciname, gadm_r[0], locality_match))
                    logger1.debug(cur.query)
            del(gadm0_records)
    #GADM1
    for record in records:
        if record['countrycode'] != "":
            if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
                cur.execute("SELECT uid, name_1 as name, name_0 as located_at FROM gadm1 WHERE name_0 = %s UNION SELECT uid, varname_1 as name, name_0 as located_at FROM gadm1 WHERE name_0 = %s AND varname_1 IS NOT NULL", (pycountry.countries.get(alpha_2 = record['countrycode']).name, pycountry.countries.get(alpha_2 = record['countrycode']).name))
                logger1.info(cur.query)
                gadm_records = cur.fetchall()
                #Find candidates for each record
                for gadm_r in gadm_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm1', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(gadm_records)
            else:
                cur.execute("SELECT uid, name_1 as name, name_0 as located_at FROM gadm1 UNION SELECT uid, varname_1 as name, name_0 as located_at FROM gadm1 WHERE varname_1 IS NOT NULL")
                logger1.info(cur.query)
                gadm1_records = cur.fetchall()
                for gadm_r in gadm1_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm1', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(gadm1_records)
        else:
            cur.execute("SELECT uid, name_1 as name, name_0 as located_at FROM gadm1 UNION SELECT uid, varname_1 as name, name_0 as located_at FROM gadm1 WHERE varname_1 IS NOT NULL")
            logger1.info(cur.query)
            gadm1_records = cur.fetchall()
            for gadm_r in gadm1_records:
                locality_match = match_localities(record['locality'], gadm_r[1])
                if locality_match > settings.min_match:
                    cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                        (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm1', sciname, gadm_r[0], locality_match, gadm_r[2]))
                    logger1.debug(cur.query)
            del(gadm1_records)
    #GADM2
    for record in records:
        if record['countrycode'] != "":
            if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
                cur.execute("SELECT uid, name_2 as name, name_1 || ', ' || name_0 as located_at FROM gadm2 WHERE name_0 = %s UNION SELECT uid, varname_2 as name, name_1 || ', ' || name_0 as located_at FROM gadm2 WHERE name_0 = %s AND varname_2 IS NOT NULL", (pycountry.countries.get(alpha_2 = record['countrycode']).name, pycountry.countries.get(alpha_2 = record['countrycode']).name))
                logger1.info(cur.query)
                gadm_records = cur.fetchall()
                #Find candidates for each record
                for gadm_r in gadm_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm2', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(gadm_records)
            else:
                cur.execute("SELECT uid, name_2 as name, name_1 || ', ' || name_0 as located_at FROM gadm2 UNION SELECT uid, varname_2 as name, name_1 || ', ' || name_0 as located_at FROM gadm2 WHERE varname_2 IS NOT NULL")
                logger1.info(cur.query)
                gadm2_records = cur.fetchall()
                for gadm_r in gadm2_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm2', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(gadm2_records)
        else:
            cur.execute("SELECT uid, name_2 as name, name_1 || ', ' || name_0 as located_at FROM gadm2 UNION SELECT uid, varname_2 as name, name_1 || ', ' || name_0 as located_at FROM gadm2 WHERE varname_2 IS NOT NULL")
            logger1.info(cur.query)
            gadm2_records = cur.fetchall()
            for gadm_r in gadm2_records:
                locality_match = match_localities(record['locality'], gadm_r[1])
                if locality_match > settings.min_match:
                    cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                        (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm2', sciname, gadm_r[0], locality_match, gadm_r[2]))
                    logger1.debug(cur.query)
            del(gadm2_records)
    #GADM3
    for record in records:
        if record['countrycode'] != "":
            if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
                cur.execute("SELECT uid, name_3 as name, name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm3 WHERE name_0 = %s UNION SELECT uid, varname_3 as name, name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm3 WHERE name_0 = %s AND varname_3 IS NOT NULL", (pycountry.countries.get(alpha_2 = record['countrycode']).name, pycountry.countries.get(alpha_2 = record['countrycode']).name))
                logger1.info(cur.query)
                gadm_records = cur.fetchall()
                #Find candidates for each record
                for gadm_r in gadm_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm3', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(gadm_records)
            else:
                cur.execute("SELECT uid, name_3 as name, name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm3 UNION SELECT uid, varname_3 as name, name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm3 WHERE varname_3 IS NOT NULL")
                logger1.info(cur.query)
                gadm3_records = cur.fetchall()
                for gadm_r in gadm3_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm3', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(gadm3_records)
        else:
            cur.execute("SELECT uid, name_3 as name, name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm3 UNION SELECT uid, varname_3 as name, name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm3 WHERE varname_3 IS NOT NULL")
            logger1.info(cur.query)
            gadm3_records = cur.fetchall()
            for gadm_r in gadm3_records:
                locality_match = match_localities(record['locality'], gadm_r[1])
                if locality_match > settings.min_match:
                    cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                        (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm3', sciname, gadm_r[0], locality_match, gadm_r[2]))
                    logger1.debug(cur.query)
            del(gadm3_records)
    #GADM4
    for record in records:
        if record['countrycode'] != "":
            if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
                cur.execute("SELECT uid, name_4 as name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm4 WHERE name_0 = %s UNION SELECT uid, varname_4 as name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm4 WHERE name_0 = %s AND varname_4 IS NOT NULL", (pycountry.countries.get(alpha_2 = record['countrycode']).name, pycountry.countries.get(alpha_2 = record['countrycode']).name))
                logger1.info(cur.query)
                gadm_records = cur.fetchall()
                #Find candidates for each record
                for gadm_r in gadm_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm4', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(gadm_records)
            else:
                cur.execute("SELECT uid, name_4 as name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm4 UNION SELECT uid, varname_4 as name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm4 WHERE varname_4 IS NOT NULL")
                logger1.info(cur.query)
                gadm4_records = cur.fetchall()
                for gadm_r in gadm4_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(gadm4_records)
        else:
            cur.execute("SELECT uid, name_4 as name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm4 UNION SELECT uid, varname_4 as name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm4 WHERE varname_4 IS NOT NULL")
            logger1.info(cur.query)
            gadm4_records = cur.fetchall()
            for gadm_r in gadm4_records:
                locality_match = match_localities(record['locality'], gadm_r[1])
                if locality_match > settings.min_match:
                    cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                        (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm4', sciname, gadm_r[0], locality_match, gadm_r[2]))
                    logger1.debug(cur.query)
            del(gadm4_records)
    #GADM5
    for record in records:
        if record['countrycode'] != "":
            if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
                cur.execute("SELECT uid, name_5 as name, name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm5 WHERE name_0 = %s", (pycountry.countries.get(alpha_2 = record['countrycode']).name,))
                logger1.info(cur.query)
                gadm_records = cur.fetchall()
                #Find candidates for each record
                for gadm_r in gadm_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm5', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(gadm_records)
            else:
                cur.execute("SELECT uid, name_5 as name, name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm5")
                logger1.info(cur.query)
                gadm5_records = cur.fetchall()
                for gadm_r in gadm5_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm5', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(gadm5_records)
        else:
            cur.execute("SELECT uid, name_5 as name, name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as located_at FROM gadm5")
            logger1.info(cur.query)
            gadm5_records = cur.fetchall()
            for gadm_r in gadm5_records:
                locality_match = match_localities(record['locality'], gadm_r[1])
                if locality_match > settings.min_match:
                    cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                        (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'gadm5', sciname, gadm_r[0], locality_match, gadm_r[2]))
                    logger1.debug(cur.query)
            del(gadm5_records)
    #######
    #WDPA_POLY
    #######
    #Find candidates for each record
    for record in records:
        if record['countrycode'] != "":
            if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
                cur.execute("SELECT uid, name, parent_iso as located_at FROM wdpa_polygons WHERE CHAR_LENGTH(name) > 3 AND parent_iso = %s UNION SELECT uid, orig_name AS name, parent_iso as located_at FROM wdpa_polygons WHERE parent_iso = %s AND lower(name) != 'unknown'", (pycountry.countries.get(alpha_2 = record['countrycode']).alpha_3, pycountry.countries.get(alpha_2 = record['countrycode']).alpha_3))
                logger1.info(cur.query)
                gadm_records = cur.fetchall()
                #only look in country
                for gadm_r in gadm_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'wdpa_polygons', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(gadm_records)
            else:
                #Get WDPA_POLYGONS
                cur.execute("SELECT uid, name, parent_iso as located_at FROM wdpa_polygons WHERE CHAR_LENGTH(name) > 3 UNION SELECT uid, orig_name AS name, parent_iso as located_at FROM wdpa_polygons WHERE CHAR_LENGTH(name) > 3 AND lower(name) != 'unknown'")
                logger1.info(cur.query)
                wdpa_polygons_records = cur.fetchall()
                for gadm_r in wdpa_polygons_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'wdpa_polygons', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(wdpa_polygons_records)
        else:
            #Get WDPA_POLYGONS
            cur.execute("SELECT uid, name, parent_iso as located_at FROM wdpa_polygons WHERE CHAR_LENGTH(name) > 3 UNION SELECT uid, orig_name AS name, parent_iso as located_at FROM wdpa_polygons WHERE CHAR_LENGTH(name) > 3 AND lower(name) != 'unknown'")
            logger1.info(cur.query)
            wdpa_polygons_records = cur.fetchall()
            for gadm_r in wdpa_polygons_records:
                locality_match = match_localities(record['locality'], gadm_r[1])
                if locality_match > settings.min_match:
                    cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                        (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'wdpa_polygons', sciname, gadm_r[0], locality_match, gadm_r[2]))
                    logger1.debug(cur.query)
            del(wdpa_polygons_records)
    #######
    #WDPA_POINTS
    #######
    #Find candidates for each record
    for record in records:
        if record['countrycode'] != "":
            if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
                cur.execute("SELECT uid, name, parent_iso as located_at FROM wdpa_points WHERE CHAR_LENGTH(name) > 3 AND parent_iso = %s UNION SELECT uid, orig_name AS name, parent_iso as located_at FROM wdpa_points WHERE parent_iso = %s AND lower(name) != 'unknown'", (pycountry.countries.get(alpha_2 = record['countrycode']).alpha_3, pycountry.countries.get(alpha_2 = record['countrycode']).alpha_3))
                logger1.info(cur.query)
                gadm_records = cur.fetchall()
                #only look in country
                for gadm_r in gadm_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'wdpa_points', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(gadm_records)
            else:
                cur.execute("SELECT uid, name, parent_iso as located_at FROM wdpa_points WHERE CHAR_LENGTH(name) > 3 UNION SELECT uid, orig_name AS name, parent_iso as located_at FROM wdpa_points WHERE CHAR_LENGTH(name) > 3 AND lower(name) != 'unknown'")
                logger1.info(cur.query)
                wdpa_points_records = cur.fetchall()
                for gadm_r in wdpa_points_records:
                    locality_match = match_localities(record['locality'], gadm_r[1])
                    if locality_match > settings.min_match:
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                            (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'wdpa_points', sciname, gadm_r[0], locality_match, gadm_r[2]))
                        logger1.debug(cur.query)
                del(wdpa_points_records)
        else:
            cur.execute("SELECT uid, name, parent_iso as located_at FROM wdpa_points WHERE CHAR_LENGTH(name) > 3 UNION SELECT uid, orig_name AS name, parent_iso as located_at FROM wdpa_points WHERE CHAR_LENGTH(name) > 3 AND lower(name) != 'unknown'")
            logger1.info(cur.query)
            wdpa_points_records = cur.fetchall()
            for gadm_r in wdpa_points_records:
                locality_match = match_localities(record['locality'], gadm_r[1])
                if locality_match > settings.min_match:
                    cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
                                        (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'wdpa_points', sciname, gadm_r[0], locality_match, gadm_r[2]))
                    logger1.debug(cur.query)
            del(wdpa_points_records)
    #######
    #geonames
    #######
    #Find candidates for each record
    # for record in records:
    #     if record['countrycode'] != "":
    #         cur.execute("SELECT uid, name, country_code as located_at FROM geonames WHERE country_code = %s UNION SELECT uid, alternatenames as name, country_code as located_at FROM geonames WHERE country_code = %s AND alternatenames IS NOT NULL", (record['countrycode'], record['countrycode']))
    #         logger1.info(cur.query)
    #         gadm_records = cur.fetchall()
    #         #only look in country
    #         for gadm_r in gadm_records:
    #             locality_match = match_localities(record['locality'], gadm_r[1])
    #             if locality_match > settings.min_match:
    #                 cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
    #                                     (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'geonames', sciname, gadm_r[0], locality_match, gadm_r[2]))
    #                 logger1.debug(cur.query)
    #         del(gadm_records)
    #     else:
    #         cur.execute("SELECT uid, name, country_code as located_at FROM geonames UNION SELECT uid, alternatenames AS name, country_code as located_at FROM geonames")
    #         logger1.info(cur.query)
    #         geonames_records = cur.fetchall()
    #         for gadm_r in geonames_records:
    #             locality_match = match_localities(record['locality'], gadm_r[1])
    #             if locality_match > settings.min_match:
    #                 cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at) VALUES 
    #                                         (%s, %s, %s, %s, %s, %s)""", (record['gbifid'], 'geonames', sciname, gadm_r[0], locality_match, gadm_r[2]))
    #                 logger1.debug(cur.query)
    #         del(geonames_records)




sys.exit(0)