#!/usr/bin/env python3

"""Get Wikidata dump records as a JSON stream (one JSON object per line) and save the data to a Postgres database."""
# Modified script taken from this link: "https://www.reddit.com/r/LanguageTechnology/comments/7wc2oi/does_anyone_know_a_good_python_library_code/dtzsh2j/"

"""
Based on script at https://akbaritabar.netlify.com/how_to_use_a_wikidata_dump
"""

import json, pydash, os, sys, psycopg2, bz2
from pathlib import Path
#To measure how long it takes
import time


start_time = time.time()


#Get postgres creds
import settings



def wikidata(filename):
    """
    Function that reads the data dump and streams line by line, to avoid trying to 
    load a huge file into memory. Can use either the bz2 compressed version or the
    JSON uncompressed file.
    """
    #Get file extension
    ext = Path(filename).suffix.lower()
    if ext == '.json':
        #Uncompressed JSON
        with open(filename, mode='rt') as f:
            f.read(2) # skip first two bytes: "{\n"
            for line in f:
                try:
                    yield json.loads(line.rstrip(',\n'))
                except json.decoder.JSONDecodeError:
                    continue
    elif ext == '.bz2':
        #Compressed bz2
        with bz2.open(filename, mode='rt') as f:
            f.read(2) # skip first two bytes: "{\n"
            for line in f:
                try:
                    yield json.loads(line.rstrip(',\n'))
                except json.decoder.JSONDecodeError:
                    continue
    else:
        print("ERROR: Unknown format.")
        return False
    
    


if __name__ == '__main__':
    i = 0
    import argparse
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description=__doc__
    )
    parser.add_argument(
        'dumpfile',
        help=(
            'a Wikidata dumpfile from: '
            'https://dumps.wikimedia.org/wikidatawiki/entities/'
            'latest-all.json.bz2'
        )
    )
    args = parser.parse_args()
    #Connect to Postgres
    # Password is read from the user's .pgpass file
    conn = psycopg2.connect(host = settings.host, database = settings.db, user = settings.user)
    conn.autocommit = True
    cur = conn.cursor()
    for record in wikidata(args.dumpfile):
        # only extract items with geographical coordinates (P625)
        if pydash.has(record, 'claims.P625'):
            #Exclude astronomical locations
            if pydash.has(record, 'claims.P376'):
                #Although P376 doesn't explicitly (?) exclude Earth, it is not used, with 
                # a few exceptions, 20 as of June 2019: https://www.wikidata.org/wiki/Property_talk:P376
                # https://petscan.wmflabs.org/?psid=5844683
                # SELECT ?item WHERE {?item wdt:P376 wd:Q2 . }
                continue
            else:
                print('i = {} item {} started!\n'. format(i, record['id']))
                latitude = pydash.get(record, 'claims.P625[0].mainsnak.datavalue.value.latitude')
                longitude = pydash.get(record, 'claims.P625[0].mainsnak.datavalue.value.longitude')
                english_label = pydash.get(record, 'labels.en.value')
                item_id = pydash.get(record, 'id')
                item_type = pydash.get(record, 'type')
                english_desc = pydash.get(record, 'descriptions.en.value')
                #Get labels in multiple languages
                langs = pydash.get(record, 'labels')
                for lang in langs:
                    cur.execute("""
                        INSERT INTO wikidata_names (id, language, name)
                        VALUES (%s, %s, %s);
                        """,
                        (item_id, langs[lang]['language'], langs[lang]['value']))
                #Get descriptions in multiple languages
                langs = pydash.get(record, 'descriptions')
                for lang in langs:
                    cur.execute("""
                        INSERT INTO wikidata_descrip (id, language, description)
                        VALUES (%s, %s, %s);
                        """,
                        (item_id, langs[lang]['language'], langs[lang]['value']))
                cur.execute("""
                    INSERT INTO wikidata_records (id, type, name, latitude, longitude, the_geom)
                    VALUES (%(id)s, %(type)s, %(name)s, %(latitude)s, %(longitude)s, ST_SETSRID(ST_POINT(%(longitude)s, %(latitude)s), 4326));
                    """,
                    {'id': item_id, 'type': item_type, 'name': english_label, 'latitude': latitude, 'longitude': longitude})
                i += 1
    cur.close()
    conn.close()


end_time = time.time()
total_time = end_time - start_time

#Display how many hours it took to run
print("\nScript took {} hrs to complete.\n".format(total_time / 3600))

sys.exit(0)
