# Data Sources

Scripts to extract, scrub, insert to database, or analyze sources of geographical data.

## List of sources

 * [Database of Global Administrative Areas](https://gadm.org) - GADM wants to map the administrative areas of all countries, at all levels of sub-division. It uses high spatial resolution, and of a extensive set of attributes.
 * [GBIF Occurrence Download](https://gbif.org) - GBIF—the Global Biodiversity Information Facility—is an international network and research infrastructure funded by the world’s governments and aimed at providing anyone, anywhere, open access to data about all types of life on Earth.
 * [GeoNames](https://www.geonames.org/) - The GeoNames geographical database covers all countries and contains over eleven million placenames that are available for download free of charge.
 * [Geographic Names Information System](https://www.usgs.gov/core-science-systems/ngp/board-on-geographic-names) - The Geographic Names Information System (GNIS) is the Federal and national standard for geographic nomenclature.
 * [OpenStreetMap](http://www.openstreetmap.org/) - OpenStreetMap is built by a community of mappers that contribute and maintain data about roads, trails, cafés, railway stations, and much more, all over the world.
 * [World Database on Protected Areas](https://www.protectedplanet.net) - The most up to date and complete source of information on protected areas, updated monthly with submissions from governments, non-governmental organizations, landowners and communities. It is managed by the United Nations Environment World Conservation Monitoring Centre (UNEP-WCMC) with support from IUCN and its World Commission on Protected Areas (WCPA).
 * [WikiData](https://www.wikidata.org) - Wikidata is a free and open knowledge base that can be read and edited by both humans and machines.

## Data loading scripts

These scripts have been tested to load the current data dump to a PostgreSQL 10.10 server with the PostGIS package version 2.4 running on Ubuntu 18.04.

 * gadm
 * geonames
 * gnis
 * wdpa
 * wikidata

Scripts still being tested:

 * osm
 * gbif
