#!/bin/bash
#
# Pre-process the GBIF occurrence file
#

#Replace backslashes in some text fields
sed -i 's.\\./.g' occurrence.txt

#Break into smaller pieces, each with 5M rows
split -l 5000000 occurrence.txt gbif

#Remove first line (header) in the first file
sed -i '1d' gbifaa
