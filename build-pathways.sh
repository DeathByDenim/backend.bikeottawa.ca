#!/bin/sh
echo "========================================================"
echo "Starting pathways build on `date`"
echo "========================================================"

NAME=pathways
QUERY_FILE=./osm/$NAME.query
OSM_FILE=./osm/$NAME.osm
JSON_FILE=./osm/$NAME.json
JSON_WITH_STATS=./osm/$NAME+.json
JSON_WITH_STATS_OLD=./osm/$NAME-old.json

#MAPBOX=mapbox                 #for Mac
MAPBOX=~/.local/bin/mapbox   #for Linux
export MAPBOX_ACCESS_TOKEN="[PRIVATE_MAPBOX_TOKEN]"
OSMTOGEOJSON=/usr/local/bin/osmtogeojson
#OSMTOGEOJSON=osmtogeojson
GEOJSONPICK=/usr/local/bin/geojson-pick
#GEOJSONPICK=geojson-pick
PICKTAGS="winter_service surface width smoothness lit id highway footway"

cd ~/backend.bikeottawa.ca

echo "Processing and uploading ALL pathways data ..."

if [ ! -e $QUERY_FILE ]; then
  echo "Error: Missing pathways query file $QUERY_FILE"
  exit 1
fi

rm $OSM_FILE
rm $JSON_FILE
mv $JSON_WITH_STATS $JSON_WITH_STATS_OLD

wget -nv -O $OSM_FILE --post-file=$QUERY_FILE "http://overpass-api.de/api/interpreter"

if [ $? -ne 0 ]; then
  echo "Error: There was a problem running wget."
  exit 1
fi

$OSMTOGEOJSON -m $OSM_FILE | $GEOJSONPICK $PICKTAGS > $JSON_FILE

if [ $? -ne 0 ]; then
  echo "Error: There was a problem running osmtogeojson."
  exit 1
fi

node calc-stats.js $JSON_FILE > $JSON_WITH_STATS

if cmp -s $JSON_WITH_STATS $JSON_WITH_STATS_OLD; then
    echo 'No changes'
    exit 0
fi

$MAPBOX upload bikeottawa.1bli4ynb $JSON_WITH_STATS
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload ALL pathways tileset to Mapbox."
  exit 1
fi
